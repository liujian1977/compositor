// ModelDownloader.swift — Downloads ML model weights from ModelScope (moba community)

import Foundation
import ArgumentParser

// MARK: - Known Models Registry

/// All known downloadable models.
enum KnownModelKey: String, CaseIterable, ExpressibleByArgument {
    case sam2Lightweight = "sam2-lightweight"
    case lamaFast = "lama-fast"

    var displayName: String { rawValue }

    /// Approximate total download size in bytes.
    var estimatedSizeBytes: Int64 {
        switch self {
        case .sam2Lightweight: return 36_700_160   // ~35MB (model.safetensors)
        case .lamaFast:        return 204_000_000   // ~195MB (big-lama.safetensors from HF)
        }
    }

    /// ModelScope repo identifier (owner/repo format). nil if HF-only.
    var modelScopeRepo: String? {
        switch self {
        case .sam2Lightweight: return "AI-ModelScope/sam2-hiera-tiny"
        case .lamaFast:        return nil   // Not available on ModelScope, use HuggingFace
        }
    }

    /// HuggingFace repo identifier (owner/repo format). Used when ModelScope unavailable.
    var huggingfaceRepo: String? {
        switch self {
        case .sam2Lightweight: return nil
        case .lamaFast:        return "AEmotionStudio/lama-inpainting"
        }
    }

    /// The directory name under the models path (includes .mlx suffix per architecture).
    var modelDirName: String { rawValue + ".mlx" }

    /// Human-readable description.
    var description: String {
        switch self {
        case .sam2Lightweight: return "SAM2 lightweight segmentation (~35MB)"
        case .lamaFast:        return "LaMa inpainting big model (~195MB)"
        }
    }

    /// ModelScope web page URL for reference. Empty if HF-only.
    var modelScopeURL: String {
        guard let repo = modelScopeRepo else { return "" }
        return "https://modelscope.cn/models/\(repo)"
    }

    /// HuggingFace URL for reference.
    var huggingfaceURL: String? {
        guard let repo = huggingfaceRepo else { return nil }
        return "https://huggingface.co/\(repo)"
    }

    /// Files to download for this model (filename, branch). Branch is HF revision or MS branch.
    var files: [(filename: String, branch: String)] {
        switch self {
        case .sam2Lightweight:
            return [("model.safetensors", "main"), ("config.json", "main")]
        case .lamaFast:
            return [("big-lama.safetensors", "main")]
        }
    }

    var displaySize: String {
        let mb = Double(estimatedSizeBytes) / (1024.0 * 1024.0)
        return String(format: "%.0f", mb) + "MB"
    }
}

// MARK: - Model Status

/// Status of a single known model on disk.
enum ModelStatus: Codable {
    /// Built-in (no download needed).
    case builtIn
    /// Directory exists and contains files.
    case installed
    /// No directory found.
    case missing

    func label() -> String {
        switch self {
        case .builtIn: return "built-in"
        case .installed: return "installed"
        case .missing: return "missing"
        }
    }
}

/// A single model entry in the `list` output.
struct ModelInfo: Codable {
    let key: String
    let sizeBytes: Int64
    let status: ModelStatus

    var displaySizeMB: Double {
        switch status {
        case .builtIn: return 0
        default:
            return Double(sizeBytes) / (1024.0 * 1024.0)
        }
    }

    var statusLabel: String { status.label() }
}

// MARK: - Model Path Helpers

/// The base models directory: ~/Library/Application Support/Compositor/models/
func modelBasePath() -> URL {
    do {
        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return path.appendingPathComponent("Compositor").appendingPathComponent("models")
    } catch {
        // Fallback to a safe default if something goes wrong
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".compositor")
            .appendingPathComponent("models")
    }
}

/// Full path to a model's directory.
func modelPath(for key: KnownModelKey) -> URL {
    modelBasePath().appendingPathComponent(key.modelDirName)
}

/// Check whether a model is installed (directory exists with files).
func modelStatus(for key: KnownModelKey) -> ModelStatus {
    let dir = modelPath(for: key)
    guard FileManager.default.fileExists(atPath: dir.path),
          let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
          !contents.isEmpty else {
        return .missing
    }
    return .installed
}

// MARK: - Download Result & Progress

/// Result of a model download operation.
enum ModelDownloadResult {
    case success(URL)   // URL to the downloaded model directory
    case failure(String) // Error description
}

/// Progress information reported during download.
struct DownloadProgress {
    let key: String
    let fileIndex: Int
    let totalFiles: Int
    let downloadedBytes: Int64
    let totalBytes: Int64?   // nil if server doesn't report content-length

    var percentComplete: Double {
        guard let total = totalBytes, total > 0 else { return 0 }
        return min(Double(downloadedBytes) / Double(total), 1.0)
    }

    /// Human-readable size string.
    private func formatBytes(_ bytes: Int64) -> String {
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f", Double(bytes) / 1_073_741_824) + "GB"
        } else if bytes >= 1_048_576 {
            return String(format: "%.1f", Double(bytes) / 1_048_576) + "MB"
        } else if bytes >= 1_024 {
            return String(format: "%.0f", Double(bytes) / 1_024) + "KB"
        }
        return String(bytes) + "B"
    }

    var displayString: String {
        let total = totalBytes != nil ? " (\(formatBytes(downloadedBytes))/\(formatBytes(totalBytes!)))" : ""
        let barWidth = 30
        let filled = Int(percentComplete * Double(barWidth))
        let empty = barWidth - filled
        let bar = String(repeating: "=", count: max(filled, 0)) + String(repeating: " ", count: max(empty, 0))
        return "[" + bar + "] \(key): file \(fileIndex+1)/\(totalFiles), \(Int(percentComplete*100))%\(total)"
    }
}

// MARK: - Model Manifest

/// Metadata stored per model directory.
struct ModelManifest: Codable {
    let key: String
    let version: String = "1.0"
    var sizeBytes: Int64
    var downloadedAt: String

    init(key: String, sizeBytes: Int64) {
        self.key = key
        self.sizeBytes = sizeBytes
        self.downloadedAt = ISO8601DateFormatter().string(from: Date())
    }

    func save(to directory: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: directory.appendingPathComponent("manifest.json"), options: .atomic)
    }
}

// MARK: - Download Engine (fully synchronous)

    /// Downloads models from ModelScope (moba community), falling back to HuggingFace.
struct ModelDownloader {

    private let apiBase = "https://modelscope.cn/api/v1/models"
    private let requestTimeout: TimeInterval = 300   // 5 minutes per request
    private let hfApiBase = "https://huggingface.co"

    init() {}

    /// Download a model synchronously with progress reporting.
    /// - Parameters:
    ///   - key: The model key to download.
    ///   - destination: Directory to place the downloaded files.
    ///   - progressHandler: Called periodically with progress info (on main queue by default).
    /// - Returns: Success with URL to destination, or failure with error string.
    @discardableResult
    func download(key: KnownModelKey,
                  to destination: URL,
                  progressHandler: @escaping (_ progress: DownloadProgress) -> Void) throws -> ModelDownloadResult {

        // Ensure destination directory exists
        do {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return .failure("Failed to create model directory at \(destination.path): \(error.localizedDescription)")
        }

        let totalFiles = key.files.count
        var downloadedBytesTotal: Int64 = 0

        // First pass: get download URLs from API for all files
        struct FileInfo {
            let filename: String
            let downloadURL: URL
        }
        var fileInfos: [FileInfo] = []

        for fileInfo in key.files {
            do {
                let downloadURL = try getDownloadURL(modelKey: key, filename: fileInfo.filename, branch: fileInfo.branch)
                fileInfos.append(FileInfo(filename: fileInfo.filename, downloadURL: downloadURL))
            } catch let err as NSError {
                // Clean up partial downloads
                try? FileManager.default.removeItem(at: destination)
                return .failure("Failed to get download URL for \(fileInfo.filename): \(err.localizedDescription).")
            }
        }

        // Second pass: actually download each file sequentially using blocking calls
        for (idx, fileInfo) in key.files.enumerated() {
            guard idx < fileInfos.count else { break }
            let downloadURL = fileInfos[idx].downloadURL
            do {
                let bytesDownloaded = try downloadFile(downloadURL, to: destination.appendingPathComponent(fileInfo.filename))
                downloadedBytesTotal += bytesDownloaded

                // Report progress on main thread
                let progress = DownloadProgress(
                    key: key.displayName,
                    fileIndex: idx,
                    totalFiles: totalFiles,
                    downloadedBytes: downloadedBytesTotal,
                    totalBytes: key.estimatedSizeBytes
                )
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            } catch let err as NSError {
                // Clean up on failure
                try? FileManager.default.removeItem(at: destination)
                return .failure("Download failed for \(fileInfo.filename): \(err.localizedDescription)")
            }
        }

        // Write manifest.json
        do {
            let manifest = ModelManifest(key: key.displayName, sizeBytes: downloadedBytesTotal)
            try manifest.save(to: destination)
        } catch {
            return .failure("Failed to save model manifest: \(error.localizedDescription)")
        }

        return .success(destination)
    }

    /// Remove a downloaded model.
    /// - Returns: true if removed, false if not found.
    @discardableResult
    func remove(key: KnownModelKey) -> Bool {
        let dir = modelPath(for: key)
        guard FileManager.default.fileExists(atPath: dir.path) else { return false }
        do {
            try FileManager.default.removeItem(at: dir)
            return true
        } catch {
            fputs("Warning: Failed to remove model \(key.displayName): \(error.localizedDescription)\n", stderr)
            return false
        }
    }

    // MARK: - Private Helpers

    /// Get the direct download URL from ModelScope REST API, falling back to HuggingFace.
    private func getDownloadURL(modelKey: KnownModelKey, filename: String, branch: String) throws -> URL {
        // Try ModelScope first if available
        if modelKey.modelScopeRepo != nil {
            do {
                return try getModelScopeDownloadURL(modelKey: modelKey, filename: filename, branch: branch)
            } catch {
                // Fall through to HuggingFace
            }
        }

        // Use HuggingFace
        guard let repo = modelKey.huggingfaceRepo else {
            throw NSError(domain: "ModelDownloader", code: 100, userInfo: [NSLocalizedDescriptionKey: "No download source available for this model."])
        }
        return try getHFDownloadURL(repo: repo, filename: filename)
    }

    /// Get the direct download URL from ModelScope REST API.
    private func getModelScopeDownloadURL(modelKey: KnownModelKey, filename: String, branch: String) throws -> URL {
        guard let repo = modelKey.modelScopeRepo else {
            throw NSError(domain: "ModelDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: "No ModelScope repo for this model"])
        }
        var components = URLComponents(string: apiBase + "/" + repo + "/repo")!
        components.queryItems = [
            URLQueryItem(name: "Revision", value: branch),
            URLQueryItem(name: "FilePath", value: filename)
        ]

        guard let url = components.url else {
            throw NSError(domain: "ModelDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout

        // Synchronous data fetch (blocking but safe for CLI tool)
        var respData: Data = Data()
        var respResponse: URLResponse!
        do {
            var syncError: Error?
            let sem = DispatchSemaphore(value: 0)
            URLSession.shared.dataTask(with: request) { d, r, e in
                if let d = d { respData = d }
                respResponse = r
                syncError = e
                sem.signal()
            }.resume()
            _ = sem.wait(timeout: .now() + requestTimeout)

            // Check for timeout or error
            if let err = syncError as NSError?, err.code != NSUserCancelledError {
                throw err
            }
        } catch {
            throw error
        }

        guard let httpResponse = respResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ModelDownloader", code: 2, userInfo: [NSLocalizedDescriptionKey: "API returned non-200 status"])
        }

        // Parse JSON response
        struct APIResponse: Decodable {
            let code: String?
            let message: String?
            let data: APIData?
        }
        struct APIData: Decodable {
            let download_url: String?
        }

        guard let apiResp = try? JSONDecoder().decode(APIResponse.self, from: respData) else {
            throw NSError(domain: "ModelDownloader", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid API response format"])
        }

        if apiResp.code != "Success", let msg = apiResp.message {
            throw NSError(domain: "ModelDownloader", code: 3, userInfo: [NSLocalizedDescriptionKey: "API error: \(msg)"])
        }

        guard let downloadURLString = apiResp.data?.download_url else {
            throw NSError(domain: "ModelDownloader", code: 4, userInfo: [NSLocalizedDescriptionKey: "No download URL in API response. The file may not exist or requires authentication."])
        }

        guard let finalURL = URL(string: downloadURLString) else {
            throw NSError(domain: "ModelDownloader", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL from API"])
        }

        return finalURL
    }

    /// Get the direct download URL from HuggingFace.
    private func getHFDownloadURL(repo: String, filename: String) throws -> URL {
        guard var components = URLComponents(string: hfApiBase + "/\(repo)/resolve/main/\(filename)") else {
            throw NSError(domain: "ModelDownloader", code: 20, userInfo: [NSLocalizedDescriptionKey: "Invalid HF URL"])
        }

        // First do a HEAD request to get the actual redirect URL (HF uses redirects)
        var headRequest = URLRequest(url: components.url!)
        headRequest.httpMethod = "HEAD"
        headRequest.timeoutInterval = 60

        let sem = DispatchSemaphore(value: 0)
        var finalURL: URL?

        URLSession.shared.dataTask(with: headRequest) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                finalURL = httpResponse.url
            }
            sem.signal()
        }.resume()

        _ = sem.wait(timeout: .now() + 60)

        // If HEAD failed, use the original URL (URLSession will follow redirects automatically on GET)
        guard let baseURL = finalURL ?? components.url else {
            throw NSError(domain: "ModelDownloader", code: 21, userInfo: [NSLocalizedDescriptionKey: "Failed to resolve HF download URL"])
        }

        return baseURL
    }

    /// Download a single file synchronously with progress tracking.
    private func downloadFile(_ url: URL, to destination: URL) throws -> Int64 {
        let sem = DispatchSemaphore(value: 0)
        var resultBytes: Int64 = 0
        var lastError: Error?

        let task = URLSession.shared.downloadTask(with: url) { tempURL, httpResponse, error in
            if let error = error {
                lastError = error
                sem.signal()
                return
            }

            guard let tempURL = tempURL else {
                lastError = NSError(domain: "ModelDownloader", code: 10, userInfo: [NSLocalizedDescriptionKey: "No temporary URL returned"])
                sem.signal()
                return
            }

            // Get file size from HTTP headers or filesystem
            if let httpResponse = httpResponse as? HTTPURLResponse,
               let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let length = Int64(contentLength) {
                resultBytes = length
            } else {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: tempURL.path)
                    if let size = attrs[.size] as? Int64 {
                        resultBytes = size
                    }
                } catch {}
            }

            // Move from temp to final destination
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
            } catch {
                lastError = error
            }

            sem.signal()
        }

        task.resume()

        // Wait for download with timeout (30 minutes)
        let result = sem.wait(timeout: .now() + 1800)
        if result == .timedOut {
            task.cancel()
            throw NSError(domain: "ModelDownloader", code: 11, userInfo: [NSLocalizedDescriptionKey: "Download timed out"])
        }

        if let error = lastError {
            throw error
        }

        return resultBytes
    }
}
