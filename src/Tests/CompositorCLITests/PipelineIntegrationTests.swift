// PipelineIntegrationTests.swift — End-to-end tests for extract → inpaint pipeline.

import XCTest
@testable import CompositorCLI

final class PipelineIntegrationTests: XCTestCase {

    /// Test that a gray image with a visible defect can be extracted and inpainted end-to-end.
    func testExtractThenInpaintPipeline() throws {
        // 1. Create a gray image (255) with a dark square in the center (defect)
        let width = 64, height = 64
        var pixels = [UInt8](repeating: 255, count: width * height)
        for y in 20..<44 { for x in 20..<44 { pixels[y * width + x] = 128 } }

        let imageURL = temporaryFile(suffix: ".png")
        try saveGrayImage(pixels, width: width, height: height, to: imageURL)

        // 2. Create a mask that covers the defect area (all white = inpaint everything)
        let maskPixels = [UInt8](repeating: 255, count: width * height)
        let maskURL = temporaryFile(suffix: ".png")
        try saveGrayImage(maskPixels, width: width, height: height, to: maskURL)

        // 3. Run extract — should produce a mask PNG
        let extractOutputURL = temporaryFile(suffix: ".png")
        let extractRunner = ExtractCommandRunner(
            input: imageURL, output: extractOutputURL, model: nil, refineRadius: 0, contrastThreshold: 0.0, edgeShift: 0, format: .text
        )
        var extractResult = try extractRunner.execute()
        XCTAssertEqual(extractResult.status, "success")

        // 4. Run inpaint with patch-based algorithm (all-white mask)
        let inpaintOutputURL = temporaryFile(suffix: ".png")
        let inpaintRunner = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: inpaintOutputURL, format: .text
        )
        let inpaintResult = try inpaintRunner.execute()

        XCTAssertEqual(inpaintResult.status, "success")
        XCTAssertNotNil(inpaintResult.output)
        XCTAssertTrue(FileManager.default.fileExists(atPath: inpaintOutputURL.path))

        // 5. Verify output is a valid PNG with correct dimensions
        guard let data = try? Data(contentsOf: inpaintOutputURL),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            XCTFail("Inpaint output should be a valid PNG")
            return
        }
        XCTAssertEqual(cgImage.width, width)
        XCTAssertEqual(cgImage.height, height)

        // Cleanup
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
    }

    /// Test that inpaint with a partial mask produces valid output.
    func testInpaintChangesMaskedRegion() throws {
        let width = 64, height = 64

        // Create image: left half light (200), right half dark (50)
        var pixels = [UInt8](repeating: 50, count: width * height)
        for y in 0..<height {
            for x in 0..<32 {
                pixels[y * width + x] = 200 // light left half
            }
        }

        let imageURL = temporaryFile(suffix: ".png")
        try saveGrayImage(pixels, width: width, height: height, to: imageURL)

        // Mask only the right half of the image (the dark area)
        var maskPixels = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 32..<width {
                maskPixels[y * width + x] = 255 // inpaint right half only
            }
        }

        let maskURL = temporaryFile(suffix: ".png")
        try saveGrayImage(maskPixels, width: width, height: height, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")
        let runner = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try runner.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // The right half is the only masked region, so it must move toward the
        // preserved left half (200). The left half must stay 200. A mask that
        // was ignored would leave the right half at 50.
        let decoded = try readGray(outputURL)
        XCTAssertEqual(decoded.width, width)
        XCTAssertEqual(decoded.height, height)
        for y in 0..<height {
            for x in 0..<width {
                let value = Int(decoded.pixels[y * width + x])
                if x < 32 {
                    XCTAssertEqual(value, 200, "unmasked left column \(x) changed")
                } else {
                    XCTAssertGreaterThan(value, 170, "masked right column \(x) was not filled from the left")
                }
            }
        }

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    /// A black mask preserves every pixel. The photo itself contains 255, so a
    /// runner that painted the photo into the mask buffer would treat that
    /// block as a hole and pull it toward the surrounding 0.
    func testBlackMaskLeavesImageUnchanged() throws {
        let width = 32, height = 32
        var pixels = [UInt8](repeating: 0, count: width * height)
        for y in 12..<20 {
            for x in 12..<20 { pixels[y * width + x] = 255 }
        }
        let imageURL = temporaryFile(suffix: ".png")
        try saveGrayImage(pixels, width: width, height: height, to: imageURL)

        let maskURL = temporaryFile(suffix: ".png")
        try saveGrayImage([UInt8](repeating: 0, count: width * height), width: width, height: height, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")
        let runner = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )
        let result = try runner.execute()
        XCTAssertEqual(result.status, "success")

        let decoded = try readGray(outputURL)
        for y in 0..<height {
            for x in 0..<width {
                let value = Int(decoded.pixels[y * width + x])
                if x >= 12 && x < 20 && y >= 12 && y < 20 {
                    XCTAssertGreaterThan(value, 250, "black mask must keep the bright block")
                } else {
                    XCTAssertLessThan(value, 5, "black mask must keep the surround")
                }
            }
        }

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - Helpers

    private func saveGrayImage(_ pixels: [UInt8], width: Int, height: Int, to url: URL) throws {
        var mutable = pixels
        guard let ctx = CGContext(
                    data: &mutable, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let cgImage = ctx.makeImage() else { throw NSError(domain: "TestError", code: 1, userInfo: nil) }

        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw NSError(domain: "TestError", code: 2, userInfo: nil)
        }

        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
    }

    private func temporaryFile(suffix: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory().appending("/compositor-test-\(UUID().uuidString)\(suffix)"))
    }

    private func readGray(_ url: URL) throws -> (pixels: [UInt8], width: Int, height: Int) {
        let data = try Data(contentsOf: url)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "TestError", code: 3, userInfo: nil)
        }
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw NSError(domain: "TestError", code: 4, userInfo: nil)
        }
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (pixels, w, h)
    }
}
