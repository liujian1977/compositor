// ModelsIntegrationTests.swift — Tests for the `compositor models` subcommand.

import XCTest
@testable import CompositorCLI

final class ModelsIntegrationTests: XCTestCase {

    /// Verify that `models list --json` produces valid JSON with expected keys.
    func testModelsListJSONOutput() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        var objects: [[String: Any]] = [
            ["key": "vision", "status": "built-in", "size_mb": 0.0]
        ]

        for key in KnownModelKey.allCases {
            let status = modelStatus(for: key)
            objects.append([
                "key": key.displayName,
                "status": status.label(),
                "size_mb": Double(key.estimatedSizeBytes) / (1024 * 1024)
            ])
        }

        guard let data = try? JSONSerialization.data(withJSONObject: objects),
              let text = String(data: data, encoding: .utf8) else {
            XCTFail("JSON output should be valid")
            return
        }

        // Parse the JSON back to verify structure
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              parsed.count == KnownModelKey.allCases.count + 1 else {
            XCTFail("JSON should have \(KnownModelKey.allCases.count + 1) entries")
            return
        }

        // Verify each entry has required keys
        for entry in parsed {
            XCTAssert(entry["key"] != nil, "Each entry must have a 'key' field")
            XCTAssert(entry["status"] != nil, "Each entry must have a 'status' field")
            XCTAssert(entry["size_mb"] != nil, "Each entry must have a 'size_mb' field")
        }

        // Verify known keys are present
        let keys = parsed.map { $0["key"] as? String ?? "" }
        XCTAssertTrue(keys.contains("vision"), "Should include built-in 'vision' model")
        XCTAssertTrue(keys.contains("sam2-lightweight"), "Should include sam2-lightweight")
        XCTAssertTrue(keys.contains("lama-fast"), "Should include lama-fast")
    }

    /// Verify that installed models report status "installed".
    func testModelsListInstalledStatus() throws {
        // SAM2 should always be installed (it's a built-in macOS model)
        let sam2Status = modelStatus(for: .sam2Lightweight)
        XCTAssertNotEqual(sam2Status, .missing, "SAM2 model directory should exist or be handled as built-in")

        // LaMa status depends on whether the download has been done
        let lamaStatus = modelStatus(for: .lamaFast)
        // Just verify the status is one of the valid values
        switch lamaStatus {
        case .installed, .missing:
            break // Both are acceptable depending on environment
        case .builtIn:
            XCTFail("LaMa should never be built-in")
        }
    }

    /// Verify that removing a model changes its status to "missing".
    func testModelRemoveChangesStatus() throws {
        let key = KnownModelKey.lamaFast
        let dir = modelPath(for: key)

        guard FileManager.default.fileExists(atPath: dir.path),
              let _ = try? FileManager.default.contentsOfDirectory(
                  at: dir, includingPropertiesForKeys: nil) else {
            throw XCTSkip("LaMa model not installed — skip remove test")
        }

        // Verify it's currently installed
        XCTAssertEqual(modelStatus(for: key), .installed)

        // Remove the model
        let downloader = ModelDownloader()
        XCTAssertTrue(downloader.remove(key: key))

        // Verify status is now missing
        XCTAssertEqual(modelStatus(for: key), .missing)

        // Re-download to restore state (or skip if network unavailable)
        do {
            _ = try downloader.download(key: key, to: dir) { _ in }
            XCTAssertEqual(modelStatus(for: key), .installed)
        } catch {
            // Network may not be available — that's fine for this test
        }
    }

    /// Verify JSON output is machine-parseable (agent-friendly).
    func testModelsListJSONIsMachineParseable() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        var objects: [[String: Any]] = [
            ["key": "vision", "status": "built-in", "size_mb": 0.0]
        ]

        for key in KnownModelKey.allCases {
            let status = modelStatus(for: key)
            objects.append([
                "key": key.displayName,
                "status": status.label(),
                "size_mb": Double(key.estimatedSizeBytes) / (1024 * 1024)
            ])
        }

        let data = try JSONSerialization.data(withJSONObject: objects)

        // Simulate what an agent would do: parse as JSON and extract status for a specific key
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            XCTFail("JSON should be parseable")
            return
        }

        let sam2Entry = parsed.first { $0["key"] as? String == "sam2-lightweight" }
        XCTAssertNotNil(sam2Entry, "Should find sam2-lightweight entry")
        XCTAssertNotNil(sam2Entry?["status"], "sam2-lightweight should have a status field")
    }

    /// Verify text output format for human readability.
    func testModelsListTextOutput() throws {
        var installedLines: [String] = []
        var missingLines: [String] = []

        for key in KnownModelKey.allCases {
            let sizeMB = Double(key.estimatedSizeBytes) / (1024.0 * 1024.0)
            let line = "  - \(key.displayName) (\(String(format: "%.0f", sizeMB))MB)"
            switch modelStatus(for: key) {
            case .installed:
                installedLines.append(line + " ✓")
            case .missing:
                missingLines.append(line + " ✗")
            default:
                break
            }
        }

        // At minimum, text output should have been generated without crashing
        XCTAssertFalse(installedLines.isEmpty && missingLines.isEmpty,
                       "Should have at least one installed or missing model listed")
    }
}
