// SobelOp.swift — CoreRendering (Swift wrapper)
// Swift wrappers for C edge detection and boundary snapping functions.

/// Edge detection operations for selection-modify --operation edge-snap.
public enum SobelOp {
    /// Compute gradient magnitude at each pixel using 3×3 Sobel kernels. Output values are in [0, 1].
    public static func detectEdges(_ image: [UInt8], width: Int, height: Int) throws -> [Float] {
        guard width > 0 && height > 0 else { return [] }
        guard image.count >= width * height else { throw CoreError.invalidData }

        var edges = [Float](repeating: 0, count: width * height)
        let rc = sobel_edge_detect_from_array(image, width: width, height: height, edges: &edges)
        guard rc == 0 else { throw CoreError.renderFailed(reason: "sobel_edge_detect failed") }
        return edges
    }

    /// Snap mask boundary pixels to nearest high-gradient location within snapRadius.
    public static func snapToEdges(mask: [UInt8], edges: [Float], threshold: Float, radius: Int, width: Int, height: Int) throws -> [UInt8] {
        guard width > 0 && height > 0 else { return mask }
        var output = mask
        let rc = snap_to_edges_from_array(mask, edges: edges, width: width, height: height, threshold: threshold, radius: radius, output: &output)
        guard rc == 0 else { throw CoreError.renderFailed(reason: "snap_to_edges failed") }
        return output
    }

    private static func sobel_edge_detect_from_array(_ image: [UInt8], width: Int, height: Int, edges: inout [Float]) -> Int {
        guard image.count >= width * height && edges.count == width * height else { return -1 }
        var result = -1
        image.withUnsafeBufferPointer { maskPtr in
            edges.withUnsafeMutableBufferPointer { edgePtr in
                let rc = sobel_edge_detect(
                    maskPtr.baseAddress,
                    width, height, width, // stride = bytes per row = width for grayscale
                    edgePtr.baseAddress
                )
                result = rc
            }
        }
        return result
    }

    private static func snap_to_edges_from_array(_ mask: [UInt8], edges: [Float], width: Int, height: Int, threshold: Float, radius: Int, output: inout [UInt8]) -> Int {
        guard mask.count == width * height && edges.count == width * height && output.count == width * height else { return -1 }
        var result = -1
        mask.withUnsafeBufferPointer { maskPtr in
            edges.withUnsafeBufferPointer { edgePtr in
                output.withUnsafeMutableBufferPointer { outPtr in
                    let rc = snap_to_edges(
                        maskPtr.baseAddress,
                        width,            // maskStride
                        edgePtr.baseAddress,
                        width, height, threshold, radius,
                        outPtr.baseAddress,
                        width             // outStride
                    )
                    result = rc
                }
            }
        }
        return result
    }
}

// MARK: - C Function Declarations (bridged)

@_silgen_name("sobel_edge_detect")
func sobel_edge_detect(
    _ image: UnsafePointer<UInt8>?,
    _ width: Int, _ height: Int,
    _ stride: Int,
    _ edges: UnsafeMutablePointer<Float>?
) -> Int

@_silgen_name("snap_to_edges")
func snap_to_edges(
    _ mask: UnsafePointer<UInt8>?,
    _ maskStride: Int,
    _ edges: UnsafePointer<Float>?,
    _ width: Int, _ height: Int,
    _ threshold: Float, _ radius: Int,
    _ output: UnsafeMutablePointer<UInt8>?,
    _ outStride: Int
) -> Int
