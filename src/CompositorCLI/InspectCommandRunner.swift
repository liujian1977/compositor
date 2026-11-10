// InspectCommandRunner.swift — JSON report for a mask.
// Stdout is produced by the CLI command, not here, so pipeline runs stay quiet.
// The document is the compact JSON from MaskOps.inspectJSON (no extra keys, no log lines).

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct InspectOutcome {
    let result: CommandResult
    /// Inspection document without a trailing newline. Nil when `result.status != "success"`.
    let document: String?
}

struct InspectCommandRunner {
    let input: URL
    /// "luminance" (default) or "alpha".
    let channel: String
    /// When set, the document plus a trailing newline is also written here.
    let output: URL?
    let format: OutputFormat

    func execute() throws -> InspectOutcome {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        if CompositorCLI.isVerbose() { fputs("[compositor] Inspecting mask...\n", stderr) }

        guard FileManager.default.fileExists(atPath: input.path) else {
            return failure(.fileNotFound, detail: "Input file not found: \(input.path)", phases: phases)
        }

        guard let data = try? Data(contentsOf: input),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return failure(.invalidImageFormat, detail: "Cannot decode image at \(input.path)", phases: phases)
        }

        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else {
            return failure(.invalidImageFormat, detail: "Image has zero dimensions", phases: phases)
        }

        let samples: [UInt8]
        switch channel.lowercased() {
        case "luminance", "gray", "grey":
            guard let bytes = grayscaleBytes(image) else {
                return failure(.renderFailed, detail: "Cannot read luminance", phases: phases)
            }
            samples = bytes
        case "alpha":
            guard let bytes = alphaBytes(image) else {
                return failure(.renderFailed, detail: "Cannot read alpha channel", phases: phases)
            }
            samples = bytes
        default:
            return failure(
                .renderFailed,
                detail: "Unknown channel '\(channel)'. Expected luminance or alpha",
                phases: phases
            )
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        let document: String
        do {
            document = try MaskOps.inspectJSON(mask: samples, width: width, height: height)
        } catch {
            return failure(.renderFailed, detail: "Inspect failed: \(error.localizedDescription)", phases: phases)
        }

        let inspectPhase = DispatchTime.now()
        phases.append(.init(name: "inspect", ms: dispatchTimeIntervalMs(readPhase, inspectPhase)))

        if let output {
            do {
                try (document + "\n").write(to: output, atomically: true, encoding: .utf8)
            } catch {
                return failure(
                    .renderFailed,
                    detail: "Cannot write report to \(output.path): \(error.localizedDescription)",
                    phases: phases
                )
            }
            let writePhase = DispatchTime.now()
            phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(inspectPhase, writePhase)))
        }

        // `--format` does not wrap this document. Callers print `document` alone.
        _ = format
        let end = DispatchTime.now()
        let totalMs = max(dispatchTimeIntervalMs(phaseStart, end), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)
        let reported = output?.path ?? input.path
        return InspectOutcome(result: CommandResult.makeSuccess(output: reported, timing: timing), document: document)
    }

    private func grayscaleBytes(_ image: CGImage) -> [UInt8]? {
        guard let mask = try? SoftMask.fromCGImage(image),
              mask.pixels.count == mask.width * mask.height else { return nil }
        return mask.pixels.map { sample in
            UInt8(round(min(1.0, max(0.0, sample)) * 255))
        }
    }

    /// Alpha byte from a premultipliedLast draw. Coverage lives in alpha even when RGB is premultiplied.
    private func alphaBytes(_ image: CGImage) -> [UInt8]? {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &rgba,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var alpha = [UInt8](repeating: 0, count: w * h)
        for i in 0..<(w * h) {
            alpha[i] = rgba[i * 4 + 3]
        }
        return alpha
    }

    private func failure(
        _ type: CommandErrorType,
        detail: String,
        phases: [CommandResult.TimingEntry.PhaseEntry]
    ) -> InspectOutcome {
        let timing = CommandResult.TimingEntry(
            total_ms: max(phases.reduce(0) { $0 + $1.ms }, 1),
            phases: phases.isEmpty ? [.init(name: "read_input", ms: 1)] : phases
        )
        return InspectOutcome(result: CommandResult.makeError(type, detail: detail, timing: timing), document: nil)
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
