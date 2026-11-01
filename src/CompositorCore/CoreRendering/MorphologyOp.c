// MorphologyOp.c — CoreRendering
// Expand (dilate) and contract (erode) a binary mask using 8-connected neighborhood.

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void morph_dilate(const uint8_t *mask, size_t width, size_t height,
                  uint8_t *output, int radius) {
    if (!width || !height || radius <= 0) return;

    // Use a ping-pong buffer approach: each dilation step writes to buf1, reads from buf0.
    // For efficiency with small radii, we just do `radius` passes of single-pixel dilation.
    size_t n = width * height;
    uint8_t *buf0 = malloc(n);
    uint8_t *buf1 = malloc(n);
    if (!buf0 || !buf1) { free(buf0); free(buf1); return; }  // allocation failed

    memcpy(buf0, mask, n);

    for (int pass = 0; pass < radius; ++pass) {
        memset(buf1, 0, n);
        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                if (!buf0[y * width + x]) continue;  // background pixel, skip
                uint8_t val = buf0[y * width + x];
                // 8-connected neighborhood. Out-of-bounds neighbours are treated
                // as background, so foreground cannot expand past the image edge.
                for (int dy = -1; dy <= 1; ++dy) {
                    int ny = (int)y + dy;
                    if (ny < 0 || ny >= (int)height) continue;
                    size_t row = (size_t)ny * width;
                    for (int dx = -1; dx <= 1; ++dx) {
                        int nx = (int)x + dx;
                        if (nx < 0 || nx >= (int)width) continue;
                        size_t idx = row + (size_t)nx;
                        if (!buf1[idx]) buf1[idx] = val;
                    }
                }
            }
        }
        // Swap buffers: copy buf1 → buf0 for next pass
        memcpy(buf0, buf1, n);
    }

    memcpy(output, buf0, n);
    free(buf0);
    free(buf1);
}

void morph_erode(const uint8_t *mask, size_t width, size_t height,
                 uint8_t *output, int radius) {
    if (!width || !height || radius <= 0) return;

    size_t n = width * height;
    uint8_t *buf0 = malloc(n);
    uint8_t *buf1 = malloc(n);
    if (!buf0 || !buf1) { free(buf0); free(buf1); return; }  // allocation failed

    memcpy(buf0, mask, n);

    for (int pass = 0; pass < radius; ++pass) {
        memset(buf1, 0, n);
        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                if (!buf0[y * width + x]) continue;

                // Keep the pixel only if ALL 8-neighbours are foreground.
                // Out-of-bounds neighbours count as background, so the mask
                // shrinks correctly at the image edge (clamp padding would
                // leave a false border of foreground).
                int eroded = 1;
                for (int dy = -1; dy <= 1 && eroded; ++dy) {
                    int ny = (int)y + dy;
                    if (ny < 0 || ny >= (int)height) { eroded = 0; continue; }
                    size_t row = (size_t)ny * width;
                    for (int dx = -1; dx <= 1 && eroded; ++dx) {
                        int nx = (int)x + dx;
                        if (nx < 0 || nx >= (int)width) { eroded = 0; continue; }
                        if (!buf0[row + (size_t)nx]) eroded = 0;
                    }
                }
                if (eroded) buf1[y * width + x] = 255;
            }
        }
        memcpy(buf0, buf1, n);
    }

    memcpy(output, buf0, n);
    free(buf0);
    free(buf1);
}
