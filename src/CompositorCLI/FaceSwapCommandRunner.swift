// FaceSwapCommandRunner.swift — face swapping using Core ML InsightFace models
// Models: face-swap-insightface.mlpackage (inswapper_128) + face-recognition-insightface.mlpackage
// (w600k_r50 embedding), both converted by tools/convert_models.py.
// Pipeline: Vision face landmarks → similarity-transform alignment (eyes) →
// recognition embedding of source face → inswapper generation → inverse-map
// feathered paste-back onto the target image.

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
#if canImport(CoreImage)
import CoreImage
#endif

struct FaceSwapCommandRunner {
    let sourceFaceURL: URL       // image containing the source face to swap in
    let targetImageURL: URL      // image where the face will be swapped into
    let model: String            // "insightface"
    let faceIndex: Int?          // target only; nil keeps the default largest face
    let targetBoxText: String?   // "x,y,width,height" in top-left pixels
    let output: URL
    let format: OutputFormat

    /// inswapper canvas size.
    private static let canvasSize = 128
    /// ArcFace recognition input size.
    private static let recInputSize = 112
    /// InsightFace canonical eye template positions (128x128 canvas, y-down).
    private static let templateLeftEye  = CGPoint(x: 0.38202382 * 128, y: 0.39087692 * 128)
    private static let templateRightEye = CGPoint(x: 0.64236082 * 128, y: 0.42770044 * 128)

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Phase 1: Read images
        if CompositorCLI.isVerbose() { fputs("[compositor] Reading images...\n", stderr) }
        guard FileManager.default.fileExists(atPath: sourceFaceURL.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Source face file not found: \(sourceFaceURL.path)", timing: nil)
        }
        guard FileManager.default.fileExists(atPath: targetImageURL.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Target image file not found: \(targetImageURL.path)", timing: nil)
        }
        guard let sourceCG = decodeImage(sourceFaceURL) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode source face image", timing: nil)
        }
        guard let targetCG = decodeImage(targetImageURL) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode target image", timing: nil)
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        // Phase 2: Detect faces + landmark eye centers
        if CompositorCLI.isVerbose() { fputs("[compositor] Detecting faces...\n", stderr) }
        let sourceFace: AlignedFace
        let targetFace: AlignedFace
        do {
            sourceFace = try chosenFace(in: sourceCG, faceIndex: nil, targetBoxText: nil, role: "source")
            targetFace = try chosenFace(in: targetCG, faceIndex: faceIndex, targetBoxText: targetBoxText, role: "target")
        } catch let error as CoreError {
            let kind: CommandErrorType = error.cliErrorType == "renderFailed" ? .renderFailed : .inferenceFailed
            return CommandResult.makeError(kind, detail: error.errorDescription ?? "Face detection failed",
                                           hint: error.cliHint, timing: nil)
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: "Face detection failed: \(error.localizedDescription)", timing: nil)
        }

        let detectPhase = DispatchTime.now()
        phases.append(.init(name: "face_detection", ms: dispatchTimeIntervalMs(readPhase, detectPhase)))

        // Phase 3: Load models
        if CompositorCLI.isVerbose() { fputs("[compositor] Loading face models...\n", stderr) }
        let recModel: MLModel
        let swapModel: MLModel
        do {
            recModel = try ModelLoader.loadModel(for: ModelIdentifier(key: "face-recognition-\(model)"))
            swapModel = try ModelLoader.loadModel(for: ModelIdentifier(key: "face-swap-\(model)"))
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
        phases.append(.init(name: "load_model", ms: dispatchTimeIntervalMs(detectPhase, loadPhase)))

        // Phase 4: Build aligned canvases and extract source embedding
        if CompositorCLI.isVerbose() { fputs("[compositor] Aligning faces...\n", stderr) }
        let embedding: MLMultiArray
        do {
            // Source face canvas → recognition input (resized 128→112)
            let srcCanvas = try renderAlignedCanvas(face: sourceFace, from: sourceCG)
            let recBuffer = try resizePixelBuffer(srcCanvas, to: CGSize(width: Self.recInputSize, height: Self.recInputSize))
            let provider = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: recBuffer)])
            let pred = try recModel.prediction(from: provider)
            guard let feat = pred.featureValue(for: "embedding"), let arr = feat.multiArrayValue else {
                throw CoreError.inferenceFailed(reason: "Recognition model produced no 'embedding' output")
            }
            embedding = try copyAsFloat32(arr)
        } catch let error as CoreError {
            return CommandResult.makeError(.inferenceFailed, detail: error.errorDescription ?? "embedding failed", timing: nil)
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: error.localizedDescription, timing: nil)
        }

        let embedPhase = DispatchTime.now()
        phases.append(.init(name: "face_embedding", ms: dispatchTimeIntervalMs(loadPhase, embedPhase)))

        // Phase 5: Generate swapped face on target canvas
        if CompositorCLI.isVerbose() { fputs("[compositor] Running face swap inference...\n", stderr) }
        let swappedRGBA: [UInt8]
        do {
            let tgtCanvas = try renderAlignedCanvas(face: targetFace, from: targetCG)
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "target": MLFeatureValue(pixelBuffer: tgtCanvas),
                "source": MLFeatureValue(multiArray: embedding),
            ])
            let pred = try swapModel.prediction(from: provider)
            guard let feat = pred.featureValue(for: "output"), let out = feat.multiArrayValue else {
                throw CoreError.inferenceFailed(reason: "Face swap model produced no 'output' feature")
            }
            swappedRGBA = try decodeNormalizedRGB(out, canvas: Self.canvasSize)
        } catch let error as CoreError {
            return CommandResult.makeError(.inferenceFailed, detail: error.errorDescription ?? "swap inference failed", timing: nil)
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: error.localizedDescription, timing: nil)
        }

        let inferPhase = DispatchTime.now()
        phases.append(.init(name: "face_swap", ms: dispatchTimeIntervalMs(embedPhase, inferPhase)))

        // Phase 6: Paste back with feathered blend via inverse transform
        if CompositorCLI.isVerbose() { fputs("[compositor] Blending result...\n", stderr) }
        let finalImage: CGImage
        do {
            finalImage = try pasteCanvas(swappedRGBA, canvas: Self.canvasSize,
                                         transform: targetFace.imageToCanvas, onto: targetCG)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Blending failed: \(error.localizedDescription)", timing: nil)
        }

        let blendPhase = DispatchTime.now()
        phases.append(.init(name: "blend", ms: dispatchTimeIntervalMs(inferPhase, blendPhase)))

        // Phase 7: Write output PNG
        if CompositorCLI.isVerbose() { fputs("[compositor] Writing result...\n", stderr) }
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output file at \(output.path)", timing: nil)
        }
        CGImageDestinationAddImage(destination, finalImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot finalize output image", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(blendPhase, writePhase)))

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Face swap complete. Result written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Face alignment (similarity transform from eye centers)

    /// Image→canvas similarity mapping: canvas = scale · rotate(img - srcMid) + dstMid.
    private struct Similarity {
        let scale: Double
        let cos: Double
        let sin: Double
        let srcMid: CGPoint   // midpoint of eye centers in image pixel coords (y-down)
        let dstMid: CGPoint   // midpoint of eye template in canvas coords (y-down)

        func forward(_ p: CGPoint) -> CGPoint {
            let dx = Double(p.x - srcMid.x), dy = Double(p.y - srcMid.y)
            let rx = cos * dx - sin * dy
            let ry = sin * dx + cos * dy
            return CGPoint(x: dstMid.x + scale * rx, y: dstMid.y + scale * ry)
        }

        func inverse(_ q: CGPoint) -> CGPoint {
            let dx = (Double(q.x - dstMid.x)) / scale, dy = (Double(q.y - dstMid.y)) / scale
            // rotate by -θ
            let rx = cos * dx + sin * dy
            let ry = -sin * dx + cos * dy
            return CGPoint(x: srcMid.x + rx, y: srcMid.y + ry)
        }
    }

    /// A detected face with eye centers and the derived similarity transform.
    private struct AlignedFace {
        let eyeMid: CGPoint          // in image pixel coords (y-down)
        let imageToCanvas: Similarity
    }

    private struct FoundFace {
        let x, y, width, height, confidence: Double
        let aligned: AlignedFace
    }

    private func chosenFace(in cgImage: CGImage, faceIndex: Int?, targetBoxText: String?, role: String) throws -> AlignedFace {
        let found = try alignedFaces(in: cgImage)
        if found.isEmpty {
            throw CoreError.inferenceFailed(reason: "No face detected in \(role) image")
        }
        let box = try parsedTargetBox(targetBoxText)
        guard let index = FaceSelection.choose(
            x: found.map(\.x), y: found.map(\.y), width: found.map(\.width), height: found.map(\.height),
            confidence: found.map(\.confidence), faceIndex: faceIndex, targetBox: box
        ) else {
            throw CoreError.inferenceFailed(
                reason: "No face in the \(role) image matched --face-index/\(role == "target" ? "--target-box" : "selection") (\(found.count) detected)"
            )
        }
        return found[index].aligned
    }

    private func parsedTargetBox(_ text: String?) throws -> (x: Double, y: Double, width: Double, height: Double)? {
        guard let text, !text.isEmpty else { return nil }
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4,
              let x = Double(parts[0]), let y = Double(parts[1]),
              let w = Double(parts[2]), let h = Double(parts[3]),
              x.isFinite, y.isFinite, w.isFinite, h.isFinite, w > 0, h > 0 else {
            throw CoreError.renderFailed(reason: "--target-box must be 'x,y,width,height' with a positive size")
        }
        return (x, y, w, h)
    }

    private func alignedFaces(in cgImage: CGImage) throws -> [FoundFace] {
#if canImport(Vision)
        let request = VNDetectFaceLandmarksRequest()
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else { return [] }

        let w = Double(cgImage.width), h = Double(cgImage.height)
        return observations.map { observation in
            let aligned = align(observation, imageWidth: w, imageHeight: h)
            let bb = observation.boundingBox
            let pw = Double(bb.width) * w
            let ph = Double(bb.height) * h
            let px = Double(bb.origin.x) * w
            let py = (1.0 - Double(bb.origin.y)) * h - ph
            return FoundFace(x: px, y: py, width: pw, height: ph, confidence: Double(observation.confidence), aligned: aligned)
        }
#else
        throw CoreError.inferenceFailed(reason: "Vision Framework not available")
#endif
    }

#if canImport(Vision)
    private func align(_ best: VNFaceObservation, imageWidth w: Double, imageHeight h: Double) -> AlignedFace {
        // Vision: boundingBox is full-image normalized (bottom-left origin);
        // landmark normalizedPoints are RELATIVE to boundingBox (0..1 within it).
        let bb = best.boundingBox
        func pixel(_ point: CGPoint) -> CGPoint {
            let gx = bb.origin.x + point.x * bb.width
            let gy = bb.origin.y + point.y * bb.height
            return CGPoint(x: gx * w, y: (1.0 - gy) * h)
        }

        func eyeCenter(_ region: VNFaceLandmarkRegion2D?) -> CGPoint? {
            guard let region = region, region.pointCount > 0 else { return nil }
            let points = region.normalizedPoints
            var sum = CGPoint.zero
            for i in 0..<region.pointCount {
                sum.x += points[i].x
                sum.y += points[i].y
            }
            return CGPoint(x: sum.x / Double(region.pointCount),
                           y: sum.y / Double(region.pointCount))
        }

        if let landmarks = best.landmarks,
           let le = eyeCenter(landmarks.leftEye),
           let re = eyeCenter(landmarks.rightEye) {
            let lp = pixel(le), rp = pixel(re)
            let eyeMid = CGPoint(x: (lp.x + rp.x) / 2, y: (lp.y + rp.y) / 2)
            let sim = similarityFromEyes(leftEye: lp, rightEye: rp,
                                         leftTemplate: Self.templateLeftEye,
                                         rightTemplate: Self.templateRightEye)
            return AlignedFace(eyeMid: eyeMid, imageToCanvas: sim)
        }

        // Fallback: bbox-based canonical eye placement (approximate alignment).
        let x = Double(bb.origin.x) * w
        let y = (1 - Double(bb.origin.y) - Double(bb.height)) * h
        let bw = Double(bb.width) * w, bh = Double(bb.height) * h
        // Standard heuristic: eyes at ~35% height, ~30%/70% width within bbox.
        let le = CGPoint(x: x + bw * 0.30, y: y + bh * 0.35)
        let re = CGPoint(x: x + bw * 0.70, y: y + bh * 0.35)
        let sim = similarityFromEyes(leftEye: le, rightEye: re,
                                     leftTemplate: Self.templateLeftEye,
                                     rightTemplate: Self.templateRightEye)
        let eyeMid = CGPoint(x: (le.x + re.x) / 2, y: (le.y + re.y) / 2)
        return AlignedFace(eyeMid: eyeMid, imageToCanvas: sim)
    }
#endif

    private func similarityFromEyes(leftEye: CGPoint, rightEye: CGPoint,
                                    leftTemplate: CGPoint, rightTemplate: CGPoint) -> Similarity {
        let vp = CGPoint(x: rightEye.x - leftEye.x, y: rightEye.y - leftEye.y)
        let vq = CGPoint(x: rightTemplate.x - leftTemplate.x, y: rightTemplate.y - leftTemplate.y)
        let scale = Double(vq.x * vq.x + vq.y * vq.y) / max(Double(vp.x * vp.x + vp.y * vp.y), 1e-9)
        let s = (scale).squareRoot()
        let theta = atan2(Double(vq.y), Double(vq.x)) - atan2(Double(vp.y), Double(vp.x))
        return Similarity(
            scale: s, cos: cos(theta), sin: sin(theta),
            srcMid: CGPoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2),
            dstMid: CGPoint(x: (leftTemplate.x + rightTemplate.x) / 2, y: (leftTemplate.y + rightTemplate.y) / 2)
        )
    }

    // MARK: - Canvas rendering (y-down canvas with inverse-mapped bilinear sampling)

    private func renderAlignedCanvas(face: AlignedFace, from cgImage: CGImage) throws -> CVPixelBuffer {
        let n = Self.canvasSize
        let rgba = try extractRGBA(cgImage)   // top-first rows, read via sampleYDown
        let iw = cgImage.width, ih = cgImage.height

        var canvas = [UInt8](repeating: 0, count: n * n * 4)  // A,R,G,B byte order (32ARGB layout)
        for v in 0..<n {
            for u in 0..<n {
                let img = face.imageToCanvas.inverse(CGPoint(x: Double(u) + 0.5, y: Double(v) + 0.5))
                let outIdx = (v * n + u) * 4
                if let sample = sampleYDown(rgba, w: iw, h: ih, x: img.x, y: img.y) {
                    canvas[outIdx]     = 255  // A
                    canvas[outIdx + 1] = UInt8(min(255.0, max(0.0, sample.0)))  // R
                    canvas[outIdx + 2] = UInt8(min(255.0, max(0.0, sample.1)))  // G
                    canvas[outIdx + 3] = UInt8(min(255.0, max(0.0, sample.2)))  // B
                } else {
                    // Nearest inside fallback at borders, else zero.
                    let nx = min(max(Int(img.x), 0), iw - 1)
                    let ny = min(max(Int(img.y), 0), ih - 1)
                    if img.x >= -1, img.y >= -1, img.x <= Double(iw), img.y <= Double(ih),
                       let near = sampleNearestYDown(rgba, w: iw, h: ih, x: nx, y: ny) {
                        canvas[outIdx] = 255
                        canvas[outIdx + 1] = UInt8(near.r)
                        canvas[outIdx + 2] = UInt8(near.g)
                        canvas[outIdx + 3] = UInt8(near.b)
                    }
                }
            }
        }

        var pb: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, n, n, kCVPixelFormatType_32ARGB,
                                         [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary,
                                         &pb)
        guard status == kCVReturnSuccess, let buffer = pb else {
            throw CoreError.renderFailed(reason: "Failed to create canvas pixel buffer")
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else {
            throw CoreError.renderFailed(reason: "Failed to lock canvas buffer")
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        // Canvas is filled with row 0 = top row (y-down), matching PIL/CoreML pixel-buffer convention.
        canvas.withUnsafeBytes { raw in
            let basePtr = raw.baseAddress!
            for row in 0..<n {
                memcpy(base.advanced(by: row * bytesPerRow),
                       basePtr.advanced(by: row * n * 4), n * 4)
            }
        }
        return buffer
    }

    private func resizePixelBuffer(_ buffer: CVPixelBuffer, to size: CGSize) throws -> CVPixelBuffer {
        var out: CVPixelBuffer?
        let w = Int(size.width), h = Int(size.height)
        let status = CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32ARGB,
                                         [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary,
                                         &out)
        guard status == kCVReturnSuccess, let dst = out else {
            throw CoreError.renderFailed(reason: "Failed to create resized buffer")
        }
        let ci = CIImage(cvPixelBuffer: buffer)
        let sx = Double(w) / Double(CVPixelBufferGetWidth(buffer))
        let sy = Double(h) / Double(CVPixelBufferGetHeight(buffer))
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        CIContext().render(scaled, to: dst)
        return dst
    }

    // MARK: - Pixel helpers

    /// Shared sRGB working space. All model I/O and blending happen in sRGB:
    /// drawing a tagged (e.g., Adobe RGB) image into an sRGB context color-manages
    /// it correctly, so model inputs match training convention and the output PNG
    /// (sRGB-tagged) renders with correct colors.
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// Extract RGBA bytes in CGContext memory order: buffer row 0 = TOP row of the
    /// image (verified: PNG written from this context matches JPEG decode row-for-row).
    /// Use `sampleYDown` with y-down image coordinates to read.
    /// Color-managed to sRGB.
    private func extractRGBA(_ cgImage: CGImage) throws -> [UInt8] {
        let w = cgImage.width, h = cgImage.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: Self.sRGB,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)) else {
            throw CoreError.renderFailed(reason: "Cannot create RGBA context")
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return rgba
    }

    /// Bilinear sample with y-down image coordinates (0 ≤ x < w, 0 ≤ y < h).
    /// Returns (r,g,b,a) or nil when completely outside.
    private func sampleYDown(_ rgba: [UInt8], w: Int, h: Int, x: Double, y: Double) -> (Double, Double, Double, Double)? {
        let fx = x - 0.5, fy = y - 0.5
        let x0 = Int(floor(fx)), yDown0 = Int(floor(fy))
        let tx = fx - Double(x0), ty = fy - Double(yDown0)
        if x0 < 0 || yDown0 < 0 || x0 + 1 >= w || yDown0 + 1 >= h { return nil }
        // Buffer row 0 = top image row, so y-down row r ↔ buffer row r.
        let b0 = yDown0               // row of (x0, yDown0)
        let b1 = yDown0 + 1           // row of (x0, yDown0+1)
        let i00 = (b0 * w + x0) * 4
        let i01 = (b0 * w + x0 + 1) * 4
        let i10 = (b1 * w + x0) * 4
        let i11 = (b1 * w + x0 + 1) * 4
        var out: (Double, Double, Double, Double) = (0, 0, 0, 0)
        for c in 0..<4 {
            let a = Double(rgba[i00 + c]) * (1 - tx) + Double(rgba[i01 + c]) * tx
            let bb = Double(rgba[i10 + c]) * (1 - tx) + Double(rgba[i11 + c]) * tx
            let v = a * (1 - ty) + bb * ty
            if c == 0 { out.0 = v } else if c == 1 { out.1 = v } else if c == 2 { out.2 = v } else { out.3 = v }
        }
        return out
    }

    /// Nearest sample with y-down coordinates; nil outside.
    private func sampleNearestYDown(_ rgba: [UInt8], w: Int, h: Int, x: Int, y: Int) -> (r: Int, g: Int, b: Int, a: Int)? {
        if x < 0 || y < 0 || x >= w || y >= h { return nil }
        let i = (y * w + x) * 4
        return (Int(rgba[i]), Int(rgba[i + 1]), Int(rgba[i + 2]), Int(rgba[i + 3]))
    }

    private func copyAsFloat32(_ array: MLMultiArray) throws -> MLMultiArray {
        let count = array.count
        let out = try MLMultiArray(shape: array.shape, dataType: .float32)
        let dst = out.dataPointer.bindMemory(to: Float32.self, capacity: count)
        switch array.dataType {
        case .float32:
            let src = array.dataPointer.bindMemory(to: Float32.self, capacity: count)
            for i in 0..<count { dst[i] = src[i] }
        case .double:
            let src = array.dataPointer.bindMemory(to: Double.self, capacity: count)
            for i in 0..<count { dst[i] = Float32(src[i]) }
        default:
            for i in 0..<count { dst[i] = Float32(truncating: array[i]) }
        }
        return out
    }

    /// Model output is [1,3,H,W] normalized [0,1] → RGBA y-down.
    private func decodeNormalizedRGB(_ array: MLMultiArray, canvas n: Int) throws -> [UInt8] {
        let dims = array.shape.map { $0.intValue }
        guard dims.count == 4, dims[2] == n, dims[3] == n else {
            throw CoreError.inferenceFailed(reason: "Unexpected swap output shape \(dims)")
        }
        let hw = n * n
        var values = [Double](repeating: 0, count: 3 * hw)
        switch array.dataType {
        case .float32:
            array.dataPointer.withMemoryRebound(to: Float32.self, capacity: 3 * hw) { ptr in
                for i in 0..<(3 * hw) { values[i] = Double(ptr[i]) }
            }
        case .double:
            array.dataPointer.withMemoryRebound(to: Double.self, capacity: 3 * hw) { ptr in
                for i in 0..<(3 * hw) { values[i] = ptr[i] }
            }
        default:
            for i in 0..<(3 * hw) { values[i] = array[i].doubleValue }
        }

        var rgba = [UInt8](repeating: 0, count: n * n * 4)
        for v in 0..<n {
            for u in 0..<n {
                let idx = v * n + u
                let r = values[0 * hw + idx]
                let g = values[1 * hw + idx]
                let b = values[2 * hw + idx]
                rgba[idx * 4]     = UInt8(min(255.0, max(0.0, r * 255.0)))
                rgba[idx * 4 + 1] = UInt8(min(255.0, max(0.0, g * 255.0)))
                rgba[idx * 4 + 2] = UInt8(min(255.0, max(0.0, b * 255.0)))
                rgba[idx * 4 + 3] = 255
            }
        }
        return rgba
    }

    /// Feathered paste of the canvas back onto the image through the inverse transform.
    private func pasteCanvas(_ canvasRGBA: [UInt8], canvas n: Int,
                             transform: Similarity, onto image: CGImage) throws -> CGImage {
        let w = image.width, h = image.height
        var rgba = try extractRGBA(image)

        let feather: Double = 10.0
        // Iterate canvas pixels; map to image space and blend where inside.
        for v in 0..<n {
            for u in 0..<n {
                let imgPt = transform.inverse(CGPoint(x: Double(u) + 0.5, y: Double(v) + 0.5))
                let px = Int(imgPt.x), py = Int(imgPt.y)
                if px < 0 || py < 0 || px >= w || py >= h { continue }

                // Feather: distance to canvas border in canvas units.
                let edge = min(Double(u), Double(n - 1 - u), Double(v), Double(n - 1 - v))
                let a = max(0.0, min(1.0, edge / feather))
                if a <= 0 { continue }

                let si = (v * n + u) * 4
                // Buffer row 0 = top image row: y-down row py ↔ buffer row py.
                let di = (py * w + px) * 4
                for c in 0..<3 {
                    let dst = Double(rgba[di + c])
                    let src = Double(canvasRGBA[si + c])
                    rgba[di + c] = UInt8(min(255.0, max(0.0, src * a + dst * (1.0 - a))))
                }
                rgba[di + 3] = 255
            }
        }

        guard let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: Self.sRGB,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
              let out = ctx.makeImage() else {
            throw CoreError.renderFailed(reason: "Cannot create blended image")
        }
        return out
    }

    // MARK: - Helpers

    private func decodeImage(_ url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
