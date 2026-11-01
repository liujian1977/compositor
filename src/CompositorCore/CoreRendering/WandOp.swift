// WandOp.swift — Swift wrapper for the magic-wand flood-fill (C).
import Foundation

/// Magic-wand selection: pick pixels by color similarity to a seed point.
public enum WandOp {
    /// Perform a magic-wand selection on an RGBA8 image.
    /// - Parameters:
    ///   - rgba: Row-major RGBA8 pixels (`width * height * 4` bytes).
    ///   - width, height: Image dimensions.
    ///   - point: Seed point `(x, y)` in top-left-origin pixel coordinates.
    ///   - tolerance: Per-channel absolute color difference `[0, 255]`.
    ///   - sampleSize: `1`, `3`, or `5` — averaging window used to derive the target color.
    ///   - contiguous: When `true`, only the 4-connected region from the seed is selected;
    ///     when `false`, every pixel matching the color key is selected.
    /// - Returns: A `width * height` mask (`255` = selected, `0` = not).
    public static func select(rgba: [UInt8], width: Int, height: Int,
                              point: (x: Int, y: Int), tolerance: Int,
                              sampleSize: Int, contiguous: Bool) throws -> [UInt8] {
        guard width > 0 && height > 0 else { return [] }
        guard rgba.count >= width * height * 4 else { throw CoreError.invalidData }
        guard point.x >= 0 && point.y >= 0 && point.x < width && point.y < height else {
            throw CoreError.invalidData
        }

        var output = [UInt8](repeating: 0, count: width * height)
        let rc = rgba.withUnsafeBufferPointer { srcPtr in
            output.withUnsafeMutableBufferPointer { outPtr in
                wand_select(srcPtr.baseAddress,
                           Int32(width), Int32(height),
                           Int32(point.x), Int32(point.y),
                           Int32(tolerance),
                           Int32(sampleSize),
                           contiguous ? 1 : 0,
                           outPtr.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "wand_select failed") }
        return output
    }
}

// MARK: - C bridge
@_silgen_name("wand_select")
func wand_select(
    _ image: UnsafePointer<UInt8>?,
    _ width: Int32, _ height: Int32,
    _ px: Int32, _ py: Int32,
    _ tolerance: Int32, _ sampleSize: Int32,
    _ contiguous: Int32,
    _ output: UnsafeMutablePointer<UInt8>?
) -> Int
