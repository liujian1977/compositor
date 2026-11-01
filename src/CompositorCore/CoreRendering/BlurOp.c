// BlurOp.c — Separable Gaussian blur (deterministic mask feathering).

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "BlurOp.h"

int gaussian_blur(const float *src, int width, int height, float sigma, float *dst) {
    if (!src || !dst || width <= 0 || height <= 0) return -1;

    if (sigma <= 0.0f) {
        memcpy(dst, src, (size_t)width * (size_t)height * sizeof(float));
        return 0;
    }

    int radius = (int)ceilf(sigma * 3.0f);
    int ksize = radius * 2 + 1;

    float *kernel = malloc((size_t)ksize * sizeof(float));
    if (!kernel) return -1;

    float sum = 0.0f;
    float twoSigma2 = 2.0f * sigma * sigma;
    for (int i = 0; i < ksize; ++i) {
        float x = (float)(i - radius);
        float v = expf(-(x * x) / twoSigma2);
        kernel[i] = v;
        sum += v;
    }
    if (sum > 0.0f) {
        for (int i = 0; i < ksize; ++i) kernel[i] /= sum;
    }

    float *tmp = malloc((size_t)width * (size_t)height * sizeof(float));
    if (!tmp) { free(kernel); return -1; }

    size_t n = (size_t)width * (size_t)height;

    // Horizontal pass (clamp at borders).
    for (int y = 0; y < height; ++y) {
        const float *row = src + (size_t)y * (size_t)width;
        float *out = tmp + (size_t)y * (size_t)width;
        for (int x = 0; x < width; ++x) {
            float acc = 0.0f;
            for (int k = -radius; k <= radius; ++k) {
                int xx = x + k;
                if (xx < 0) xx = 0; else if (xx >= width) xx = width - 1;
                acc += row[xx] * kernel[k + radius];
            }
            out[x] = acc;
        }
    }

    // Vertical pass (clamp at borders).
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float acc = 0.0f;
            for (int k = -radius; k <= radius; ++k) {
                int yy = y + k;
                if (yy < 0) yy = 0; else if (yy >= height) yy = height - 1;
                acc += tmp[(size_t)yy * (size_t)width + (size_t)x] * kernel[k + radius];
            }
            dst[(size_t)y * (size_t)width + (size_t)x] = acc;
        }
    }

    free(tmp);
    free(kernel);
    return 0;
}
