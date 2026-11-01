// CompositeOp.swift — Swift wrapper for C compositing operations
// Provides alpha blending, difference blend mode, and Poisson fusion.

import Foundation

enum CompositeError: Error {
    case invalidDimensions
    case bufferTooSmall(expected: Int, actual: Int)
}

/// Image compositing operations.
public enum CompositeOp {

    private static func blend(operation: String, background: [UInt8], foreground: [UInt8],
                              alpha: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        guard background.count == foreground.count else {
            throw CompositeError.bufferTooSmall(expected: background.count, actual: foreground.count)
        }
        let expectedCount = width * height * 3
        guard background.count == expectedCount else { throw CompositeError.invalidDimensions }
        guard alpha.count == width * height else { throw CompositeError.invalidDimensions }

        var result = [UInt8](repeating: 0, count: expectedCount)

        // withCString gives UnsafePointer<Int8> matching C's `const char *operation`.
        operation.withCString { opPtr in
            background.withUnsafeBufferPointer { bgPtr in
                foreground.withUnsafeBufferPointer { fgPtr in
                    alpha.withUnsafeBufferPointer { alPtr in
                        result.withUnsafeMutableBufferPointer { resPtr in
                            composite_images(opPtr, bgPtr.baseAddress, fgPtr.baseAddress,
                                             alPtr.baseAddress, width, height, resPtr.baseAddress)
                        }
                    }
                }
            }
        }
        return result
    }

    /// Blend foreground onto background using alpha compositing.
    public static func alphaBlend(background: [UInt8], foreground: [UInt8], alpha: [UInt8],
                                  width: Int, height: Int) throws -> [UInt8] {
        try blend(operation: "alpha", background: background, foreground: foreground, alpha: alpha, width: width, height: height)
    }

    /// Blend foreground onto background using difference blend mode.
    public static func differenceBlend(background: [UInt8], foreground: [UInt8], alpha: [UInt8],
                                      width: Int, height: Int) throws -> [UInt8] {
        try blend(operation: "difference", background: background, foreground: foreground, alpha: alpha, width: width, height: height)
    }

    /// Gradient-domain compositing using simplified Poisson approach.
    public static func poissonBlend(background: [UInt8], foreground: [UInt8], alpha: [UInt8],
                                    width: Int, height: Int) throws -> [UInt8] {
        try blend(operation: "poisson", background: background, foreground: foreground, alpha: alpha, width: width, height: height)
    }
}

// MARK: - C Function Bridging

@_silgen_name("composite_images")
func composite_images(
    _ operation: UnsafePointer<Int8>?,
    _ background: UnsafePointer<UInt8>?,
    _ foreground: UnsafePointer<UInt8>?,
    _ alpha: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ result: UnsafeMutablePointer<UInt8>?
)
