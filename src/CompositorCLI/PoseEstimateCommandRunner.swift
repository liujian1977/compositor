// PoseEstimateCommandRunner.swift — body keypoint estimation using Core ML RTMPose model
// Model: rtmpose-m 256x192 (SimCC head), converted via tools/convert_models.py.
// Pipeline mirrors the reference preprocessing: full-image bbox (padding 1.25),
// aspect-ratio-preserving fit into 192x256, model applies ImageNet normalization
// internally, output decoded via SimCC argmax / split_ratio.

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore
#if canImport(CoreML)
@preconcurrency import CoreML
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif

/// Represents a single body keypoint with position and confidence (COCO-17 layout).
struct Keypoint: Codable {
    let id: Int
    let name: String
    let x: Double
    let y: Double
    let confidence: Double
}

private let cocoKeypointNames = [
    "nose", "left_eye", "right_eye", "left_ear", "right_ear",
    "left_shoulder", "right_shoulder", "left_elbow", "right_elbow",
    "left_wrist", "right_wrist", "left_hip", "right_hip",
    "left_knee", "right_knee", "left_ankle", "right_ankle",
]

struct PoseEstimateCommandRunner {
    let input: URL
    let model: String        // "rtmpose" or "dwpose"
    let output: URL
    let format: OutputFormat

    /// SimCC split ratio used by RTMPose heads (simcc width = input_width * ratio).
    private static let simccSplitRatio = 2.0
    /// Padding around the full-image bbox, matching MMPose whole-image inference.
    private static let bboxPadding = 1.25

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Phase 1: Read input image
        if CompositorCLI.isVerbose() { fputs("[compositor] Reading input...\n", stderr) }
        guard FileManager.default.fileExists(atPath: input.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Input file not found: \(input.path)", timing: nil)
        }

        let imageData = try Data(contentsOf: input)
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode image at \(input.path)", timing: nil)
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
                return CommandResult.makeError(.inferenceFailed, detail: "Pose model has no image input", timing: nil)
            }
            inputW = Int(constraint.pixelsWide)
            inputH = Int(constraint.pixelsHigh)
        } catch let error as CoreError {
            return CommandResult.makeError(
                error.cliErrorType == "modelMissing" ? .modelMissing : .inferenceFailed,
                detail: error.errorDescription ?? "model load failed",
                hint: error.cliHint ?? "Convert with 'python3 tools/convert_models.py \(model)'",
                timing: nil
            )
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: error.localizedDescription, timing: nil)
        }

        let loadPhase = DispatchTime.now()
        phases.append(.init(name: "load_model", ms: dispatchTimeIntervalMs(readPhase, loadPhase)))

        // Phase 3: Preprocess — aspect-preserving fit of the padded full image
        if CompositorCLI.isVerbose() { fputs("[compositor] Preprocessing image...\n", stderr) }
        let fit: FitTransform
        let pixelBuffer: CVPixelBuffer
        do {
            fit = try FitTransform(imageSize: CGSize(width: cgImage.width, height: cgImage.height),
                                   canvasSize: CGSize(width: inputW, height: inputH),
                                   padding: Self.bboxPadding)
            pixelBuffer = try fit.makePixelBuffer(from: cgImage)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Preprocessing failed: \(error.localizedDescription)", timing: nil)
        }

        let preprocessPhase = DispatchTime.now()
        phases.append(.init(name: "preprocess", ms: dispatchTimeIntervalMs(loadPhase, preprocessPhase)))

        // Phase 4: Run Core ML inference + SimCC decode
        if CompositorCLI.isVerbose() { fputs("[compositor] Running pose estimation...\n", stderr) }
        let keypoints: [Keypoint]
        do {
            keypoints = try runPoseInference(model: mlModel, input: pixelBuffer,
                                             fit: fit, splitRatio: Self.simccSplitRatio)
        } catch let error as CoreError {
            return CommandResult.makeError(.inferenceFailed, detail: error.errorDescription ?? "inference failed", timing: nil)
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: error.localizedDescription, timing: nil)
        }

        let inferencePhase = DispatchTime.now()
        phases.append(.init(name: "pose_estimation", ms: dispatchTimeIntervalMs(preprocessPhase, inferencePhase)))

        // Phase 5: Write output JSON
        if CompositorCLI.isVerbose() { fputs("[compositor] Writing results...\n", stderr) }
        do {
            try writeKeypointsOutput(keypoints, to: output)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Cannot write output: \(error.localizedDescription)", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(inferencePhase, writePhase)))

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Detected \(keypoints.count) keypoint(s). Results written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Preprocessing (aspect-preserving fit, no rotation)

    /// Maps the source image into the model canvas with uniform scale + centering.
    /// Equivalent to MMPose's warpAffine with rot=0 and aspect-fixed bbox scale.
    private struct FitTransform {
        let scale: Double          // uniform source->canvas scale
        let center: CGPoint        // source center in source pixel coords
        let canvasCenter: CGPoint  // canvas center
        let canvasSize: CGSize

        init(imageSize: CGSize, canvasSize: CGSize, padding: Double) throws {
            guard imageSize.width > 0, imageSize.height > 0 else {
                throw CoreError.invalidImageFormat(url: URL(fileURLWithPath: "?"), reason: "empty image")
            }
            let bboxW = Double(imageSize.width) * padding
            let bboxH = Double(imageSize.height) * padding
            // Fix aspect ratio to canvas aspect, like MMPose _fix_aspect_ratio.
            // With a full-image bbox the fixed bbox is always canvas-aspect, so
            // uniform scale = canvas width / fixed bbox width.
            let canvasAspect = Double(canvasSize.width) / Double(canvasSize.height)
            let fixedW = max(bboxW, bboxH * canvasAspect)
            self.scale = Double(canvasSize.width) / fixedW
            self.center = CGPoint(x: Double(imageSize.width) / 2, y: Double(imageSize.height) / 2)
            self.canvasCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            self.canvasSize = canvasSize
        }

        func makePixelBuffer(from cgImage: CGImage) throws -> CVPixelBuffer {
            let w = Int(canvasSize.width), h = Int(canvasSize.height)
            var pb: CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32ARGB,
                                             [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                                              kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary,
                                             &pb)
            guard status == kCVReturnSuccess, let buffer = pb else {
                throw CoreError.renderFailed(reason: "Failed to create CVPixelBuffer")
            }
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            guard let base = CVPixelBufferGetBaseAddress(buffer),
                  let ctx = CGContext(data: base, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpace(name: CGColorSpace.sRGB),
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)) else {
                throw CoreError.renderFailed(reason: "Failed to create preprocessing context")
            }
            ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

            // In canvas coords (y-down) the image content maps to:
            //   x: [cx - scale*imgW/2, cx + scale*imgW/2]
            //   y: [cy - scale*imgH/2, cy + scale*imgH/2]
            // CGContext is y-up, so mirror vertically: y_cg = canvasH - y_down.
            let imgW = Double(cgImage.width) * scale
            let imgH = Double(cgImage.height) * scale
            let x0 = canvasCenter.x - imgW / 2
            let yDown0 = canvasCenter.y - imgH / 2
            let yCg0 = Double(canvasSize.height) - yDown0 - imgH
            ctx.draw(cgImage, in: CGRect(x: x0, y: yCg0, width: imgW, height: imgH))
            return buffer
        }

        /// Map a canvas-space keypoint (y-down, before split ratio) back to image pixels.
        func unmap(canvasPoint: CGPoint) -> CGPoint {
            let s = CGFloat(scale)
            let cx = CGFloat(center.x), cy = CGFloat(center.y)
            // dst = (p - canvasCenter)/scale + center, inverse of draw mapping.
            let x = (canvasPoint.x - canvasCenter.x) / s + cx
            let y = (canvasPoint.y - canvasCenter.y) / s + cy
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Inference

    private func runPoseInference(model: MLModel, input: CVPixelBuffer,
                                  fit: FitTransform, splitRatio: Double) throws -> [Keypoint] {
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

        var keypoints: [Keypoint] = []
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
            let canvasPt = CGPoint(x: Double(bestXi) / splitRatio, y: Double(bestYi) / splitRatio)
            _ = inputW; _ = inputH  // unmap uses fit.scale/centers derived from same aspect
            let imgPt = fit.unmap(canvasPoint: canvasPt)

            keypoints.append(Keypoint(
                id: k,
                name: k < cocoKeypointNames.count ? cocoKeypointNames[k] : "keypoint_\(k)",
                x: imgPt.x,
                y: imgPt.y,
                confidence: score
            ))
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

    // MARK: - Output Writing

    private func writeKeypointsOutput(_ keypoints: [Keypoint], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let data = try encoder.encode(keypoints)
        try data.write(to: url)
    }

    // MARK: - Timing Helper

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
