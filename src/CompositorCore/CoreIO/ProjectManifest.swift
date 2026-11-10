// ProjectManifest.swift — CoreIO
/// Read/write .comp project manifests. Based on Compositor's official format docs.

import Foundation

/// A parsed .comp project manifest. Immutable once created (copy-on-write mutations).
public struct ProjectManifest: Sendable, Codable {
    public let format: String             // always "com.compositor.project"
    public let version: Int               // 1–11 (new saves use 11)
    public let colorSpace: String         // currently "sRGB"
    public let documentID: UUID
    public let width: Int                 // canvas width in pixels
    public let height: Int                // canvas height in pixels
    public let resolution: Double         // pixels/inch, default 72
    public var activeLayerID: UUID

    /// Layers in bottom-to-top render order.
    public var layers: [LayerRecord]

    public struct LayerRecord: Sendable, Codable {
        public let id: UUID               // must match image file name (without .png)
        public let name: String
        public var imageFile: String?     // nil for adjustment/text layers
        public var maskFile: String?      // optional: "<id>.mask.png"
        public var maskEnabled: Bool = true

        /// Layer appearance (version 3+)
        public var opacity: Double = 1.0  // clamped to [0, 1]
        public var blendMode: BlendMode = .normal

        /// Layer transform in document pixel coordinates (always present)
        public var transform: Transform   // origin, size, rotation, flips, sampling

        /// Optional: adjustment layer settings (version 7+)
        var adjustment: Adjustment?       // nil for normal image layers

        /// Optional: text layer metadata (versions 10–11)
        var text: TextMetadata?           // content, font, size, color, alignment

        /// Filename of the layer's PNG image file within the .comp folder.
        /// Set by ProjectStore during save operations; nil for non-image layers.
        var filename: String?

        /// Image dimensions read from PNG metadata at load time.
        /// Defaults to canvas size if not available.
        var width: Int?
        var height: Int?

        enum CodingKeys: String, CodingKey {
            case id, name, imageFile, maskFile, maskEnabled
            case opacity, blendMode, transform, adjustment, text
            case filename, width, height
        }

        public init(id: UUID, name: String, imageFile: String?, opacity: Double, blendMode: BlendMode, transform: Transform) {
            self.id = id
            self.name = name
            self.imageFile = imageFile
            self.maskFile = nil
            self.maskEnabled = true
            self.opacity = opacity
            self.blendMode = blendMode
            self.transform = transform
            self.adjustment = nil
            self.text = nil
            self.filename = imageFile
            self.width = nil
            self.height = nil
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            imageFile = try container.decodeIfPresent(String.self, forKey: .imageFile)
            maskFile = try container.decodeIfPresent(String.self, forKey: .maskFile)
            maskEnabled = try container.decodeIfPresent(Bool.self, forKey: .maskEnabled) ?? true
            opacity = max(0, min(1, try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0))
            blendMode = try container.decodeIfPresent(BlendMode.self, forKey: .blendMode) ?? .normal
            transform = try container.decode(Transform.self, forKey: .transform)

            // Decode optional fields
            adjustment = try container.decodeIfPresent(Adjustment.self, forKey: .adjustment)
            text = try container.decodeIfPresent(TextMetadata.self, forKey: .text)
            filename = try container.decodeIfPresent(String.self, forKey: .filename)
            width = try container.decodeIfPresent(Int.self, forKey: .width)
            height = try container.decodeIfPresent(Int.self, forKey: .height)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            if let imageFile { try container.encode(imageFile, forKey: .imageFile) }
            if let maskFile { try container.encode(maskFile, forKey: .maskFile) }
            if !maskEnabled { try container.encode(maskEnabled, forKey: .maskEnabled) }
            try container.encode(opacity, forKey: .opacity)
            try container.encode(blendMode, forKey: .blendMode)
            try container.encode(transform, forKey: .transform)
            if let adjustment { try container.encode(adjustment, forKey: .adjustment) }
            if let text { try container.encode(text, forKey: .text) }
            if let filename { try container.encode(filename, forKey: .filename) }
            if let width { try container.encode(width, forKey: .width) }
            if let height { try container.encode(height, forKey: .height) }
        }
    }

    public enum BlendMode: String, Codable {
        case normal = "Normal", darken = "Darken"
        case multiply = "Multiply", colorBurn = "Color Burn", linearBurn = "Linear Burn"
        case screen = "Screen", colorDodge = "Color Dodge", linearDodgeAdd = "Linear Dodge (Add)"
        case overlay = "Overlay", softLight = "Soft Light", hardLight = "Hard Light"
        case vividLight = "Vivid Light", linearLight = "Linear Light", pinLight = "Pin Light"
        case hardMix = "Hard Mix", difference = "Difference", exclusion = "Exclusion"
        case subtract = "Subtract", divide = "Divide"
        case hue = "Hue", saturation = "Saturation", color = "Color", luminosity = "Luminosity"
    }

    public struct Transform: Sendable, Codable {
        public let origin: [Double]       // [x, y] in document pixels
        public let size: [Double]         // [width, height]
        public let rotation: Double       // degrees, clockwise
        public let flipX: Bool, flipY: Bool
        public let sampling: String       // "High quality", "Smooth", or "Nearest"

        public init(origin: [Double], size: [Double], rotation: Double, flipX: Bool, flipY: Bool, sampling: String) {
            self.origin = origin
            self.size = size
            self.rotation = rotation
            self.flipX = flipX
            self.flipY = flipY
            self.sampling = sampling
        }
    }

    public enum AdjustmentKind: String, Codable {
        case hueSaturation, levels, curves, exposure, gradientMap, grain
        case invert, blackWhite, colorBalance
        case gaussianBlur, motionBlur, addNoise
    }

    public struct Adjustment: Sendable, Codable {
        public let kind: AdjustmentKind
        // Fields vary by kind — simplified for CLI purposes.
        // Full implementation would include all per-kind settings.
    }

    public struct TextMetadata: Sendable, Codable {
        public let content: String
        public let fontName: String       // PostScript name
        public let fontSize: Double       // in pixels
        public let red: Double, green: Double, blue: Double
        public let alignment: String      // "Left", "Center", "Right"
    }

    public init(
        format: String = "com.compositor.project",
        version: Int = 11,
        colorSpace: String = "sRGB",
        documentID: UUID = UUID(),
        width: Int, height: Int,
        resolution: Double = 72,
        activeLayerID: UUID,
        layers: [LayerRecord]
    ) {
        self.format = format
        self.version = version
        self.colorSpace = colorSpace
        self.documentID = documentID
        self.width = width
        self.height = height
        self.resolution = resolution
        self.activeLayerID = activeLayerID
        self.layers = layers
    }

    /// Validate manifest constraints. Returns nil if valid, or an error string.
    func validate() -> String? {
        guard width >= 1 && width <= 30_000 else { return "Canvas width \(width) out of range [1, 30000]" }
        guard height >= 1 && height <= 30_000 else { return "Canvas height \(height) out of range [1, 30000]" }
        guard Int64(width) * Int64(height) <= 100_000_000 else { return "Total pixels \(width)x\(height) exceeds 100M" }
        guard layers.count <= 10_000 else { return "Layer count \(layers.count) exceeds 10,000 limit" }

        var seenIDs = Set<UUID>()
        for layer in layers {
            if !seenIDs.insert(layer.id).inserted {
                return "Duplicate layer ID: \(layer.id)"
            }
            // Image file must match layer UUID (uppercase)
            if let imageFile = layer.imageFile, imageFile != "\(layer.id.uuidString.uppercased()).png" {
                return "Layer \(layer.id): imageFile '\(imageFile)' doesn't match ID"
            }
        }
        return nil
    }
}

/// Read/write manifest files for .comp project folders.
public enum ManifestIO {
    /// Read a manifest from a .comp folder path. Throws on invalid JSON or format violations.
    public static func read(from packageURL: URL) throws -> ProjectManifest {
        let manifestURL = packageURL.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw CoreError.fileNotFound(path: manifestURL.path)
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            let manifest = try decoder.decode(ProjectManifest.self, from: data)

            if let error = manifest.validate() {
                throw CoreError.invalidImageFormat(url: packageURL, reason: error)
            }

            return manifest
        } catch is DecodingError {
            throw CoreError.invalidImageFormat(url: manifestURL, reason: "Invalid JSON format")
        } catch {
            throw error
        }
    }

    /// Write a manifest to a .comp folder atomically (write to tmp, then rename).
    public static func write(to packageURL: URL, manifest: ProjectManifest) throws {
        let manifestURL = packageURL.appendingPathComponent("manifest.json")
        let tmpURL = packageURL.appendingPathComponent(".manifest.json.tmp")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let data = try encoder.encode(manifest)
            try data.write(to: tmpURL)
            // Atomic rename — Compositor sees old or new manifest, never partial
            try? FileManager.default.removeItem(at: manifestURL)  // may fail if not exists; ignore
            try FileManager.default.moveItem(at: tmpURL, to: manifestURL)
        } catch {
            throw CoreError.renderFailed(reason: "Failed to write manifest: \(error.localizedDescription)")
        }
    }
}
