// ProjectCommand.swift — list, add, remove, edit, and flatten .comp projects.
// Numeric checks and the flatten blend live in ProjectEdit.c.

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore

struct ProjectCommandRunner {
    static func list(project: URL) -> CommandResult {
        do {
            let manifest = try ManifestIO.read(from: project)
            let numbers = try numbers(manifest)
            let json = try ProjectEdit.listJSON(
                width: manifest.width, height: manifest.height,
                ids: manifest.layers.map { $0.id.uuidString },
                names: manifest.layers.map(\.name),
                layers: numbers
            )
            print(json)
            return CommandResult.makeSuccess(output: project.path, timing: nil)
        } catch {
            return failure(error)
        }
    }

    static func add(project: URL, image: URL, name: String, opacity: Double, blend: String,
                    origin: String?, size: String?, rotation: Double) -> CommandResult {
        guard ProjectEdit.relativePathOK(image.lastPathComponent) else {
            return CommandResult.makeError(.renderFailed, detail: "Image file name '\(image.lastPathComponent)' is not a safe relative path", timing: nil)
        }
        guard FileManager.default.fileExists(atPath: image.path) else {
            return CommandResult.makeError(.fileNotFound, detail: "Image file not found: \(image.path)", timing: nil)
        }
        do {
            var manifest = try ManifestIO.read(from: project)
            guard let source = CGImageSourceCreateWithURL(image as CFURL, nil),
                  let cg = CGImageSourceCreateImageAtIndex(source, 0, nil), cg.width > 0, cg.height > 0 else {
                return CommandResult.makeError(.invalidImageFormat, detail: "Cannot decode \(image.path)", timing: nil)
            }
            let originPair = try pair(origin, fallback: (0, 0), name: "--origin")
            let sizePair = try pair(size, fallback: (Double(cg.width), Double(cg.height)), name: "--size")
            var layers = try numbers(manifest)
            let index = layers.count
            layers.append(ProjectLayerNumbers(
                opacity: 1, originX: originPair.0, originY: originPair.1,
                sizeW: sizePair.0, sizeH: sizePair.1, rotation: rotation,
                flipX: false, flipY: false, blend: "Normal"
            ))
            try ProjectEdit.setOpacity(&layers, index: index, opacity: opacity)
            try ProjectEdit.setBlend(&layers, index: index, name: blend)
            let id = UUID()
            let filename = "\(id.uuidString.uppercased()).png"
            let layersDir = project.appendingPathComponent("layers")
            try FileManager.default.createDirectory(at: layersDir, withIntermediateDirectories: true)
            let destination = layersDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: image, to: destination)
            let added = layers[index]
            manifest.layers.append(ProjectManifest.LayerRecord(
                id: id, name: name.isEmpty ? "Layer" : name, imageFile: filename,
                opacity: added.opacity, blendMode: try blendMode(added.blend), transform: transform(added)
            ))
            if let error = manifest.validate() {
                try? FileManager.default.removeItem(at: destination)
                return CommandResult.makeError(.renderFailed, detail: error, timing: nil)
            }
            try ManifestIO.write(to: project, manifest: manifest)
            print("Added layer \(manifest.layers.count - 1) \(filename)")
            return CommandResult.makeSuccess(output: destination.path, timing: nil)
        } catch {
            return failure(error)
        }
    }

    static func remove(project: URL, layer token: String) -> CommandResult {
        do {
            var manifest = try ManifestIO.read(from: project)
            guard let index = find(manifest, token) else {
                return CommandResult.makeError(.renderFailed, detail: "No layer matches '\(token)'", timing: nil)
            }
            var layers = try numbers(manifest)
            try ProjectEdit.remove(&layers, index: index)
            manifest.layers.remove(at: index)
            if manifest.layers.isEmpty == false && manifest.layers.contains(where: { $0.id == manifest.activeLayerID }) == false {
                manifest.activeLayerID = manifest.layers[0].id
            }
            try ManifestIO.write(to: project, manifest: manifest)
            print("Removed layer \(index)")
            return CommandResult.makeSuccess(output: project.path, timing: nil)
        } catch {
            return failure(error)
        }
    }

    static func set(project: URL, layer token: String, opacity: Double?, blend: String?,
                    origin: String?, size: String?, rotation: Double?, flipX: Bool?, flipY: Bool?) -> CommandResult {
        do {
            var manifest = try ManifestIO.read(from: project)
            guard let index = find(manifest, token) else {
                return CommandResult.makeError(.renderFailed, detail: "No layer matches '\(token)'", timing: nil)
            }
            var layers = try numbers(manifest)
            if let opacity { try ProjectEdit.setOpacity(&layers, index: index, opacity: opacity) }
            if let blend { try ProjectEdit.setBlend(&layers, index: index, name: blend) }
            if origin != nil || size != nil || rotation != nil || flipX != nil || flipY != nil {
                let current = layers[index]
                let originPair = try pair(origin, fallback: (current.originX, current.originY), name: "--origin")
                let sizePair = try pair(size, fallback: (current.sizeW, current.sizeH), name: "--size")
                try ProjectEdit.setTransform(
                    &layers, index: index,
                    originX: originPair.0, originY: originPair.1,
                    sizeW: sizePair.0, sizeH: sizePair.1,
                    rotation: rotation ?? current.rotation,
                    flipX: flipX ?? current.flipX, flipY: flipY ?? current.flipY
                )
            }
            let edited = layers[index]
            manifest.layers[index].opacity = edited.opacity
            manifest.layers[index].blendMode = try blendMode(edited.blend)
            manifest.layers[index].transform = transform(edited)
            try ManifestIO.write(to: project, manifest: manifest)
            print("Updated layer \(index)")
            return CommandResult.makeSuccess(output: project.path, timing: nil)
        } catch {
            return failure(error)
        }
    }

    static func flatten(project: URL, output: URL) -> CommandResult {
        do {
            let manifest = try ManifestIO.read(from: project)
            let width = manifest.width
            let height = manifest.height
            var canvasRGB = [UInt8](repeating: 0, count: width * height * 3)
            var canvasA = [UInt8](repeating: 0, count: width * height)
            for (index, layer) in manifest.layers.enumerated() {
                guard let imageFile = layer.imageFile else {
                    return CommandResult.makeError(.renderFailed, detail: "Layer \(index) has no image and cannot be flattened", timing: nil)
                }
                if !ProjectEdit.relativePathOK(imageFile) {
                    return CommandResult.makeError(.renderFailed, detail: "Layer \(index) image path is not safe: \(imageFile)", timing: nil)
                }
                let url = project.appendingPathComponent("layers").appendingPathComponent(imageFile)
                guard FileManager.default.fileExists(atPath: url.path),
                      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    return CommandResult.makeError(.fileNotFound, detail: "Missing layer image \(url.path)", timing: nil)
                }
                let rgb = try straightRGB(cg)
                let alpha = try layerAlpha(cg)
                let placed = try LayerPlacement.place(
                    foregroundRGB: rgb, foregroundAlpha: alpha,
                    foregroundWidth: cg.width, foregroundHeight: cg.height,
                    backgroundWidth: width, backgroundHeight: height,
                    originX: layer.transform.origin[0], originY: layer.transform.origin[1],
                    sizeWidth: layer.transform.size[0], sizeHeight: layer.transform.size[1],
                    rotationDegrees: layer.transform.rotation,
                    flipX: layer.transform.flipX, flipY: layer.transform.flipY,
                    sampling: layer.transform.sampling
                )
                try ProjectEdit.flattenOver(
                    canvasRGB: &canvasRGB, canvasAlpha: &canvasA,
                    layerRGB: placed.rgb, layerAlpha: placed.alpha,
                    width: width, height: height, opacity: layer.opacity, blend: layer.blendMode.rawValue
                )
            }
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            for i in 0..<(width * height) {
                rgba[i * 4] = canvasRGB[i * 3]
                rgba[i * 4 + 1] = canvasRGB[i * 3 + 1]
                rgba[i * 4 + 2] = canvasRGB[i * 3 + 2]
                rgba[i * 4 + 3] = canvasA[i]
            }
            try ImageExporter.writeStraightRGBAPNG(rgba, width: width, height: height, to: output)
            print("Flattened project written to \(output.path)")
            return CommandResult.makeSuccess(output: output.path, timing: nil)
        } catch {
            return failure(error)
        }
    }

    private static func numbers(_ manifest: ProjectManifest) throws -> [ProjectLayerNumbers] {
        try manifest.layers.map { layer in
            guard layer.transform.origin.count == 2, layer.transform.size.count == 2 else {
                throw CoreError.invalidData
            }
            return ProjectLayerNumbers(
                opacity: layer.opacity,
                originX: layer.transform.origin[0], originY: layer.transform.origin[1],
                sizeW: layer.transform.size[0], sizeH: layer.transform.size[1],
                rotation: layer.transform.rotation, flipX: layer.transform.flipX, flipY: layer.transform.flipY,
                blend: layer.blendMode.rawValue
            )
        }
    }

    private static func transform(_ layer: ProjectLayerNumbers) -> ProjectManifest.Transform {
        ProjectManifest.Transform(
            origin: [layer.originX, layer.originY], size: [layer.sizeW, layer.sizeH],
            rotation: layer.rotation, flipX: layer.flipX, flipY: layer.flipY, sampling: "Nearest"
        )
    }

    private static func blendMode(_ name: String) throws -> ProjectManifest.BlendMode {
        guard let mode = ProjectManifest.BlendMode(rawValue: name) else {
            throw CoreError.renderFailed(reason: "Unknown blend '\(name)'")
        }
        return mode
    }

    private static func find(_ manifest: ProjectManifest, _ token: String) -> Int? {
        if let index = Int(token), index >= 0, index < manifest.layers.count { return index }
        if let id = UUID(uuidString: token) { return manifest.layers.firstIndex { $0.id == id } }
        return manifest.layers.firstIndex { $0.name == token }
    }

    private static func pair(_ text: String?, fallback: (Double, Double), name: String) throws -> (Double, Double) {
        guard let text, !text.isEmpty else { return fallback }
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let a = Double(parts[0]), let b = Double(parts[1]), a.isFinite, b.isFinite else {
            throw CoreError.renderFailed(reason: "\(name) must be 'a,b'")
        }
        return (a, b)
    }

    private static func layerAlpha(_ image: CGImage) throws -> [UInt8] {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &rgba, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw CoreError.renderFailed(reason: "Cannot read layer alpha") }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (0..<(w * h)).map { rgba[$0 * 4 + 3] }
    }

    private static func report(_ result: CommandResult) {
        if result.status != "success" {
            print(String(data: result.toJSON(), encoding: .utf8)!)
        }
    }

    private static func failure(_ error: Error) -> CommandResult {
        if let core = error as? CoreError {
            let kind: CommandErrorType
            switch core.cliErrorType {
            case "fileNotFound": kind = .fileNotFound
            case "invalidImageFormat": kind = .invalidImageFormat
            case "modelMissing": kind = .modelMissing
            default: kind = .renderFailed
            }
            return CommandResult.makeError(kind, detail: core.errorDescription ?? "project failed", hint: core.cliHint, timing: nil)
        }
        return CommandResult.makeError(.renderFailed, detail: error.localizedDescription, timing: nil)
    }
}

struct ProjectCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project",
        abstract: "List, edit, and flatten a .comp project.",
        subcommands: [ListProject.self, AddProjectLayer.self, RemoveProjectLayer.self, SetProjectLayer.self, FlattenProject.self]
    )
}

struct ListProject: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "list", abstract: "Print project layers as JSON.")
    @Option(name: .customLong("project"), help: "Path to the .comp folder")
    var project: String = ""
    func run() throws { ProjectCommandRunner.report(ProjectCommandRunner.list(project: URL(fileURLWithPath: project))) }
}

struct AddProjectLayer: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "add", abstract: "Copy an image in as a new layer.")
    @Option(name: .customLong("project"), help: "Path to the .comp folder")
    var project: String = ""
    @Option(help: "Image to copy into layers/")
    var image: String = ""
    @Option(help: "Layer name")
    var name: String = "Layer"
    @Option(help: "Opacity in [0, 1]")
    var opacity: Double = 1
    @Option(help: "Normal, Multiply, or Screen")
    var blend: String = "Normal"
    @Option(name: .customLong("origin"), help: "x,y")
    var origin: String?
    @Option(name: .customLong("size"), help: "width,height")
    var placedSize: String?
    @Option(help: "Clockwise degrees")
    var rotation: Double = 0
    func run() throws {
        ProjectCommandRunner.report(ProjectCommandRunner.add(
            project: URL(fileURLWithPath: project), image: URL(fileURLWithPath: image),
            name: name, opacity: opacity, blend: blend, origin: origin, size: placedSize, rotation: rotation
        ))
    }
}

struct RemoveProjectLayer: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "remove", abstract: "Remove a layer by index, id, or name.")
    @Option(name: .customLong("project"), help: "Path to the .comp folder")
    var project: String = ""
    @Option(help: "Layer index, UUID, or name")
    var layer: String = ""
    func run() throws {
        ProjectCommandRunner.report(ProjectCommandRunner.remove(project: URL(fileURLWithPath: project), layer: layer))
    }
}

struct SetProjectLayer: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "set", abstract: "Change opacity, blend, or transform.")
    @Option(name: .customLong("project"), help: "Path to the .comp folder")
    var project: String = ""
    @Option(help: "Layer index, UUID, or name")
    var layer: String = ""
    @Option(help: "Opacity in [0, 1]")
    var opacity: Double?
    @Option(help: "Normal, Multiply, or Screen")
    var blend: String?
    @Option(name: .customLong("origin"), help: "x,y")
    var origin: String?
    @Option(name: .customLong("size"), help: "width,height")
    var placedSize: String?
    @Option(help: "Clockwise degrees")
    var rotation: Double?
    @Flag(name: .customLong("flip-x"))
    var flipX: Bool = false
    @Flag(name: .customLong("flip-y"))
    var flipY: Bool = false
    func run() throws {
        ProjectCommandRunner.report(ProjectCommandRunner.set(
            project: URL(fileURLWithPath: project), layer: layer, opacity: opacity, blend: blend,
            origin: origin, size: placedSize, rotation: rotation,
            flipX: flipX ? true : nil, flipY: flipY ? true : nil
        ))
    }
}

struct FlattenProject: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "flatten", abstract: "Composite the layer stack to a PNG.")
    @Option(name: .customLong("project"), help: "Path to the .comp folder")
    var project: String = ""
    @Option(help: "Output PNG")
    var output: String = ""
    func run() throws {
        ProjectCommandRunner.report(ProjectCommandRunner.flatten(project: URL(fileURLWithPath: project), output: URL(fileURLWithPath: output)))
    }
}
