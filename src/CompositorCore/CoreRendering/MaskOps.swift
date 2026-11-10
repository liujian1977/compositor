// MaskOps.swift — Swift wrappers for cutout, mask arithmetic, and inspection.
// Pixel work lives in MaskOps.c so it can be tested without CoreGraphics.

import Foundation

/// Byte-level mask and cutout operations.
public enum MaskOps {

    /// Straight RGBA (`width * height * 4`). RGB is copied from `rgb`; alpha is `mask`.
    public static func applyCutout(rgb: [UInt8], mask: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        let n = try pixelCount(width: width, height: height)
        guard rgb.count == n * 3, mask.count == n else { throw CoreError.invalidData }
        var out = [UInt8](repeating: 0, count: n * 4)
        var rc: Int32 = -1
        rgb.withUnsafeBufferPointer { rgbPtr in
            mask.withUnsafeBufferPointer { maskPtr in
                out.withUnsafeMutableBufferPointer { outPtr in
                    rc = cutout_apply_mask(rgbPtr.baseAddress, maskPtr.baseAddress,
                                           width, height, outPtr.baseAddress)
                }
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "cutout_apply_mask failed") }
        return out
    }

    /// `255 - src` at every byte.
    public static func invert(_ src: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        let n = try pixelCount(width: width, height: height)
        guard src.count == n else { throw CoreError.invalidData }
        var out = [UInt8](repeating: 0, count: n)
        var rc: Int32 = -1
        src.withUnsafeBufferPointer { srcPtr in
            out.withUnsafeMutableBufferPointer { outPtr in
                rc = mask_invert(srcPtr.baseAddress, width, height, outPtr.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "mask_invert failed") }
        return out
    }

    /// Per-byte maximum.
    public static func union(_ a: [UInt8], _ b: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        try binary(a, b, width: width, height: height) { aPtr, bPtr, outPtr in
            mask_union(aPtr, bPtr, width, height, outPtr)
        }
    }

    /// Per-byte minimum.
    public static func intersect(_ a: [UInt8], _ b: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        try binary(a, b, width: width, height: height) { aPtr, bPtr, outPtr in
            mask_intersect(aPtr, bPtr, width, height, outPtr)
        }
    }

    /// Saturating `a - b`. On 0/255 masks this is set difference.
    public static func subtract(_ a: [UInt8], _ b: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        try binary(a, b, width: width, height: height) { aPtr, bPtr, outPtr in
            mask_subtract(aPtr, bPtr, width, height, outPtr)
        }
    }

    /// Compact inspection JSON. No trailing newline. Schema is fixed; see command-spec.md.
    public static func inspectJSON(mask: [UInt8], width: Int, height: Int) throws -> String {
        let n = try pixelCount(width: width, height: height)
        guard mask.count == n else { throw CoreError.invalidData }
        var raw: UnsafeMutablePointer<CChar>?
        let rc: Int32 = mask.withUnsafeBufferPointer { ptr in
            mask_inspect_format_json(ptr.baseAddress, width, height, &raw)
        }
        defer { mask_inspect_json_free(raw) }
        guard rc == 0, let raw else {
            throw CoreError.renderFailed(reason: "mask_inspect_format_json failed")
        }
        return String(cString: raw)
    }

    private static func pixelCount(width: Int, height: Int) throws -> Int {
        guard width > 0, height > 0, width <= Int(Int32.max), height <= Int(Int32.max) else {
            throw CoreError.invalidData
        }
        let (pixels, overflow) = width.multipliedReportingOverflow(by: height)
        guard !overflow else { throw CoreError.invalidData }
        return pixels
    }

    private static func binary(
        _ a: [UInt8],
        _ b: [UInt8],
        width: Int,
        height: Int,
        op: (UnsafePointer<UInt8>?, UnsafePointer<UInt8>?, UnsafeMutablePointer<UInt8>?) -> Int32
    ) throws -> [UInt8] {
        let n = try pixelCount(width: width, height: height)
        guard a.count == n, b.count == n else { throw CoreError.invalidData }
        var out = [UInt8](repeating: 0, count: n)
        var rc: Int32 = -1
        a.withUnsafeBufferPointer { aPtr in
            b.withUnsafeBufferPointer { bPtr in
                out.withUnsafeMutableBufferPointer { outPtr in
                    rc = op(aPtr.baseAddress, bPtr.baseAddress, outPtr.baseAddress)
                }
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "mask binary op failed") }
        return out
    }
}

// MARK: - C function bridging

@_silgen_name("cutout_apply_mask")
private func cutout_apply_mask(
    _ rgb: UnsafePointer<UInt8>?,
    _ mask: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ outRGBA: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("mask_invert")
private func mask_invert(
    _ src: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("mask_union")
private func mask_union(
    _ a: UnsafePointer<UInt8>?,
    _ b: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("mask_intersect")
private func mask_intersect(
    _ a: UnsafePointer<UInt8>?,
    _ b: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("mask_subtract")
private func mask_subtract(
    _ a: UnsafePointer<UInt8>?,
    _ b: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("mask_inspect_format_json")
private func mask_inspect_format_json(
    _ mask: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ outJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("mask_inspect_json_free")
private func mask_inspect_json_free(_ json: UnsafeMutablePointer<CChar>?)
