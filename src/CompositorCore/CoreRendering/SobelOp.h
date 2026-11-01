// SobelOp.h — Edge detection and edge-aware selection snapping.

#ifndef SOBEL_OP_H
#define SOBEL_OP_H

#ifdef __cplusplus
extern "C" {
#endif

/// Compute gradient magnitude using 3×3 Sobel kernels (SobelX + SobelY).
/// edges:    float array, H×W. Values in [0, 1] normalized to max gradient.
/// Returns: 0 on success, -1 on invalid parameters.
int sobel_edge_detect(const uint8_t *image, size_t width, size_t height, size_t stride,
                      float *edges);

/// Snap mask boundary pixels to nearest edge location with gradient > threshold.
/// Input: binary/soft mask (uint8_t), guide grayscale image (uint8_t).
/// Output: snapped mask written to result.
/// Returns: 0 on success, -1 on invalid parameters.
int snap_to_edges(const uint8_t *mask, size_t maskStride, const float *edges, size_t width, size_t height,
                  float sobelThreshold, int snapRadius,
                  uint8_t *output, size_t outStride);

#ifdef __cplusplus
}
#endif

#endif // SOBEL_OP_H
