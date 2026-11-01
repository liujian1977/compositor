// FaceDetectCommandRunner.swift — face detection using Vision Foundation API
// Built-in macOS capability, no model download required.

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore
#if canImport(Vision)
@preconcurrency import Vision
#endif

/// Represents a detected face with its bounding box and confidence score.
/// Coordinates are top-left origin in image pixels.
struct DetectedFace: Codable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let confidence: Double
}

struct FaceDetectCommandRunner {
    let input: URL
    let minConfidence: Double
    let output: URL
    let format: OutputFormat

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

        // Phase 2: Face detection via Vision API
        if CompositorCLI.isVerbose() { fputs("[compositor] Detecting faces...\n", stderr) }
        let faces: [DetectedFace]
        do {
            faces = try performFaceDetection(cgImage, minConfidence: minConfidence)
        } catch {
            return CommandResult.makeError(.inferenceFailed, detail: "Face detection failed: \(error.localizedDescription)", timing: nil)
        }

        let detectPhase = DispatchTime.now()
        phases.append(.init(name: "face_detection", ms: dispatchTimeIntervalMs(readPhase, detectPhase)))

        // Phase 3: Write output JSON
        if CompositorCLI.isVerbose() { fputs("[compositor] Writing results...\n", stderr) }
        do {
            try writeFacesOutput(faces, to: output)
        } catch {
            return CommandResult.makeError(.renderFailed, detail: "Cannot write output: \(error.localizedDescription)", timing: nil)
        }

        let writePhase = DispatchTime.now()
        phases.append(.init(name: "write_output", ms: dispatchTimeIntervalMs(detectPhase, writePhase)))

        let totalMs = max(dispatchTimeIntervalMs(phaseStart, writePhase), 1)
        let timing = CommandResult.TimingEntry(total_ms: totalMs + phases.reduce(0) { $0 + $1.ms }, phases: phases)

        switch format {
        case .text:
            print("Detected \(faces.count) face(s). Results written to \(output.path)")
        case .json:
            break
        }

        return CommandResult.makeSuccess(output: output.path, timing: timing)
    }

    // MARK: - Face Detection

    private func performFaceDetection(_ cgImage: CGImage, minConfidence: Double) throws -> [DetectedFace] {
#if canImport(Vision)
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNFaceObservation] else {
            return []
        }

        // Vision bounding boxes use bottom-left origin; convert to top-left pixels.
        return results.compactMap { observation -> DetectedFace? in
            guard Double(observation.confidence) >= minConfidence else { return nil }
            let rect = observation.boundingBox
            let x = Int(rect.origin.x * Double(cgImage.width))
            let y = Int((1.0 - rect.origin.y - rect.size.height) * Double(cgImage.height))
            return DetectedFace(
                x: x,
                y: max(0, y),
                width: Int(rect.size.width * Double(cgImage.width)),
                height: Int(rect.size.height * Double(cgImage.height)),
                confidence: Double(observation.confidence)
            )
        }
#else
        throw CoreError.renderFailed(reason: "Vision Framework not available on this platform")
#endif
    }

    // MARK: - Output Writing

    private func writeFacesOutput(_ faces: [DetectedFace], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let data = try encoder.encode(faces)
        try data.write(to: url)
    }

    // MARK: - Timing Helper

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}
