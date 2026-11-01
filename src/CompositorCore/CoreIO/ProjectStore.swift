// ProjectStore.swift — Read/write .comp folder structure

import Foundation
import CoreGraphics
import ImageIO

public enum ProjectStoreError: Swift.Error {
    case directoryNotFound(URL)
    case invalidManifest(String)
    case missingLayerImage(Int, URL)
    case layerIndexOutOfBounds(Int, Int, URL)
}

/// Reads and writes the `.comp` folder format (Compositor project).
/// All operations are synchronous — no threading, no UIKit/AppKit.
public enum ProjectStore {

    // MARK: - Load

    /// Load a .comp folder into a ProjectManifest.
    static func load(from url: URL) throws -> ProjectManifest {
        guard FileManager.default.fileExists(atPath: url.path),
              (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
            throw ProjectStoreError.directoryNotFound(url)
        }

        let manifestURL = url.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        var manifest = try JSONDecoder().decode(ProjectManifest.self, from: data)

        // Validate layer file existence and read pixel dimensions
        for i in 0..<manifest.layers.count {
            let record = manifest.layers[i]
            let imageFile = record.imageFile ?? record.filename ?? "\(record.id.uuidString.uppercased()).png"
            let layerURL = url.appendingPathComponent("layers").appendingPathComponent(imageFile)
            guard FileManager.default.fileExists(atPath: layerURL.path) else {
                throw ProjectStoreError.missingLayerImage(i, layerURL)
            }

            // Read image dimensions from PNG metadata (no AppKit/CGImageSource dependency on UI thread)
            let cgData = try Data(contentsOf: layerURL)
            guard let source = CGImageSourceCreateWithData(cgData as CFData, nil),
                  let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = props[kCGImagePropertyPixelWidth] as? Int,
                  let height = props[kCGImagePropertyPixelHeight] as? Int else {
                // Fallback: use manifest canvas dimensions (may differ from layer actual size)
                var updatedRecord = record
                updatedRecord.width = manifest.width
                updatedRecord.height = manifest.height
                manifest.layers[i] = updatedRecord
                continue
            }
            var updatedRecord = record
            updatedRecord.width = width
            updatedRecord.height = height
            manifest.layers[i] = updatedRecord
        }

        return manifest
    }

    // MARK: - Save

    /// Write a ProjectManifest back to disk (atomic write via temp file + rename).
    static func save(_ manifest: ProjectManifest, at url: URL) throws {
        let layersDir = url.appendingPathComponent("layers")
        try FileManager.default.createDirectory(at: layersDir, withIntermediateDirectories: true)

        // Write layer images (stub — actual PNG writing delegated to ImageExporter.writePNG)
        var layers = manifest.layers
        for (index, record) in manifest.layers.enumerated() {
            let filename = "layer_\(index).png"
            var updatedRecord = record
            updatedRecord.filename = filename
            layers[index] = updatedRecord

            // NOTE: Actual pixel data must be provided by the caller via `writeLayerPixels`.
            // This save only writes metadata. See `saveWithLayers` for full round-trip.
        }

        let manifestURL = url.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var manifestCopy = manifest
        manifestCopy.layers = layers
        let data = try encoder.encode(manifestCopy)
        try writeAtomically(data, to: manifestURL)
    }

    /// Full round-trip: save project with layer pixel data.
    static func save(_ manifest: ProjectManifest,
                    layers pixels: [CGImage],
                    at url: URL) throws {
        let layersDir = url.appendingPathComponent("layers")
        try FileManager.default.createDirectory(at: layersDir, withIntermediateDirectories: true)

        var layers = manifest.layers
        for (index, record) in manifest.layers.enumerated() {
            guard index < pixels.count else { break }
            let filename = "layer_\(index).png"
            var updatedRecord = record
            updatedRecord.filename = filename
            layers[index] = updatedRecord

            let layerURL = layersDir.appendingPathComponent(filename)
            try ImageExporter.writePNG(pixels[index], to: layerURL)
        }

        let manifestURL = url.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var manifestCopy = manifest
        manifestCopy.layers = layers
        let data = try encoder.encode(manifestCopy)
        try writeAtomically(data, to: manifestURL)
    }

    // MARK: - Helpers

    private static func writeAtomically(_ data: Data, to url: URL) throws {
        let tmpURL = url.deletingLastPathComponent().appendingPathExtension("tmp")
        try data.write(to: tmpURL, options: .atomic)
        try FileManager.default.moveItem(at: tmpURL, to: url)
    }
}
