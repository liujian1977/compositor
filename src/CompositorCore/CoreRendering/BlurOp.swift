// BlurOp.swift — Swift wrapper for separable Gaussian blur (C).
import Foundation

/// Gaussian blur operations for mask feathering.
public enum BlurOp {
    /// Apply a separable Gaussian blur with standard deviation `sigma` (pixels) to a
    /// single-channel Float mask (values in `[0, 1]`). Returns a new blurred mask.
    public static func gaussianBlur(_ src: [Float], width: Int, height: Int, sigma: Float) throws -> [Float] {
        guard width > 0 && height > 0 else { return [] }
        guard src.count >= width * height else { throw CoreError.invalidData }

        var dst = [Float](repeating: 0, count: width * height)
        let rc = src.withUnsafeBufferPointer { srcPtr in
            dst.withUnsafeMutableBufferPointer { dstPtr in
                gaussian_blur(srcPtr.baseAddress, Int32(width), Int32(height),
                             sigma, dstPtr.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "gaussian_blur failed") }
        return dst
    }
}

// MARK: - C bridge
@_silgen_name("gaussian_blur")
func gaussian_blur(
    _ src: UnsafePointer<Float>?,
    _ width: Int32, _ height: Int32,
    _ sigma: Float,
    _ dst: UnsafeMutablePointer<Float>?
) -> Int
