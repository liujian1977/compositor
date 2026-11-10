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
            // Check if LaMa model is installed on disk
            let modelDir = modelPath(for: .lamaFast)
            guard FileManager.default.fileExists(atPath: modelDir.path),
                  let files = try? FileManager.default.contentsOfDirectory(
                      at: modelDir, includingPropertiesForKeys: nil),
                  !files.isEmpty else {
                return CommandResult.makeError(
                    .modelMissing,
                    detail: "LaMa model not installed. Run `compositor models download lama-fast` to install.",
                    hint: "https://huggingface.co/AEmotionStudio/lama-inpainting",
                    timing: nil
                )
            }
        }

        if algo == "lama" {
            // LaMa inference requires an MLX backend — implement in a future phase.
            return CommandResult.makeError(
                .renderFailed,
                detail: "LaMa model is installed but Swift/MLX inference is not yet implemented.",
                hint: "Use `--algorithm patch-based` for now.",
                timing: nil
            )
        }

        // Patch-based inpainting (default) — only reached when algo != "lama"
        let inpaintStart = DispatchTime.now()
        do {
            result = try runPatchInpaint(cgImage, mask: maskCG, width: width, height: height, stride: stride)
        } catch {
            let detail = (error as? LocalizedError)?.errorDescription ?? "Patch inpaint failed"
            return CommandResult.makeError(.renderFailed, detail: detail, timing: nil)
        }
        let inpaintEnd = DispatchTime.now()
        inpaintTimeMs = dispatchTimeIntervalMs(inpaintStart, inpaintEnd)
        phases.append(.init(name: "inpainting", ms: inpaintTimeMs))

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
