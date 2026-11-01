// ExtractIntegrationTests.swift — End-to-end tests for the extract command.

import XCTest
@testable import CompositorCLI

final class ExtractIntegrationTests: XCTestCase {

    func testExtractCommandProducesValidPNG() throws {
        let (inputURL, _) = try createGrayTestImage(width: 100, height: 100, value: 255)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: inputURL, output: outputURL, model: nil, refineRadius: 3,
            contrastThreshold: 0.75, edgeShift: 0, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertNotNil(result.output)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        let data = try Data(contentsOf: outputURL)
        XCTAssertGreaterThan(data.count, 0, "Output PNG should have non-zero size")

        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testExtractCommandWithJSONFormat() throws {
        let (inputURL, _) = try createGrayTestImage(width: 50, height: 50, value: 255)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: inputURL, output: outputURL, model: nil, refineRadius: 0,
            contrastThreshold: 1.0, edgeShift: 0, format: .json
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertNotNil(result.timing)
        XCTAssertGreaterThan(result.timing!.total_ms, 0)
        XCTAssertFalse(result.timing!.phases.isEmpty)

        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testExtractCommandWithRefineRadius() throws {
        let (inputURL, _) = try createGrayTestImage(width: 64, height: 64, value: 255)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: inputURL, output: outputURL, model: nil, refineRadius: 5,
            contrastThreshold: 0.75, edgeShift: 0, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")

        guard let cgImage = CGImageSourceCreateImageAtIndex(
            CGImageSourceCreateWithData(try Data(contentsOf: outputURL) as CFData, nil)!, 0, nil) else {
            XCTFail("Output should be a valid image"); return
        }
        XCTAssertEqual(cgImage.width, 64)
        XCTAssertEqual(cgImage.height, 64)

        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testExtractCommandWithEdgeShiftDilate() throws {
        let (inputURL, _) = try createGrayTestImage(width: 50, height: 50, value: 255)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: inputURL, output: outputURL, model: nil, refineRadius: 0,
            contrastThreshold: 1.0, edgeShift: 3, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")

        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testExtractCommandWithEdgeShiftErode() throws {
        let (inputURL, _) = try createGrayTestImage(width: 50, height: 50, value: 255)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: inputURL, output: outputURL, model: nil, refineRadius: 0,
            contrastThreshold: 1.0, edgeShift: -2, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")

        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testExtractCommandFileNotFound() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/test.png")
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: nonExistentURL, output: outputURL, model: nil, refineRadius: 3,
            contrastThreshold: 0.75, edgeShift: 0, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error!.type, "fileNotFound")
    }

    func testExtractCommandInvalidImageFormat() throws {
        let invalidURL = temporaryFile(suffix: ".dat")
        try "not an image".write(to: invalidURL, atomically: true, encoding: .utf8)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = ExtractCommandRunner(
            input: invalidURL, output: outputURL, model: nil, refineRadius: 3,
            contrastThreshold: 0.75, edgeShift: 0, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error!.type, "invalidImageFormat")

        try? FileManager.default.removeItem(at: invalidURL)
    }

    // MARK: - Helpers

    private func createGrayTestImage(width: Int, height: Int, value: UInt8) throws -> (url: URL, data: Data) {
        let url = temporaryFile(suffix: ".png")
        var pixels = [UInt8](repeating: value, count: width * height)

        guard let ctx = CGContext(
                    data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let cgImage = ctx.makeImage() else { throw XCTSkip("Cannot create context") }

        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Cannot create destination")
        }

        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)

        let data = try Data(contentsOf: url)
        return (url, data)
    }

    private func temporaryFile(suffix: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory().appending("/compositor-test-\(UUID().uuidString)\(suffix)"))
    }
}
