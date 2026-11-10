// CutoutCommandRunner.swift — apply a mask as the alpha channel of an image.
// Writes a straight RGBA PNG (color from the image, alpha from the mask).

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct CutoutCommandRunner {
    let image: URL
    let mask: URL
    let output: URL
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        if CompositorCLI.isVerbose() { fputs("[compositor] Reading image and mask...\n", stderr) }

        guard FileManager.default.fileExists(atPath: image.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Image file not found: \(image.path)", timing: nil)
        }
        guard FileManager.default.fileExists(atPath: mask.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Mask file not found: \(mask.path)", timing: nil)
        }

        guard let imageCG = decodeFirstImage(at: image) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode image at \(image.path)", timing: nil)
        }
        guard let maskCG = decodeFirstImage(at: mask) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode mask at \(mask.path)", timing: nil)
        }

        let width = imageCG.width
        let height = imageCG.height
        guard width > 0, height > 0 else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Image has zero dimensions", timing: nil)
        }
        guard maskCG.width == width, maskCG.height == height else {
            return CommandResult.makeError(
                .dimensionMismatch,
                detail: "Mask \(maskCG.width)×\(maskCG.height) must match image \(width)×\(height)",
                timing: nil
            )
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        guard let rgb = readStraightRGB(imageCG), let maskBytes = grayscaleBytes(maskCG) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot read pixels", timing: partialTiming(readPhase, phases))
        }

        let rgba: [UInt8]
        do {
            rgba = try MaskOps.applyCutout(rgb: rgb, mask: maskBytes, width: width, height: height)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Cutout failed: \(error.localizedDescription)", timing: partialTiming(readPhase, phases))
        }

        let cutoutPhase = DispatchTime.now()
        phases.append(.init(name: "cutout", ms: dispatchTimeIntervalMs(readPhase, cutoutPhase)))

        if CompositorCLI.isVerbose() { fputs("[compositor] Writing RGBA PNG...\n", stderr) }
        do {
            try ImageExporter.writeStraightRGBAPNG(rgba, width: width, height: height, to: output)
        } catch {
            return CommandResult.makeError(
                .renderFailed,
                detail: "Cannot write output to \(output.path): \(error.localizedDescription)",
                timing: partialTiming(cutoutPhase, phases)
            )
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(cutoutPhase, writePhase)))

        switch format {
        case .text:
            print("Cutout written to \(output.path)")
        case .json:
            break
        }

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)
        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    private func decodeFirstImage(at url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return image
    }

    /// Device-RGB samples. Opaque sources keep their color. The mask supplies alpha later.
    private func readStraightRGB(_ image: CGImage) -> [UInt8]? {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &rgba,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var rgb = [UInt8](repeating: 0, count: w * h * 3)
        for i in 0..<(w * h) {
            rgb[i * 3] = rgba[i * 4]
            rgb[i * 3 + 1] = rgba[i * 4 + 1]
            rgb[i * 3 + 2] = rgba[i * 4 + 2]
        }
        return rgb
    }

    private func grayscaleBytes(_ image: CGImage) -> [UInt8]? {
        guard let mask = try? SoftMask.fromCGImage(image) else { return nil }
        guard mask.pixels.count == mask.width * mask.height else { return nil }
        return mask.pixels.map { sample in
            let clamped = min(1.0, max(0.0, sample))
            return UInt8(round(clamped * 255))
        }
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }

    private func partialTiming(_ now: DispatchTime, _ phases: [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult.TimingEntry? {
        CommandResult.TimingEntry(total_ms: max(dispatchTimeIntervalMs(now, now), 1) + phases.reduce(0) { $0 + $1.ms }, phases: phases)
    }
}
