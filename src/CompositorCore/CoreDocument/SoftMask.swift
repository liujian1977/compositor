// SoftMask.swift — CoreRendering (central data structure)
// Bridging type between ML inference engines and Core rendering.
// No AppKit/SwiftUI imports.

import Foundation
@preconcurrency import CoreGraphics

#if canImport(CoreVideo)
import CoreVideo
#endif

/// A grayscale coverage map: 0.0 = fully transparent, 1.0 = fully opaque.
/// Stored as a flat row-major [Float] array of width * height elements.
public struct SoftMask: Sendable {
    public let pixels: [Float]     // row-major, width * height elements, values clamped to [0.0, 1.0]
    public let width: Int
    public let height: Int

    /// Create from CVPixelBuffer (Vision Framework output). Values converted from UInt8 [0,255] → Float [0,1].
    #if canImport(CoreVideo)
    public init(cvPixelBuffer buffer: CVPixelBuffer, width: Int, height: Int) throws {
        self.width = width
        self.height = height

        guard CVPixelBufferLockBaseAddress(buffer, .readOnly) == kCVReturnSuccess else {
            throw CoreError.renderFailed(reason: "CVPixelBuffer lock failed")
        }
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(buffer),
              width > 0 && height > 0 else {
            self.pixels = []
            return
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let count = width * height
        var result: [Float] = .init(repeating: 0, count: count)

        // Convert UInt8 grayscale → Float normalized to [0,1]
        let src = base.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
        for i in 0..<count {
            let row = i / width
            let col = i % width
            result[i] = Float(src[row * bytesPerRow + col]) / 255.0
        }

        self.pixels = result
    }
    #else
    /// Stub when CoreVideo is not available (requires canImport(CoreVideo))
    init(cvPixelBuffer buffer: Any, width: Int, height: Int) throws {
        throw CoreError.modelMissing(key: "vision")
    }
    #endif

    /// Create from MLX tensor (H, W; values assumed in [0.0, 1.0]).
    /// Requires mlx-swift package. Placeholder for Phase 3+.
    init(mlxTensor: Any) {
        // TODO: Convert MLXArray to [Float]. For now returns empty.
        self.pixels = []
        self.width = 0
        self.height = 0
    }

    /// Create from raw pixel data (values assumed clamped to [0,1]).
    public init(pixels: [Float], width: Int, height: Int) {
        self.pixels = pixels.map { min(1.0, max(0.0, $0)) }
        self.width = width
        self.height = height
    }

    /// Convert to a grayscale PNG image (8-bit per pixel). White = 1.0, black = 0.0.
    public func asCGImage() throws -> CGImage {
        let w = self.width, h = self.height
        guard pixels.count == w * h else { throw CoreError.invalidData }

        guard let context = CGContext(
            data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { throw CoreError.renderFailed(reason: "CGContext creation failed") }

        let data = context.data!.bindMemory(to: UInt8.self, capacity: w * h)
        for i in 0..<pixels.count {
            data[i] = UInt8(round(min(1.0, max(0.0, pixels[i])) * 255))
        }

        guard let image = context.makeImage() else { throw CoreError.renderFailed(reason: "CGContext makeImage failed") }
        return image
    }

    /// Create from a CGImage (grayscale). Converts [0,255] → Float [0,1].
    public static func fromCGImage(_ cgImage: CGImage) throws -> SoftMask {
        let w = cgImage.width, h = cgImage.height
        guard w > 0 && h > 0 else { return SoftMask(pixels: [], width: 0, height: 0) }

        guard let context = CGContext(
            data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { throw CoreError.renderFailed(reason: "CGContext creation failed") }

        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let data = context.data else { throw CoreError.renderFailed(reason: "CGContext.data unavailable") }
        let src = data.bindMemory(to: UInt8.self, capacity: w * h)
        var pixels: [Float] = .init(repeating: 0, count: w * h)
        for i in 0..<w * h {
            pixels[i] = Float(src[i]) / 255.0
        }

        return SoftMask(pixels: pixels, width: w, height: h)
    }
}


