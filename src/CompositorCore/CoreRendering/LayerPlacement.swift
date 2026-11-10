// LayerPlacement.swift — Place a foreground layer using ProjectManifest.Transform.
// The rasterizer is LayerPlacement.c so the pixels can be tested without CoreGraphics.

import Foundation

public enum LayerPlacement {
    /// Sample `foreground` into a background-sized RGB buffer and alpha mask.
    /// `sampling` accepts the manifest strings (`Nearest`, `Smooth`, `High quality`)
    /// and the lowercase CLI aliases. Smooth and High quality are bilinear.
    public static func place(
        foregroundRGB: [UInt8],
        foregroundAlpha: [UInt8],
        foregroundWidth: Int,
        foregroundHeight: Int,
        backgroundWidth: Int,
        backgroundHeight: Int,
        originX: Double,
        originY: Double,
        sizeWidth: Double,
        sizeHeight: Double,
        rotationDegrees: Double,
        flipX: Bool,
        flipY: Bool,
        sampling: String
    ) throws -> (rgb: [UInt8], alpha: [UInt8]) {
        let fgCount = try pixelCount(foregroundWidth, foregroundHeight)
        let bgCount = try pixelCount(backgroundWidth, backgroundHeight)
        guard foregroundRGB.count == fgCount * 3, foregroundAlpha.count == fgCount else {
            throw CoreError.invalidData
        }
        let transform = try manifestTransform(
            originX: originX, originY: originY,
            sizeWidth: sizeWidth, sizeHeight: sizeHeight,
            rotationDegrees: rotationDegrees,
            flipX: flipX, flipY: flipY,
            sampling: sampling
        )
        let mode = transform.sampling == "Nearest" ? 0 : 1
        var rgb = [UInt8](repeating: 0, count: bgCount * 3)
        var alpha = [UInt8](repeating: 0, count: bgCount)
        var rc: Int32 = -1
        foregroundRGB.withUnsafeBufferPointer { rgbPtr in
            foregroundAlpha.withUnsafeBufferPointer { alphaPtr in
                rgb.withUnsafeMutableBufferPointer { outRGB in
                    alpha.withUnsafeMutableBufferPointer { outAlpha in
                        rc = layer_place(
                            rgbPtr.baseAddress, alphaPtr.baseAddress,
                            foregroundWidth, foregroundHeight, backgroundWidth, backgroundHeight,
                            transform.origin[0], transform.origin[1],
                            transform.size[0], transform.size[1],
                            transform.rotation,
                            transform.flipX ? 1 : 0, transform.flipY ? 1 : 0, mode,
                            outRGB.baseAddress, outAlpha.baseAddress
                        )
                    }
                }
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "layer_place failed") }
        return (rgb, alpha)
    }

    /// Build the project-manifest transform the rasterizer consumes.
    static func manifestTransform(
        originX: Double, originY: Double,
        sizeWidth: Double, sizeHeight: Double,
        rotationDegrees: Double,
        flipX: Bool, flipY: Bool,
        sampling: String
    ) throws -> ProjectManifest.Transform {
        let canonical: String
        switch sampling.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "nearest": canonical = "Nearest"
        case "smooth": canonical = "Smooth"
        case "high", "high quality", "high-quality": canonical = "High quality"
        default:
            throw CoreError.renderFailed(
                reason: "Unknown sampling '\(sampling)'. Expected Nearest, Smooth, or High quality"
            )
        }
        return ProjectManifest.Transform(
            origin: [originX, originY],
            size: [sizeWidth, sizeHeight],
            rotation: rotationDegrees,
            flipX: flipX,
            flipY: flipY,
            sampling: canonical
        )
    }

    private static func pixelCount(_ width: Int, _ height: Int) throws -> Int {
        guard width > 0, height > 0, width <= Int(Int32.max), height <= Int(Int32.max) else {
            throw CoreError.invalidData
        }
        let (pixels, overflow) = width.multipliedReportingOverflow(by: height)
        guard !overflow else { throw CoreError.invalidData }
        return pixels
    }
}

@_silgen_name("layer_place")
private func layer_place(
    _ fgRGB: UnsafePointer<UInt8>?,
    _ fgAlpha: UnsafePointer<UInt8>?,
    _ fgW: Int, _ fgH: Int, _ bgW: Int, _ bgH: Int,
    _ originX: Double, _ originY: Double,
    _ sizeW: Double, _ sizeH: Double,
    _ rotationDeg: Double, _ flipX: Int, _ flipY: Int, _ sampling: Int,
    _ outRGB: UnsafeMutablePointer<UInt8>?,
    _ outAlpha: UnsafeMutablePointer<UInt8>?
) -> Int32
