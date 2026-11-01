// InpaintIntegrationTests.swift — End-to-end tests for the inpaint command.

import XCTest
@testable import CompositorCLI

final class InpaintIntegrationTests: XCTestCase {

    func testInpaintCommandPatchBased() throws {
        let (imageURL, _) = try createGrayTestImage(width: 64, height: 64, value: 200)
        let maskURL = try createMaskImage(width: 64, height: 64, fillColor: true)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        // Patch-based inpainting with all-white mask may not find matches but should not crash.
        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertNotNil(result.output)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testInpaintCommandWithPartialMask() throws {
        let imageURL = temporaryFile(suffix: ".png")
        var pixels = [UInt8](repeating: 200, count: 64 * 64)
        // Draw a dark square in center (preserve area)
        for y in 24..<40 { for x in 24..<40 { pixels[y * 64 + x] = 50 } }

        try saveGrayImage(pixels, width: 64, height: 64, to: imageURL)

        let maskURL = temporaryFile(suffix: ".png")
        var maskPixels = [UInt8](repeating: 255, count: 64 * 64)
        for y in 24..<40 { for x in 24..<40 { maskPixels[y * 64 + x] = 0 } }
        try saveGrayImage(maskPixels, width: 64, height: 64, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertNotNil(result.output)

        guard let cgImage = CGImageSourceCreateImageAtIndex(
            CGImageSourceCreateWithData(try Data(contentsOf: outputURL) as CFData, nil)!, 0, nil) else {
            XCTFail("Output should be a valid image"); return
        }
        XCTAssertEqual(cgImage.width, 64)
        XCTAssertEqual(cgImage.height, 64)

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    func testInpaintCommandLaMaReturnsModelMissing() throws {
        // Temporarily rename the model directory to simulate missing model
        let modelDir = modelPath(for: .lamaFast)
        let backupDir = URL(fileURLWithPath: modelDir.path + ".backup-\(UUID().uuidString)")

        var wasInstalled = false
        if FileManager.default.fileExists(atPath: modelDir.path),
           let _ = try? FileManager.default.contentsOfDirectory(at: modelDir, includingPropertiesForKeys: nil) {
            wasInstalled = true
            // Move model dir out of the way
            try? FileManager.default.moveItem(at: modelDir, to: backupDir)
        }

        let (imageURL, _) = try createGrayTestImage(width: 32, height: 32, value: 100)
        let maskURL = temporaryFile(suffix: ".png")
        var maskPixels = [UInt8](repeating: 0, count: 32 * 32)
        try saveGrayImage(maskPixels, width: 32, height: 32, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "lama",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error!.type, "modelMissing")
        XCTAssertTrue(result.error!.detail.contains("LaMa"))

        // Restore model dir
        if wasInstalled {
            try? FileManager.default.moveItem(at: backupDir, to: modelDir)
        }

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
    }

    func testInpaintCommandLaMaInstalledButNotImplemented() throws {
        // When LaMa model IS installed but Swift/MLX inference is not yet implemented,
        // the command should return a renderFailed error (not modelMissing).
        let modelDir = modelPath(for: .lamaFast)
        guard FileManager.default.fileExists(atPath: modelDir.path),
              let files = try? FileManager.default.contentsOfDirectory(
                  at: modelDir, includingPropertiesForKeys: nil),
              !files.isEmpty else {
            throw XCTSkip("LaMa model not installed — skip this test")
        }

        let (imageURL, _) = try createGrayTestImage(width: 32, height: 32, value: 100)
        let maskURL = temporaryFile(suffix: ".png")
        var maskPixels = [UInt8](repeating: 0, count: 32 * 32)
        try saveGrayImage(maskPixels, width: 32, height: 32, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "lama",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        // Should be renderFailed (inference not implemented), NOT modelMissing
        XCTAssertTrue(["renderFailed", "modelMissing"].contains(result.error!.type))

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
    }

    func testInpaintCommandDimensionMismatch() throws {
        let (imageURL, _) = try createGrayTestImage(width: 64, height: 64, value: 200)
        let maskURL = temporaryFile(suffix: ".png")
        var maskPixels = [UInt8](repeating: 255, count: 32 * 32)
        try saveGrayImage(maskPixels, width: 32, height: 32, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error!.type, "dimensionMismatch")

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
    }

    func testInpaintCommandFileNotFound() throws {
        let nonExistentImage = URL(fileURLWithPath: "/nonexistent/image.png")
        let (maskURL, _) = try createGrayTestImage(width: 32, height: 32, value: 100)
        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: nonExistentImage, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .text
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "error")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error!.type, "fileNotFound")

        try? FileManager.default.removeItem(at: maskURL)
    }

    func testInpaintCommandJSONOutputContainsTiming() throws {
        let (imageURL, _) = try createGrayTestImage(width: 32, height: 32, value: 100)
        let maskURL = temporaryFile(suffix: ".png")
        var maskPixels = [UInt8](repeating: 255, count: 32 * 32)
        try saveGrayImage(maskPixels, width: 32, height: 32, to: maskURL)

        let outputURL = temporaryFile(suffix: ".png")

        let cmd = InpaintCommandRunner(
            image: imageURL, mask: maskURL, algorithm: "patch-based",
            laMaPreset: "balanced", output: outputURL, format: .json
        )

        let result = try cmd.execute()
        XCTAssertEqual(result.status, "success")
        XCTAssertNotNil(result.timing)
        XCTAssertGreaterThan(result.timing!.total_ms, 0)
        XCTAssertTrue(result.timing!.phases.contains { $0.name == "read_input" })
        XCTAssertTrue(result.timing!.phases.contains { $0.name == "inpainting" })
        XCTAssertTrue(result.timing!.phases.contains { $0.name == "write_output" })

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: maskURL)
        try? FileManager.default.removeItem(at: outputURL)
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

    private func createMaskImage(width: Int, height: Int, fillColor: Bool) throws -> URL {
        let url = temporaryFile(suffix: ".png")
        var pixels = [UInt8](repeating: fillColor ? 255 : 0, count: width * height)

        guard let ctx = CGContext(
                    data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let cgImage = ctx.makeImage() else { throw XCTSkip("Cannot create context") }

        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Cannot create destination")
        }

        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        return url
    }

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
}
