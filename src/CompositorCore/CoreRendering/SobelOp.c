// SobelOp.c — CoreRendering
// Edge detection and boundary snapping for selection-modify --operation edge-snap.

#include <stdlib.h>
#include <string.h>
#include <math.h>

// Compute gradient magnitude at each pixel using 3×3 Sobel kernels (Sobel operator).
// image: grayscale input (1 byte per pixel, stride bytes per row — for grayscale stride == width).
// edges: output buffer of floats, width * height elements.
// Returns: 0 on success, -1 on invalid parameters.
int sobel_edge_detect(const uint8_t *image, size_t width, size_t height, size_t stride,
                      float *edges) {
    if (!width || !height || !image || !edges) return -1;

    // Compute gradient magnitude using Sobel kernels
    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            int gx = 0, gy = 0;

            for (int dy = -1; dy <= 1; ++dy) {
                for (int dx = -1; dx <= 1; ++dx) {
                    // Replicate (clamp) padding: sample the nearest in-bounds pixel.
                    // Skipping out-of-bounds neighbours breaks the Sobel kernel's
                    // zero-sum property at image borders and produces spurious
                    // gradients on otherwise uniform regions.
                    int sx = (int)x + dx;
                    int sy = (int)y + dy;
                    if (sx < 0) sx = 0; else if (sx >= (int)width) sx = (int)width - 1;
                    if (sy < 0) sy = 0; else if (sy >= (int)height) sy = (int)height - 1;

                    uint8_t v = image[(size_t)sy * stride + (size_t)sx];
                    int wx = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
                    int wy = dy == 0 ? 0 : (dy > 0 ? 1 : -1);

                    if (dx != 0 && dy == 0) wx *= 2;
                    if (dy != 0 && dx == 0) wy *= 2;

                    gx += v * wx;
                    gy += v * wy;
                }
            }

            float mag = sqrtf((float)(gx * gx + gy * gy));
            edges[y * width + x] = mag;
        }
    }

    // Normalize to [0, 1] by dividing by max possible magnitude (255 × 8 = 2040 for 3×3 Sobel)
    float maxMag = 0.0f;
    size_t n = width * height;
    for (size_t i = 0; i < n; ++i) {
        if (edges[i] > maxMag) maxMag = edges[i];
    }

    if (maxMag > 0) {
        for (size_t i = 0; i < n; ++i) {
            edges[i] /= maxMag;
        }
    }

    return 0;
}

// Find the nearest high-gradient location for each boundary pixel in a mask.
// mask: binary/soft mask (1 byte per pixel, stride bytes per row).
// edges: gradient magnitude map from sobel_edge_detect (width * height floats).
// threshold: minimum gradient to count as "high" (0.0–1.0 normalized).
// radius: search window in pixels around each boundary pixel.
// output: output mask where boundary pixels have been snapped.
// Returns: 0 on success, -1 on invalid parameters.
int snap_to_edges(const uint8_t *mask, size_t maskStride, const float *edges, size_t width, size_t height,
                  float threshold, int radius, uint8_t *output, size_t outStride) {
    if (!width || !height || !mask || !edges || !output) return -1;

    memcpy(output, mask, maskStride * height);  // Start with a copy

    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            uint8_t val = mask[y * maskStride + x];
            if (val == 0 || val == 255) continue;

            float bestGrad = -1.0f;
            size_t bestX = x, bestY = y;

            int y_min = y > (size_t)radius ? y - radius : 0;
            int y_max = (int)y + radius < (int)height ? (int)y + radius : (int)(height - 1);
            int x_min = x > (size_t)radius ? x - radius : 0;
            int x_max = (int)x + radius < (int)width ? (int)x + radius : (int)(width - 1);

            for (int sy = y_min; sy <= y_max; ++sy) {
                for (int sx = x_min; sx <= x_max; ++sx) {
                    uint8_t sv = mask[(size_t)sy * maskStride + sx];
                    if (sv == 0 || sv == 255) continue;

                    float grad = edges[(size_t)sy * width + sx];
                    if (grad > bestGrad && grad >= threshold) {
                        bestGrad = grad;
                        bestX = sx;
                        bestY = sy;
                    }
                }
            }

            // Snap: relocate the soft boundary pixel onto the nearest high-gradient
            // location instead of duplicating it. Read decisions always come from the
            // original `mask` (unchanged), so writes to `output` cannot cascade.
            if (bestGrad >= 0.0f && (bestX != x || bestY != y)) {
                output[(size_t)bestY * outStride + bestX] = val;  // place at edge
                output[y * outStride + x] = 0;                     // clear old spot
            }
        }
    }

    return 0;
}
