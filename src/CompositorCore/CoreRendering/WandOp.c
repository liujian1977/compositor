// WandOp.c — Magic Wand flood-fill selection (deterministic, no ML).

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "WandOp.h"

static inline int color_match(const uint8_t *p, uint8_t tr, uint8_t tg, uint8_t tb, uint8_t ta, int tol) {
    return (abs((int)p[0] - tr) <= tol &&
            abs((int)p[1] - tg) <= tol &&
            abs((int)p[2] - tb) <= tol &&
            abs((int)p[3] - ta) <= tol);
}

int wand_select(const uint8_t *image, int width, int height,
                int px, int py, int tolerance, int sampleSize,
                int contiguous, uint8_t *output) {
    if (!image || !output || width <= 0 || height <= 0) return -1;
    if (px < 0 || py < 0 || px >= width || py >= height) return -1;
    if (tolerance < 0) tolerance = 0;

    // 1. Determine the target color by averaging the sample window.
    int half = sampleSize / 2;
    unsigned long sr = 0, sg = 0, sb = 0, sa = 0;
    int cnt = 0;
    for (int y = py - half; y <= py + half; ++y) {
        if (y < 0 || y >= height) continue;
        for (int x = px - half; x <= px + half; ++x) {
            if (x < 0 || x >= width) continue;
            const uint8_t *p = image + ((size_t)y * (size_t)width + (size_t)x) * 4;
            sr += p[0]; sg += p[1]; sb += p[2]; sa += p[3];
            ++cnt;
        }
    }
    if (cnt == 0) return -1;
    uint8_t tr = (uint8_t)(sr / (unsigned long)cnt);
    uint8_t tg = (uint8_t)(sg / (unsigned long)cnt);
    uint8_t tb = (uint8_t)(sb / (unsigned long)cnt);
    uint8_t ta = (uint8_t)(sa / (unsigned long)cnt);

    size_t n = (size_t)width * (size_t)height;
    memset(output, 0, n);

    // 2a. Non-contiguous: global color key over the whole image.
    if (!contiguous) {
        for (size_t i = 0; i < n; ++i) {
            const uint8_t *p = image + i * 4;
            if (color_match(p, tr, tg, tb, ta, tolerance)) output[i] = 255;
        }
        return 0;
    }

    // 2b. Contiguous: 4-connected flood fill with an explicit stack.
    // A pixel is marked visited at push time so it is enqueued at most once,
    // bounding the stack to n entries regardless of image size.
    uint8_t *visited = malloc(n);
    int *stack = malloc(n * 2 * sizeof(int));
    if (!visited || !stack) { free(visited); free(stack); return -1; }
    memset(visited, 0, n);

    int sp = 0;
    size_t seedIdx = (size_t)py * (size_t)width + (size_t)px;
    if (!color_match(image + seedIdx * 4, tr, tg, tb, ta, tolerance)) {
        // Seed itself does not match (e.g. transparent) — nothing to select.
        free(visited); free(stack);
        return 0;
    }
    visited[seedIdx] = 1;
    stack[sp++] = px; stack[sp++] = py;

    while (sp > 0) {
        int y = stack[--sp];
        int x = stack[--sp];
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        size_t idx = (size_t)y * (size_t)width + (size_t)x;
        const uint8_t *p = image + idx * 4;
        if (!color_match(p, tr, tg, tb, ta, tolerance)) continue;
        output[idx] = 255;

        // Push 4-connected neighbours (deduped via visited).
        if (x + 1 < width)  { size_t ni = (size_t)y * (size_t)width + (size_t)(x + 1); if (!visited[ni]) { visited[ni] = 1; stack[sp++] = x + 1; stack[sp++] = y; } }
        if (x - 1 >= 0)     { size_t ni = (size_t)y * (size_t)width + (size_t)(x - 1); if (!visited[ni]) { visited[ni] = 1; stack[sp++] = x - 1; stack[sp++] = y; } }
        if (y + 1 < height) { size_t ni = (size_t)(y + 1) * (size_t)width + (size_t)x; if (!visited[ni]) { visited[ni] = 1; stack[sp++] = x; stack[sp++] = y + 1; } }
        if (y - 1 >= 0)     { size_t ni = (size_t)(y - 1) * (size_t)width + (size_t)x; if (!visited[ni]) { visited[ni] = 1; stack[sp++] = x; stack[sp++] = y - 1; } }
    }

    free(visited);
    free(stack);
    return 0;
}
