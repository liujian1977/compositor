import XCTest
import CompositorCore

/// Mirrors the C pixel/JSON contract. The assertions run the Swift wrappers,
/// which call the same MaskOps.c functions covered by test_mask_ops.c.
final class MaskOpsTests: XCTestCase {

    func testCutoutCopiesRGBAndTakesAlphaFromMask() throws {
        let rgb: [UInt8] = [255, 0, 0, 0, 255, 10]
        let mask: [UInt8] = [255, 0]
        let out = try MaskOps.applyCutout(rgb: rgb, mask: mask, width: 2, height: 1)
        XCTAssertEqual(out, [255, 0, 0, 255, 0, 255, 10, 0])

        let partial = try MaskOps.applyCutout(rgb: [10, 20, 30], mask: [128], width: 1, height: 1)
        XCTAssertEqual(partial, [10, 20, 30, 128])
    }

    func testArithmeticPixels() throws {
        let a: [UInt8] = [0, 10, 200, 255]
        let b: [UInt8] = [5, 10, 100, 0]
        XCTAssertEqual(try MaskOps.invert(a, width: 2, height: 2), [255, 245, 55, 0])
        XCTAssertEqual(try MaskOps.union(a, b, width: 2, height: 2), [5, 10, 200, 255])
        XCTAssertEqual(try MaskOps.intersect(a, b, width: 2, height: 2), [0, 10, 100, 0])
        XCTAssertEqual(try MaskOps.subtract(a, b, width: 2, height: 2), [0, 0, 100, 255])
    }

    func testInspectJSONMatchesSchema() throws {
        let diag: [UInt8] = [255, 0, 0, 255]
        let json = try MaskOps.inspectJSON(mask: diag, width: 2, height: 2)
        XCTAssertFalse(json.contains("\n"))
        XCTAssertEqual(
            json,
            "{\"width\":2,\"height\":2,\"coverage\":0.5,\"foreground_threshold\":128,\"connectivity\":8,"
                + "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":2,\"height\":2},\"component_count\":1,"
                + "\"components\":[{\"index\":0,\"area\":2,\"center\":{\"x\":0.5,\"y\":0.5}}]}"
        )
    }

    func testInspectRejectsMismatchedLength() {
        XCTAssertThrowsError(try MaskOps.inspectJSON(mask: [255], width: 2, height: 2))
        XCTAssertThrowsError(try MaskOps.applyCutout(rgb: [1, 2, 3], mask: [255, 0], width: 1, height: 1))
    }
}
