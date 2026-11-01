import XCTest
import CompositorCore

final class WandTests: XCTestCase {

    /// A 2×2 solid-color block (top half red, bottom half blue) — contiguous wand
    /// from the red region should select only the contiguous red pixels.
    func testContiguousWandSelectsOneRegion() throws {
        let w = 4, h = 4
        // RGBA: top two rows red, bottom two rows blue.
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let i = (y * w + x) * 4
                if y < 2 { rgba[i] = 255; rgba[i+1] = 0; rgba[i+2] = 0 }
                else     { rgba[i] = 0;   rgba[i+1] = 0; rgba[i+2] = 255 }
                rgba[i+3] = 255
            }
        }
        let mask = try WandOp.select(rgba: rgba, width: w, height: h,
                                    point: (x: 0, y: 0), tolerance: 8,
                                    sampleSize: 1, contiguous: true)
        XCTAssertEqual(mask.count, w * h)
        // Top two rows fully selected, bottom two rows untouched.
        for y in 0..<2 {
            for x in 0..<w { XCTAssertEqual(mask[y * w + x], 255) }
        }
        for y in 2..<h {
            for x in 0..<w { XCTAssertEqual(mask[y * w + x], 0) }
        }
    }

    /// Non-contiguous wand with high tolerance selects ALL matching-color pixels
    /// even when separated.
    func testNonContiguousWandSelectsAllMatching() throws {
        let w = 4, h = 4
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let i = (y * w + x) * 4
                // Checkerboard of red / black.
                if (x + y) % 2 == 0 { rgba[i] = 255 }
                rgba[i+3] = 255
            }
        }
        let mask = try WandOp.select(rgba: rgba, width: w, height: h,
                                    point: (x: 0, y: 0), tolerance: 8,
                                    sampleSize: 1, contiguous: false)
        // Every red pixel (8 of them) selected, black (0) not.
        var selected = 0
        for v in mask where v == 255 { selected += 1 }
        XCTAssertEqual(selected, 8)
    }

    func testWandOutOfBoundsPointThrows() throws {
        let rgba = [UInt8](repeating: 255, count: 4 * 4 * 4)
        XCTAssertThrowsError(try WandOp.select(rgba: rgba, width: 4, height: 4,
                                               point: (x: 99, y: 0), tolerance: 8,
                                               sampleSize: 1, contiguous: true))
    }
}
