// FaceSelect.swift — Swift wrapper for face_select. Vision stays in the CLI.

import Foundation

public enum FaceSelection {
    /// Index into the original `faces` arrays.
    /// `faceIndex` nil and `targetBox` nil keeps the largest face.
    /// Returns nil when the request matches nothing or the input is invalid.
    public static func choose(
        x: [Double], y: [Double], width: [Double], height: [Double], confidence: [Double],
        faceIndex: Int?,
        targetBox: (x: Double, y: Double, width: Double, height: Double)?
    ) -> Int? {
        let count = x.count
        guard y.count == count, width.count == count, height.count == count, confidence.count == count else {
            return nil
        }
        if count == 0 { return nil }
        let index = Int32(faceIndex ?? -1)
        let hasBox: Int32 = targetBox == nil ? 0 : 1
        let box = targetBox ?? (x: 0, y: 0, width: 0, height: 0)
        var rc: Int32 = -1
        x.withUnsafeBufferPointer { xp in
            y.withUnsafeBufferPointer { yp in
                width.withUnsafeBufferPointer { wp in
                    height.withUnsafeBufferPointer { hp in
                        confidence.withUnsafeBufferPointer { cp in
                            rc = face_select(
                                xp.baseAddress, yp.baseAddress, wp.baseAddress, hp.baseAddress, cp.baseAddress,
                                Int32(count), index, hasBox, box.x, box.y, box.width, box.height
                            )
                        }
                    }
                }
            }
        }
        return rc >= 0 ? Int(rc) : nil
    }
}

@_silgen_name("face_select")
private func face_select(
    _ x: UnsafePointer<Double>?,
    _ y: UnsafePointer<Double>?,
    _ width: UnsafePointer<Double>?,
    _ height: UnsafePointer<Double>?,
    _ confidence: UnsafePointer<Double>?,
    _ count: Int32,
    _ faceIndex: Int32,
    _ hasBox: Int32,
    _ boxX: Double, _ boxY: Double, _ boxW: Double, _ boxH: Double
) -> Int32
