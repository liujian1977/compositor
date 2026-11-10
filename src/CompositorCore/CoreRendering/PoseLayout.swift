// PoseLayout.swift — Ordering, crop fit, and multi-person pose JSON.
// Detection and Core ML stay in the CLI. This file only moves numbers.

import Foundation

public struct PosePersonBox: Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var score: Double

    public init(x: Double, y: Double, width: Double, height: Double, score: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.score = score
    }
}

public struct PoseKeypointValue: Sendable {
    public var id: Int
    public var x: Double
    public var y: Double
    public var confidence: Double

    public init(id: Int, x: Double, y: Double, confidence: Double) {
        self.id = id
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

public enum PoseLayout {
    /// Score descending, then top-to-bottom, then left-to-right.
    public static func sorted(_ people: [PosePersonBox]) throws -> [PosePersonBox] {
        if people.isEmpty { return [] }
        let xs = people.map(\.x)
        let ys = people.map(\.y)
        let ws = people.map(\.width)
        let hs = people.map(\.height)
        let scores = people.map(\.score)
        var order = [Int32](repeating: -1, count: people.count)
        var rc: Int32 = -1
        xs.withUnsafeBufferPointer { xp in
            ys.withUnsafeBufferPointer { yp in
                ws.withUnsafeBufferPointer { wp in
                    hs.withUnsafeBufferPointer { hp in
                        scores.withUnsafeBufferPointer { sp in
                            order.withUnsafeMutableBufferPointer { op in
                                rc = pose_sort_order(
                                    xp.baseAddress, yp.baseAddress, wp.baseAddress, hp.baseAddress,
                                    sp.baseAddress, Int32(people.count), op.baseAddress
                                )
                            }
                        }
                    }
                }
            }
        }
        guard rc == 0 else { throw CoreError.invalidData }
        return order.map { people[Int($0)] }
    }

    public static func fit(
        box: PosePersonBox, padding: Double, canvasWidth: Double, canvasHeight: Double
    ) throws -> (scale: Double, centerX: Double, centerY: Double) {
        var scale = 0.0
        var centerX = 0.0
        var centerY = 0.0
        let rc = pose_fit(
            box.x, box.y, box.width, box.height, padding, canvasWidth, canvasHeight,
            &scale, &centerX, &centerY
        )
        guard rc == 0 else { throw CoreError.invalidData }
        return (scale, centerX, centerY)
    }

    public static func unmap(
        canvasX: Double, canvasY: Double,
        scale: Double, centerX: Double, centerY: Double,
        canvasWidth: Double, canvasHeight: Double
    ) throws -> (x: Double, y: Double) {
        var x = 0.0
        var y = 0.0
        let rc = pose_unmap(
            canvasX, canvasY, scale, centerX, centerY, canvasWidth, canvasHeight, &x, &y
        )
        guard rc == 0 else { throw CoreError.invalidData }
        return (x, y)
    }

    /// Compact JSON document, no trailing newline.
    public static func peopleJSON(
        width: Int, height: Int, people: [(box: PosePersonBox, keypoints: [PoseKeypointValue])]
    ) throws -> String {
        let boxes = people.map(\.box)
        let counts = people.map { Int32($0.keypoints.count) }
        let keypoints = people.flatMap(\.keypoints)
        let ids = keypoints.map { Int32($0.id) }
        let xs = keypoints.map(\.x)
        let ys = keypoints.map(\.y)
        let conf = keypoints.map(\.confidence)
        var raw: UnsafeMutablePointer<CChar>?
        let rc: Int32 = callJSON(
            width: width, height: height, boxes: boxes, counts: counts,
            ids: ids, xs: xs, ys: ys, conf: conf, raw: &raw
        )
        defer { pose_people_json_free(raw) }
        guard rc == 0, let raw else { throw CoreError.renderFailed(reason: "pose_people_json failed") }
        return String(cString: raw)
    }

    private static func callJSON(
        width: Int, height: Int, boxes: [PosePersonBox], counts: [Int32],
        ids: [Int32], xs: [Double], ys: [Double], conf: [Double],
        raw: inout UnsafeMutablePointer<CChar>?
    ) -> Int32 {
        let bx = boxes.map(\.x)
        let by = boxes.map(\.y)
        let bw = boxes.map(\.width)
        let bh = boxes.map(\.height)
        let scores = boxes.map(\.score)
        var rc: Int32 = -1
        bx.withUnsafeBufferPointer { bxp in
            by.withUnsafeBufferPointer { byp in
                bw.withUnsafeBufferPointer { bwp in
                    bh.withUnsafeBufferPointer { bhp in
                        scores.withUnsafeBufferPointer { sp in
                            counts.withUnsafeBufferPointer { cp in
                                ids.withUnsafeBufferPointer { ip in
                                    xs.withUnsafeBufferPointer { xp in
                                        ys.withUnsafeBufferPointer { yp in
                                            conf.withUnsafeBufferPointer { kp in
                                                rc = pose_people_json(
                                                    Int32(width), Int32(height),
                                                    bxp.baseAddress, byp.baseAddress, bwp.baseAddress, bhp.baseAddress,
                                                    sp.baseAddress, cp.baseAddress, Int32(boxes.count),
                                                    ip.baseAddress, xp.baseAddress, yp.baseAddress, kp.baseAddress,
                                                    &raw
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return rc
    }
}

@_silgen_name("pose_sort_order")
private func pose_sort_order(
    _ x: UnsafePointer<Double>?, _ y: UnsafePointer<Double>?,
    _ width: UnsafePointer<Double>?, _ height: UnsafePointer<Double>?,
    _ score: UnsafePointer<Double>?, _ count: Int32,
    _ order: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("pose_fit")
private func pose_fit(
    _ boxX: Double, _ boxY: Double, _ boxW: Double, _ boxH: Double,
    _ padding: Double, _ canvasW: Double, _ canvasH: Double,
    _ scale: UnsafeMutablePointer<Double>?,
    _ centerX: UnsafeMutablePointer<Double>?,
    _ centerY: UnsafeMutablePointer<Double>?
) -> Int32

@_silgen_name("pose_unmap")
private func pose_unmap(
    _ canvasX: Double, _ canvasY: Double,
    _ scale: Double, _ centerX: Double, _ centerY: Double,
    _ canvasW: Double, _ canvasH: Double,
    _ outX: UnsafeMutablePointer<Double>?,
    _ outY: UnsafeMutablePointer<Double>?
) -> Int32

@_silgen_name("pose_people_json")
private func pose_people_json(
    _ imageW: Int32, _ imageH: Int32,
    _ boxX: UnsafePointer<Double>?, _ boxY: UnsafePointer<Double>?,
    _ boxW: UnsafePointer<Double>?, _ boxH: UnsafePointer<Double>?,
    _ score: UnsafePointer<Double>?, _ kptCounts: UnsafePointer<Int32>?,
    _ personCount: Int32,
    _ kptIds: UnsafePointer<Int32>?,
    _ kptX: UnsafePointer<Double>?, _ kptY: UnsafePointer<Double>?,
    _ kptConf: UnsafePointer<Double>?,
    _ outJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("pose_people_json_free")
private func pose_people_json_free(_ json: UnsafeMutablePointer<CChar>?)
