// ExportCommandRunner.swift — export command execution logic (Phase 0 stub)

import Foundation
import CoreGraphics
import ImageIO

/// Simple error type for export failures.
struct ExportError: Swift.Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// Minimal .comp format types (inlined to avoid cross-target access issues)
fileprivate struct CompManifest: Codable {
    let layers: [CompLayer]
}

fileprivate struct CompLayer: Codable {
    let id: UUID
    var imageFile: String?
    var filename: String?
}

struct ExportCommandRunner {
    let input: URL           // .comp folder or single image file
    let exportFormat: String // png|jpeg|pdf
    let jpegQuality: Int     // 1-100
    let scale: Double        // 0.01-4.0
    let output: URL
    let format: OutputFormat

    func execute() throws -> CommandResult {
        let phaseStart = DispatchTime.now()
        var phases: [CommandResult.TimingEntry.PhaseEntry] = []

        guard FileManager.default.fileExists(atPath: input.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Input not found: \(input.path)", timing: nil)
        }

        // Determine if input is a .comp folder or single image
        let isCompFolder = (try? input.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true &&
                           FileManager.default.fileExists(atPath: input.appendingPathComponent("manifest.json").path)

        if CompositorCLI.isVerbose() { fputs("[compositor] Loading...\n", stderr) }

        var cgImage: CGImage?

        if isCompFolder {
            // Load project manifest and composite layers (stub — no actual compositing yet)
            let loadPhase = DispatchTime.now()
            phases.append(.init(name: "load_project", ms: dispatchTimeIntervalMs(phaseStart, loadPhase)))

            do {
                let manifestData = try Data(contentsOf: input.appendingPathComponent("manifest.json"))
                let compManifest = try JSONDecoder().decode(CompManifest.self, from: manifestData)

                guard !compManifest.layers.isEmpty else {
                    return CommandResult.makeError(.invalidImageFormat, detail: "Project has no layers", timing: nil)
                }

                let firstLayerURL = input.appendingPathComponent("layers").appendingPathComponent(
                    compManifest.layers[0].imageFile ?? compManifest.layers[0].filename ?? "\(compManifest.layers[0].id.uuidString.uppercased()).png"
                )
                guard FileManager.default.fileExists(atPath: firstLayerURL.path),
                      let data = try? Data(contentsOf: firstLayerURL),
                      let img = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(data as CFData, nil)!, 0, nil) else {
                    return CommandResult.makeError(.renderFailed, detail: "Cannot load layer image", timing: nil)
                }

                cgImage = img
            } catch {
                return CommandResult.makeError(.invalidImageFormat, detail: "Failed to load project: \(error.localizedDescription)", timing: nil)
            }
        } else {
            // Single image input — read and re-export with possible format/quality conversion
            let loadPhase = DispatchTime.now()
            phases.append(.init(name: "read_input", ms: dispatchTimeIntervalMs(phaseStart, loadPhase)))

            guard let data = try? Data(contentsOf: input),
                  let img = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(data as CFData, nil)!, 0, nil) else {
                return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode image at \(input.path)", timing: nil)
            }

            cgImage = img
        }

        guard let image = cgImage else {
            return CommandResult.makeError(.renderFailed, detail: "No image to export", timing: nil)
        }

        // Apply scaling if requested
        let scaledPhaseStart = DispatchTime.now()
        var finalImage = image
        if scale != 1.0 && isCompFolder == false {
            let newWidth = max(1, Int(round(Double(image.width) * scale)))
            let newHeight = max(1, Int(round(Double(image.height) * scale)))

            guard let ctx = CGContext(data: nil, width: newWidth, height: newHeight,
                                      bitsPerComponent: 8, bytesPerRow: newWidth * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return CommandResult.makeError(.renderFailed, detail: "Cannot create scaled image", timing: nil)
            }

            ctx.interpolationQuality = .high
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
            guard let scaledCG = ctx.makeImage() else {
                return CommandResult.makeError(.renderFailed, detail: "Cannot finalize scaled image", timing: nil)
            }
            finalImage = scaledCG

            let scaledPhase = DispatchTime.now()
            phases.append(.init(name: "scale", ms: dispatchTimeIntervalMs(scaledPhaseStart, scaledPhase)))
        } else {
            // No scaling needed — still record the phase for timing accuracy
            _ = scaledPhaseStart
            let noScalePhase = DispatchTime.now()
            phases.append(.init(name: "scale", ms: 0))
        }

        // Export with format/quality conversion
        do {
            try exportImage(finalImage, to: output, format: exportFormat, quality: Float(jpegQuality) / 100.0)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Export failed: \(error.localizedDescription)", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(writePhase, writePhase)))

        // Build timing entry
        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Exported to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Helpers

    private func exportImage(_ image: CGImage, to url: URL, format fmt: String, quality: Float) throws {
        let uti: CFString
        switch fmt.lowercased() {
        case "png":
            uti = "public.png" as CFString
        case "jpeg", "jpg":
            uti = "public.jpeg" as CFString
        case "pdf":
            // CGImageDestination requires the ImageIO UTI "com.adobe.pdf"
            // (the generic "public.pdf" returns a nil destination).
            uti = "com.adobe.pdf" as CFString
        default:
            throw ExportError(message: "Unsupported export format: \(fmt)")
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw ExportError(message: "Cannot create output file at \(url.path)")
        }

        var props: [CFString: Any]?
        if fmt.lowercased() == "jpeg" || fmt.lowercased() == "jpg" {
            // Quality must be 0.0–1.0 for CGImageDestination
            let clampedQuality = max(0.0, min(quality, 1.0))
            props = [kCGImageDestinationLossyCompressionQuality: clampedQuality]
        }

        CGImageDestinationAddImage(destination, image, props as CFDictionary?)
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError(message: "Cannot finalize output at \(url.path)")
        }
    }

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
