import XCTest
import CompositorCore

/// Pixel checks for masked Poisson compositing. Mirrors the C driver in
/// CoreRenderingCTests: a constant foreground offset must disappear, alpha 0
/// must keep the background, and a single interior spike must survive.
final class CompositeOpTests: XCTestCase {

    func testPoissonConstantOffsetMatchesBackground() throws {
        let w = 8, h = 4, n = w * h
        var bg = [UInt8](repeating: 0, count: n * 3)
        var fg = [UInt8](repeating: 0, count: n * 3)
        var alpha = [UInt8](repeating: 255, count: n)
        for i in 0..<n {
            let b = UInt8(20 + (i % 17))
            bg[i * 3] = b
            bg[i * 3 + 1] = b + 3
            bg[i * 3 + 2] = 255 - b
            fg[i * 3] = b + 40
            fg[i * 3 + 1] = b + 43
            fg[i * 3 + 2] = 255 - b - 20
        }
        let out = try CompositeOp.poissonBlend(background: bg, foreground: fg, alpha: alpha, width: w, height: h)
        XCTAssertEqual(out, bg)
    }

    func testPoissonAlphaZeroIsBackground() throws {
        let w = 4, h = 3, n = w * h
        let bg = [UInt8](repeating: 30, count: n * 3)
        var fg = [UInt8](repeating: 200, count: n * 3)
        fg[0] = 1
        let alpha = [UInt8](repeating: 0, count: n)
        let out = try CompositeOp.poissonBlend(background: bg, foreground: fg, alpha: alpha, width: w, height: h)
        XCTAssertEqual(out, bg)
    }

    func testPoissonSingleInteriorSpike() throws {
        let w = 3, h = 3, n = w * h
        let bg = [UInt8](repeating: 0, count: n * 3)
        var fg = bg
        fg[4 * 3] = 100
        fg[4 * 3 + 1] = 100
        fg[4 * 3 + 2] = 100
        let alpha = [UInt8](repeating: 255, count: n)
        let out = try CompositeOp.poissonBlend(background: bg, foreground: fg, alpha: alpha, width: w, height: h)
        for i in 0..<n where i != 4 {
            XCTAssertEqual(out[i * 3], 0)
            XCTAssertEqual(out[i * 3 + 1], 0)
            XCTAssertEqual(out[i * 3 + 2], 0)
        }
        XCTAssertEqual(out[4 * 3], 100)
        XCTAssertEqual(out[4 * 3 + 1], 100)
        XCTAssertEqual(out[4 * 3 + 2], 100)
    }

    func testPoissonFlatForegroundCollapsesToBoundary() throws {
        let w = 5, h = 5, n = w * h
        let bg = [UInt8](repeating: 0, count: n * 3)
        let fg = [UInt8](repeating: 100, count: n * 3)
        let alpha = [UInt8](repeating: 255, count: n)
        let out = try CompositeOp.poissonBlend(background: bg, foreground: fg, alpha: alpha, width: w, height: h)
        XCTAssertEqual(out, bg)
    }

    func testPoissonOutsideMaskUnchanged() throws {
        let w = 6, h = 4, n = w * h
        var bg = [UInt8](repeating: 0, count: n * 3)
        var fg = [UInt8](repeating: 0, count: n * 3)
        var alpha = [UInt8](repeating: 0, count: n)
        for i in 0..<n {
            bg[i * 3] = UInt8(10 + i)
            bg[i * 3 + 1] = 20
            bg[i * 3 + 2] = 30
            fg[i * 3] = UInt8((i * 9) % 200)
            fg[i * 3 + 1] = 180
            fg[i * 3 + 2] = 40
            alpha[i] = (i % w < 2) ? 0 : 255
        }
        let out = try CompositeOp.poissonBlend(background: bg, foreground: fg, alpha: alpha, width: w, height: h)
        for i in 0..<n where alpha[i] == 0 {
            XCTAssertEqual(out[i * 3], bg[i * 3])
            XCTAssertEqual(out[i * 3 + 1], bg[i * 3 + 1])
            XCTAssertEqual(out[i * 3 + 2], bg[i * 3 + 2])
        }
    }

    func testInvalidDimensionsThrow() {
        let bg = [UInt8](repeating: 0, count: 3)
        XCTAssertThrowsError(
            try CompositeOp.poissonBlend(background: bg, foreground: bg, alpha: [255, 0], width: 1, height: 1)
        )
    }
}
