// CompositeOp.c — Image compositing operations using pixel-level blending
// Supports alpha blending, difference blend mode, and basic Poisson fusion.

#include "CompositeOp.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

// ─── Alpha Blending ──────────────────────────────────────────────────

/**
 * Blend foreground onto background using standard alpha compositing (over operator).
 * Result: C_out = C_fg * α_fg + C_bg * (1 - α_fg)
 *
 * @param background  RGB pixels of background image (w*h*3 bytes)
 * @param foreground  RGB pixels of foreground image (w*h*3 bytes)
 * @param alpha       Alpha mask [0,255] (w*h bytes)
 * @param width       Image width
 * @param height      Image height
 * @param result      Output buffer (must be w*h*3 bytes, pre-allocated by caller)
 */
void alpha_blend(const uint8_t *background, const uint8_t *foreground,
                 const uint8_t *alpha, int width, int height, uint8_t *result) {
    if (!background || !foreground || !alpha || !result) return;

    for (int i = 0; i < width * height; i++) {
        float a = alpha[i] / 255.0f;
        a = fmax(0.0f, fmin(1.0f, a)); // clamp to [0,1]

        for (int c = 0; c < 3; c++) {
            float fg = foreground[i * 3 + c];
            float bg = background[i * 3 + c];
            result[i * 3 + c] = (uint8_t)roundf(fg * a + bg * (1.0f - a));
        }
    }
}

// ─── Difference Blend Mode ───────────────────────────────────────────

/**
 * Difference blend mode: |foreground - background|, masked by alpha.
 * Where alpha=0, keep original background; where alpha=255, use difference result.
 */
void blend_difference(const uint8_t *background, const uint8_t *foreground,
                      const uint8_t *alpha, int width, int height, uint8_t *result) {
    if (!background || !foreground || !alpha || !result) return;

    for (int i = 0; i < width * height; i++) {
        float a = alpha[i] / 255.0f;

        for (int c = 0; c < 3; c++) {
            float fg = foreground[i * 3 + c];
            float bg = background[i * 3 + c];
            float diff = fabsf(fg - bg);

            result[i * 3 + c] = (uint8_t)roundf(diff * a + bg * (1.0f - a));
        }
    }
}

// ─── Simple Poisson-like Blending ────────────────────────────────────

/**
 * Gradient-domain blending using simplified Poisson approach.
 * This creates seamless blends by matching gradients at the boundary.
 * For full Poisson fusion, you'd solve a sparse linear system — here we use
 * a simpler gradient-matching heuristic that works well for most cases.
 *
 * @param background      Background image RGB (w*h*3)
 * @param foreground      Foreground image RGB (w*h*3)
 * @param alpha           Soft alpha mask [0,255] (w*h)
 * @param width           Image width
 * @param height          Image height
 * @param result          Output buffer (pre-allocated by caller)
 */
void poisson_blend_simple(const uint8_t *background, const uint8_t *foreground,
                          const uint8_t *alpha, int width, int height, uint8_t *result) {
    if (!background || !foreground || !alpha || !result) return;

    // Allocate working buffers (float32 for numerical stability)
    float *bg_f = calloc(width * height * 3, sizeof(float));
    float *fg_f = calloc(width * height * 3, sizeof(float));
    float *out_f = calloc(width * height * 3, sizeof(float));

    if (!bg_f || !fg_f || !out_f) {
        free(bg_f); free(fg_f); free(out_f);
        return;
    }

    // Convert to float
    for (int i = 0; i < width * height * 3; i++) {
        bg_f[i] = background[i];
        fg_f[i] = foreground[i];
    }

    // Step 1: Compute gradient field of foreground
    float *fg_grad_x = calloc((width - 1) * height * 3, sizeof(float));
    float *fg_grad_y = calloc(width * (height - 1) * 3, sizeof(float));

    if (!fg_grad_x || !fg_grad_y) {
        free(bg_f); free(fg_f); free(out_f);
        free(fg_grad_x); free(fg_grad_y);
        return;
    }

    // Horizontal gradients
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width - 1; x++) {
            int idx = (y * width + x) * 3;
            int idx_next = (y * width + (x + 1)) * 3;
            for (int c = 0; c < 3; c++) {
                fg_grad_x[idx + c] = fg_f[idx_next + c] - fg_f[idx + c];
            }
        }
    }

    // Vertical gradients
    for (int y = 0; y < height - 1; y++) {
        for (int x = 0; x < width; x++) {
            int idx = (y * width + x) * 3;
            int idx_below = ((y + 1) * width + x) * 3;
            for (int c = 0; c < 3; c++) {
                fg_grad_y[idx + c] = fg_f[idx_below + c] - fg_f[idx + c];
            }
        }
    }

    // Step 2: Solve using iterative relaxation (simplified)
    // Copy background as initial guess
    memcpy(out_f, bg_f, width * height * 3 * sizeof(float));

    int iterations = 50;
    for (int iter = 0; iter < iterations; iter++) {
        for (int y = 1; y < height - 1; y++) {
            for (int x = 1; x < width - 1; x++) {
                int idx = (y * width + x) * 3;

                // Average of neighbors from current output
                float sum_r = 0, sum_g = 0, sum_b = 0;
                int count = 0;

                // Left neighbor gradient match
                if (x > 0) {
                    int left_idx = (y * width + (x - 1)) * 3;
                    sum_r += fg_f[left_idx] + fg_grad_x[idx];
                    sum_g += fg_f[left_idx + 1] + fg_grad_x[idx + 1];
                    sum_b += fg_f[left_idx + 2] + fg_grad_x[idx + 2];
                    count++;
                }

                // Right neighbor gradient match
                if (x < width - 1) {
                    int right_idx = (y * width + (x + 1)) * 3;
                    sum_r += fg_f[right_idx] - fg_grad_x[idx];
                    sum_g += fg_f[right_idx + 1] - fg_grad_x[idx + 1];
                    sum_b += fg_f[right_idx + 2] - fg_grad_x[idx + 2];
                    count++;
                }

                // Top neighbor gradient match
                if (y > 0) {
                    int top_idx = ((y - 1) * width + x) * 3;
                    sum_r += fg_f[top_idx] + fg_grad_y[idx];
                    sum_g += fg_f[top_idx + 1] + fg_grad_y[idx + 1];
                    sum_b += fg_f[top_idx + 2] + fg_grad_y[idx + 2];
                    count++;
                }

                // Bottom neighbor gradient match
                if (y < height - 1) {
                    int bottom_idx = ((y + 1) * width + x) * 3;
                    sum_r += fg_f[bottom_idx] - fg_grad_y[idx];
                    sum_g += fg_f[bottom_idx + 1] - fg_grad_y[idx + 1];
                    sum_b += fg_f[bottom_idx + 2] - fg_grad_y[idx + 2];
                    count++;
                }

                if (count > 0) {
                    out_f[idx] = sum_r / count;
                    out_f[idx + 1] = sum_g / count;
                    out_f[idx + 2] = sum_b / count;
                }
            }
        }

        // Step 3: Enforce alpha mask constraint
        for (int i = 0; i < width * height; i++) {
            float a = alpha[i] / 255.0f;
            for (int c = 0; c < 3; c++) {
                out_f[i * 3 + c] = out_f[i * 3 + c] * a + bg_f[i * 3 + c] * (1.0f - a);
            }
        }
    }

    // Convert back to uint8 and write result
    for (int i = 0; i < width * height * 3; i++) {
        float val = fmax(0.0f, fmin(255.0f, out_f[i]));
        result[i] = (uint8_t)roundf(val);
    }

    free(bg_f); free(fg_f); free(out_f);
    free(fg_grad_x); free(fg_grad_y);
}

// ─── Public API ──────────────────────────────────────────────────────

/**
 * Composite foreground onto background using the specified blend mode and alpha mask.
 *
 * @param operation   Blend operation: "alpha", "difference", or "poisson"
 * @param background  Background image (RGB, w*h*3 bytes)
 * @param foreground  Foreground image (RGB, w*h*3 bytes)
 * @param alpha       Alpha mask (grayscale, w*h bytes, values [0,255])
 * @param width       Image width
 * @param height      Image height
 * @param result      Output buffer (caller must allocate w*h*3 bytes)
 */
void composite_images(const char *operation, const uint8_t *background,
                     const uint8_t *foreground, const uint8_t *alpha,
                     int width, int height, uint8_t *result) {
    if (!operation || !background || !foreground || !alpha || !result) return;

    memset(result, 0, (size_t)width * height * 3 * sizeof(uint8_t));

    if (strcmp(operation, "difference") == 0) {
        blend_difference(background, foreground, alpha, width, height, result);
    } else if (strcmp(operation, "poisson") == 0) {
        poisson_blend_simple(background, foreground, alpha, width, height, result);
    } else {
        // Default to standard alpha blending
        alpha_blend(background, foreground, alpha, width, height, result);
    }
}
