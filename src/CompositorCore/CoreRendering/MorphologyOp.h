// MorphologyOp.h — Dilation and erosion operations on binary masks.

#ifndef MORPHOLOGY_OP_H
#define MORPHOLOGY_OP_H

#ifdef __cplusplus
extern "C" {
#endif

/// 8-connected neighborhood dilation (expand selection outward by `radius` pixels).
void morph_dilate(const uint8_t *mask, size_t width, size_t height,
                  uint8_t *output, int radius);

/// 8-connected neighborhood erosion (contract selection inward by `radius` pixels).
void morph_erode(const uint8_t *mask, size_t width, size_t height,
                 uint8_t *output, int radius);

#ifdef __cplusplus
}
#endif

#endif // MORPHOLOGY_OP_H
