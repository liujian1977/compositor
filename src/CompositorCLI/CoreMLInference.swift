// CoreMLInference.swift — SAM2 and LaMa prediction.
//
// Assumed Core ML contracts (not verified against real weights in this environment):
//
// sam2-lightweight.mlpackage
//   image:         float32 NCHW 1x3xSxS, RGB in [0, 1], S from the input constraint or 1024
//   point_coords:  float32 1xNx2 in that canvas
//   point_labels:  float32 1xN   (1 = point, 2/3 = box corners)
//   masks | mask:  float32, last two dims are HxW logits or probabilities
//
// lama-fast.mlpackage
//   image:         float32 NCHW 1x3xSxS, RGB in [0, 1]
//   mask:          float32 NCHW 1x1xSxS, 1 = fill
//   output | inpainted: float32 NCHW 1x3xSxS in [0, 1]
//
// A missing package is modelMissing. Safetensors without a package are inferenceFailed.
// A package whose inputs do not match is inferenceFailed. There is no silent fallback.

import Foundation
import CoreGraphics
import ImageIO
import CompositorCore
#if canImport(CoreML)
@preconcurrency import CoreML
#endif

enum CoreMLSegmentation {
    static func mask(image: CGImage, point: (Double, Double)?, box: (Double, Double, Double, Double)?) throws -> [UInt8] {
        let identifier = try requirePackage(key: "sam2-lightweight", weights: .sam2Lightweight)
        #if canImport(CoreML)
        let model = try ModelLoader.loadModel(for: identifier)
        let names = Set(model.modelDescription.inputDescriptionsByName.keys)
        for required in ["image", "point_coords", "point_labels"] where !names.contains(required) {
            throw CoreError.inferenceFailed(
                reason: "SAM2 model is missing input '\(required)'. Inputs: \(names.sorted().joined(separator: ", ")). Expected image, point_coords, point_labels."
            )
        }
        let side = spatialSize(model, input: "image", fallback: 1024)
        let rgb = try straightRGB(image)
        let letter = try ModelPrep.letterboxRGB(rgb, width: image.width, height: image.height, dstWidth: side, dstHeight: side)
        let prompts = try ModelPrep.encodePrompts(plan: letter.plan, point: point, box: box)
        let imageTensor = try nchwArray(ModelPrep.normalizeUnitNCHW(letter.rgb, width: side, height: side), shape: [1, 3, side, side])
        let coordTensor = try floatArray(prompts.coords, shape: [1, prompts.labels.count, 2])
        let labelTensor = try floatArray(prompts.labels, shape: [1, prompts.labels.count])
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "image": MLFeatureValue(multiArray: imageTensor),
            "point_coords": MLFeatureValue(multiArray: coordTensor),
            "point_labels": MLFeatureValue(multiArray: labelTensor)
        ])
        let prediction: MLFeatureProvider
        do {
            prediction = try model.prediction(from: provider)
        } catch {
            throw CoreError.inferenceFailed(reason: "SAM2 prediction failed: \(error.localizedDescription)")
        }
        guard let maskValue = prediction.featureValue(for: "masks") ?? prediction.featureValue(for: "mask"),
              let maskArray = maskValue.multiArrayValue else {
            let outputs = prediction.featureNames.sorted().joined(separator: ", ")
            throw CoreError.inferenceFailed(reason: "SAM2 model did not produce 'masks' or 'mask'. Outputs: \(outputs)")
        }
        let plane = copyLastPlane(maskArray)
        let binary = try ModelPrep.thresholdMask(plane.values, width: plane.width, height: plane.height, threshold: 0)
        let canvas: [UInt8]
        if plane.width == side && plane.height == side {
            canvas = binary
        } else {
            canvas = try ModelPrep.upsampleNearest(binary, width: plane.width, height: plane.height, dstWidth: side, dstHeight: side)
        }
        return try ModelPrep.unletterbox(canvas, plan: letter.plan, outWidth: image.width, outHeight: image.height)
        #else
        _ = identifier
        throw CoreError.inferenceFailed(reason: "Core ML is not available, so SAM2 cannot run. Not falling back to the vision heuristic.")
        #endif
    }
}

enum CoreMLInpaint {
    static func fill(rgb: [UInt8], mask: [UInt8], width: Int, height: Int, preset: String) throws -> [UInt8] {
        let identifier = try requirePackage(key: "lama-fast", weights: .lamaFast)
        #if canImport(CoreML)
        let model = try ModelLoader.loadModel(for: identifier)
        let names = Set(model.modelDescription.inputDescriptionsByName.keys)
        for required in ["image", "mask"] where !names.contains(required) {
            throw CoreError.inferenceFailed(
                reason: "LaMa model is missing input '\(required)'. Inputs: \(names.sorted().joined(separator: ", ")). Expected image and mask."
            )
        }
        let presetParams = try ModelPrep.lamaPreset(preset)
        let side = spatialSize(model, input: "image", fallback: presetParams.tile)
        let tiles = try ModelPrep.lamaTiles(width: width, height: height, tile: side, overlap: presetParams.overlap)
        var painted: [(plan: LamaTilePlan, rgb: [UInt8])] = []
        for tile in tiles {
            let extracted = try ModelPrep.extractTile(rgb: rgb, mask: mask, width: width, height: height, tile: tile, tileSize: side)
            let imageTensor = try nchwArray(ModelPrep.normalizeUnitNCHW(extracted.rgb, width: side, height: side), shape: [1, 3, side, side])
            let maskFloat = extracted.mask.map { Float($0) / 255.0 }
            let maskTensor = try floatArray(maskFloat, shape: [1, 1, side, side])
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "image": MLFeatureValue(multiArray: imageTensor),
                "mask": MLFeatureValue(multiArray: maskTensor)
            ])
            let prediction: MLFeatureProvider
            do {
                prediction = try model.prediction(from: provider)
            } catch {
                throw CoreError.inferenceFailed(reason: "LaMa prediction failed: \(error.localizedDescription)")
            }
            guard let value = prediction.featureValue(for: "output") ?? prediction.featureValue(for: "inpainted"),
                  let array = value.multiArrayValue else {
                let outputs = prediction.featureNames.sorted().joined(separator: ", ")
                throw CoreError.inferenceFailed(reason: "LaMa model did not produce 'output' or 'inpainted'. Outputs: \(outputs)")
            }
            painted.append((tile, rgbFromUnitNCHW(array, side: side)))
        }
        return try ModelPrep.blendTiles(width: width, height: height, tiles: painted, tileSize: side)
        #else
        _ = (identifier, preset)
        throw CoreError.inferenceFailed(reason: "Core ML is not available, so LaMa cannot run. Not falling back to patch-based inpainting.")
        #endif
    }
}

private func requirePackage(key: String, weights: KnownModelKey) throws -> ModelIdentifier {
    let identifier = ModelIdentifier(key: key)
    if ModelLoader.isModelAvailable(for: identifier) { return identifier }
    let downloaded = modelPath(for: weights)
    if FileManager.default.fileExists(atPath: downloaded.path) {
        throw CoreError.inferenceFailed(
            reason: "\(key) weights exist at \(downloaded.path), but this build only runs a Core ML .mlpackage named \(key).mlpackage in Application Support/Compositor/models-ml. Refusing to report a different algorithm as success."
        )
    }
    throw CoreError.modelMissing(key: key)
}

#if canImport(CoreML)
private func spatialSize(_ model: MLModel, input name: String, fallback: Int) -> Int {
    guard let desc = model.modelDescription.inputDescriptionsByName[name],
          let shape = desc.multiArrayConstraint?.shape.map({ $0.intValue }),
          let last = shape.last, last > 1 else {
        return fallback
    }
    return last
}

private func nchwArray(_ floats: [Float], shape: [Int]) throws -> MLMultiArray {
    try floatArray(floats, shape: shape)
}

private func floatArray(_ floats: [Float], shape: [Int]) throws -> MLMultiArray {
    let count = shape.reduce(1, *)
    guard count == floats.count else {
        throw CoreError.inferenceFailed(reason: "Tensor length \(floats.count) does not match shape \(shape)")
    }
    let array = try MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: .float32)
    for i in 0..<floats.count {
        array[i] = NSNumber(value: floats[i])
    }
    return array
}

private func copyLastPlane(_ array: MLMultiArray) -> (values: [Float], width: Int, height: Int) {
    let shape = array.shape.map { $0.intValue }
    let height = shape.count >= 2 ? shape[shape.count - 2] : 1
    let width = shape.last ?? 1
    var values = [Float](repeating: 0, count: width * height)
    var index = [NSNumber](repeating: 0, count: shape.count)
    for y in 0..<height {
        if shape.count >= 2 { index[shape.count - 2] = NSNumber(value: y) }
        for x in 0..<width {
            index[shape.count - 1] = NSNumber(value: x)
            values[y * width + x] = array[index].floatValue
        }
    }
    return (values, width, height)
}

private func rgbFromUnitNCHW(_ array: MLMultiArray, side: Int) -> [UInt8] {
    let shape = array.shape.map { $0.intValue }
    var rgb = [UInt8](repeating: 0, count: side * side * 3)
    guard shape.count >= 3, shape[shape.count - 1] == side, shape[shape.count - 2] == side, shape[shape.count - 3] >= 3 else {
        let plane = copyLastPlane(array)
        for i in 0..<min(side * side, plane.values.count) {
            let value = byte(plane.values[i])
            rgb[i * 3] = value
            rgb[i * 3 + 1] = value
            rgb[i * 3 + 2] = value
        }
        return rgb
    }
    var index = [NSNumber](repeating: 0, count: shape.count)
    let channelAxis = shape.count - 3
    for channel in 0..<3 {
        index[channelAxis] = NSNumber(value: channel)
        for y in 0..<side {
            index[shape.count - 2] = NSNumber(value: y)
            for x in 0..<side {
                index[shape.count - 1] = NSNumber(value: x)
                rgb[(y * side + x) * 3 + channel] = byte(array[index].floatValue)
            }
        }
    }
    return rgb
}

private func byte(_ value: Float) -> UInt8 {
    let scaled = value <= 1.0 ? value * 255.0 : value
    if scaled <= 0 { return 0 }
    if scaled >= 255 { return 255 }
    return UInt8(scaled + 0.5)
}
#endif

func straightRGB(_ image: CGImage) throws -> [UInt8] {
    let w = image.width, h = image.height
    var rgba = [UInt8](repeating: 0, count: w * h * 4)
    guard let ctx = CGContext(
        data: &rgba, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw CoreError.renderFailed(reason: "Cannot read RGB")
    }
    ctx.interpolationQuality = .none
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var rgb = [UInt8](repeating: 0, count: w * h * 3)
    for i in 0..<(w * h) {
        rgb[i * 3] = rgba[i * 4]
        rgb[i * 3 + 1] = rgba[i * 4 + 1]
        rgb[i * 3 + 2] = rgba[i * 4 + 2]
    }
    return rgb
}

func straightGray(_ image: CGImage) throws -> [UInt8] {
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w * h)
    guard let ctx = CGContext(
        data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else {
        throw CoreError.renderFailed(reason: "Cannot read mask")
    }
    ctx.interpolationQuality = .none
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    return pixels
}
