import XCTest
import CompositorCore

final class BlurTests: XCTestCase {

    /// A hard edge (left half 1.0, right half 0.0) should be smoothed by the blur:
    /// the interior of each side stays near its original value, and the boundary
    /// region becomes intermediate.
    func testGaussianBlurSoftensEdge() throws {
        let w = 16, h = 4
        var img = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                img[y * w + x] = x < 8 ? 1.0 : 0.0
            }
        }
        let out = try BlurOp.gaussianBlur(img, width: w, height: h, sigma: 2.0)
        XCTAssertEqual(out.count, w * h)
        // Deep-left stays ~1.0, deep-right stays ~0.0.
        XCTAssertGreaterThan(out[1 * w + 1], 0.9)
        XCTAssertLessThan(out[1 * w + 14], 0.1)
        // Near the boundary the value is intermediate (softened).
        let mid = out[1 * w + 8]
        XCTAssertGreaterThan(mid, 0.1)
        XCTAssertLessThan(mid, 0.9)
    }

    func testBlurSigmaZeroIsIdentity() throws {
        let w = 3, h = 3
        let img: [Float] = [0.0, 0.5, 1.0, 0.2, 0.7, 0.3, 0.9, 0.1, 0.4]
        let out = try BlurOp.gaussianBlur(img, width: w, height: h, sigma: 0.0)
        XCTAssertEqual(out, img)
    }

    func testBlurClampsToUnitAfterEdge() throws {
        // Even with a large sigma, values stay within [0,1].
        let w = 8, h = 8
        var img = [Float](repeating: 0, count: w * h)
        for i in 0..<w*h { img[i] = (i % 2 == 0) ? 1.0 : 0.0 }
        let out = try BlurOp.gaussianBlur(img, width: w, height: h, sigma: 5.0)
        for v in out {
            XCTAssertGreaterThanOrEqual(v, 0.0)
            XCTAssertLessThanOrEqual(v, 1.0)
        }
    }
}
