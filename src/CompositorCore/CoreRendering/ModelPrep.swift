// ModelPrep.swift — Swift access to the C prep used by SAM2 and LaMa.
// Prediction itself stays in the CLI, behind Core ML.

import Foundation

struct Letterbox {
    var src_w: Int32 = 0
    var src_h: Int32 = 0
    var dst_w: Int32 = 0
    var dst_h: Int32 = 0
    var pad_x: Int32 = 0
    var pad_y: Int32 = 0
    var content_w: Int32 = 0
    var content_h: Int32 = 0
    var scale: Double = 0
}

struct LamaTile {
    var x: Int32 = 0
    var y: Int32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var pad_right: Int32 = 0
    var pad_bottom: Int32 = 0
}

public struct LetterboxPlan: Sendable {
    public var srcWidth: Int
    public var srcHeight: Int
    public var dstWidth: Int
    public var dstHeight: Int
    public var padX: Int
    public var padY: Int
    public var contentWidth: Int
    public var contentHeight: Int
    public var scale: Double
}

public struct LamaTilePlan: Sendable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int
    public var padRight: Int
    public var padBottom: Int
}

public enum ModelPrep {
    public static func letterboxRGB(_ rgb: [UInt8], width: Int, height: Int, dstWidth: Int, dstHeight: Int) throws -> (rgb: [UInt8], plan: LetterboxPlan) {
        var dst = [UInt8](repeating: 0, count: dstWidth * dstHeight * 3)
        var box = Letterbox()
        var rc: Int32 = -1
        rgb.withUnsafeBufferPointer { src in
            dst.withUnsafeMutableBufferPointer { out in
                rc = model_letterbox_rgb(src.baseAddress, width, height, dstWidth, dstHeight, 0, 0, 0, out.baseAddress, &box)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return (dst, plan(box))
    }

    public static func letterboxGray(_ pixels: [UInt8], width: Int, height: Int, dstWidth: Int, dstHeight: Int) throws -> [UInt8] {
        var dst = [UInt8](repeating: 0, count: dstWidth * dstHeight)
        var rc: Int32 = -1
        pixels.withUnsafeBufferPointer { src in
            dst.withUnsafeMutableBufferPointer { out in
                rc = model_letterbox_gray(src.baseAddress, width, height, dstWidth, dstHeight, 0, out.baseAddress, nil)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return dst
    }

    public static func normalizeUnitNCHW(_ rgb: [UInt8], width: Int, height: Int) throws -> [Float] {
        var out = [Float](repeating: 0, count: width * height * 3)
        var rc: Int32 = -1
        rgb.withUnsafeBufferPointer { src in
            out.withUnsafeMutableBufferPointer { dst in
                rc = model_normalize_nchw(src.baseAddress, width, height, 0, dst.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return out
    }

    /// coords is N*2, labels is N. An empty prompt becomes a full-image box.
    public static func encodePrompts(
        plan: LetterboxPlan, point: (Double, Double)?, box: (Double, Double, Double, Double)?
    ) throws -> (coords: [Float], labels: [Float], usedDefaultBox: Bool) {
        var cbox = cLetterbox(plan)
        var points: [Double] = []
        if let point { points = [point.0, point.1] }
        var boxes: [Double] = []
        if let box { boxes = [box.0, box.1, box.2, box.3] }
        var coords = [Float](repeating: 0, count: 8)
        var labels = [Float](repeating: 0, count: 4)
        var count: Int32 = 0
        var used: Int32 = 0
        var rc: Int32 = -1
        points.withUnsafeBufferPointer { pp in
            boxes.withUnsafeBufferPointer { bp in
                coords.withUnsafeMutableBufferPointer { cp in
                    labels.withUnsafeMutableBufferPointer { lp in
                        rc = sam_encode_prompts(
                            &cbox,
                            points.isEmpty ? nil : pp.baseAddress, Int32(points.count / 2),
                            boxes.isEmpty ? nil : bp.baseAddress, Int32(boxes.count / 4),
                            cp.baseAddress, lp.baseAddress, 4, &count, &used
                        )
                    }
                }
            }
        }
        guard rc == 0, count > 0 else { throw CoreError.invalidData }
        return (Array(coords.prefix(Int(count) * 2)), Array(labels.prefix(Int(count))), used != 0)
    }

    public static func thresholdMask(_ values: [Float], width: Int, height: Int, threshold: Float) throws -> [UInt8] {
        var dst = [UInt8](repeating: 0, count: width * height)
        var rc: Int32 = -1
        values.withUnsafeBufferPointer { src in
            dst.withUnsafeMutableBufferPointer { out in
                rc = model_mask_threshold(src.baseAddress, width, height, threshold, out.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return dst
    }

    public static func upsampleNearest(_ src: [UInt8], width: Int, height: Int, dstWidth: Int, dstHeight: Int) throws -> [UInt8] {
        var dst = [UInt8](repeating: 0, count: dstWidth * dstHeight)
        var rc: Int32 = -1
        src.withUnsafeBufferPointer { s in
            dst.withUnsafeMutableBufferPointer { d in
                rc = model_upsample_nearest(s.baseAddress, width, height, dstWidth, dstHeight, d.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return dst
    }

    public static func unletterbox(_ mask: [UInt8], plan: LetterboxPlan, outWidth: Int, outHeight: Int) throws -> [UInt8] {
        var box = cLetterbox(plan)
        var dst = [UInt8](repeating: 0, count: outWidth * outHeight)
        var rc: Int32 = -1
        mask.withUnsafeBufferPointer { src in
            dst.withUnsafeMutableBufferPointer { out in
                rc = model_mask_unletterbox(src.baseAddress, plan.dstWidth, plan.dstHeight, &box, outWidth, outHeight, out.baseAddress)
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return dst
    }

    public static func lamaPreset(_ name: String) throws -> (tile: Int, overlap: Int) {
        var tile: Int32 = 0
        var overlap: Int32 = 0
        let rc = name.withCString { lama_preset_params($0, &tile, &overlap) }
        guard rc == 0 else { throw CoreError.invalidData }
        return (Int(tile), Int(overlap))
    }

    public static func lamaTiles(width: Int, height: Int, tile: Int, overlap: Int) throws -> [LamaTilePlan] {
        var needed: Int32 = 0
        var storage = [LamaTile](repeating: LamaTile(), count: 64)
        var rc: Int32 = -1
        storage.withUnsafeMutableBufferPointer { buf in
            rc = lama_plan_tiles(Int32(width), Int32(height), Int32(tile), Int32(overlap), buf.baseAddress, Int32(buf.count), &needed)
        }
        guard rc == 0, needed >= 0, needed <= 64 else { throw CoreError.invalidData }
        return storage.prefix(Int(needed)).map {
            LamaTilePlan(x: Int($0.x), y: Int($0.y), width: Int($0.width), height: Int($0.height),
                         padRight: Int($0.pad_right), padBottom: Int($0.pad_bottom))
        }
    }

    public static func extractTile(
        rgb: [UInt8], mask: [UInt8], width: Int, height: Int, tile: LamaTilePlan, tileSize: Int
    ) throws -> (rgb: [UInt8], mask: [UInt8]) {
        var ctile = LamaTile(x: Int32(tile.x), y: Int32(tile.y), width: Int32(tile.width), height: Int32(tile.height),
                             pad_right: Int32(tile.padRight), pad_bottom: Int32(tile.padBottom))
        var tileRGB = [UInt8](repeating: 0, count: tileSize * tileSize * 3)
        var tileMask = [UInt8](repeating: 0, count: tileSize * tileSize)
        var rc: Int32 = -1
        rgb.withUnsafeBufferPointer { r in
            mask.withUnsafeBufferPointer { m in
                tileRGB.withUnsafeMutableBufferPointer { tr in
                    tileMask.withUnsafeMutableBufferPointer { tm in
                        rc = lama_extract_tile(r.baseAddress, m.baseAddress, Int32(width), Int32(height), &ctile, Int32(tileSize), tr.baseAddress, tm.baseAddress)
                    }
                }
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return (tileRGB, tileMask)
    }

    public static func blendTiles(width: Int, height: Int, tiles: [(plan: LamaTilePlan, rgb: [UInt8])], tileSize: Int) throws -> [UInt8] {
        let n = width * height
        var acc = [Float](repeating: 0, count: n * 3)
        var weight = [Float](repeating: 0, count: n)
        var rc = lama_blend_begin(&acc, &weight, Int32(n))
        guard rc == 0 else { throw CoreError.invalidData }
        for item in tiles {
            var ctile = LamaTile(x: Int32(item.plan.x), y: Int32(item.plan.y), width: Int32(item.plan.width), height: Int32(item.plan.height),
                                 pad_right: Int32(item.plan.padRight), pad_bottom: Int32(item.plan.padBottom))
            rc = item.rgb.withUnsafeBufferPointer { ptr in
                acc.withUnsafeMutableBufferPointer { a in
                    weight.withUnsafeMutableBufferPointer { w in
                        lama_blend_add(a.baseAddress, w.baseAddress, Int32(width), Int32(height), &ctile, ptr.baseAddress, Int32(tileSize))
                    }
                }
            }
            guard rc == 0 else { throw CoreError.invalidData }
        }
        var out = [UInt8](repeating: 0, count: n * 3)
        rc = acc.withUnsafeBufferPointer { a in
            weight.withUnsafeBufferPointer { w in
                out.withUnsafeMutableBufferPointer { o in
                    lama_blend_finish(a.baseAddress, w.baseAddress, Int32(n), o.baseAddress)
                }
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return out
    }

    public static func httpPayloadOK(status: Int, nbytes: Int64, head: [UInt8]) -> Int32 {
        head.withUnsafeBufferPointer { ptr in
            model_http_payload_ok(Int32(status), nbytes, ptr.baseAddress, ptr.count)
        }
    }

    private static func plan(_ box: Letterbox) -> LetterboxPlan {
        LetterboxPlan(srcWidth: Int(box.src_w), srcHeight: Int(box.src_h), dstWidth: Int(box.dst_w), dstHeight: Int(box.dst_h),
                      padX: Int(box.pad_x), padY: Int(box.pad_y), contentWidth: Int(box.content_w), contentHeight: Int(box.content_h),
                      scale: box.scale)
    }

    private static func cLetterbox(_ plan: LetterboxPlan) -> Letterbox {
        var box = Letterbox()
        box.src_w = Int32(plan.srcWidth)
        box.src_h = Int32(plan.srcHeight)
        box.dst_w = Int32(plan.dstWidth)
        box.dst_h = Int32(plan.dstHeight)
        box.pad_x = Int32(plan.padX)
        box.pad_y = Int32(plan.padY)
        box.content_w = Int32(plan.contentWidth)
        box.content_h = Int32(plan.contentHeight)
        box.scale = plan.scale
        return box
    }
}

@_silgen_name("model_letterbox_rgb")
private func model_letterbox_rgb(
    _ src: UnsafePointer<UInt8>?, _ srcW: Int, _ srcH: Int, _ dstW: Int, _ dstH: Int,
    _ padR: UInt8, _ padG: UInt8, _ padB: UInt8,
    _ dst: UnsafeMutablePointer<UInt8>?, _ plan: UnsafeMutablePointer<Letterbox>?
) -> Int32

@_silgen_name("model_letterbox_gray")
private func model_letterbox_gray(
    _ src: UnsafePointer<UInt8>?, _ srcW: Int, _ srcH: Int, _ dstW: Int, _ dstH: Int,
    _ pad: UInt8, _ dst: UnsafeMutablePointer<UInt8>?, _ plan: UnsafeMutablePointer<Letterbox>?
) -> Int32

@_silgen_name("model_normalize_nchw")
private func model_normalize_nchw(
    _ rgb: UnsafePointer<UInt8>?, _ width: Int, _ height: Int, _ mode: Int32, _ out: UnsafeMutablePointer<Float>?
) -> Int32

@_silgen_name("sam_encode_prompts")
private func sam_encode_prompts(
    _ box: UnsafePointer<Letterbox>?,
    _ points: UnsafePointer<Double>?, _ pointCount: Int32,
    _ boxes: UnsafePointer<Double>?, _ boxCount: Int32,
    _ coords: UnsafeMutablePointer<Float>?, _ labels: UnsafeMutablePointer<Float>?,
    _ cap: Int32, _ outCount: UnsafeMutablePointer<Int32>?, _ usedDefault: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("model_mask_threshold")
private func model_mask_threshold(
    _ src: UnsafePointer<Float>?, _ width: Int, _ height: Int, _ threshold: Float, _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("model_upsample_nearest")
private func model_upsample_nearest(
    _ src: UnsafePointer<UInt8>?, _ srcW: Int, _ srcH: Int, _ dstW: Int, _ dstH: Int, _ dst: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("model_mask_unletterbox")
private func model_mask_unletterbox(
    _ mask: UnsafePointer<UInt8>?, _ modelW: Int, _ modelH: Int,
    _ box: UnsafePointer<Letterbox>?, _ outW: Int, _ outH: Int, _ out: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("lama_preset_params")
private func lama_preset_params(_ name: UnsafePointer<CChar>?, _ tile: UnsafeMutablePointer<Int32>?, _ overlap: UnsafeMutablePointer<Int32>?) -> Int32

@_silgen_name("lama_plan_tiles")
private func lama_plan_tiles(
    _ imageW: Int32, _ imageH: Int32, _ tile: Int32, _ overlap: Int32,
    _ out: UnsafeMutablePointer<LamaTile>?, _ cap: Int32, _ needed: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("lama_extract_tile")
private func lama_extract_tile(
    _ rgb: UnsafePointer<UInt8>?, _ mask: UnsafePointer<UInt8>?,
    _ imageW: Int32, _ imageH: Int32, _ tile: UnsafePointer<LamaTile>?, _ tileSize: Int32,
    _ tileRGB: UnsafeMutablePointer<UInt8>?, _ tileMask: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("lama_blend_begin")
private func lama_blend_begin(_ acc: UnsafeMutablePointer<Float>?, _ weight: UnsafeMutablePointer<Float>?, _ count: Int32) -> Int32

@_silgen_name("lama_blend_add")
private func lama_blend_add(
    _ acc: UnsafeMutablePointer<Float>?, _ weight: UnsafeMutablePointer<Float>?,
    _ imageW: Int32, _ imageH: Int32, _ tile: UnsafePointer<LamaTile>?,
    _ tileRGB: UnsafePointer<UInt8>?, _ tileSize: Int32
) -> Int32

@_silgen_name("lama_blend_finish")
private func lama_blend_finish(
    _ acc: UnsafePointer<Float>?, _ weight: UnsafePointer<Float>?, _ count: Int32, _ out: UnsafeMutablePointer<UInt8>?
) -> Int32

@_silgen_name("model_http_payload_ok")
private func model_http_payload_ok(_ status: Int32, _ nbytes: Int64, _ head: UnsafePointer<UInt8>?, _ headLen: Int) -> Int32
