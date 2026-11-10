// CompositeCommandRunner.swift — composite multiple images using masks and blend modes

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct CompositeCommandRunner {
    let foregroundURL: URL
    let backgroundURL: URL
    let maskURL: URL?           // optional alpha mask; if omitted, uses FG's alpha channel
    let blendMode: String       // "alpha", "difference", or "poisson"
    let originText: String?     // "x,y"; nil places the layer at (0, 0)
    let sizeText: String?       // "w,h" displayed size; nil keeps the foreground's pixel size
    let rotationDegrees: Double // clockwise, y down
    let flipX: Bool
    let flipY: Bool
    let sampling: String        // Nearest | Smooth | High quality
    let output: URL
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        // Phase 1: Read all input images
        if CompositorCLI.isVerbose() { fputs("[compositor] Reading inputs...\n", stderr) }

        guard FileManager.default.fileExists(atPath: foregroundURL.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Foreground file not found: \(foregroundURL.path)", timing: nil)
        }
        guard FileManager.default.fileExists(atPath: backgroundURL.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Background file not found: \(backgroundURL.path)", timing: nil)
        }

        let fgData = try Data(contentsOf: foregroundURL)
        let bgData = try Data(contentsOf: backgroundURL)

        guard let fgSource = CGImageSourceCreateWithData(fgData as CFData, nil),
              let fgCG = CGImageSourceCreateImageAtIndex(fgSource, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode foreground image", timing: nil)
        }

        guard let bgSource = CGImageSourceCreateWithData(bgData as CFData, nil),
              let bgCG = CGImageSourceCreateImageAtIndex(bgSource, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode background image", timing: nil)
        }

        // Read mask if provided
        var maskData: [UInt8]? = nil
        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        if let maskURL = maskURL {
            guard FileManager.default.fileExists(atPath: maskURL.path) else {
                return CommandResult.makeError(.fileNotFound, detail: "Mask file not found: \(maskURL.path)", timing: nil)
            }
            let maskImageData = try Data(contentsOf: maskURL)
            guard let maskSource = CGImageSourceCreateWithData(maskImageData as CFData, nil),
                  let maskCG = CGImageSourceCreateImageAtIndex(maskSource, 0, nil) else {
                return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode mask image", timing: nil)
            }
            maskData = try readGrayscaleMask(maskCG)
        }

        // Phase 2: Extract RGB pixels and prepare alpha channel
        if CompositorCLI.isVerbose() { fputs("[compositor] Preparing pixel data...\n", stderr) }
        let bgRGB = try extractRGB(bgCG)
        let fgRGB = try extractRGB(fgCG)

        // The mask is in foreground source pixels. It is resampled with the layer.
        var alpha: [UInt8]
        if let providedMask = maskData {
            guard providedMask.count == fgCG.width * fgCG.height else {
                return CommandResult.makeError(.dimensionMismatch, detail: "Mask dimensions (\(providedMask.count)) don't match foreground (\(fgCG.width * fgCG.height))", timing: nil)
            }
            alpha = providedMask
        } else {
            alpha = try extractAlphaFromImage(fgCG)
        }

        let origin: (Double, Double)
        let placedSize: (Double, Double)
        do {
            origin = try parsePair(originText, fallback: (0, 0), name: "--origin")
            placedSize = try parsePair(sizeText, fallback: (Double(fgCG.width), Double(fgCG.height)), name: "--size")
        } catch {
            return CommandResult.makeError(.renderFailed, detail: error.localizedDescription, timing: nil)
        }

        let preparePhase = DispatchTime.now()
        phases.append(.init(name: "prepare", ms: dispatchTimeIntervalMs(readPhase, preparePhase)))

        // Phase 3: Rasterize the layer into the background canvas, then blend.
        if CompositorCLI.isVerbose() { fputs("[compositor] Placing foreground...\n", stderr) }
        let width = bgCG.width
        let height = bgCG.height
        guard width > 0, height > 0, fgCG.width > 0, fgCG.height > 0 else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Image has zero dimensions", timing: nil)
        }

        let placed: (rgb: [UInt8], alpha: [UInt8])
        do {
            placed = try LayerPlacement.place(
                foregroundRGB: fgRGB,
                foregroundAlpha: alpha,
                foregroundWidth: fgCG.width,
                foregroundHeight: fgCG.height,
                backgroundWidth: width,
                backgroundHeight: height,
                originX: origin.0,
                originY: origin.1,
                sizeWidth: placedSize.0,
                sizeHeight: placedSize.1,
                rotationDegrees: rotationDegrees,
                flipX: flipX,
                flipY: flipY,
                sampling: sampling
            )
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Layer placement failed: \(error.localizedDescription)", timing: nil)
        }

        let placePhase = DispatchTime.now()
        phases.append(.init(name: "place", ms: dispatchTimeIntervalMs(preparePhase, placePhase)))

        if CompositorCLI.isVerbose() { fputs("[compositor] Compositing...\n", stderr) }
        var resultRGB: [UInt8]
        do {
            switch blendMode.lowercased() {
            case "difference":
                resultRGB = try CompositeOp.differenceBlend(
                    background: bgRGB, foreground: placed.rgb, alpha: placed.alpha,
                    width: width, height: height
                )
            case "poisson":
                resultRGB = try CompositeOp.poissonBlend(
                    background: bgRGB, foreground: placed.rgb, alpha: placed.alpha,
                    width: width, height: height
                )
            default:
                resultRGB = try CompositeOp.alphaBlend(
                    background: bgRGB, foreground: placed.rgb, alpha: placed.alpha,
                    width: width, height: height
                )
            }
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Compositing failed: \(error.localizedDescription)", timing: nil)
        }

        let compositePhase = DispatchTime.now()
        phases.append(.init(name: "composite", ms: dispatchTimeIntervalMs(placePhase, compositePhase)))

        // Phase 4: Write output PNG
        if CompositorCLI.isVerbose() { fputs("[compositor] Writing result...\n", stderr) }
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output file at \(output.path)", timing: nil)
        }

        // Convert RGB result to RGBA for PNG output (add full alpha since we composited everything)
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<width * height {
            rgba[i * 4] = resultRGB[i * 3]     // R
            rgba[i * 4 + 1] = resultRGB[i * 3 + 1]  // G
            rgba[i * 4 + 2] = resultRGB[i * 3 + 2]  // B
            rgba[i * 4 + 3] = 255              // A (fully opaque after compositing)
        }

        guard let ctx = CGContext(data: &rgba, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let finalCGImage = ctx.makeImage() else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output image", timing: nil)
        }

        CGImageDestinationAddImage(destination, finalCGImage, [kCGImageDestinationLossyCompressionQuality: 1.0] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot finalize output", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(compositePhase, writePhase)))

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Composite complete. Result written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Pixel Extraction Helpers

    private func extractRGB(_ cgImage: CGImage) throws -> [UInt8] {
        let w = cgImage.width, h = cgImage.height
        // CGContext requires 4-byte-aligned rows; draw into RGBA and strip alpha.
        var rgba = [UInt8](repeating: 0, count: w * h * 4)

        guard let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw CoreError.renderFailed(reason: "Cannot create RGB context")
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        var rgb = [UInt8](repeating: 0, count: w * h * 3)
        for i in 0..<w * h {
            rgb[i * 3] = rgba[i * 4]
            rgb[i * 3 + 1] = rgba[i * 4 + 1]
            rgb[i * 3 + 2] = rgba[i * 4 + 2]
        }
        return rgb
    }

    private func extractAlphaFromImage(_ cgImage: CGImage) throws -> [UInt8] {
        let w = cgImage.width, h = cgImage.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)

        guard let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CoreError.renderFailed(reason: "Cannot create context for alpha extraction")
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        var alpha = [UInt8](repeating: 0, count: w * h)
        for i in 0..<w * h {
            alpha[i] = rgba[i * 4 + 3]
        }
        return alpha
    }

    private func readGrayscaleMask(_ cgImage: CGImage) throws -> [UInt8] {
        let w = cgImage.width, h = cgImage.height
        var pixels = [UInt8](repeating: 0, count: w * h)

        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw CoreError.renderFailed(reason: "Cannot create mask context")
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return pixels
    }

    /// `"x,y"` pair. Nil text uses `fallback`.
    private func parsePair(_ text: String?, fallback: (Double, Double), name: String) throws -> (Double, Double) {
        guard let text, !text.isEmpty else { return fallback }
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let a = Double(parts[0]), let b = Double(parts[1]), a.isFinite, b.isFinite else {
            throw CoreError.renderFailed(reason: "\(name) must be two finite numbers, 'a,b'")
        }
        return (a, b)
    }

    // MARK: - Timing Helper

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
