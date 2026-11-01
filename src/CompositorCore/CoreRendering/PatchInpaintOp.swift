// PatchInpaintOp.swift — CoreRendering (Swift wrapper)
// Wraps C patch-matching inpainting function.

import Foundation

/// Patch-based inpainting operations for the inpaint command.
public enum PatchInpaintOp {
    /// Fill masked regions of an RGBA image using patch matching.
    public static func inpaint(
        image: [UInt8], mask: [UInt8], width: Int, height: Int, stride: Int, searchRadius: Int = 64
    ) throws -> [UInt8] {
        guard width > 0 && height > 0 else { return [] }
        guard image.count >= stride * height, mask.count == max(stride, width) * height else {
            throw CoreError.invalidData
        }

        var output = image
        let rc = patch_inpaint_from_array(
            image, width: width, height: height, stride: stride,
            mask: mask, searchRadius: searchRadius, output: &output
        )
        guard rc == 0 else { throw CoreError.renderFailed(reason: "patch_inpaint failed") }
        return output
    }
}

// MARK: - C Function Bridging

@_silgen_name("patch_inpaint")
func patch_inpaint(
    _ img: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int, _ stride: Int,
    _ mask: UnsafePointer<UInt8>?,
    _ output: UnsafeMutablePointer<UInt8>?,
    _ searchRadius: Int
) -> Int

private func patch_inpaint_from_array(
    _ image: [UInt8], width: Int, height: Int, stride: Int,
    mask: [UInt8], searchRadius: Int, output: inout [UInt8]
) -> Int {
    guard image.count >= stride * height && output.count == image.count else { return -1 }

    var result = -1
    image.withUnsafeBufferPointer { imgPtr in
        mask.withUnsafeBufferPointer { maskPtr in
            output.withUnsafeMutableBufferPointer { outPtr in
                let rc = patch_inpaint(
                    imgPtr.baseAddress, width, height, stride,
                    maskPtr.baseAddress,
                    outPtr.baseAddress, searchRadius
                )
                result = rc
            }
        }
    }
    return result
}
