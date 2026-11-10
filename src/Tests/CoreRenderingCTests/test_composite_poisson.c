/* Regression tests for composite_images / poisson blending.
 * Build with ASan, UBSan, and LSan (see run_asan.sh).
 *
 * The 8x4 cases are the size that previously overflowed the horizontal
 * gradient buffer: allocation was (width-1)*height*3 floats while stores used
 * a row stride of `width`.
 */

#include "CompositeOp.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_failed = 0;

static void expect_true(int cond, const char *name) {
    if (!cond) {
        fprintf(stderr, "FAIL %s\n", name);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
}

static void fill_rgb(uint8_t *buf, int n, uint8_t r, uint8_t g, uint8_t b) {
    for (int i = 0; i < n; i++) {
        buf[i * 3] = r;
        buf[i * 3 + 1] = g;
        buf[i * 3 + 2] = b;
    }
}

static void test_rejects_invalid_without_writing(void) {
    uint8_t px[3] = {9, 8, 7};
    uint8_t alpha[1] = {255};
    uint8_t result[8];
    memset(result, 0xAB, sizeof result);

    expect_true(composite_images(NULL, px, px, alpha, 1, 1, result) == -1, "null operation");
    expect_true(result[0] == 0xAB, "null operation leaves result");
    expect_true(composite_images("poisson", NULL, px, alpha, 1, 1, result) == -1, "null background");
    expect_true(composite_images("poisson", px, px, alpha, 0, 4, result) == -1, "zero width");
    expect_true(composite_images("poisson", px, px, alpha, 4, -1, result) == -1, "negative height");
    expect_true(composite_images("poisson", px, px, NULL, 1, 1, result) == -1, "null alpha");
    int untouched = 1;
    for (size_t i = 0; i < sizeof result; i++) {
        if (result[i] != 0xAB) untouched = 0;
    }
    expect_true(untouched, "failed calls do not write a black success image");
}

static void test_alpha_and_difference_still_work(void) {
    const int w = 2, h = 2, n = 4;
    uint8_t bg[12], fg[12], alpha[4], out[12];
    fill_rgb(bg, n, 0, 0, 0);
    fill_rgb(fg, n, 255, 255, 255);
    alpha[0] = 255;
    alpha[1] = 0;
    alpha[2] = 128;
    alpha[3] = 255;
    expect_true(composite_images("alpha", bg, fg, alpha, w, h, out) == 0, "alpha returns 0");
    expect_true(out[0] == 255 && out[3] == 0 && out[6] == 128, "alpha 255/0/128");

    fill_rgb(bg, n, 40, 40, 40);
    fill_rgb(fg, n, 10, 10, 10);
    for (int i = 0; i < n; i++) alpha[i] = 255;
    alpha[1] = 0;
    expect_true(composite_images("difference", bg, fg, alpha, w, h, out) == 0, "difference returns 0");
    expect_true(out[0] == 30 && out[3] == 40, "difference full and masked");

    /* Unknown mode stays on alpha blending, and still reports success. */
    fill_rgb(bg, n, 0, 0, 0);
    fill_rgb(fg, n, 200, 0, 0);
    for (int i = 0; i < n; i++) alpha[i] = 255;
    expect_true(composite_images("no-such-mode", bg, fg, alpha, w, h, out) == 0, "unknown mode");
    expect_true(out[0] == 200 && out[1] == 0, "unknown mode is alpha");
}

/* Flat foreground offset must disappear: Laplacian is zero and the Dirichlet
 * boundary is the background, so the unique solution is the background. */
static void test_constant_offset_is_background(int w, int h, const char *name) {
    int n = w * h;
    uint8_t *bg = (uint8_t *)malloc((size_t)n * 3);
    uint8_t *fg = (uint8_t *)malloc((size_t)n * 3);
    uint8_t *alpha = (uint8_t *)malloc((size_t)n);
    uint8_t *out = (uint8_t *)malloc((size_t)n * 3);
    expect_true(bg && fg && alpha && out, "alloc constant-offset buffers");
    if (!bg || !fg || !alpha || !out) {
        free(bg); free(fg); free(alpha); free(out);
        return;
    }
    for (int i = 0; i < n; i++) {
        uint8_t b = (uint8_t)(20 + (i % 17));
        bg[i * 3] = b;
        bg[i * 3 + 1] = (uint8_t)(b + 3);
        bg[i * 3 + 2] = (uint8_t)(255 - b);
        int r = b + 40; if (r > 255) r = 255;
        int g = b + 3 + 40; if (g > 255) g = 255;
        int bl = (255 - b) - 20; if (bl < 0) bl = 0;
        fg[i * 3] = (uint8_t)r;
        fg[i * 3 + 1] = (uint8_t)g;
        fg[i * 3 + 2] = (uint8_t)bl;
        alpha[i] = 255;
    }
    int rc = composite_images("poisson", bg, fg, alpha, w, h, out);
    expect_true(rc == 0, name);
    expect_true(rc == 0 && memcmp(out, bg, (size_t)n * 3) == 0, "constant offset matches background");
    free(bg); free(fg); free(alpha); free(out);
}

static void test_alpha_zero_keeps_background(void) {
    const int w = 8, h = 4, n = 32;
    uint8_t bg[96], fg[96], alpha[32], out[96];
    fill_rgb(bg, n, 30, 40, 50);
    fill_rgb(fg, n, 200, 10, 10);
    memset(alpha, 0, sizeof alpha);
    memset(out, 0, sizeof out);
    expect_true(composite_images("poisson", bg, fg, alpha, w, h, out) == 0, "alpha 0 returns 0");
    expect_true(memcmp(out, bg, sizeof bg) == 0, "alpha 0 is background, pixel for pixel");
}

static void test_identical_images_stay(void) {
    const int w = 6, h = 5, n = 30;
    uint8_t bg[90], alpha[30], out[90];
    for (int i = 0; i < n; i++) {
        bg[i * 3] = (uint8_t)(i * 3);
        bg[i * 3 + 1] = (uint8_t)(255 - i);
        bg[i * 3 + 2] = 80;
        alpha[i] = (i % 5 == 0) ? 0 : 255;
    }
    expect_true(composite_images("poisson", bg, bg, alpha, w, h, out) == 0, "identical returns 0");
    expect_true(memcmp(out, bg, sizeof bg) == 0, "identical fg/bg is unchanged");
}

/* 3x3, only the center is an unknown. Foreground spike of 100 on a zero
 * background solves to exactly 100 at the center; the border stays 0. */
static void test_single_interior_pixel(void) {
    const int w = 3, h = 3, n = 9;
    uint8_t bg[27], fg[27], alpha[9], out[27];
    memset(bg, 0, sizeof bg);
    memset(fg, 0, sizeof fg);
    memset(alpha, 255, sizeof alpha);
    fg[4 * 3] = 100;
    fg[4 * 3 + 1] = 100;
    fg[4 * 3 + 2] = 100;
    expect_true(composite_images("poisson", bg, fg, alpha, w, h, out) == 0, "3x3 returns 0");
    int border_ok = 1;
    for (int i = 0; i < n; i++) {
        if (i == 4) continue;
        if (out[i * 3] || out[i * 3 + 1] || out[i * 3 + 2]) border_ok = 0;
    }
    expect_true(border_ok, "3x3 border stays background");
    expect_true(out[4 * 3] == 100 && out[4 * 3 + 1] == 100 && out[4 * 3 + 2] == 100,
                "3x3 center reproduces the foreground spike");
}

/* Constant foreground on a zero background is harmonic. With a zero Dirichlet
 * border the solution is 0, not a copy of the foreground. */
static void test_flat_foreground_does_not_copy(void) {
    const int w = 5, h = 5, n = 25;
    uint8_t bg[75], fg[75], alpha[25], out[75];
    memset(bg, 0, sizeof bg);
    fill_rgb(fg, n, 100, 100, 100);
    memset(alpha, 255, sizeof alpha);
    expect_true(composite_images("poisson", bg, fg, alpha, w, h, out) == 0, "flat fg returns 0");
    int ok = 1;
    for (int i = 0; i < n * 3; i++) if (out[i] != 0) ok = 0;
    expect_true(ok, "flat foreground collapses to the zero boundary");
}

static void test_outside_mask_exact_and_thin_image(void) {
    const int w = 8, h = 4, n = 32;
    uint8_t bg[96], fg[96], alpha[32], out[96];
    fill_rgb(bg, n, 15, 25, 35);
    for (int i = 0; i < n; i++) {
        fg[i * 3] = (uint8_t)(100 + (i % 20));
        fg[i * 3 + 1] = (uint8_t)(i * 7);
        fg[i * 3 + 2] = 220;
        alpha[i] = (i % w < 3) ? 0 : 255;
    }
    expect_true(composite_images("poisson", bg, fg, alpha, w, h, out) == 0, "partial mask returns 0");
    int outside_ok = 1;
    for (int i = 0; i < n; i++) {
        if (alpha[i] != 0) continue;
        if (out[i * 3] != bg[i * 3] || out[i * 3 + 1] != bg[i * 3 + 1] || out[i * 3 + 2] != bg[i * 3 + 2]) {
            outside_ok = 0;
        }
    }
    expect_true(outside_ok, "alpha 0 pixels stay exactly the background");

    uint8_t bg1[12], fg1[12], a1[4], out1[12];
    fill_rgb(bg1, 4, 60, 60, 60);
    fill_rgb(fg1, 4, 10, 20, 30);
    memset(a1, 255, sizeof a1);
    expect_true(composite_images("poisson", bg1, fg1, a1, 1, 4, out1) == 0, "width 1 returns 0");
    expect_true(memcmp(out1, bg1, sizeof bg1) == 0, "width 1 has no interior and copies background");
}

/* Independent dense solve for one channel. Unknowns match poisson_blend:
 * alpha >= 128 and not on the image border. */
static int dense_channel(const uint8_t *bg, const uint8_t *fg, const uint8_t *alpha,
                         int w, int h, double *out) {
    int n = w * h;
    int *index = (int *)malloc((size_t)n * sizeof(int));
    if (!index) return -1;
    for (int i = 0; i < n; i++) index[i] = -1;
    int nu = 0;
    for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
            int i = y * w + x;
            if (alpha[i] >= 128) index[i] = nu++;
        }
    }
    for (int i = 0; i < n; i++) out[i] = bg[i];
    if (nu == 0) { free(index); return 0; }

    double *A = (double *)calloc((size_t)nu * (size_t)nu, sizeof(double));
    double *b = (double *)calloc((size_t)nu, sizeof(double));
    if (!A || !b) { free(A); free(b); free(index); return -1; }

    for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
            int i = y * w + x;
            int k = index[i];
            if (k < 0) continue;
            A[(size_t)k * (size_t)nu + (size_t)k] = 4.0;
            double rhs = 4.0 * fg[i];
            const int nbs[4] = {i - 1, i + 1, i - w, i + w};
            for (int t = 0; t < 4; t++) {
                int j = nbs[t];
                rhs -= fg[j];
                if (index[j] >= 0) A[(size_t)k * (size_t)nu + (size_t)index[j]] -= 1.0;
                else rhs += bg[j];
            }
            b[k] = rhs;
        }
    }

    for (int col = 0; col < nu; col++) {
        int pivot = col;
        double best = fabs(A[(size_t)col * (size_t)nu + (size_t)col]);
        for (int r = col + 1; r < nu; r++) {
            double v = fabs(A[(size_t)r * (size_t)nu + (size_t)col]);
            if (v > best) { best = v; pivot = r; }
        }
        if (best < 1e-12) { free(A); free(b); free(index); return -1; }
        if (pivot != col) {
            for (int c = col; c < nu; c++) {
                double tmp = A[(size_t)col * (size_t)nu + (size_t)c];
                A[(size_t)col * (size_t)nu + (size_t)c] = A[(size_t)pivot * (size_t)nu + (size_t)c];
                A[(size_t)pivot * (size_t)nu + (size_t)c] = tmp;
            }
            double tb = b[col];
            b[col] = b[pivot];
            b[pivot] = tb;
        }
        double diag = A[(size_t)col * (size_t)nu + (size_t)col];
        for (int r = col + 1; r < nu; r++) {
            double f = A[(size_t)r * (size_t)nu + (size_t)col] / diag;
            A[(size_t)r * (size_t)nu + (size_t)col] = 0.0;
            for (int c = col + 1; c < nu; c++) {
                A[(size_t)r * (size_t)nu + (size_t)c] -= f * A[(size_t)col * (size_t)nu + (size_t)c];
            }
            b[r] -= f * b[col];
        }
    }
    for (int col = nu - 1; col >= 0; col--) {
        double sum = b[col];
        for (int c = col + 1; c < nu; c++) sum -= A[(size_t)col * (size_t)nu + (size_t)c] * b[c];
        b[col] = sum / A[(size_t)col * (size_t)nu + (size_t)col];
    }
    for (int i = 0; i < n; i++) {
        if (index[i] >= 0) out[i] = b[index[i]];
    }
    free(A); free(b); free(index);
    return 0;
}

static void test_matches_dense_reference(void) {
    const int w = 8, h = 6, n = 48;
    uint8_t bg[144], fg[144], alpha[48], out[144];
    double ref[48];
    uint8_t bg_c[48], fg_c[48];
    for (int i = 0; i < n; i++) {
        int x = i % w;
        bg_c[i] = (uint8_t)((i * 5 + 11) % 60);
        fg_c[i] = (uint8_t)((i * 13 + 4) % 200);
        /* A blob, not the whole frame, so the mask boundary is inside the image. */
        alpha[i] = (x >= 2 && x <= 5 && (i / w) >= 1 && (i / w) <= 4) ? 255 : 0;
        bg[i * 3] = bg[i * 3 + 1] = bg[i * 3 + 2] = bg_c[i];
        fg[i * 3] = fg[i * 3 + 1] = fg[i * 3 + 2] = fg_c[i];
    }
    expect_true(dense_channel(bg_c, fg_c, alpha, w, h, ref) == 0, "dense reference solved");
    expect_true(composite_images("poisson", bg, fg, alpha, w, h, out) == 0, "reference image returns 0");

    int outside_ok = 1, inside_ok = 1;
    for (int i = 0; i < n; i++) {
        for (int c = 0; c < 3; c++) {
            if (alpha[i] == 0) {
                if (out[i * 3 + c] != bg[i * 3 + c]) outside_ok = 0;
            } else {
                double rounded = ref[i] < 0 ? 0 : (ref[i] > 255 ? 255 : ref[i]);
                double got = out[i * 3 + c];
                if (fabs(got - rounded) > 1.0) inside_ok = 0;
            }
        }
    }
    expect_true(outside_ok, "reference mask outside is exact background");
    expect_true(inside_ok, "poisson matches dense solve within 1 gray level");
}

int main(void) {
    test_rejects_invalid_without_writing();
    test_alpha_and_difference_still_work();
    test_constant_offset_is_background(8, 4, "8x4 poisson returns 0");
    test_constant_offset_is_background(4, 2, "4x2 poisson returns 0");
    test_alpha_zero_keeps_background();
    test_identical_images_stay();
    test_single_interior_pixel();
    test_flat_foreground_does_not_copy();
    test_outside_mask_exact_and_thin_image();
    test_matches_dense_reference();
    if (g_failed) {
        fprintf(stderr, "%d assertion(s) failed\n", g_failed);
        return 1;
    }
    printf("ALL PASSED composite/poisson\n");
    return 0;
}
