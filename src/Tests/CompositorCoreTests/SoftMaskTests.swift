import XCTest
import CoreGraphics
import CompositorCore

final class SoftMaskTests: XCTestCase {

    func testPixelRoundTrip() throws {
        let w = 2, h = 2
        let pixels: [Float] = [0.0, 0.5, 1.0, 0.25]
        let mask = SoftMask(pixels: pixels, width: w, height: h)
        let cgImage = try mask.asCGImage()
        XCTAssertEqual(cgImage.width, w)
        XCTAssertEqual(cgImage.height, h)

        let back = try SoftMask.fromCGImage(cgImage)
        XCTAssertEqual(back.width, w)
        XCTAssertEqual(back.height, h)
        XCTAssertEqual(back.pixels.count, w * h)
        for i in 0..<pixels.count {
            XCTAssertEqual(back.pixels[i], pixels[i], accuracy: 0.02, "pixel \(i) round-trip mismatch")
        }
    }

    func testValuesClampedToUnit() {
        let mask = SoftMask(pixels: [-1.0, 2.0, 0.3, 0.7], width: 2, height: 2)
        for v in mask.pixels {
            XCTAssertGreaterThanOrEqual(v, 0.0)
            XCTAssertLessThanOrEqual(v, 1.0)
        }
    }
}
