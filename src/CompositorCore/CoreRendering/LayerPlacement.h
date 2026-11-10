// LayerPlacement.h — Rasterize a foreground layer into a background-sized buffer.
//
// The parameters are ProjectManifest.Transform:
//   origin   [x, y]     top-left of the unrotated box, background pixels, y down
//   size     [w, h]     displayed size of the layer (scale = size / source size)
//   rotation degrees, clockwise around the center of that box
//   flipX/Y            mirror in local space before rotation
//   sampling           0 = Nearest, 1 = bilinear (Smooth and High quality)
//
// Every background pixel is written. Samples that miss the source are RGB 0
// and alpha 0. The function never allocates a buffer the size of the rotated
// layer, so a foreground that hangs off the background cannot grow memory
// past the caller-provided background buffers.

#ifndef LAYER_PLACEMENT_H
#define LAYER_PLACEMENT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Inverse-map each background pixel into the foreground and sample it.
 *
 * fg_rgb:    fg_w * fg_h * 3, row-major RGB
 * fg_alpha:  fg_w * fg_h, or NULL for opaque
 * out_rgb:   bg_w * bg_h * 3
 * out_alpha: bg_w * bg_h
 *
 * Returns 0 on success. Returns -1 (and does not write the outputs) when a
 * pointer is NULL, a dimension is invalid, a transform value is non-finite,
 * size is not in (1e-6, 1e7], or sampling is not 0 or 1.
 */
int layer_place(const uint8_t *fg_rgb, const uint8_t *fg_alpha,
                int fg_w, int fg_h, int bg_w, int bg_h,
                double origin_x, double origin_y,
                double size_w, double size_h,
                double rotation_deg, int flip_x, int flip_y, int sampling,
                uint8_t *out_rgb, uint8_t *out_alpha);

#ifdef __cplusplus
}
#endif

#endif /* LAYER_PLACEMENT_H */
