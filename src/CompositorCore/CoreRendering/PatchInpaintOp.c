// PatchInpaintOp.c — CoreRendering
// Simple patch-matching inpainting algorithm.
// Fills masked regions by copying patches from unmasked areas with gradient-aware search.

#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// Compute L2 distance between two patches of given size at specified locations.
// Includes gradient weight to prefer edges over flat regions.
static float patch_distance(
    const uint8_t *img, int w, int h, int stride,
    int x1, int y1,
    const uint8_t *m,   // mask: 255=inpainted region, 0=preserve
    int x2, int y2,
    int patch_size) {

    float sum = 0.0f;
    int half = patch_size / 2;
    int count = 0;

    for (int dy = -half; dy <= half; ++dy) {
        for (int dx = -half; dx <= half; ++dx) {
            // Source pixel must be in preserved region
            if (y1 + dy < 0 || y1 + dy >= h || x1 + dx < 0 || x1 + dx >= w) continue;
            if (m[y1 * stride + x1] != 0) continue;

            // Target pixel must also be in preserved region for comparison
            int tx = x2 + dx, ty = y2 + dy;
            if (tx < 0 || tx >= w || ty < 0 || ty >= h) continue;
            if (m[ty * stride + tx] != 0) continue;

            // RGB difference (3 channels assumed RGBA or RGB)
            int src_stride = MAX(stride, w * 4);
            float r_diff = (float)(img[(y1 + dy) * src_stride + (x1 + dx) * 4 + 0] -
                                   img[ty * src_stride + tx * 4 + 0]);
            float g_diff = (float)(img[(y1 + dy) * src_stride + (x1 + dx) * 4 + 1] -
                                   img[ty * src_stride + tx * 4 + 1]);
            float b_diff = (float)(img[(y1 + dy) * src_stride + (x1 + dx) * 4 + 2] -
                                   img[ty * src_stride + tx * 4 + 2]);

            // Gradient weight: prefer patches near edges in the source image
            float grad_w = 1.0f;
            if (tx > 0 && tx < w-1 && ty > 0 && ty < h-1) {
                float gx = (float)(img[ty * src_stride + (tx+1) * 4] - img[ty * src_stride + (tx-1) * 4]);
                float gy = (float)(img[(ty+1) * src_stride + tx * 4] - img[(ty-1) * src_stride + tx * 4]);
                grad_w = 1.0f + sqrtf(gx*gx + gy*gy) / 512.0f;
            }

            sum += (r_diff*r_diff + g_diff*g_diff + b_diff*b_diff) / grad_w;
            count++;
        }
    }

    return count > 0 ? sqrtf(sum / count) : 1e9f;
}

// Find the best matching patch for a given location within search radius.
// Returns best source (sx, sy), or (-1,-1) if no match found.
static int find_best_patch(
    const uint8_t *img, int w, int h, int stride,
    const uint8_t *mask,  // 255=fill, 0=preserve
    int tx, int ty,
    int patch_size, int search_radius,
    float scores[3],   // output: top-3 distances (used for averaging)
    int best_sx[3], int best_sy[3]) {

    int half = patch_size / 2;
    int min_x = MAX(0, tx - search_radius);
    int max_x = MIN(w - 1, tx + search_radius);
    int min_y = MAX(0, ty - search_radius);
    int max_y = MIN(h - 1, ty + search_radius);

    // Initialize top-3 with sentinel
    for (int i = 0; i < 3; ++i) { scores[i] = 1e9f; best_sx[i] = -1; best_sy[i] = -1; }

    int found = 0;

    for (int sy = min_y; sy <= max_y; ++sy) {
        for (int sx = min_x; sx <= max_x; ++sx) {
            // Source must be in preserved region
            if (mask[sy * stride + sx] != 0) continue;

            float dist = patch_distance(img, w, h, stride, sx, sy, mask, tx, ty, patch_size);
            if (dist >= scores[2]) continue;

            // Insert into top-3 sorted list
            for (int i = 2; i > 0; --i) {
                if (dist < scores[i]) {
                    scores[i] = scores[i-1];
                    best_sx[i] = best_sx[i-1];
                    best_sy[i] = best_sy[i-1];
                }
            }
            scores[0] = dist;
            best_sx[0] = sx;
            best_sy[0] = sy;
            found++;
        }
    }

    return found;
}

// Main inpainting function.
// img: RGBA image (4 bytes per pixel), stride >= width*4
// mask: binary mask, 255=pixels to fill, 0=preserve
// output: filled image (same format as input)
// Returns: 0 on success, -1 on invalid parameters.
int patch_inpaint(
    const uint8_t *img, size_t width, size_t height, size_t stride,
    const uint8_t *mask,
    uint8_t *output,
    int search_radius) {

    if (!width || !height || !img || !mask || !output) return -1;

    // Initialize output as copy of input
    memcpy(output, img, stride * height);

    size_t total = width * height;

    // Pass 1: Fill interior pixels using patch matching (multiple passes for propagation)
    int passes = 3;  // Multiple passes handle growing filled regions
    for (int pass = 0; pass < passes; ++pass) {
        // Copy current output as working buffer so we don't read from newly-filled pixels
        uint8_t *working = malloc(stride * height);
        if (!working) return -1;
        memcpy(working, output, stride * height);

        int changed = 0;

        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                if (mask[y * stride + x] != 255) continue;  // Skip preserved pixels

                int sx[3], sy[3];
                float scores[3];
                int count = find_best_patch(working, (int)width, (int)height, (int)stride,
                                            mask, (int)x, (int)y, 8, search_radius,
                                            scores, sx, sy);

                if (count == 0) continue;

                // Average top-3 matching patches (weighted by inverse distance)
                float total_w = 0.0f;
                for (int i = 0; i < count && i < 3; ++i) {
                    float w_val = scores[i] > 0.1f ? (1.0f / scores[i]) : 0.0f;
                    output[(y * stride + x) * 4 + 0] += (uint8_t)(working[(sy[i] * stride + sx[i]) * 4 + 0]);
                    output[(y * stride + x) * 4 + 1] += (uint8_t)(working[(sy[i] * stride + sx[i]) * 4 + 1]);
                    output[(y * stride + x) * 4 + 2] += (uint8_t)(working[(sy[i] * stride + sx[i]) * 4 + 2]);
                    output[(y * stride + x) * 4 + 3] = working[sy[i] * stride + sx[i] * 4 + 3];
                }

                // Average: divide by number of contributing patches (capped at 3)
                int div = count < 3 ? count : 3;
                output[y * stride + x * 4 + 0] /= (uint8_t)div;
                output[y * stride + x * 4 + 1] /= (uint8_t)div;
                output[y * stride + x * 4 + 2] /= (uint8_t)div;

                changed++;
            }
        }

        // If nothing changed this pass, we're done
        if (changed == 0) break;

        free(working);
    }

    // Pass 2: Boundary blending — smooth the seam between filled and preserved regions
    int blend_width = 5;  // Blend 5 pixels from mask boundary
    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            uint8_t m = mask[y * stride + x];
            if (m != 255) continue;  // Only blend boundary pixels

            // Count how many neighbors are preserved vs filled
            int preserved_neighbors = 0;
            int total_neighbors = 0;

            for (int dy = -1; dy <= 1; ++dy) {
                for (int dx = -1; dx <= 1; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    int nx = (int)x + dx, ny = (int)y + dy;
                    if (nx < 0 || nx >= (int)width || ny < 0 || ny >= (int)height) continue;

                    total_neighbors++;
                    if (mask[ny * stride + nx] == 0) {
                        // This neighbor is in preserved region and close enough to boundary
                        int dist = abs(dx) + abs(dy);
                        if (dist <= blend_width) {
                            preserved_neighbors++;
                        }
                    }
                }
            }

            if (preserved_neighbors > 0 && total_neighbors > 0) {
                float alpha = (float)preserved_neighbors / (float)total_neighbors;
                // Blend: preserve more of the original at the boundary
                uint8_t orig_r, orig_g, orig_b;
                memcpy(&orig_r, img + y * stride + x * 4, sizeof(uint8_t));
                memcpy(&orig_g, img + y * stride + x * 4 + 1, sizeof(uint8_t));
                memcpy(&orig_b, img + y * stride + x * 4 + 2, sizeof(uint8_t));

                output[y * stride + x * 4 + 0] = (uint8_t)(output[y * stride + x * 4 + 0] * (1.0f - alpha) + orig_r * alpha);
                output[y * stride + x * 4 + 1] = (uint8_t)(output[y * stride + x * 4 + 1] * (1.0f - alpha) + orig_g * alpha);
                output[y * stride + x * 4 + 2] = (uint8_t)(output[y * stride + x * 4 + 2] * (1.0f - alpha) + orig_b * alpha);
            }
        }
    }

    return 0;
}
