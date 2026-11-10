// InpaintCommandRunner.swift — inpaint command execution logic (patch-based algorithm)

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct InpaintCommandRunner {
    let image: URL
    let mask: URL
    let algorithm: String?   // nil = use default "patch-based"
    let laMaPreset: String   // fast|balanced|high (only for lama)
    let output: URL
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Validate inputs exist
        guard FileManager.default.fileExists(atPath: image.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Image file not found: \(image.path)", timing: nil)
        }
        guard FileManager.default.fileExists(atPath: mask.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Mask file not found: \(mask.path)", timing: nil)
        }

        // Read image and mask
        let imageData = try Data(contentsOf: image)
        let maskData = try Data(contentsOf: mask)

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode image", timing: nil)
        }
        guard let maskSource = CGImageSourceCreateWithData(maskData as CFData, nil),
              let maskCG = CGImageSourceCreateImageAtIndex(maskSource, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode mask", timing: nil)
        }

        // Validate dimensions match (required by spec)
        guard cgImage.width == maskCG.width && cgImage.height == maskCG.height else {
            return CommandResult.makeError(
                .dimensionMismatch,
                detail: "Image (\(cgImage.width)x\(cgImage.height)) and mask (\(maskCG.width)x\(maskCG.height)) dimensions do not match",
                timing: nil
            )
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        if CompositorCLI.isVerbose() { fputs("[compositor] Inpainting (patch-based)...\n", stderr) }

        let algo = algorithm ?? "patch-based"
        var result: [UInt8]!  // set below; if branch returns early with modelMissing error
        let width = cgImage.width
        let height = cgImage.height
        let stride = max(width * 4, Int(cgImage.bytesPerRow))

        var inpaintTimeMs = 0
        if algo == "lama" {
            let allowed = ["fast", "balanced", "high"]
            guard allowed.contains(laMaPreset) else {
                return CommandResult.makeError(.renderFailed, detail: "Unknown LaMa preset '\(laMaPreset)'. Expected fast, balanced, or high.", timing: nil)
            }
            let inpaintStart = DispatchTime.now()
            do {
                let rgb = try straightRGB(cgImage)
                let maskBytes = try straightGray(maskCG)
                let filled = try CoreMLInpaint.fill(rgb: rgb, mask: maskBytes, width: width, height: height, preset: laMaPreset)
                var packed = [UInt8](repeating: 255, count: stride * height)
                for y in 0..<height {
                    for x in 0..<width {
                        let s = (y * width + x) * 3
                        let d = y * stride + x * 4
                        packed[d] = filled[s]
                        packed[d + 1] = filled[s + 1]
                        packed[d + 2] = filled[s + 2]
                    }
                }
                result = packed
            } catch let error as CoreError {
                let kind: CommandErrorType
                switch error.cliErrorType {
                case "modelMissing": kind = .modelMissing
                default: kind = .inferenceFailed
                }
                return CommandResult.makeError(kind, detail: error.errorDescription ?? "LaMa failed", hint: error.cliHint, timing: nil)
            } catch {
                return CommandResult.makeError(.inferenceFailed, detail: error.localizedDescription, timing: nil)
            }
            inpaintTimeMs = dispatchTimeIntervalMs(inpaintStart, DispatchTime.now())
            phases.append(.init(name: "inpainting", ms: inpaintTimeMs))
        } else if algo != "patch-based" {
            return CommandResult.makeError(.renderFailed, detail: "Unknown algorithm '\(algo)'. Expected patch-based or lama.", timing: nil)
        } else {

            let inpaintStart = DispatchTime.now()
            do {
                result = try runPatchInpaint(cgImage, mask: maskCG, width: width, height: height, stride: stride)
            } catch {
                let detail = (error as? LocalizedError)?.errorDescription ?? "Patch inpaint failed"
                return CommandResult.makeError(.renderFailed, detail: detail, timing: nil)
            }
            inpaintTimeMs = dispatchTimeIntervalMs(inpaintStart, DispatchTime.now())
            phases.append(.init(name: "inpainting", ms: inpaintTimeMs))
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(writePhase, writePhase)))

        // Write output image (PNG)
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output file at \(output.path)", timing: nil)
        }

        // Convert RGBA8 → CGImage by drawing into a context
        var data = result!  // safe: result is set in the patch-based branch above; lama returns early
        guard let ctx = CGContext(
                    data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: stride,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
              let outCG = ctx.makeImage() else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output image", timing: nil)
        }

        CGImageDestinationAddImage(destination, outCG, [kCGImageDestinationLossyCompressionQuality: 1.0] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot finalize output", timing: nil)
        }
        let finalPhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(writePhase, finalPhase)))

        // Build timing entry
        let totalMs = max(dispatchTimeIntervalMs(phaseStart, finalPhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Inpainted image written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    private func runPatchInpaint(_ cgImage: CGImage, mask: CGImage, width: Int, height: Int, stride: Int) throws -> [UInt8] {
        // RGBA image. `stride` is the byte row stride passed to C (pixel at y * stride + x * 4).
        var imgData = [UInt8](repeating: 0, count: stride * height)
        guard let ctx = CGContext(data: &imgData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: stride,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw CoreError.renderFailed(reason: "Cannot create image context")
        }
        ctx.interpolationQuality = .none
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Mask is one byte per pixel and does not share the image stride.
        // bytesPerRow here is maskStride; C indexes mask[y * maskStride + x].
        let maskStride = width
        var maskData = [UInt8](repeating: 0, count: maskStride * height)
        guard let mctx = CGContext(data: &maskData, width: width, height: height, bitsPerComponent: 8,
                                   bytesPerRow: maskStride, space: CGColorSpaceCreateDeviceGray(),
                                   bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw CoreError.renderFailed(reason: "Cannot create mask context")
        }
        mctx.interpolationQuality = .none
        // Draw the user mask. The gray context converts it; do not substitute the photo.
        mctx.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))

        return try PatchInpaintOp.inpaint(
            image: imgData, mask: maskData, width: width, height: height,
            stride: stride, maskStride: maskStride, searchRadius: 64
        )
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
