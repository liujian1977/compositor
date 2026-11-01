// ModelLoader.swift — CoreML model loading from .mlpackage directories
// Supports RTMPose, InsightFace, and other Core ML models for Phase 2+ commands.

import Foundation
#if canImport(CoreML)
@preconcurrency import CoreML
#endif

/// Identifies a Core ML model stored as a `.mlpackage` directory.
public struct ModelIdentifier: Sendable {
    let key: String           // e.g., "pose-rtmpose", "face-swap-insightface"
    let packageName: String   // the .mlpackage directory name

    public init(key: String, packageName: String? = nil) {
        self.key = key
        self.packageName = packageName ?? "\(key).mlpackage"
    }
}

/// Loads Core ML models from the Compositor model directory.
public final class ModelLoader: Sendable {

    /// The base path where .mlpackage models are stored.
    public static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Compositor/models-ml")
    }()

    /// Returns the URL to a model's .mlpackage directory.
    public static func modelURL(for identifier: ModelIdentifier) throws -> URL {
        let url = modelsDirectory.appendingPathComponent(identifier.packageName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CoreError.modelMissing(key: identifier.key)
        }
        return url
    }

    /// Loads a compiled Core ML model ready for inference.
    /// `.mlpackage` directories are compiled to `.mlmodelc` on first use and
    /// cached next to the package, so subsequent loads are fast.
    /// Input shapes/sizes should be read from `model.modelDescription` — do not hardcode.
    public static func loadModel(for identifier: ModelIdentifier) throws -> MLModel {
        let packageURL = try modelURL(for: identifier)

        // Prefer a pre-compiled bundle inside the package, else our cache directory.
        let compiledInPackage = packageURL.appendingPathComponent("Compiled/mlmodel")
        let cached = compiledCacheURL(for: identifier)

        let loadURL: URL
        if FileManager.default.fileExists(atPath: compiledInPackage.path) {
            loadURL = compiledInPackage
        } else if FileManager.default.fileExists(atPath: cached.path) {
            loadURL = cached
        } else {
            do {
                try FileManager.default.createDirectory(at: cached.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                let compiled = try MLModel.compileModel(at: packageURL)
                try FileManager.default.moveItem(at: compiled, to: cached)
                loadURL = cached
            } catch {
                throw CoreError.inferenceFailed(reason: "Failed to compile model '\(identifier.key)': \(error.localizedDescription)")
            }
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all  // CPU + GPU + Neural Engine
        do {
            return try MLModel(contentsOf: loadURL, configuration: config)
        } catch {
            throw CoreError.inferenceFailed(reason: "Failed to load model '\(identifier.key)': \(error.localizedDescription)")
        }
    }

    /// Cache path for the compiled form of a .mlpackage model.
    private static func compiledCacheURL(for identifier: ModelIdentifier) -> URL {
        modelsDirectory
            .appendingPathComponent(".compiled")
            .appendingPathComponent("\(identifier.key).mlmodelc")
    }

    /// Checks whether a model is available without throwing.
    public static func isModelAvailable(for identifier: ModelIdentifier) -> Bool {
        let url = modelsDirectory.appendingPathComponent(identifier.packageName)
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Installs a model package copied from a local source URL.
    public static func installModel(from sourceURL: URL, to identifier: ModelIdentifier) throws {
        let destination = modelsDirectory.appendingPathComponent(identifier.packageName)

        try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
    }
}
