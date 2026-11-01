import XCTest
import CompositorCore

final class MorphologyTests: XCTestCase {

    func testDilateSinglePixelRadius1() throws {
        let w = 5, h = 5
        var mask = [UInt8](repeating: 0, count: w * h)
        mask[2 * w + 2] = 255   // center pixel
        let out = try MorphologyOp.dilate(mask, width: w, height: h, radius: 1)
        // Expect a 3x3 block of 255 centered at (2,2)
        for y in 1...3 {
            for x in 1...3 {
                XCTAssertEqual(out[y * w + x], 255, "pixel (\(x),\(y)) should be foreground")
            }
        }
        XCTAssertEqual(out[0], 0)
        XCTAssertEqual(out[(h - 1) * w + (w - 1)], 0)
    }

    func testDilateRadius0IsIdentity() throws {
        let w = 4, h = 4
        let mask = [UInt8](repeating: 255, count: w * h)
        let out = try MorphologyOp.dilate(mask, width: w, height: h, radius: 0)
        XCTAssertEqual(out, mask)
    }

    func testErodeFullMaskRadius1() throws {
        let w = 5, h = 5
        let mask = [UInt8](repeating: 255, count: w * h)
        let out = try MorphologyOp.erode(mask, width: w, height: h, radius: 1)
        // Erosion shrinks by 1px: the strict interior (1..3, 1..3) remains 255
        // and the 1-pixel outer frame is removed (out-of-bounds counts as background).
        for y in 1...3 {
            for x in 1...3 {
                XCTAssertEqual(out[y * w + x], 255)
            }
        }
        XCTAssertEqual(out[0], 0)                          // top-left corner removed
        XCTAssertEqual(out[w - 1], 0)                      // top-right corner removed
        XCTAssertEqual(out[(h - 1) * w], 0)                // bottom-left corner removed
        XCTAssertEqual(out[(h - 1) * w + (w - 1)], 0)      // bottom-right corner removed
    }

    func testErodeThenDilateRoundTrip() throws {
        let w = 20, h = 20
        var mask = [UInt8](repeating: 0, count: w * h)
        // a 10x10 square
        for y in 5..<15 {
            for x in 5..<15 { mask[y * w + x] = 255 }
        }
        let eroded = try MorphologyOp.erode(mask, width: w, height: h, radius: 1)
        let opened = try MorphologyOp.dilate(eroded, width: w, height: h, radius: 1)
        // Opening should match original square (convex shape is unchanged)
        XCTAssertEqual(opened, mask)
    }
}
