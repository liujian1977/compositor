// BlurOp.h — Separable Gaussian blur for mask feathering.
#ifndef BLUR_OP_H
#define BLUR_OP_H

#include <stdint.h>

// Separable Gaussian blur of a single-channel Float image (values in [0,1]).
// src, dst: width*height floats, row-major.
// sigma: standard deviation in pixels. sigma <= 0 copies src -> dst unchanged.
// Returns: 0 on success, -1 on invalid parameters / allocation failure.
int gaussian_blur(const float *src, int width, int height, float sigma, float *dst);

#endif /* BLUR_OP_H */
