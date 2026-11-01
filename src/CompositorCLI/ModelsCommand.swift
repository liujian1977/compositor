// ModelsCommand.swift — `compositor models` subcommand: list/download/remove

import Foundation
import ArgumentParser

extension CompositorCLI {

    // MARK: - Parent Command

    struct ModelsCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "models",
            abstract: "Manage optional ML model downloads (stored in ~/Library/Application Support/Compositor/models/).",
            subcommands: [
                ListModelsCommand.self,
                DownloadModelCommand.self,
                RemoveModelCommand.self
            ]
        )

        func run() throws {
            throw CleanExit.helpRequest(nil)  // Show usage when `compositor models` called alone
        }
    }

    // MARK: - list subcommand

    struct ListModelsCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "list"
        )

        @Flag(help: "Output as JSON for agent parsing.")
        var json: Bool = false

        func run() throws {
            if json {
                // Build model list including built-in "vision"
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

                // Create a simple array of key/status pairs for cleaner JSON output
                var objects: [[String: Any]] = [
                    ["key": "vision", "status": "built-in", "size_mb": 0.0]
                ]

                for key in KnownModelKey.allCases {
                    let status = modelStatus(for: key)
                    objects.append([
                        "key": key.displayName,
                        "status": status.label(),
                        "size_mb": key.estimatedSizeBytes / (1024 * 1024)
                    ])
                }

                if let data = try? JSONSerialization.data(withJSONObject: objects),
                   let text = String(data: data, encoding: .utf8) {
                    print(text)
                }
            } else {
                // Text output with sections
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

                print("Installed models:")
                if installedLines.isEmpty {
                    print("  (none)")
                } else {
                    for line in installedLines {
                        print(line)
                    }
                }

                print("\nMissing model(s):")
                if missingLines.isEmpty {
                    print("  (all models installed)")
                } else {
                    for line in missingLines {
                        print(line)
                    }
                }
            }
        }
    }

    // MARK: - download subcommand

    struct DownloadModelCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "download",
            abstract: "Download an ML model from ModelScope (moba community)."
        )

        @Argument(help: "Model key to download. Available: \(KnownModelKey.allCases.map(\.displayName).joined(separator: ", "))")
        var modelKey: KnownModelKey

        @Flag(name: .shortAndLong, help: "Re-download even if the model is already installed.")
        var force: Bool = false

        func run() throws {
            // Check if already installed (unless --force)
            let status = modelStatus(for: modelKey)
            if !force && status == .installed {
                print("Model '\(modelKey.displayName)' is already installed. Use --force to re-download.")
                return
            }

            let dir = modelPath(for: modelKey)

            // Progress bar on stderr with carriage return for in-place updates
            var lastProgressDisplay: String?
            func progressCallback(_ progress: DownloadProgress) {
                let display = progress.displayString
                if display != lastProgressDisplay {
                    fputs(display + "\r", stderr)
                    fflush(stderr)
                    lastProgressDisplay = display
                }
            }

            // Execute download (now synchronous)
            do {
                let result = try ModelDownloader().download(key: modelKey, to: dir, progressHandler: progressCallback)
                switch result {
                case .success(let path):
                    // Final newline after progress updates stop
                    fputs("\n", stderr)
                    print("Downloaded \(modelKey.displayName) to \(path.path)")
                case .failure(let error):
                    fputs("\n", stderr)
                    throw NSError(domain: "ModelDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
                }
            } catch {
                // Clean up partial download on failure (already done in ModelDownloader, but be safe)
                try? FileManager.default.removeItem(at: dir)
                fputs("\n", stderr)
                throw error
            }
        }
    }

    // MARK: - remove subcommand

    struct RemoveModelCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "remove",
            abstract: "Remove a downloaded ML model."
        )

        @Argument(help: "Model key to remove. Available: \(KnownModelKey.allCases.map(\.displayName).joined(separator: ", "))")
        var modelKey: KnownModelKey

        func run() throws {
            let dir = modelPath(for: modelKey)
            guard FileManager.default.fileExists(atPath: dir.path) else {
                print("Model '\(modelKey.displayName)' is not installed. Nothing to remove.")
                return
            }

            if ModelDownloader().remove(key: modelKey) {
                print("Removed \(modelKey.displayName)")
            } else {
                print("Failed to remove \(modelKey.displayName).")
            }
        }
    }
}
