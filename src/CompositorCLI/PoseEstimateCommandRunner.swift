// PoseEstimateCommandRunner.swift — body keypoint estimation using Core ML RTMPose model
// Model: rtmpose-m 256x192 (SimCC head), converted via tools/convert_models.py.
// People are detected first (Vision human rectangles, or the whole frame when
// none are found). Each box is fit with pose_fit and the keypoints are unmapped
// with pose_unmap. Stdout is the multi-person JSON from pose_people_json.

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore
#if canImport(CoreML)
@preconcurrency import CoreML
#endif
#if canImport(Vision)
@preconcurrency import Vision
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif

struct PoseEstimateOutcome {
    let result: CommandResult
    /// Multi-person document without a trailing newline. Nil on failure.
    let document: String?
}

struct PoseEstimateCommandRunner {
    let input: URL
    let model: String        // "rtmpose" or "dwpose"
    let output: URL
    let format: OutputFormat

    /// SimCC split ratio used by RTMPose heads (simcc width = input_width * ratio).
    private static let simccSplitRatio = 2.0
    /// Padding around the full-image bbox, matching MMPose whole-image inference.
    private static let bboxPadding = 1.25

    func execute() throws -> PoseEstimateOutcome {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Phase 1: Read input image
        if CompositorCLI.isVerbose() { fputs("[compositor] Reading input...\n", stderr) }
        guard FileManager.default.fileExists(atPath: input.path) else {
            return failure(.fileNotFound, detail: "Input file not found: \(input.path)")
        }

        let imageData = try Data(contentsOf: input)
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return failure(.invalidImageFormat, detail: "Cannot decode image at \(input.path)")
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        // Phase 2: Load Core ML model
        if CompositorCLI.isVerbose() { fputs("[compositor] Loading pose estimation model...\n", stderr) }
        let mlModel: MLModel
        let inputW: Int
        let inputH: Int
        do {
            mlModel = try ModelLoader.loadModel(for: ModelIdentifier(key: "pose-\(model)"))
            guard let imageDesc = mlModel.modelDescription.inputDescriptionsByName.values.first(where: { $0.type == .image }),
                  let constraint = imageDesc.imageConstraint else {
                return failure(.inferenceFailed, detail: "Pose model has no image input")
            }
            inputW = Int(constraint.pixelsWide)
            inputH = Int(constraint.pixelsHigh)
        } catch let error as CoreError {
            let kind: CommandErrorType = error.cliErrorType == "modelMissing" ? .modelMissing : .inferenceFailed
            return PoseEstimateOutcome(
                result: CommandResult.makeError(
                    kind,
                    detail: error.errorDescription ?? "model load failed",
                    hint: error.cliHint ?? "Convert with 'python3 tools/convert_models.py \(model)'",
                    timing: nil
                ),
                document: nil
            )
        } catch {
            return failure(.inferenceFailed, detail: error.localizedDescription)
        }

        let loadPhase = DispatchTime.now()
        phases.append(.init(name: "load_model", ms: dispatchTimeIntervalMs(readPhase, loadPhase)))

        // Phase 3: Detect people, then estimate each one. No detections fall back to the whole frame.
        if CompositorCLI.isVerbose() { fputs("[compositor] Detecting people...\n", stderr) }
        let people: [PosePersonBox]
        do {
            people = try detectedPeople(in: cgImage)
        } catch {
            return failure(.inferenceFailed, detail: "Person detection failed: \(error.localizedDescription)")
        }

        let detectPhase = DispatchTime.now()
        phases.append(.init(name: "person_detection", ms: dispatchTimeIntervalMs(loadPhase, detectPhase)))

        if CompositorCLI.isVerbose() { fputs("[compositor] Estimating \(people.count) person(s)...\n", stderr) }
        var estimated: [(box: PosePersonBox, keypoints: [PoseKeypointValue])] = []
        do {
            for person in people {
                let fit = try PoseLayout.fit(
                    box: person, padding: Self.bboxPadding,
                    canvasWidth: Double(inputW), canvasHeight: Double(inputH)
                )
                let buffer = try renderCanvas(
                    from: cgImage, scale: fit.scale, centerX: fit.centerX, centerY: fit.centerY,
                    canvasWidth: inputW, canvasHeight: inputH
                )
                let keypoints = try runPoseInference(
                    model: mlModel, input: buffer,
                    scale: fit.scale, centerX: fit.centerX, centerY: fit.centerY,
                    canvasWidth: Double(inputW), canvasHeight: Double(inputH),
                    splitRatio: Self.simccSplitRatio
                )
                estimated.append((person, keypoints))
            }
        } catch let error as CoreError {
            return failure(.inferenceFailed, detail: error.errorDescription ?? "inference failed")
        } catch {
            return failure(.inferenceFailed, detail: error.localizedDescription)
        }

        let inferencePhase = DispatchTime.now()
        phases.append(.init(name: "pose_estimation", ms: dispatchTimeIntervalMs(detectPhase, inferencePhase)))

        let document: String
        do {
            document = try PoseLayout.peopleJSON(width: cgImage.width, height: cgImage.height, people: estimated)
            let directory = output.deletingLastPathComponent()
            if !directory.path.isEmpty && !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            try (document + "\n").write(to: output, atomically: true, encoding: .utf8)
        } catch {
            return failure(.renderFailed, detail: "Cannot write output: \(error.localizedDescription)")
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(inferencePhase, writePhase)))
        _ = format
        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)
        return PoseEstimateOutcome(
            result: CommandResult.makeSuccess(output: output.path, timing: timing),
            document: document
        )
    }

    private func failure(_ type: CommandErrorType, detail: String) -> PoseEstimateOutcome {
        PoseEstimateOutcome(result: CommandResult.makeError(type, detail: detail, timing: nil), document: nil)
    }

    /// Vision rectangles when available. An empty detection becomes one full-frame box
    /// so a single subject still gets a pose. Ordering is PoseLayout.sorted.
    private func detectedPeople(in image: CGImage) throws -> [PosePersonBox] {
        let width = Double(image.width)
        let height = Double(image.height)
        var boxes: [PosePersonBox] = []
#if canImport(Vision)
        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        if let observations = request.results as? [VNHumanObservation] {
            for observation in observations {
                let rect = observation.boundingBox
                let boxW = Double(rect.width) * width
                let boxH = Double(rect.height) * height
                let boxX = Double(rect.origin.x) * width
                let boxY = (1.0 - Double(rect.origin.y)) * height - boxH
                guard boxW > 1, boxH > 1 else { continue }
                boxes.append(PosePersonBox(
                    x: boxX, y: boxY, width: boxW, height: boxH, score: Double(observation.confidence)
                ))
            }
        }
#endif
        if boxes.isEmpty {
            boxes = [PosePersonBox(x: 0, y: 0, width: width, height: height, score: 0)]
        }
        return try PoseLayout.sorted(boxes)
    }

    /// Draw the source so pose_unmap is the inverse. Scale and center come from pose_fit.
    private func renderCanvas(
        from cgImage: CGImage, scale: Double, centerX: Double, centerY: Double,
        canvasWidth: Int, canvasHeight: Int
    ) throws -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, canvasWidth, canvasHeight, kCVPixelFormatType_32ARGB,
            [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary,
            &pb
        )
        guard status == kCVReturnSuccess, let buffer = pb else {
            throw CoreError.renderFailed(reason: "Failed to create CVPixelBuffer")
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let ctx = CGContext(
                data: base, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpace(name: CGColorSpace.sRGB),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
              ) else {
            throw CoreError.renderFailed(reason: "Failed to create preprocessing context")
        }
        ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        let canvasW = Double(canvasWidth)
        let canvasH = Double(canvasHeight)
        let drawW = Double(cgImage.width) * scale
        let drawH = Double(cgImage.height) * scale
        let x0 = canvasW * 0.5 + (0 - centerX) * scale
        let yDown0 = canvasH * 0.5 + (0 - centerY) * scale
        let yCg0 = canvasH - yDown0 - drawH
        ctx.draw(cgImage, in: CGRect(x: x0, y: yCg0, width: drawW, height: drawH))
        return buffer
    }

    // MARK: - Inference

    private func runPoseInference(model: MLModel, input: CVPixelBuffer,
                                  scale: Double, centerX: Double, centerY: Double,
                                  canvasWidth: Double, canvasHeight: Double,
                                  splitRatio: Double) throws -> [PoseKeypointValue] {
#if canImport(CoreML)
        let provider = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: input)])
        let prediction = try model.prediction(from: provider)

        guard let featX = prediction.featureValue(for: "simcc_x"),
              let simccX = featX.multiArrayValue,
              let featY = prediction.featureValue(for: "simcc_y"),
              let simccY = featY.multiArrayValue else {
            throw CoreError.inferenceFailed(reason: "Pose model did not produce simcc_x/simcc_y outputs")
        }

        // Shapes: [1, numKeypoints, 2*W] and [1, numKeypoints, 2*H].
        let dimsX = simccX.shape.map { $0.intValue }
        guard dimsX.count == 3 else {
            throw CoreError.inferenceFailed(reason: "Unexpected simcc_x shape \(dimsX)")
        }
        let numK = dimsX[1]
        let dimX = dimsX[2]
        let dimY = simccY.shape.map { $0.intValue }[2]

        // Read distributions (may be FLOAT16 → read via NSNumber conversion path).
        let valuesX = try toArray(simccX)
        let valuesY = try toArray(simccY)

        let inputW = Double(dimX) / splitRatio
        let inputH = Double(dimY) / splitRatio

        var keypoints: [PoseKeypointValue] = []
        for k in 0..<numK {
            var bestXi = 0, bestYi = 0
            var bestXv = -Double.infinity, bestYv = -Double.infinity
            for i in 0..<dimX where valuesX[k * dimX + i] > bestXv {
                bestXv = valuesX[k * dimX + i]; bestXi = i
            }
            for j in 0..<dimY where valuesY[k * dimY + j] > bestYv {
                bestYv = valuesY[k * dimY + j]; bestYi = j
            }
            let score = min(bestXv, bestYv)

            // SimCC coords → canvas pixel (y-down), then unmap to image pixels.
            let mapped = try PoseLayout.unmap(
                canvasX: Double(bestXi) / splitRatio,
                canvasY: Double(bestYi) / splitRatio,
                scale: scale, centerX: centerX, centerY: centerY,
                canvasWidth: canvasWidth, canvasHeight: canvasHeight
            )
            _ = inputW; _ = inputH
            keypoints.append(PoseKeypointValue(id: k, x: mapped.x, y: mapped.y, confidence: score))
        }
        return keypoints
#else
        throw CoreError.inferenceFailed(reason: "CoreML not available on this platform")
#endif
    }

    /// Flatten an MLMultiArray into [Double] regardless of storage dtype.
    private func toArray(_ array: MLMultiArray) throws -> [Double] {
        let count = array.count
        var out = [Double](repeating: 0, count: count)
        switch array.dataType {
        case .double:
            array.dataPointer.withMemoryRebound(to: Double.self, capacity: count) { ptr in
                for i in 0..<count { out[i] = ptr[i] }
            }
        case .float32:
            array.dataPointer.withMemoryRebound(to: Float32.self, capacity: count) { ptr in
                for i in 0..<count { out[i] = Double(ptr[i]) }
            }
        case .float16:
            for i in 0..<count { out[i] = array[i].doubleValue }
        case .int32:
            array.dataPointer.withMemoryRebound(to: Int32.self, capacity: count) { ptr in
                for i in 0..<count { out[i] = Double(ptr[i]) }
            }
        case .int8:
            array.dataPointer.withMemoryRebound(to: Int8.self, capacity: count) { ptr in
                for i in 0..<count { out[i] = Double(ptr[i]) }
            }
        @unknown default:
            for i in 0..<count { out[i] = array[i].doubleValue }
        }
        return out
    }

    // MARK: - Timing Helper

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
