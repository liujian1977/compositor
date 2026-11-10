/* Regression tests for patch_inpaint.
 * Build with ASan, UBSan, and LSan (see run_asan.sh).
 *
 * Covers the previous heap overflow (accumulate address used the image stride
 * as a pixel index), the empty-mask leak, fill-by-addition, missing inward
 * growth, and top-3 insertion order.
 */

#include "PatchInpaintOp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void patch_inpaint_test_top3(const float *dists, const int *sxs, const int *sys, int n,
                             float out_scores[3], int out_sx[3], int out_sy[3]);

static int g_failed = 0;

static void expect_true(int cond, const char *name) {
    if (!cond) {
        fprintf(stderr, "FAIL %s\n", name);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
}

static void put_px(uint8_t *img, size_t stride, int x, int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    size_t i = (size_t)y * stride + (size_t)x * 4u;
    img[i] = r;
    img[i + 1] = g;
    img[i + 2] = b;
    img[i + 3] = a;
}

static int px_eq(const uint8_t *img, size_t stride, int x, int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    size_t i = (size_t)y * stride + (size_t)x * 4u;
    return img[i] == r && img[i + 1] == g && img[i + 2] == b && img[i + 3] == a;
}

static void test_invalid_does_not_write(void) {
    uint8_t img[16], mask[4], out[16];
    memset(img, 1, sizeof img);
    memset(mask, 0, sizeof mask);
    memset(out, 0xCD, sizeof out);
    expect_true(patch_inpaint(NULL, 1, 1, 4, mask, 1, out, 1) == -1, "null image");
    expect_true(patch_inpaint(img, 1, 1, 4, NULL, 1, out, 1) == -1, "null mask");
    expect_true(patch_inpaint(img, 1, 1, 4, mask, 1, NULL, 1) == -1, "null output");
    expect_true(patch_inpaint(img, 0, 1, 4, mask, 1, out, 1) == -1, "zero width");
    expect_true(patch_inpaint(img, 2, 2, 4, mask, 2, out, 1) == -1, "stride too small");
    expect_true(patch_inpaint(img, 2, 2, 8, mask, 1, out, 1) == -1, "mask stride too small");
    expect_true(patch_inpaint(img, 1, 1, 4, mask, 1, out, -3) == -1, "negative radius");
    int untouched = 1;
    for (size_t i = 0; i < sizeof out; i++) if (out[i] != 0xCD) untouched = 0;
    expect_true(untouched, "invalid arguments leave output untouched");
}

static void test_empty_mask_is_identity(void) {
    const int w = 4, h = 2;
    const size_t stride = 16; /* tight RGBA */
    const size_t mask_stride = 4;
    uint8_t img[32], mask[8], out[32];
    for (size_t i = 0; i < sizeof img; i++) img[i] = (uint8_t)(i * 3 + 1);
    memset(mask, 0, sizeof mask);
    memset(out, 0xFF, sizeof out);
    int rc = patch_inpaint(img, w, h, stride, mask, mask_stride, out, 4);
    expect_true(rc == 0, "empty mask returns 0");
    expect_true(memcmp(out, img, stride * h) == 0, "empty mask does not change any byte");
}

static void test_uniform_hole_replaced(void) {
    /* 8x4, stride 32. Previously the accumulate address (y*stride+x)*4 walked
     * off a height-2-or-more image. Mask is packed with maskStride == width. */
    const int w = 8, h = 4;
    const size_t stride = 32;
    const size_t mask_stride = 8;
    uint8_t img[32 * 4];
    uint8_t mask[8 * 4];
    uint8_t out[32 * 4];
    memset(img, 0x5A, sizeof img); /* row padding marker */
    memset(mask, 0, sizeof mask);
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) put_px(img, stride, x, y, 10, 10, 10, 255);
    }
    put_px(img, stride, 0, 1, 200, 200, 200, 255);
    mask[1 * mask_stride + 0] = 255;

    int rc = patch_inpaint(img, w, h, stride, mask, mask_stride, out, 4);
    expect_true(rc == 0, "8x4 hole returns 0");
    expect_true(px_eq(out, stride, 0, 1, 10, 10, 10, 255), "hole is replaced by the surround, not kept at 200");

    int preserved = 1;
    int padding = 1;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (x == 0 && y == 1) continue;
            if (!px_eq(out, stride, x, y, 10, 10, 10, 255)) preserved = 0;
        }
        for (size_t b = (size_t)w * 4u; b < stride; b++) {
            if (out[(size_t)y * stride + b] != 0x5A) padding = 0;
        }
    }
    expect_true(preserved, "unmasked 8x4 pixels stay 10");
    expect_true(padding, "image row padding is not written");
}

static void test_single_pixel_scratch(void) {
    /* 1x16, only x=8 masked. Old boundary blend wrote the hole color back. */
    const int w = 16, h = 1;
    const size_t stride = 64;
    uint8_t img[64], mask[16], out[64];
    memset(img, 10, sizeof img);
    memset(mask, 0, sizeof mask);
    put_px(img, stride, 8, 0, 200, 200, 200, 10);
    mask[8] = 255;
    int rc = patch_inpaint(img, w, h, stride, mask, (size_t)w, out, 4);
    expect_true(rc == 0, "1x16 returns 0");
    expect_true(px_eq(out, stride, 8, 0, 10, 10, 10, 10), "scratch RGB becomes 10, not 200");
    int others = 1;
    for (int x = 0; x < w; x++) {
        if (x == 8) continue;
        if (!px_eq(out, stride, x, 0, 10, 10, 10, 10)) others = 0;
    }
    expect_true(others, "1x16 unmasked pixels unchanged");
}

static void test_wide_hole_propagates(void) {
    /* Radius 2 cannot see the center from the original surround in one pass.
     * x=6..18 is the hole. The center must not stay 180. */
    const int w = 24, h = 1;
    const size_t stride = (size_t)w * 4u;
    uint8_t img[24 * 4], mask[24], out[24 * 4];
    memset(img, 10, sizeof img);
    memset(mask, 0, sizeof mask);
    for (int x = 0; x < w; x++) put_px(img, stride, x, 0, 10, 20, 30, 255);
    for (int x = 6; x <= 18; x++) {
        put_px(img, stride, x, 0, 180, 180, 180, 255);
        mask[x] = 255;
    }
    int rc = patch_inpaint(img, w, h, stride, mask, (size_t)w, out, 2);
    expect_true(rc == 0, "wide hole returns 0");
    int filled = 1;
    int kept = 1;
    for (int x = 0; x < w; x++) {
        if (x >= 6 && x <= 18) {
            if (!px_eq(out, stride, x, 0, 10, 20, 30, 255)) filled = 0;
        } else if (!px_eq(out, stride, x, 0, 10, 20, 30, 255)) {
            kept = 0;
        }
    }
    expect_true(filled, "wide hole including the center is filled from the surround");
    expect_true(kept, "wide hole leaves the surround untouched");
}

static void test_mask_stride_is_independent(void) {
    /* Image rows are padded. Mask rows are padded the other way.
     * Hole at (x=1, y=1) lives at mask index 1*maskStride+1, NOT at the image stride. */
    const int w = 4, h = 2;
    const size_t stride = 32;
    const size_t mask_stride = 8;
    uint8_t img[32 * 2];
    uint8_t mask[8 * 2];
    uint8_t out[32 * 2];
    memset(img, 0x11, sizeof img);
    memset(mask, 0, sizeof mask);
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) put_px(img, stride, x, y, 10, 10, 10, 40);
    }
    put_px(img, stride, 1, 1, 200, 180, 160, 40);
    mask[1 * mask_stride + 1] = 255;
    /* A 255 sitting in the mask-row padding must not be treated as a pixel. */
    mask[4] = 255;

    uint8_t img_copy[32 * 2];
    memcpy(img_copy, img, sizeof img);
    int rc = patch_inpaint(img, w, h, stride, mask, mask_stride, out, 3);
    expect_true(rc == 0, "padded strides return 0");
    expect_true(px_eq(out, stride, 1, 1, 10, 10, 10, 40), "padded-stride hole is filled");

    int others = 1;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (x == 1 && y == 1) continue;
            size_t i = (size_t)y * stride + (size_t)x * 4u;
            if (memcmp(out + i, img_copy + i, 4) != 0) others = 0;
        }
        for (size_t b = (size_t)w * 4u; b < stride; b++) {
            if (out[(size_t)y * stride + b] != 0x11) others = 0;
        }
    }
    expect_true(others, "only the masked pixel changes; padding 255 is not a pixel");
}

static void test_unique_preserved_pixels_and_neighbor_average(void) {
    /* 1x5. Hole at x=2. Boundary blend sees preserved neighbors x=1 and x=3
     * and must average those colors, not restore 9,9,9. */
    const int w = 5, h = 1;
    const size_t stride = 20;
    uint8_t img[20], mask[5], out[20];
    memset(mask, 0, sizeof mask);
    put_px(img, stride, 0, 0, 1, 2, 3, 4);
    put_px(img, stride, 1, 0, 5, 6, 7, 8);
    put_px(img, stride, 2, 0, 9, 9, 9, 9);
    put_px(img, stride, 3, 0, 10, 11, 12, 13);
    put_px(img, stride, 4, 0, 14, 15, 16, 17);
    mask[2] = 255;
    int rc = patch_inpaint(img, w, h, stride, mask, (size_t)w, out, 2);
    expect_true(rc == 0, "unique row returns 0");
    expect_true(px_eq(out, stride, 0, 0, 1, 2, 3, 4), "x0 preserved");
    expect_true(px_eq(out, stride, 1, 0, 5, 6, 7, 8), "x1 preserved");
    expect_true(px_eq(out, stride, 3, 0, 10, 11, 12, 13), "x3 preserved");
    expect_true(px_eq(out, stride, 4, 0, 14, 15, 16, 17), "x4 preserved");
    /* (5+10)/2=7.5→8, (6+11)/2=8.5→9, (7+12)/2=9.5→10. Alpha comes from sources. */
    expect_true(out[2 * 4] == 8 && out[2 * 4 + 1] == 9 && out[2 * 4 + 2] == 10,
                "hole RGB is the preserved-neighbor average");
    expect_true(!(out[2 * 4] == 9 && out[2 * 4 + 1] == 9 && out[2 * 4 + 2] == 9),
                "hole RGB is not the deleted color");
}

static void test_partial_mask_blends_with_original(void) {
    const int w = 3, h = 1;
    const size_t stride = 12;
    uint8_t img[12], mask[3], out[12];
    memset(mask, 0, sizeof mask);
    put_px(img, stride, 0, 0, 10, 10, 10, 255);
    put_px(img, stride, 1, 0, 200, 200, 200, 255);
    put_px(img, stride, 2, 0, 10, 10, 10, 255);
    mask[1] = 128; /* ~half */
    int rc = patch_inpaint(img, w, h, stride, mask, (size_t)w, out, 2);
    expect_true(rc == 0, "partial mask returns 0");
    expect_true(px_eq(out, stride, 0, 0, 10, 10, 10, 255), "partial left preserved");
    expect_true(px_eq(out, stride, 2, 0, 10, 10, 10, 255), "partial right preserved");
    /* Fill color 10, then 128/255*10 + 127/255*200 = 104.627 → 105. */
    expect_true(out[4] == 105 && out[5] == 105 && out[6] == 105, "partial mask blends toward the original");
}

static void test_all_white_mask_has_no_source(void) {
    const int w = 4, h = 2;
    const size_t stride = (size_t)w * 4u;
    uint8_t img[32], mask[8], out[32];
    for (size_t i = 0; i < sizeof img; i++) img[i] = (uint8_t)(30 + i);
    memset(mask, 255, sizeof mask);
    int rc = patch_inpaint(img, w, h, stride, mask, (size_t)w, out, 2);
    expect_true(rc == 0, "all-white mask returns 0");
    expect_true(memcmp(out, img, stride * (size_t)h) == 0, "all-white mask cannot invent source pixels");
}

static void test_top3_insertion_order(void) {
    const float dists[] = {5.f, 3.f, 4.f, 3.5f, 1.f};
    const int sxs[] = {0, 1, 2, 3, 4};
    const int sys[] = {10, 11, 12, 13, 14};
    float scores[3];
    int sx[3], sy[3];
    patch_inpaint_test_top3(dists, sxs, sys, 5, scores, sx, sy);
    int scores_ok = scores[0] == 1.f && scores[1] == 3.f && scores[2] == 3.5f;
    int src_ok = sx[0] == 4 && sx[1] == 1 && sx[2] == 3 && sy[0] == 14 && sy[1] == 11 && sy[2] == 13;
    expect_true(scores_ok, "top-3 keeps [1, 3, 3.5] and drops 4 and 5");
    expect_true(src_ok, "top-3 source order follows the sorted distances");
}

int main(void) {
    test_invalid_does_not_write();
    test_empty_mask_is_identity();
    test_uniform_hole_replaced();
    test_single_pixel_scratch();
    test_wide_hole_propagates();
    test_mask_stride_is_independent();
    test_unique_preserved_pixels_and_neighbor_average();
    test_partial_mask_blends_with_original();
    test_all_white_mask_has_no_source();
    test_top3_insertion_order();
    if (g_failed) {
        fprintf(stderr, "%d assertion(s) failed\n", g_failed);
        return 1;
    }
    printf("ALL PASSED patch_inpaint\n");
    return 0;
}
