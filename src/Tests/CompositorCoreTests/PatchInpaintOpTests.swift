import XCTest
import CompositorCore

/// Pixel checks for patch inpaint and the mask-stride contract.
/// Mask bytes are packed with `maskStride`, which is not the RGBA `stride`.
final class PatchInpaintOpTests: XCTestCase {

    func testEmptyMaskIsIdentity() throws {
        let w = 4, h = 2
        let stride = w * 4
        let maskStride = w
        var image = [UInt8](repeating: 0, count: stride * h)
        for i in 0..<image.count { image[i] = UInt8((i * 3 + 1) % 256) }
        let mask = [UInt8](repeating: 0, count: maskStride * h)
        let out = try PatchInpaintOp.inpaint(
            image: image, mask: mask, width: w, height: h,
            stride: stride, maskStride: maskStride, searchRadius: 4
        )
        XCTAssertEqual(out, image)
    }

    func testMaskedPixelChangesAndUnmaskedPixelsDoNot() throws {
        let w = 8, h = 4
        let stride = 32
        let maskStride = w
        var image = [UInt8](repeating: 0x5A, count: stride * h)
        var mask = [UInt8](repeating: 0, count: maskStride * h)
        for y in 0..<h {
            for x in 0..<w {
                let i = y * stride + x * 4
                image[i] = 10
                image[i + 1] = 10
                image[i + 2] = 10
                image[i + 3] = 255
            }
        }
        let hole = 1 * stride + 0 * 4
        image[hole] = 200
        image[hole + 1] = 200
        image[hole + 2] = 200
        mask[1 * maskStride + 0] = 255

        let out = try PatchInpaintOp.inpaint(
            image: image, mask: mask, width: w, height: h,
            stride: stride, maskStride: maskStride, searchRadius: 4
        )
        XCTAssertEqual(out[hole], 10)
        XCTAssertEqual(out[hole + 1], 10)
        XCTAssertEqual(out[hole + 2], 10)
        for y in 0..<h {
            for x in 0..<w where !(x == 0 && y == 1) {
                let i = y * stride + x * 4
                XCTAssertEqual(out[i], 10)
                XCTAssertEqual(out[i + 1], 10)
                XCTAssertEqual(out[i + 2], 10)
                XCTAssertEqual(out[i + 3], 255)
            }
            for b in (w * 4)..<stride {
                XCTAssertEqual(out[y * stride + b], 0x5A, "row padding must survive")
            }
        }
    }

    func testWideHoleReachesCenter() throws {
        let w = 24, h = 1
        let stride = w * 4
        var image = [UInt8](repeating: 0, count: stride)
        var mask = [UInt8](repeating: 0, count: w)
        for x in 0..<w {
            image[x * 4] = 10
            image[x * 4 + 1] = 20
            image[x * 4 + 2] = 30
            image[x * 4 + 3] = 255
        }
        for x in 6...18 {
            image[x * 4] = 180
            image[x * 4 + 1] = 180
            image[x * 4 + 2] = 180
            mask[x] = 255
        }
        let out = try PatchInpaintOp.inpaint(
            image: image, mask: mask, width: w, height: h,
            stride: stride, maskStride: w, searchRadius: 2
        )
        for x in 0..<w {
            XCTAssertEqual(out[x * 4], 10)
            XCTAssertEqual(out[x * 4 + 1], 20)
            XCTAssertEqual(out[x * 4 + 2], 30)
            if x < 6 || x > 18 {
                XCTAssertEqual(Array(out[(x * 4)..<(x * 4 + 4)]), Array(image[(x * 4)..<(x * 4 + 4)]))
            }
        }
    }

    func testMaskStrideDoesNotFollowImageStride() throws {
        let w = 4, h = 2
        let stride = 32
        let maskStride = 8
        var image = [UInt8](repeating: 0x11, count: stride * h)
        var mask = [UInt8](repeating: 0, count: maskStride * h)
        for y in 0..<h {
            for x in 0..<w {
                let i = y * stride + x * 4
                image[i] = 10
                image[i + 1] = 10
                image[i + 2] = 10
                image[i + 3] = 40
            }
        }
        let hole = 1 * stride + 1 * 4
        image[hole] = 200
        image[hole + 1] = 180
        image[hole + 2] = 160
        mask[1 * maskStride + 1] = 255
        mask[4] = 255 // padding in the mask row, not a pixel

        let out = try PatchInpaintOp.inpaint(
            image: image, mask: mask, width: w, height: h,
            stride: stride, maskStride: maskStride, searchRadius: 3
        )
        XCTAssertEqual(out[hole], 10)
        XCTAssertEqual(out[hole + 1], 10)
        XCTAssertEqual(out[hole + 2], 10)
        for y in 0..<h {
            for x in 0..<w where !(x == 1 && y == 1) {
                let i = y * stride + x * 4
                XCTAssertEqual(Array(out[i..<(i + 4)]), Array(image[i..<(i + 4)]))
            }
        }
    }

    func testMismatchedMaskStrideThrows() {
        let image = [UInt8](repeating: 0, count: 16)
        let mask = [UInt8](repeating: 0, count: 4)
        XCTAssertThrowsError(
            try PatchInpaintOp.inpaint(
                image: image, mask: mask, width: 2, height: 2,
                stride: 8, maskStride: 1, searchRadius: 1
            )
        )
    }
}
