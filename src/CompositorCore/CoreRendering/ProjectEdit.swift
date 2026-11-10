// ProjectEdit.swift — Layer-stack edits and flatten blending for the project command.

import Foundation

public struct ProjectLayerNumbers: Sendable {
    public var opacity: Double
    public var originX: Double
    public var originY: Double
    public var sizeW: Double
    public var sizeH: Double
    public var rotation: Double
    public var flipX: Bool
    public var flipY: Bool
    public var blend: String

    public init(opacity: Double, originX: Double, originY: Double, sizeW: Double, sizeH: Double,
                rotation: Double, flipX: Bool, flipY: Bool, blend: String) {
        self.opacity = opacity
        self.originX = originX
        self.originY = originY
        self.sizeW = sizeW
        self.sizeH = sizeH
        self.rotation = rotation
        self.flipX = flipX
        self.flipY = flipY
        self.blend = blend
    }
}

public enum ProjectEdit {
    public static func blendCode(_ name: String) -> Int? {
        let code = name.withCString { project_blend_code($0) }
        return code >= 0 ? Int(code) : nil
    }

    public static func listJSON(width: Int, height: Int, ids: [String], names: [String], layers: [ProjectLayerNumbers]) throws -> String {
        guard ids.count == layers.count, names.count == layers.count else { throw CoreError.invalidData }
        var states = layers.map { state($0) }
        let idCopies = ids.map { strdup($0) }
        let nameCopies = names.map { strdup($0) }
        defer { idCopies.forEach { free($0) }; nameCopies.forEach { free($0) } }
        var idPtrs: [UnsafePointer<CChar>?] = idCopies.map { UnsafePointer($0) }
        var namePtrs: [UnsafePointer<CChar>?] = nameCopies.map { UnsafePointer($0) }
        var raw: UnsafeMutablePointer<CChar>?
        let rc: Int32 = idPtrs.withUnsafeMutableBufferPointer { ip in
            namePtrs.withUnsafeMutableBufferPointer { np in
                states.withUnsafeMutableBufferPointer { buf in
                    project_list_json(Int32(width), Int32(height), ip.baseAddress, np.baseAddress, buf.baseAddress, Int32(layers.count), &raw)
                }
            }
        }
        defer { project_list_json_free(raw) }
        guard rc == 0, let raw else { throw CoreError.renderFailed(reason: "project_list_json failed") }
        return String(cString: raw)
    }

    public static func flattenOver(
        canvasRGB: inout [UInt8], canvasAlpha: inout [UInt8],
        layerRGB: [UInt8], layerAlpha: [UInt8],
        width: Int, height: Int, opacity: Double, blend: String
    ) throws {
        guard let code = blendCode(blend) else {
            throw CoreError.renderFailed(reason: "Flatten supports Normal, Multiply, and Screen. '\(blend)' is not one of them.")
        }
        let n = width * height
        guard canvasRGB.count == n * 3, canvasAlpha.count == n, layerRGB.count == n * 3, layerAlpha.count == n else {
            throw CoreError.invalidData
        }
        var rc: Int32 = -1
        canvasRGB.withUnsafeMutableBufferPointer { crgb in
            canvasAlpha.withUnsafeMutableBufferPointer { ca in
                layerRGB.withUnsafeBufferPointer { lrgb in
                    layerAlpha.withUnsafeBufferPointer { la in
                        rc = project_flatten_over(crgb.baseAddress, ca.baseAddress, lrgb.baseAddress, la.baseAddress,
                                                  width, height, opacity, Int32(code))
                    }
                }
            }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "flatten failed") }
    }

    public static func setOpacity(_ layers: inout [ProjectLayerNumbers], index: Int, opacity: Double) throws {
        var states = layers.map { state($0) }
        let rc = states.withUnsafeMutableBufferPointer { project_set_opacity($0.baseAddress, Int32(layers.count), Int32(index), opacity) }
        guard rc == 0 else { throw CoreError.invalidData }
        layers[index].opacity = states[index].opacity
    }

    public static func setBlend(_ layers: inout [ProjectLayerNumbers], index: Int, name: String) throws {
        var states = layers.map { state($0) }
        let rc = name.withCString { cname in
            states.withUnsafeMutableBufferPointer { project_set_blend($0.baseAddress, Int32(layers.count), Int32(index), cname) }
        }
        guard rc == 0 else { throw CoreError.renderFailed(reason: "Blend must be Normal, Multiply, or Screen") }
        layers[index].blend = name
    }

    public static func setTransform(
        _ layers: inout [ProjectLayerNumbers], index: Int,
        originX: Double, originY: Double, sizeW: Double, sizeH: Double,
        rotation: Double, flipX: Bool, flipY: Bool
    ) throws {
        var states = layers.map { state($0) }
        let rc = states.withUnsafeMutableBufferPointer {
            project_set_transform($0.baseAddress, Int32(layers.count), Int32(index), originX, originY, sizeW, sizeH, rotation, flipX ? 1 : 0, flipY ? 1 : 0)
        }
        guard rc == 0 else { throw CoreError.invalidData }
        layers[index].originX = originX
        layers[index].originY = originY
        layers[index].sizeW = sizeW
        layers[index].sizeH = sizeH
        layers[index].rotation = rotation
        layers[index].flipX = flipX
        layers[index].flipY = flipY
    }

    public static func remove(_ layers: inout [ProjectLayerNumbers], index: Int) throws {
        var states = layers.map { state($0) }
        var count = Int32(layers.count)
        let rc = states.withUnsafeMutableBufferPointer { project_remove_layer($0.baseAddress, &count, Int32(index)) }
        guard rc == 0 else { throw CoreError.invalidData }
        layers.remove(at: index)
    }

    public static func relativePathOK(_ path: String) -> Bool {
        path.withCString { project_relative_path_ok($0) == 0 }
    }

    private static func state(_ layer: ProjectLayerNumbers) -> ProjectLayerState {
        var s = ProjectLayerState()
        s.opacity = layer.opacity
        s.origin_x = layer.originX
        s.origin_y = layer.originY
        s.size_w = layer.sizeW
        s.size_h = layer.sizeH
        s.rotation = layer.rotation
        s.flip_x = layer.flipX ? 1 : 0
        s.flip_y = layer.flipY ? 1 : 0
        s.blend = Int32(blendCode(layer.blend) ?? 0)
        return s
    }
}

private struct ProjectLayerState {
    var opacity: Double = 0
    var origin_x: Double = 0
    var origin_y: Double = 0
    var size_w: Double = 0
    var size_h: Double = 0
    var rotation: Double = 0
    var flip_x: Int32 = 0
    var flip_y: Int32 = 0
    var blend: Int32 = 0
}

@_silgen_name("project_blend_code")
private func project_blend_code(_ name: UnsafePointer<CChar>?) -> Int32

@_silgen_name("project_list_json")
private func project_list_json(
    _ canvasW: Int32, _ canvasH: Int32,
    _ ids: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
    _ names: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
    _ layers: UnsafePointer<ProjectLayerState>?,
    _ count: Int32,
    _ outJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("project_list_json_free")
private func project_list_json_free(_ json: UnsafeMutablePointer<CChar>?)

@_silgen_name("project_flatten_over")
private func project_flatten_over(
    _ canvasRGB: UnsafeMutablePointer<UInt8>?, _ canvasA: UnsafeMutablePointer<UInt8>?,
    _ layerRGB: UnsafePointer<UInt8>?, _ layerA: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int, _ opacity: Double, _ blend: Int32
) -> Int32

@_silgen_name("project_set_opacity")
private func project_set_opacity(_ layers: UnsafeMutablePointer<ProjectLayerState>?, _ count: Int32, _ index: Int32, _ opacity: Double) -> Int32

@_silgen_name("project_set_blend")
private func project_set_blend(_ layers: UnsafeMutablePointer<ProjectLayerState>?, _ count: Int32, _ index: Int32, _ name: UnsafePointer<CChar>?) -> Int32

@_silgen_name("project_set_transform")
private func project_set_transform(
    _ layers: UnsafeMutablePointer<ProjectLayerState>?, _ count: Int32, _ index: Int32,
    _ originX: Double, _ originY: Double, _ sizeW: Double, _ sizeH: Double,
    _ rotation: Double, _ flipX: Int32, _ flipY: Int32
) -> Int32

@_silgen_name("project_remove_layer")
private func project_remove_layer(_ layers: UnsafeMutablePointer<ProjectLayerState>?, _ count: UnsafeMutablePointer<Int32>?, _ index: Int32) -> Int32

@_silgen_name("project_relative_path_ok")
private func project_relative_path_ok(_ path: UnsafePointer<CChar>?) -> Int32
