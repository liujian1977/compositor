// Errors.swift — CompositorCore (shared across all modules)
/// Unified error types for the Core library. No AppKit/SwiftUI imports.

import Foundation

/// All errors that can be thrown by CompositorCore functions.
public enum CoreError: LocalizedError, Sendable {
    case fileNotFound(path: String)
    case invalidImageFormat(url: URL, reason: String?)     // failed to decode as image
    case dimensionMismatch(image: (Int, Int), mask: (Int, Int))  // width/height mismatch
    case renderFailed(reason: String)                       // CGContext or CGImageDestination failure
    case inferenceFailed(reason: String)                    // CoreML model load/predict failure
    case modelMissing(key: String)                          // SAM2/LaMa weights not found
    case invalidData                                         // array count doesn't match dimensions

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidImageFormat(let url, let reason):
            if let reason {
                return "Invalid image format at \(url.path): \(reason)"
            }
            return "Invalid image format at \(url.path)"
        case .dimensionMismatch(let (iw, ih), let (mw, mh)):
            return "Dimension mismatch: image \(iw)×\(ih) vs mask \(mw)×\(mh)"
        case .renderFailed(let reason):
            return "Rendering failed: \(reason)"
        case .inferenceFailed(let reason):
            return "Inference failed: \(reason)"
        case .modelMissing(let key):
            return "Model not found: \(key)"
        case .invalidData:
            return "Invalid data: array dimensions don't match"
        }
    }

    /// Map to CLI JSON error type for agent consumption.
    public var cliErrorType: String {
        switch self {
        case .fileNotFound:
            return "fileNotFound"
        case .invalidImageFormat:
            return "invalidImageFormat"
        case .dimensionMismatch:
            return "dimensionMismatch"
        case .renderFailed, .invalidData:
            return "renderFailed"
        case .inferenceFailed:
            return "inferenceFailed"
        case .modelMissing:
            return "modelMissing"
        }
    }

    /// Recovery hint for agent (may be nil).
    public var cliHint: String? {
        switch self {
        case .fileNotFound(let path):
            return "Verify the file exists at \(path)"
        case .invalidImageFormat(_, let reason):
            if let reason { return reason }
            return "The file is not a valid image"
        case .dimensionMismatch:
            return "Mask dimensions must match image dimensions"
        case .modelMissing(let key):
            return "compositor models download \(key)"
        default:
            return nil
        }
    }
}
