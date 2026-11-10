// PatchInpaintOp.h — CoreRendering
// Simple patch-matching inpainting algorithm.

#ifndef PATCH_INPAINT_OP_H
#define PATCH_INPAINT_OP_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Fill masked regions using patch matching.
///
/// Image layout (img and output): RGBA8, 4 bytes per pixel.
/// Pixel (x, y) channel c is at index `y * stride + x * 4 + c`.
/// `stride` is the image row stride in bytes and must be >= width * 4.
/// Rows may be padded; padding bytes are copied through and never used as pixels.
///
/// Mask layout: one byte per pixel, independent of `stride`.
/// Mask (x, y) is at index `y * maskStride + x`.
/// `maskStride` must be >= width. A tightly packed mask uses maskStride == width.
///   0   = preserve (legal source for patches)
///   255 = replace with the synthesized color
///   1…254 = partial fill: synthesize, then blend toward the original by mask/255
///
/// search_radius: window, in pixels, around each hole pixel when searching for
/// source patches. Negative is invalid.
///
/// Returns 0 on success. Returns -1 on invalid arguments or allocation failure.
/// On invalid arguments `output` is not modified. On allocation failure
/// `output` is unspecified.
int patch_inpaint(
    const uint8_t *img, size_t width, size_t height, size_t stride,
    const uint8_t *mask, size_t maskStride,
    uint8_t *output,
    int search_radius);

#ifdef __cplusplus
}
#endif

#endif // PATCH_INPAINT_OP_H
