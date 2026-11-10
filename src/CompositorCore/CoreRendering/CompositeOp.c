// CompositeOp.c — Image compositing operations using pixel-level blending.
// Alpha blending, difference blend mode, and masked Poisson (seamless) cloning.

#include "CompositeOp.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

static uint8_t clamp_u8_from_double(double v) {
    if (v <= 0.0) return 0;
    if (v >= 255.0) return 255;
    return (uint8_t)(v + 0.5);
}

static int checked_pixel_count(int width, int height, size_t *out_count) {
    if (width <= 0 || height <= 0) return -1;
    size_t w = (size_t)width;
    size_t h = (size_t)height;
    if (h != 0 && w > SIZE_MAX / h) return -1;
    size_t n = w * h;
    if (n > SIZE_MAX / 3) return -1;
    *out_count = n;
    return 0;
}

// ─── Alpha Blending ──────────────────────────────────────────────────

/**
 * Blend foreground onto background using standard alpha compositing (over operator).
 * Result: C_out = C_fg * α + C_bg * (1 - α)
 */
static void alpha_blend(const uint8_t *background, const uint8_t *foreground,
                        const uint8_t *alpha, size_t count, uint8_t *result) {
    for (size_t i = 0; i < count; i++) {
        float a = alpha[i] / 255.0f;
        if (a < 0.0f) a = 0.0f;
        if (a > 1.0f) a = 1.0f;

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
static void blend_difference(const uint8_t *background, const uint8_t *foreground,
                             const uint8_t *alpha, size_t count, uint8_t *result) {
    for (size_t i = 0; i < count; i++) {
        float a = alpha[i] / 255.0f;
        if (a < 0.0f) a = 0.0f;
        if (a > 1.0f) a = 1.0f;

        for (int c = 0; c < 3; c++) {
            float fg = foreground[i * 3 + c];
            float bg = background[i * 3 + c];
            float diff = fabsf(fg - bg);
            result[i * 3 + c] = (uint8_t)roundf(diff * a + bg * (1.0f - a));
        }
    }
}

// ─── Masked Poisson blending ─────────────────────────────────────────

/**
 * Seamless clone: solve Δf = Δg inside the mask, with f = background outside.
 *
 * Unknowns are pixels with alpha >= 128 that are not on the one-pixel image
 * border. The border is always Dirichlet = background, because those pixels
 * do not have a full 4-neighborhood. The discrete system at an unknown p is
 *
 *   4*f_p - Σ_{q neighbor} f_q = 4*g_p - Σ_{q neighbor} g_q
 *
 * with f_q fixed to the background wherever q is not an unknown. Conjugate
 * gradient solves that SPD system per channel. Failure to allocate, or
 * failure to drive the RMS residual under 1e-6, returns -1 and does not
 * write `result`.
 */
static int poisson_blend(const uint8_t *background, const uint8_t *foreground,
                         const uint8_t *alpha, int width, int height,
                         size_t count, uint8_t *result) {
    uint8_t *unknown = NULL;
    double *x = NULL;
    double *r = NULL;
    double *pdir = NULL;
    double *Ap = NULL;
    uint8_t *tmp = NULL;
    int rc = -1;

    size_t w = (size_t)width;
    size_t h = (size_t)height;
    size_t n_unknown = 0;

    unknown = (uint8_t *)calloc(count, 1);
    x = (double *)malloc(count * sizeof(double));
    r = (double *)malloc(count * sizeof(double));
    pdir = (double *)malloc(count * sizeof(double));
    Ap = (double *)malloc(count * sizeof(double));
    tmp = (uint8_t *)malloc(count * 3);
    if (!unknown || !x || !r || !pdir || !Ap || !tmp) goto done;
    if (w >= 2 && h >= 2) {
        for (size_t y = 1; y + 1 < h; y++) {
            for (size_t xpix = 1; xpix + 1 < w; xpix++) {
                size_t i = y * w + xpix;
                if (alpha[i] >= 128) {
                    unknown[i] = 1;
                    n_unknown++;
                }
            }
        }
    }

    for (int c = 0; c < 3; c++) {
        for (size_t i = 0; i < count; i++) {
            x[i] = (double)background[i * 3 + c];
        }
        memset(r, 0, count * sizeof(double));

        double rs = 0.0;
        if (n_unknown > 0) {
            for (size_t y = 1; y + 1 < h; y++) {
                for (size_t xpix = 1; xpix + 1 < w; xpix++) {
                    size_t i = y * w + xpix;
                    if (!unknown[i]) continue;
                    size_t left = i - 1;
                    size_t right = i + 1;
                    size_t up = i - w;
                    size_t down = i + w;
                    double lap_g =
                        4.0 * (double)foreground[i * 3 + c]
                        - (double)foreground[left * 3 + c]
                        - (double)foreground[right * 3 + c]
                        - (double)foreground[up * 3 + c]
                        - (double)foreground[down * 3 + c];
                    double lap_x = 4.0 * x[i] - x[left] - x[right] - x[up] - x[down];
                    double ri = lap_g - lap_x;
                    r[i] = ri;
                    rs += ri * ri;
                }
            }
        }
        memcpy(pdir, r, count * sizeof(double));

        /* RMS residual below 1e-6 is far inside one gray level after rounding. */
        double stop = 1e-12 * (double)(n_unknown > 0 ? n_unknown : 1);
        size_t max_iter = (w + h) * 48u + 64u;
        size_t iter = 0;
        while (n_unknown > 0 && rs > stop && iter < max_iter) {
            iter++;
            double pAp = 0.0;
            for (size_t i = 0; i < count; i++) {
                if (!unknown[i]) {
                    Ap[i] = 0.0;
                    continue;
                }
                double acc = 4.0 * pdir[i] - pdir[i - 1] - pdir[i + 1]
                             - pdir[i - w] - pdir[i + w];
                Ap[i] = acc;
                pAp += pdir[i] * acc;
            }
            if (!(pAp > 0.0) || !isfinite(pAp) || !isfinite(rs)) goto done;

            double step = rs / pAp;
            double rs_new = 0.0;
            for (size_t i = 0; i < count; i++) {
                x[i] += step * pdir[i];
                r[i] -= step * Ap[i];
                rs_new += r[i] * r[i];
            }
            if (!isfinite(rs_new)) goto done;
            if (rs_new <= stop) {
                rs = rs_new;
                break;
            }
            double beta = rs_new / rs;
            for (size_t i = 0; i < count; i++) {
                pdir[i] = r[i] + beta * pdir[i];
            }
            rs = rs_new;
        }
        if (n_unknown > 0 && rs > stop) goto done;

        for (size_t i = 0; i < count; i++) {
            double a = (double)alpha[i] / 255.0;
            if (a < 0.0) a = 0.0;
            if (a > 1.0) a = 1.0;
            double mixed = x[i] * a + (double)background[i * 3 + c] * (1.0 - a);
            tmp[i * 3 + c] = clamp_u8_from_double(mixed);
        }
    }

    memcpy(result, tmp, count * 3);
    rc = 0;

done:
    free(unknown);
    free(x);
    free(r);
    free(pdir);
    free(Ap);
    free(tmp);
    return rc;
}

// ─── Public API ──────────────────────────────────────────────────────

int composite_images(const char *operation, const uint8_t *background,
                     const uint8_t *foreground, const uint8_t *alpha,
                     int width, int height, uint8_t *result) {
    if (!operation || !background || !foreground || !alpha || !result) return -1;

    size_t count = 0;
    if (checked_pixel_count(width, height, &count) != 0) return -1;

    if (strcmp(operation, "difference") == 0) {
        blend_difference(background, foreground, alpha, count, result);
        return 0;
    }
    if (strcmp(operation, "poisson") == 0) {
        return poisson_blend(background, foreground, alpha, width, height, count, result);
    }
    alpha_blend(background, foreground, alpha, count, result);
    return 0;
}
