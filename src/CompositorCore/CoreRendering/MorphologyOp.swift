// MorphologyOp.swift — CoreRendering (Swift wrapper)
// Wraps C functions from CoreC module.

import Foundation

/// Expand (dilate) and contract (erode) operations on binary masks.
public enum MorphologyOp {
    /// Dilate the input mask by `radius` pixels. Returns a new mask where foreground regions have expanded outward.
    public static func dilate(_ mask: [UInt8], width: Int, height: Int, radius: Int) throws -> [UInt8] {
        guard width > 0 && height > 0 && radius > 0 else { return mask }
        guard mask.count == width * height else { throw CoreError.invalidData }

        var output = mask
        mask.withUnsafeBufferPointer { maskPtr in
            output.withUnsafeMutableBufferPointer { outPtr in
                _ = morph_dilate(maskPtr.baseAddress, width, height, outPtr.baseAddress, radius)
            }
        }
        return output
    }

    /// Erode the input mask by `radius` pixels. Returns a new mask where foreground regions have shrunk inward.
    public static func erode(_ mask: [UInt8], width: Int, height: Int, radius: Int) throws -> [UInt8] {
        guard width > 0 && height > 0 && radius > 0 else { return mask }
        guard mask.count == width * height else { throw CoreError.invalidData }

        var output = mask
        mask.withUnsafeBufferPointer { maskPtr in
            output.withUnsafeMutableBufferPointer { outPtr in
                _ = morph_erode(maskPtr.baseAddress, width, height, outPtr.baseAddress, radius)
            }
        }
        return output
    }
}

// MARK: - C Function Bridging

@_silgen_name("morph_dilate")
func morph_dilate(
    _ mask: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ output: UnsafeMutablePointer<UInt8>?,
    _ radius: Int
)

@_silgen_name("morph_erode")
func morph_erode(
    _ mask: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ output: UnsafeMutablePointer<UInt8>?,
    _ radius: Int
)
