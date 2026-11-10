// PatchInpaintOp.c — CoreRendering
// Patch-matching inpainting.
// Fills masked pixels from known pixels, then grows the known region inward.

#include "PatchInpaintOp.h"

#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define PATCH_SIZE 8
#define MAX_MATCHES 3

// L2 distance between the known parts of two patches.
// (sx, sy) is the source center, (tx, ty) is the hole center.
// `hole` is tightly packed (row stride == width): non-zero means "not yet known".
static float patch_distance(
    const uint8_t *img, int w, int h, int stride,
    int sx, int sy,
    const uint8_t *hole,
    int tx, int ty,
    int patch_size) {

    float sum = 0.0f;
    int half = patch_size / 2;
    int count = 0;

    for (int dy = -half; dy <= half; ++dy) {
        for (int dx = -half; dx <= half; ++dx) {
            int x1 = sx + dx;
            int y1 = sy + dy;
            int x2 = tx + dx;
            int y2 = ty + dy;
            if (x1 < 0 || y1 < 0 || x1 >= w || y1 >= h) continue;
            if (x2 < 0 || y2 < 0 || x2 >= w || y2 >= h) continue;

            // Compare only offsets where both the target neighborhood and the
            // source sample are already known. Checking the patch center once
            // would accept a source whose overlapping samples still sit in the hole.
            if (hole[(size_t)y2 * (size_t)w + (size_t)x2] != 0) continue;
            if (hole[(size_t)y1 * (size_t)w + (size_t)x1] != 0) continue;

            size_t sp = (size_t)y1 * (size_t)stride + (size_t)x1 * 4u;
            size_t tp = (size_t)y2 * (size_t)stride + (size_t)x2 * 4u;
            float r_diff = (float)img[sp] - (float)img[tp];
            float g_diff = (float)img[sp + 1] - (float)img[tp + 1];
            float b_diff = (float)img[sp + 2] - (float)img[tp + 2];

            float grad_w = 1.0f;
            if (x2 > 0 && x2 < w - 1 && y2 > 0 && y2 < h - 1) {
                size_t row = (size_t)y2 * (size_t)stride;
                float gx = (float)img[row + (size_t)(x2 + 1) * 4u] - (float)img[row + (size_t)(x2 - 1) * 4u];
                float gy = (float)img[(size_t)(y2 + 1) * (size_t)stride + (size_t)x2 * 4u]
                         - (float)img[(size_t)(y2 - 1) * (size_t)stride + (size_t)x2 * 4u];
                grad_w = 1.0f + sqrtf(gx * gx + gy * gy) / 512.0f;
            }

            sum += (r_diff * r_diff + g_diff * g_diff + b_diff * b_diff) / grad_w;
            count++;
        }
    }

    return count > 0 ? sqrtf(sum / (float)count) : 1e9f;
}

// Insert (dist, sx, sy) into a 3-entry list ordered by ascending distance.
// scores[0] is the best match. A distance that is not strictly better than
// scores[2] is ignored. Shifting stops at the insertion slot; the new item
// is written there and does not clobber a better match.
static void insert_top3(float dist, int sx, int sy,
                        float scores[MAX_MATCHES],
                        int best_sx[MAX_MATCHES], int best_sy[MAX_MATCHES]) {
    if (!(dist < scores[MAX_MATCHES - 1])) return;

    int slot = MAX_MATCHES - 1;
    while (slot > 0 && dist < scores[slot - 1]) {
        scores[slot] = scores[slot - 1];
        best_sx[slot] = best_sx[slot - 1];
        best_sy[slot] = best_sy[slot - 1];
        slot--;
    }
    scores[slot] = dist;
    best_sx[slot] = sx;
    best_sy[slot] = sy;
}

// Find up to three known source centers inside the search window.
// Returns how many matches were stored (0..3).
static int find_best_patch(
    const uint8_t *img, int w, int h, int stride,
    const uint8_t *hole,
    int tx, int ty,
    int patch_size, int search_radius,
    float scores[MAX_MATCHES],
    int best_sx[MAX_MATCHES], int best_sy[MAX_MATCHES]) {

    for (int i = 0; i < MAX_MATCHES; ++i) {
        scores[i] = 1e9f;
        best_sx[i] = -1;
        best_sy[i] = -1;
    }

    int half = patch_size / 2;
    int known_nearby = 0;
    for (int dy = -half; dy <= half && !known_nearby; ++dy) {
        int y = ty + dy;
        if (y < 0 || y >= h) continue;
        for (int dx = -half; dx <= half; ++dx) {
            int x = tx + dx;
            if (x < 0 || x >= w) continue;
            if (hole[(size_t)y * (size_t)w + (size_t)x] == 0) {
                known_nearby = 1;
                break;
            }
        }
    }
    if (!known_nearby) return 0;

    int min_x = (tx > search_radius) ? tx - search_radius : 0;
    int min_y = (ty > search_radius) ? ty - search_radius : 0;
    int max_x = w - 1;
    int max_y = h - 1;
    if (search_radius < (w - 1) - tx) max_x = tx + search_radius;
    if (search_radius < (h - 1) - ty) max_y = ty + search_radius;

    int found = 0;
    for (int sy = min_y; sy <= max_y; ++sy) {
        for (int sx = min_x; sx <= max_x; ++sx) {
            if (hole[(size_t)sy * (size_t)w + (size_t)sx] != 0) continue;

            float dist = patch_distance(img, w, h, stride, sx, sy, hole, tx, ty, patch_size);
            if (!(dist < scores[MAX_MATCHES - 1])) continue;

            insert_top3(dist, sx, sy, scores, best_sx, best_sy);
            found++;
        }
    }

    return found > MAX_MATCHES ? MAX_MATCHES : found;
}

static int arguments_invalid(
    const uint8_t *img, size_t width, size_t height, size_t stride,
    const uint8_t *mask, size_t maskStride,
    uint8_t *output, int search_radius) {

    if (!img || !mask || !output || width == 0 || height == 0) return 1;
    if (search_radius < 0) return 1;
    /* Leave headroom so patch-window int offsets (half == 4) cannot overflow. */
    if (width > (size_t)INT_MAX - 8 || height > (size_t)INT_MAX - 8) return 1;
    if (width > SIZE_MAX / 4u) return 1;
    if (stride < width * 4u) return 1;
    if (stride > SIZE_MAX / height) return 1;
    if (maskStride < width) return 1;
    if (maskStride > SIZE_MAX / height) return 1;
    if (width > SIZE_MAX / height) return 1;
    return 0;
}

int patch_inpaint(
    const uint8_t *img, size_t width, size_t height, size_t stride,
    const uint8_t *mask, size_t maskStride,
    uint8_t *output,
    int search_radius) {

    if (arguments_invalid(img, width, height, stride, mask, maskStride, output, search_radius)) {
        return -1;
    }

    int w = (int)width;
    int h = (int)height;
    int radius = search_radius;
    int max_dim = w > h ? w : h;
    if (radius > max_dim) radius = max_dim;

    // Output starts as the source image, including row padding.
    memcpy(output, img, stride * height);

    uint8_t *hole = (uint8_t *)malloc(width * height);
    uint8_t *working = NULL;
    uint8_t *newly = NULL;
    if (!hole) return -1;

    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            uint8_t m = mask[y * maskStride + x];
            hole[y * width + x] = (m > 0) ? 1 : 0;
        }
    }

    int rc = 0;
    // One pixel of growth per pass is enough to cross the image; the patch
    // window usually advances several pixels, and a pass that fills nothing ends the loop.
    long max_passes = (long)width + (long)height;
    if (max_passes < 1) max_passes = 1;

    for (long pass = 0; pass < max_passes; ++pass) {
        working = (uint8_t *)malloc(stride * height);
        newly = (uint8_t *)calloc(width * height, 1);
        if (!working || !newly) {
            rc = -1;
            goto cleanup;
        }
        memcpy(working, output, stride * height);

        size_t changed = 0;
        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                if (hole[y * width + x] == 0) continue;

                float scores[MAX_MATCHES];
                int sx[MAX_MATCHES], sy[MAX_MATCHES];
                int count = find_best_patch(
                    working, w, h, (int)stride, hole,
                    (int)x, (int)y, PATCH_SIZE, radius,
                    scores, sx, sy);
                if (count <= 0) continue;

                float acc_r = 0.0f, acc_g = 0.0f, acc_b = 0.0f, acc_a = 0.0f;
                float total_w = 0.0f;
                int used = 0;
                for (int i = 0; i < count; ++i) {
                    if (sx[i] < 0 || sy[i] < 0) continue;
                    // Perfect matches (distance ~ 0) must dominate, not be dropped.
                    float weight = 1.0f / (scores[i] + 1e-3f);
                    size_t sp = (size_t)sy[i] * stride + (size_t)sx[i] * 4u;
                    acc_r += (float)working[sp] * weight;
                    acc_g += (float)working[sp + 1] * weight;
                    acc_b += (float)working[sp + 2] * weight;
                    acc_a += (float)working[sp + 3] * weight;
                    total_w += weight;
                    used++;
                }
                if (used == 0 || !(total_w > 0.0f)) continue;

                size_t dp = y * stride + x * 4u;
                output[dp] = (uint8_t)roundf(acc_r / total_w);
                output[dp + 1] = (uint8_t)roundf(acc_g / total_w);
                output[dp + 2] = (uint8_t)roundf(acc_b / total_w);
                output[dp + 3] = (uint8_t)roundf(acc_a / total_w);
                newly[y * width + x] = 1;
                changed++;
            }
        }

        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                if (newly[y * width + x]) hole[y * width + x] = 0;
            }
        }

        free(working);
        working = NULL;
        free(newly);
        newly = NULL;
        if (changed == 0) break;
    }

    // Seam blend: pull filled pixels toward preserved neighbors, never toward
    // the original color that the mask asked us to remove.
    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            uint8_t m = mask[y * maskStride + x];
            if (m == 0) continue;

            float nr = 0.0f, ng = 0.0f, nb = 0.0f;
            int preserved = 0;
            int total = 0;
            for (int dy = -1; dy <= 1; ++dy) {
                for (int dx = -1; dx <= 1; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    int nx = (int)x + dx;
                    int ny = (int)y + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    total++;
                    if (mask[(size_t)ny * maskStride + (size_t)nx] != 0) continue;
                    size_t np = (size_t)ny * stride + (size_t)nx * 4u;
                    nr += output[np];
                    ng += output[np + 1];
                    nb += output[np + 2];
                    preserved++;
                }
            }
            if (preserved <= 0 || total <= 0) continue;

            float blend = (float)preserved / (float)total;
            size_t dp = y * stride + x * 4u;
            float rf = (float)output[dp] * (1.0f - blend) + (nr / (float)preserved) * blend;
            float gf = (float)output[dp + 1] * (1.0f - blend) + (ng / (float)preserved) * blend;
            float bf = (float)output[dp + 2] * (1.0f - blend) + (nb / (float)preserved) * blend;
            output[dp] = (uint8_t)roundf(rf);
            output[dp + 1] = (uint8_t)roundf(gf);
            output[dp + 2] = (uint8_t)roundf(bf);
        }
    }

    // Partial mask values keep a fraction of the original pixel.
    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            uint8_t m = mask[y * maskStride + x];
            if (m == 0 || m == 255) continue;
            float t = (float)m / 255.0f;
            size_t dp = y * stride + x * 4u;
            for (int c = 0; c < 3; ++c) {
                float mixed = (float)output[dp + c] * t + (float)img[dp + c] * (1.0f - t);
                output[dp + c] = (uint8_t)roundf(mixed);
            }
        }
    }

cleanup:
    free(working);
    free(newly);
    free(hole);
    return rc;
}

#ifdef COMPOSITOR_C_TESTS
// Test hook for the top-3 insertion order. Not part of the library ABI.
void patch_inpaint_test_top3(const float *dists, const int *sxs, const int *sys, int n,
                             float out_scores[3], int out_sx[3], int out_sy[3]) {
    float scores[MAX_MATCHES];
    int sx[MAX_MATCHES], sy[MAX_MATCHES];
    for (int i = 0; i < MAX_MATCHES; ++i) {
        scores[i] = 1e9f;
        sx[i] = -1;
        sy[i] = -1;
    }
    for (int k = 0; k < n; ++k) {
        insert_top3(dists[k], sxs[k], sys[k], scores, sx, sy);
    }
    memcpy(out_scores, scores, sizeof(float) * MAX_MATCHES);
    memcpy(out_sx, sx, sizeof(int) * MAX_MATCHES);
    memcpy(out_sy, sy, sizeof(int) * MAX_MATCHES);
}
#endif
