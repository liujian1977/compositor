import XCTest
import Foundation

final class CLITests: XCTestCase {

    /// Locate the built `compositor` executable. Returns nil if not found (e.g. not yet built).
    private func compositorBinary() -> URL? {
        let fm = FileManager.default
        let exe = Bundle(for: CLITests.self).executableURL!
        // macOS layout: <root>/.build/<config>/CompositorCLITests.xctest/Contents/MacOS/<testexe>
        let candidates = [
            // exe -> Contents -> xctest -> <config> -> compositor
            exe.deletingLastPathComponent()  // MacOS
                .deletingLastPathComponent() // Contents
                .deletingLastPathComponent() // xctest
                .deletingLastPathComponent() // <config>
                .appendingPathComponent("compositor"),
            // Flat fallbacks (older layouts)
            exe.deletingLastPathComponent().appendingPathComponent("compositor")
        ]
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }

    private func run(_ args: [String]) throws -> (exitCode: Int32, stdout: String, stderr: String) {
        guard let bin = compositorBinary() else {
            throw XCTSkip("compositor binary not found — run `swift build` first")
        }
        let process = Process()
        process.executableURL = bin
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        return (process.terminationStatus, stdout, stderr)
    }

    func testVersionFlag() throws {
        let (code, stdout, _) = try run(["--version"])
        XCTAssertEqual(code, 0)
        XCTAssertTrue(stdout.contains("compositor version"), "version output: \(stdout)")
    }

    func testExtractMissingInputReturnsJsonError() throws {
        let tmp = FileManager.default.temporaryDirectory
        let out = tmp.appendingPathComponent("cli_missing_out.png")
        let (code, stdout, _) = try run([
            "extract", "--input", "/nonexistent/file.png",
            "--output", out.path, "--format", "json"
        ])
        XCTAssertEqual(code, 0, "CLI returns 0 with JSON error (per spec)")
        XCTAssertTrue(stdout.contains("\"status\" : \"error\""))
        XCTAssertTrue(stdout.contains("fileNotFound"))
    }

    func testExportPNGSuccess() throws {        // Use a system PNG as input.
        let fm = FileManager.default
        let systemPNG = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures").appendingPathComponent("Desktop.png")
        let input: URL
        if fm.fileExists(atPath: systemPNG.path) {
            input = systemPNG
        } else {
            // Fallback: any png we can find
            let found = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: "/System/Library"),
                                                    includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension.lowercased() == "png" && fm.fileExists(atPath: $0.path) })
            guard let f = found else { throw XCTSkip("no system PNG available") }
            input = f
        }
        let out = fm.temporaryDirectory.appendingPathComponent("cli_export.png")
        let (code, stdout, stderr) = try run([
            "export", "--input", input.path, "--format", "png",
            "--output", out.path, "--spec-format", "json"
        ])
        XCTAssertEqual(code, 0, "stderr: \(stderr)")
        XCTAssertTrue(fm.fileExists(atPath: out.path), "output PNG should exist")
        XCTAssertTrue(stdout.contains("\"status\" : \"success\""))
    }
}
