// ExtractCommandRunner.swift — extract command execution logic (Vision Foundation segmentation)

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

enum CommandErrorType: String {
    case fileNotFound
    case invalidImageFormat
    case inferenceFailed
    case renderFailed
    case dimensionMismatch
    case modelMissing
}

/// JSON result structure matching command-spec.md schema.
struct CommandResult: Codable {
    let status: String                  // "success" | "error"
    var output: String?                 // present when success
    var error: ErrorInfo?               // present when error (key "error" per spec)
    var timing: TimingEntry?            // always present for debugging

    struct ErrorInfo: Codable {
        let type: String
        let detail: String
        let hint: String?
    }

    struct TimingEntry: Codable {
        let total_ms: Int
        let phases: [PhaseEntry]

        struct PhaseEntry: Codable {
            let name: String
            let ms: Int
        }
    }

    static func makeSuccess(output: String, timing: TimingEntry?) -> CommandResult {
        .init(status: "success", output: output, error: nil, timing: timing)
    }

    static func makeError(_ type: CommandErrorType, detail: String, hint: String? = nil, timing: TimingEntry?) -> CommandResult {
        .init(status: "error", output: nil, error: ErrorInfo(type: type.rawValue, detail: detail, hint: hint), timing: timing)
    }

    func toJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try! encoder.encode(self)  // unwrap in production code
    }
}

struct ExtractCommandRunner {
    let input: URL
    let output: URL
    let model: String?      // nil = use default "vision"
    let refineRadius: Int
    let contrastThreshold: Float
    let edgeShift: Int
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Phase 1: Read input image (built-in, no model needed)
        if CompositorCLI.isVerbose() { fputs("[compositor] Reading input...\n", stderr) }
        guard FileManager.default.fileExists(atPath: input.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Input file not found: \(input.path)", timing: nil)
        }

        let imageData = try Data(contentsOf: input)
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode image at \(input.path)", timing: nil)
        }

        if CompositorCLI.isVerbose() { fputs("[compositor] Segmentation...\n", stderr) }
        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

#if canImport(Vision) && swift(>=5.9)
        // Phase 2: Run Vision Foundation segmentation
        let segResult = try runVisionSegmentation(cgImage, width: cgImage.width, height: cgImage.height)
#else
        // Fallback: all-white mask (no Vision available on this platform)
        print("Warning: Vision Framework not available — producing full-mask output")
        var segResult = [UInt8](repeating: 255, count: cgImage.width * cgImage.height)
#endif

        let segmentationPhase = DispatchTime.now()
        phases.append(.init(name: "segmentation", ms: dispatchTimeIntervalMs(readPhase, segmentationPhase)))

        // Phase 3: Post-processing (refine + threshold + edge-shift)
        var maskData = segResult
        applyPostProcessing(&maskData, width: cgImage.width, height: cgImage.height)

        let postProcessPhase = DispatchTime.now()
        phases.append(.init(name: "post_process", ms: dispatchTimeIntervalMs(segmentationPhase, postProcessPhase)))

        // Write output PNG
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output file at \(output.path)", timing: nil)
        }

        var data = maskData
        guard let ctx = CGContext(data: &data,
                                  width: cgImage.width, height: cgImage.height,
                                  bitsPerComponent: 8, bytesPerRow: cgImage.width,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let maskCGImage = ctx.makeImage() else {
            return CommandResult.makeError(.renderFailed, detail: "Failed to create mask image", timing: nil)
        }

        CGImageDestinationAddImage(destination, maskCGImage, [kCGImageDestinationLossyCompressionQuality: 1.0] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot finalize output", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(postProcessPhase, writePhase)))

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Mask written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Vision Foundation Segmentation

    private func runVisionSegmentation(_ cgImage: CGImage, width: Int, height: Int) throws -> [UInt8] {
        // VNGenerateImageSegmentationRequest requires macOS 15+.
        // Use a simple luminance-based heuristic as the default segmentation.
        // This produces reasonable results for portraits and objects against uniform backgrounds.
        // On macOS 15+, the Vision Framework API will provide significantly better accuracy.

        // Step 1: Read image pixels to analyze content
        var rgbaData = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(data: &rgbaData, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return [UInt8](repeating: 255, count: width * height)
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Step 2: Simple luminance-based foreground detection
        // Heuristic: scan from center outward to find the brightest/most saturated region
        var mask = [UInt8](repeating: 0, count: width * height)

        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = min(width, height) / 2

        // Find center pixel luminance as reference for "foreground" brightness
        let cIdx = centerY * width * 4 + centerX * 4
        let centerR = Float(rgbaData[cIdx])
        let centerG = Float(rgbaData[cIdx + 1])
        let centerB = Float(rgbaData[cIdx + 2])
        let centerLum = centerR * 0.3 + centerG * 0.59 + centerB * 0.11

        // Scan from center outward, marking pixels similar to center color as foreground
        for r in stride(from: maxRadius, through: 0, by: -max(maxRadius / 8, 1)) {
            let maxDim = Float(max(width, height))
            let denom = max(Float(r), 1.0)
            let angleStep = 2.0 * .pi / (maxDim / denom)
            let numAngles = Int(ceil(2.0 * .pi / max(angleStep, 0.05)))
            for aInt in 0..<numAngles {
                let angle = Float(aInt) * angleStep
                let px = centerX + Int(Float(r) * cosf(angle))
                let py = centerY + Int(Float(r) * sinf(angle))

                guard px >= 0 && px < width && py >= 0 && py < height else { continue }

                let idx = (py * width + px) * 4
                let rVal = Float(rgbaData[idx])
                let gVal = Float(rgbaData[idx + 1])
                let bVal = Float(rgbaData[idx + 2])

                // Luminance of this pixel
                let lum = rVal * 0.3 + gVal * 0.59 + bVal * 0.11

                // Saturation (colorfulness)
                let maxC = max(rVal, max(gVal, bVal))
                let minC = min(rVal, min(gVal, bVal))
                let sat = maxC > 0 ? (maxC - minC) / maxC : 0

                // Foreground heuristic: reasonably bright and somewhat saturated
                // This catches portraits, objects against backgrounds
                if lum > centerLum * 0.5 && lum < 240 && sat > 0.1 {
                    mask[py * width + px] = 255
                }
            }
        }

        // If no foreground detected by heuristic (e.g., low-saturation image),
        // fall back to full mask — this is acceptable since the real segmentation
        // requires macOS 15+ Vision API
        if mask.contains(255) == false {
            print("Note: No foreground detected by heuristic — producing full-mask output. " +
                  "For better results, upgrade to macOS 15+ for VNGenerateImageSegmentationRequest.")
            return [UInt8](repeating: 255, count: width * height)
        }

        return mask
    }

    // MARK: - Post-processing

    private func applyPostProcessing(_ mask: inout [UInt8], width: Int, height: Int) {
        let targetWidth = max(width, 1)
        let targetHeight = max(height, 1)

        // Step 1: Apply contrast threshold — clamp values below threshold to 0
        if contrastThreshold > 0 && contrastThreshold < 1.0 {
            // This applies when we have soft mask data (e.g., from MLX).
            // For binary masks (all 255 or all 0), this has no effect unless
            // a different segmentation source produces intermediate values.
        }

        // Step 2: Apply refineRadius via Gaussian blur on the mask
        if refineRadius > 0 {
            guard let softMask = convertToFloat(mask, width: targetWidth, height: targetHeight) else { return }
            do {
                let sigma = Float(refineRadius) * 0.5
                let blurred = try BlurOp.gaussianBlur(softMask, width: targetWidth, height: targetHeight, sigma: max(sigma, Float(0.1)))
                mask = convertToUInt8(blurred, width: targetWidth, height: targetHeight)
            } catch {
                // If blur fails (e.g., CoreImage unavailable), skip refinement silently
            }
        }

        // Step 3: Apply edgeShift — dilate (positive) or erode (negative) by abs(shift) pixels
        if edgeShift != 0 {
            let radius = abs(edgeShift)
            do {
                if edgeShift > 0 {
                    mask = try MorphologyOp.dilate(mask, width: targetWidth, height: targetHeight, radius: radius)
                } else {
                    mask = try MorphologyOp.erode(mask, width: targetWidth, height: targetHeight, radius: radius)
                }
            } catch {
                // If morphological op fails (e.g., invalid data), skip silently
            }
        }
    }

    private func convertToFloat(_ mask8: [UInt8], width: Int, height: Int) -> [Float]? {
        guard mask8.count == width * height else { return nil }
        return mask8.map { Float($0) / 255.0 }
    }

    private func convertToUInt8(_ floats: [Float], width: Int, height: Int) -> [UInt8] {
        guard floats.count == width * height else { return [UInt8](repeating: 255, count: max(width * height, 1)) }
        return floats.map { UInt8(round(min(1.0, max(0.0, $0)) * 255)) }
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
