import XCTest
import CompositorCore

/// The same pixel and JSON contracts as test_layer_pose.c, through the Swift wrappers.
final class LayerPoseTests: XCTestCase {

    func testRotation180MatchesPixels() throws {
        let rgb: [UInt8] = [
            10, 0, 0, 20, 0, 0,
            30, 0, 0, 40, 0, 0
        ]
        let alpha: [UInt8] = [255, 255, 255, 255]
        let placed = try LayerPlacement.place(
            foregroundRGB: rgb, foregroundAlpha: alpha,
            foregroundWidth: 2, foregroundHeight: 2,
            backgroundWidth: 2, backgroundHeight: 2,
            originX: 0, originY: 0, sizeWidth: 2, sizeHeight: 2,
            rotationDegrees: 180, flipX: false, flipY: false, sampling: "Nearest"
        )
        XCTAssertEqual(placed.rgb[0], 40)
        XCTAssertEqual(placed.rgb[3], 30)
        XCTAssertEqual(placed.rgb[6], 20)
        XCTAssertEqual(placed.rgb[9], 10)
        XCTAssertEqual(placed.alpha, [255, 255, 255, 255])
    }

    func testFaceIndexAndTargetBox() {
        let x = [0.0, 100.0, 0.0]
        let y = [0.0, 0.0, 100.0]
        let w = [10.0, 20.0, 20.0]
        let h = [10.0, 20.0, 20.0]
        let c = [0.4, 0.4, 0.9]
        XCTAssertEqual(FaceSelection.choose(x: x, y: y, width: w, height: h, confidence: c, faceIndex: nil, targetBox: nil), 2)
        XCTAssertEqual(FaceSelection.choose(x: x, y: y, width: w, height: h, confidence: c, faceIndex: 1, targetBox: nil), 1)
        XCTAssertEqual(
            FaceSelection.choose(
                x: x, y: y, width: w, height: h, confidence: c,
                faceIndex: nil, targetBox: (x: 0, y: 0, width: 10, height: 10)
            ),
            0
        )
        XCTAssertNil(
            FaceSelection.choose(
                x: x, y: y, width: w, height: h, confidence: c,
                faceIndex: 0, targetBox: (x: 0, y: 0, width: 10, height: 10)
            )
        )
    }

    func testPosePeopleJSON() throws {
        let person = PosePersonBox(x: 0, y: 0, width: 4, height: 2, score: 1)
        let nose = PoseKeypointValue(id: 0, x: 1.5, y: 0.5, confidence: 0.25)
        let json = try PoseLayout.peopleJSON(width: 4, height: 2, people: [(person, [nose])])
        XCTAssertFalse(json.contains("\n"))
        XCTAssertEqual(
            json,
            "{\"width\":4,\"height\":2,\"person_count\":1,\"people\":[{\"index\":0,\"score\":1,"
                + "\"bbox\":{\"x\":0,\"y\":0,\"width\":4,\"height\":2},\"keypoints\":[{\"id\":0,\"name\":\"nose\","
                + "\"x\":1.5,\"y\":0.5,\"confidence\":0.25}]}]}"
        )
    }

    func testPoseUnmapOfFullFrameCenter() throws {
        let box = PosePersonBox(x: 0, y: 0, width: 100, height: 50, score: 0)
        let fit = try PoseLayout.fit(box: box, padding: 1.25, canvasWidth: 192, canvasHeight: 256)
        let point = try PoseLayout.unmap(
            canvasX: 96, canvasY: 128,
            scale: fit.scale, centerX: fit.centerX, centerY: fit.centerY,
            canvasWidth: 192, canvasHeight: 256
        )
        XCTAssertEqual(point.x, 50, accuracy: 1e-9)
        XCTAssertEqual(point.y, 25, accuracy: 1e-9)
    }
}
