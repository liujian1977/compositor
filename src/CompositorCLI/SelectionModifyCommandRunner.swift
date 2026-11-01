// SelectionModifyCommandRunner.swift — selection-modify command execution logic.
//
// Implements all five sub-operations from command-spec.md:
//   expand / contract (binary morphology), feather (Gaussian blur),
//   edge-snap (Sobel-guided boundary relocation), wand (color flood-fill).

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct SelectionModifyCommandRunner {
    let input: URL
    let operation: String        // expand|contract|feather|wand|edge-snap
    let amount: Double
    let unit: String             // pixels|percent
    let point: String?           // x,y (for wand)
    let tolerance: Int           // 0-255 (for wand)
    let sampleSize: String       // point|3x3|5x5 (for wand)
    let contiguous: Bool         // for wand
    let guide: URL?              // for edge-snap
    let sobelThreshold: Float    // 0-1 (for edge-snap)
    let snapRadius: Int          // pixels (for edge-snap)
    let output: URL?             // required for expand/contract/feather/edge-snap; optional for wand
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        guard FileManager.default.fileExists(atPath: input.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Input file not found: \(input.path)", timing: nil)
        }

        let imageData = try Data(contentsOf: input)
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode input at \(input.path)", timing: nil)
        }

        let readPhase = DispatchTime.now()
        phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, readPhase)))

        if CompositorCLI.isVerbose() { fputs("[compositor] Selection modify: \(operation)\n", stderr) }

        let result: CommandResult
        switch operation {
        case "expand", "contract":
            result = geometric(cgImage, kind: operation, readPhase: readPhase, phases: &phases)
        case "feather":
            result = feather(cgImage, readPhase: readPhase, phases: &phases)
        case "edge-snap":
            result = edgeSnap(cgImage, readPhase: readPhase, phases: &phases)
        case "wand":
            result = wand(cgImage, readPhase: readPhase, phases: &phases)
        default:
            result = CommandResult.makeError(.renderFailed,
                detail: "Unknown operation '\(operation)'. Expected one of: expand, contract, feather, wand, edge-snap",
                timing: timingEntry(phaseStart, readPhase, [], phases))
        }

        return result
    }

    // MARK: - expand / contract

    private func geometric(_ cgImage: CGImage, kind: String, readPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        let width = cgImage.width, height = cgImage.height
        let mask: SoftMask
        do { mask = try SoftMask.fromCGImage(cgImage) }
        catch { return CommandResult.makeError(.renderFailed, detail: "Cannot read mask: \(error)", timing: partialTiming(readPhase, phases)) }

        let binary = mask.pixels.map { $0 >= 0.5 ? UInt8(255) : UInt8(0) }
        let radius = pixelRadius(amount: amount, unit: unit, reference: width)

        let out: [UInt8]
        do {
            out = kind == "expand"
                ? try MorphologyOp.dilate(binary, width: width, height: height, radius: radius)
                : try MorphologyOp.erode(binary, width: width, height: height, radius: radius)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Morphology failed: \(error)", timing: partialTiming(readPhase, phases))
        }

        let processPhase = DispatchTime.now()
        phases.append(.init(name: "selection", ms: dispatchTimeIntervalMs(readPhase, processPhase)))

        return writeMask(out, width: width, height: height, processPhase: processPhase, phases: &phases)
    }

    // MARK: - feather

    private func feather(_ cgImage: CGImage, readPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        let width = cgImage.width, height = cgImage.height
        let mask: SoftMask
        do { mask = try SoftMask.fromCGImage(cgImage) }
        catch { return CommandResult.makeError(.renderFailed, detail: "Cannot read mask: \(error)", timing: partialTiming(readPhase, phases)) }

        let sigma = Float(pixelRadius(amount: amount, unit: unit, reference: width)) // amount interpreted as sigma (pixels)
        let blurred: [Float]
        do { blurred = try BlurOp.gaussianBlur(mask.pixels, width: width, height: height, sigma: sigma) }
        catch { return CommandResult.makeError(.renderFailed, detail: "Gaussian blur failed: \(error)", timing: partialTiming(readPhase, phases)) }

        let clamped = blurred.map { min(1.0, max(0.0, $0)) }
        let outMask = SoftMask(pixels: clamped, width: width, height: height)
        let processPhase = DispatchTime.now()
        phases.append(.init(name: "selection", ms: dispatchTimeIntervalMs(readPhase, processPhase)))

        guard let outCG = try? outMask.asCGImage() else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot render feathered mask", timing: partialTiming(processPhase, phases))
        }
        return writeCGImage(outCG, processPhase: processPhase, phases: &phases)
    }

    // MARK: - edge-snap

    private func edgeSnap(_ cgImage: CGImage, readPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        let width = cgImage.width, height = cgImage.height

        // Guide image: explicit --guide, else use the input mask's own luminance.
        let guideCG: CGImage
        if let guideURL = guide {
            guard FileManager.default.fileExists(atPath: guideURL.path) else {
                return CommandResult.makeError(.fileNotFound, detail: "Guide file not found: \(guideURL.path)", timing: partialTiming(readPhase, phases))
            }
            let gData: Data
            do { gData = try Data(contentsOf: guideURL) }
            catch {
                return CommandResult.makeError(.fileNotFound, detail: "Cannot read guide at \(guideURL.path)", timing: partialTiming(readPhase, phases))
            }
            guard let gSource = CGImageSourceCreateWithData(gData as CFData, nil),
                  let gImage = CGImageSourceCreateImageAtIndex(gSource, 0, nil) else {
                return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode guide at \(guideURL.path)", timing: partialTiming(readPhase, phases))
            }
            guideCG = gImage
        } else {
            guideCG = cgImage
        }

        let guideGray: SoftMask
        let inputMask: SoftMask
        do {
            guideGray = try SoftMask.fromCGImage(guideCG)
            inputMask = try SoftMask.fromCGImage(cgImage)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Cannot read images: \(error)", timing: partialTiming(readPhase, phases))
        }

        // Sobel edge map on the guide luminance.
        let guideBytes = guideGray.pixels.map { UInt8(round(min(1.0, max(0.0, $0)) * 255)) }
        let edges: [Float]
        do { edges = try SobelOp.detectEdges(guideBytes, width: width, height: height) }
        catch { return CommandResult.makeError(.renderFailed, detail: "Sobel failed: \(error)", timing: partialTiming(readPhase, phases)) }

        let sobelPhase = DispatchTime.now()
        phases.append(.init(name: "sobel_compute", ms: dispatchTimeIntervalMs(readPhase, sobelPhase)))

        // Build a soft-boundary mask: interior foreground = 255, boundary foreground = 128.
        let binary = inputMask.pixels.map { $0 >= 0.5 ? UInt8(255) : UInt8(0) }
        var soft = binary
        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if binary[idx] != 255 { continue }
                var isBoundary = false
                for dy in -1...1 where !isBoundary {
                    for dx in -1...1 {
                        let nx = x + dx, ny = y + dy
                        if nx < 0 || ny < 0 || nx >= width || ny >= height { isBoundary = true; break }
                        if binary[ny * width + nx] == 0 { isBoundary = true; break }
                    }
                }
                if isBoundary { soft[idx] = 128 }
            }
        }

        let snapped: [UInt8]
        do {
            snapped = try SobelOp.snapToEdges(mask: soft, edges: edges,
                                             threshold: sobelThreshold, radius: max(1, snapRadius),
                                             width: width, height: height)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Edge snap failed: \(error)", timing: partialTiming(sobelPhase, phases))
        }

        let snapPhase = DispatchTime.now()
        phases.append(.init(name: "snap", ms: dispatchTimeIntervalMs(sobelPhase, snapPhase)))

        return writeMask(snapped, width: width, height: height, processPhase: snapPhase, phases: &phases)
    }

    // MARK: - wand

    private func wand(_ cgImage: CGImage, readPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        guard let point = point else {
            return CommandResult.makeError(.renderFailed, detail: "--point x,y is required for wand operation", timing: partialTiming(readPhase, phases))
        }
        let parts = point.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else {
            return CommandResult.makeError(.renderFailed, detail: "--point must be 'x,y' (got '\(point)')", timing: partialTiming(readPhase, phases))
        }
        let px = parts[0], py = parts[1]

        let sample: Int
        switch sampleSize {
        case "3x3": sample = 3
        case "5x5": sample = 5
        default:    sample = 1
        }

        guard let rgba = readRGBA8(cgImage) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot read input as RGBA", timing: partialTiming(readPhase, phases))
        }

        let mask: [UInt8]
        do {
            mask = try WandOp.select(rgba: rgba.data, width: rgba.width, height: rgba.height,
                                     point: (x: px, y: py), tolerance: tolerance,
                                     sampleSize: sample, contiguous: contiguous)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Wand failed: \(error)", timing: partialTiming(readPhase, phases))
        }

        let processPhase = DispatchTime.now()
        phases.append(.init(name: "selection", ms: dispatchTimeIntervalMs(readPhase, processPhase)))

        // Wand without --output reports a temp file path in JSON.
        if output == nil {
            let tmpPath = NSTemporaryDirectory().appendingFormat("selection_%d.png", ProcessInfo.processInfo.processIdentifier)
            guard writeMaskBytes(mask, width: rgba.width, height: rgba.height, to: URL(fileURLWithPath: tmpPath)) else {
                return CommandResult.makeError(.renderFailed, detail: "Cannot write selection file", timing: partialTiming(processPhase, phases))
            }
            return finish(path: tmpPath, processPhase: processPhase, phases: &phases)
        }

        return writeMask(mask, width: rgba.width, height: rgba.height, processPhase: processPhase, phases: &phases)
    }

    // MARK: - Output helpers

    private func writeMask(_ bytes: [UInt8], width: Int, height: Int, processPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        guard let url = output else {
            return CommandResult.makeError(.renderFailed, detail: "--output is required for operation '\(operation)'", timing: partialTiming(processPhase, phases))
        }
        guard writeMaskBytes(bytes, width: width, height: height, to: url) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot write output to \(url.path)", timing: partialTiming(processPhase, phases))
        }
        return finish(path: url.path, processPhase: processPhase, phases: &phases)
    }

    private func writeCGImage(_ cgImage: CGImage, processPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        guard let url = output else {
            return CommandResult.makeError(.renderFailed, detail: "--output is required for operation '\(operation)'", timing: partialTiming(processPhase, phases))
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot create output at \(url.path)", timing: partialTiming(processPhase, phases))
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return CommandResult.makeError(.renderFailed, detail: "Cannot finalize output", timing: partialTiming(processPhase, phases))
        }
        return finish(path: url.path, processPhase: processPhase, phases: &phases)
    }

    private func writeMaskBytes(_ bytes: [UInt8], width: Int, height: Int, to url: URL) -> Bool {
        let mask = SoftMask(pixels: bytes.map { Float($0) / 255.0 }, width: width, height: height)
        guard let cg = try? mask.asCGImage() else { return false }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, cg, nil)
        return CGImageDestinationFinalize(destination)
    }

    private func finish(path: String, processPhase: DispatchTime, phases: inout [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult {
        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(processPhase, writePhase)))

        switch format {
        case .text:
            print("Selection \(operation) result written to \(path)")
        case .json:
            break
        }
        return CommandResult.makeSuccess(output: path, timing: timingEntry(processPhase, writePhase, [], phases))
    }

    // MARK: - Utilities

    /// Convert `--amount`/`--unit` to a pixel radius. Percent is relative to `reference` (image width).
    private func pixelRadius(amount: Double, unit: String, reference: Int) -> Int {
        let px: Double
        if unit == "percent" {
            px = amount / 100.0 * Double(reference)
        } else {
            px = amount
        }
        return max(1, Int(round(px)))
    }

    private func readRGBA8(_ cgImage: CGImage) -> (data: [UInt8], width: Int, height: Int)? {
        let w = cgImage.width, h = cgImage.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        out.withUnsafeMutableBufferPointer { buf in
            for i in 0..<(w * h * 4) { buf[i] = ptr[i] }
        }
        return (out, w, h)
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }

    /// Timing entry from the read phase to now, carrying already-recorded phases.
    private func partialTiming(_ now: DispatchTime, _ phases: [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult.TimingEntry? {
        timingEntry(now, now, [], phases)
    }

    private func timingEntry(_ start: DispatchTime, _ end: DispatchTime, _ extra: [CommandResult.TimingEntry.PhaseEntry], _ prior: [CommandResult.TimingEntry.PhaseEntry]) -> CommandResult.TimingEntry {
        var all = prior
        // Ensure read_input is present if we somehow skipped it.
        if all.isEmpty { all.append(.init(name: "read_input", ms: 1)) }
        all.append(contentsOf: extra)
        let total = max(dispatchTimeIntervalMs(start, end), 1) + all.reduce(0) { $0 + $1.ms }
        return CommandResult.TimingEntry(total_ms: total, phases: all)
    }
}
