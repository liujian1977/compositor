// CanvasSize.swift — CoreDocument
// Value types for canvas dimensions. No side effects, no AppKit/SwiftUI.

import Foundation

/// Document pixel dimensions. Immutable value type.
struct CanvasSize: Sendable {
    let width: Int
    let height: Int

    /// Aspect ratio (width / height). Returns 0 if height is zero.
    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }

    /// Whether this size fits within the maximum canvas limit (30,000px per side).
    var isValid: Bool {
        width >= 1 && height >= 1 && width <= 30_000 && height <= 30_000
            && Int64(width) * Int64(height) <= 100_000_000
    }

    /// Center a smaller size within this one, preserving aspect ratio.
    func centering(_ other: CanvasSize) -> CGRect {
        let scale = min(Double(width) / Double(other.width),
                        Double(height) / Double(other.height))
        let scaledW = Int(round(Double(other.width) * scale))
        let scaledH = Int(round(Double(other.height) * scale))
        let originX = (width - scaledW) / 2
        let originY = (height - scaledH) / 2
        return CGRect(x: originX, y: originY, width: scaledW, height: scaledH)
    }
}
