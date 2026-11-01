import XCTest
import CompositorCore

final class SobelTests: XCTestCase {

    /// A vertical edge (left half dark, right half bright) should produce a high-gradient
    /// band at the boundary and ~0 elsewhere.
    func testVerticalEdgeDetection() throws {
        let w = 16, h = 8
        var image = [UInt8](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                image[y * w + x] = x < 8 ? 0 : 255
            }
        }
        let edges = try SobelOp.detectEdges(image, width: w, height: h)
        XCTAssertEqual(edges.count, w * h)

        // Edges near x=7/8 should be strong; far interior should be ~0
        let edgeAtBoundary = edges[4 * w + 7]   // mid-height, at boundary column
        let edgeInInterior = edges[4 * w + 2]   // mid-height, deep in dark region
        XCTAssertGreaterThan(edgeAtBoundary, edgeInInterior + 0.1, "boundary should have stronger gradient")
        XCTAssertLessThan(edgeInInterior, 0.05, "interior should be near-zero gradient")
    }

    func testUniformImageHasNoEdges() throws {
        let w = 8, h = 8
        let image = [UInt8](repeating: 128, count: w * h)
        let edges = try SobelOp.detectEdges(image, width: w, height: h)
        for e in edges { XCTAssertLessThan(e, 0.001) }
    }
}
