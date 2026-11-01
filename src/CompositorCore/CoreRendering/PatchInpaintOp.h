// PatchInpaintOp.h — CoreRendering
// Simple patch-matching inpainting algorithm.

#ifndef PATCH_INPAINT_OP_H
#define PATCH_INPAINT_OP_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Fill masked regions using a simple patch-matching algorithm.
/// img:      RGBA input (4 bytes per pixel, stride >= width*4).
/// mask:     binary mask (1 byte per pixel): 255=pixels to fill, 0=preserve.
/// output:   filled image buffer (same format as input), caller-allocated.
/// search_radius: search window in pixels for finding matching patches (default: 64).
/// Returns: 0 on success, -1 on invalid parameters.
int patch_inpaint(
    const uint8_t *img, size_t width, size_t height, size_t stride,
    const uint8_t *mask,
    uint8_t *output,
    int search_radius);

#ifdef __cplusplus
}
#endif

#endif // PATCH_INPAINT_OP_H
