/* Pixel and JSON regressions for cutout, mask arithmetic, and inspect.
 * Build with ASan, UBSan, and LSan (see run_asan.sh).
 *
 * These tests lock the byte contract the CLI wrappers call. They do not
 * decode or encode PNG; CoreGraphics writeback is macOS-only.
 */

#include "MaskOps.h"

#include <limits.h>
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

static void expect_near(double got, double want, const char *name) {
    double d = got - want;
    if (d < 0) d = -d;
    if (!(d < 1e-9)) {
        fprintf(stderr, "FAIL %s got %.17g want %.17g\n", name, got, want);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
}

static void expect_json(const uint8_t *mask, int w, int h, const char *want, const char *name) {
    char *json = NULL;
    int rc = mask_inspect_format_json(mask, w, h, &json);
    int newline = json && strchr(json, '\n') != NULL;
    if (rc != 0 || json == NULL || newline || strcmp(json, want) != 0) {
        fprintf(stderr, "FAIL %s\n  got  %s\n  want %s\n", name, json ? json : "(null)", want);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
    mask_inspect_json_free(json);
}

static void test_cutout_copies_rgb_and_takes_alpha_from_mask(void) {
    const uint8_t rgb[6] = {255, 0, 0, 0, 255, 10};
    const uint8_t mask[2] = {255, 0};
    uint8_t out[8];
    memset(out, 0xAB, sizeof out);
    expect_true(cutout_apply_mask(rgb, mask, 2, 1, out) == 0, "cutout returns 0");
    const uint8_t want[8] = {255, 0, 0, 255, 0, 255, 10, 0};
    expect_true(memcmp(out, want, sizeof want) == 0, "cutout opaque and transparent pixels");

    const uint8_t partial_rgb[3] = {10, 20, 30};
    const uint8_t partial_mask[1] = {128};
    uint8_t partial[4];
    expect_true(cutout_apply_mask(partial_rgb, partial_mask, 1, 1, partial) == 0, "partial cutout returns 0");
    const uint8_t partial_want[4] = {10, 20, 30, 128};
    expect_true(memcmp(partial, partial_want, 4) == 0, "partial alpha is the mask byte, RGB unchanged");
}

static void test_cutout_rejects_without_writing(void) {
    uint8_t rgb[3] = {1, 2, 3};
    uint8_t mask[1] = {255};
    uint8_t out[8];
    memset(out, 0xAB, sizeof out);
    expect_true(cutout_apply_mask(NULL, mask, 1, 1, out) == -1, "cutout null rgb");
    expect_true(cutout_apply_mask(rgb, NULL, 1, 1, out) == -1, "cutout null mask");
    expect_true(cutout_apply_mask(rgb, mask, 1, 1, NULL) == -1, "cutout null output");
    expect_true(cutout_apply_mask(rgb, mask, 0, 1, out) == -1, "cutout zero width");
    expect_true(cutout_apply_mask(rgb, mask, 1, -4, out) == -1, "cutout negative height");
    expect_true(cutout_apply_mask(rgb, mask, INT_MAX, INT_MAX, out) == -1, "cutout overflowing dimensions");
    int untouched = 1;
    for (size_t i = 0; i < sizeof out; i++) {
        if (out[i] != 0xAB) untouched = 0;
    }
    expect_true(untouched, "failed cutout does not write");
}

static void test_arithmetic_pixels(void) {
    const uint8_t a[4] = {0, 10, 200, 255};
    const uint8_t b[4] = {5, 10, 100, 0};
    uint8_t out[4];

    expect_true(mask_invert(a, 2, 2, out) == 0, "invert returns 0");
    const uint8_t inv[4] = {255, 245, 55, 0};
    expect_true(memcmp(out, inv, 4) == 0, "invert 255-v");

    expect_true(mask_union(a, b, 2, 2, out) == 0, "union returns 0");
    const uint8_t uni[4] = {5, 10, 200, 255};
    expect_true(memcmp(out, uni, 4) == 0, "union is max");

    expect_true(mask_intersect(a, b, 2, 2, out) == 0, "intersect returns 0");
    const uint8_t inter[4] = {0, 10, 100, 0};
    expect_true(memcmp(out, inter, 4) == 0, "intersect is min");

    expect_true(mask_subtract(a, b, 2, 2, out) == 0, "subtract returns 0");
    const uint8_t sub[4] = {0, 0, 100, 255};
    expect_true(memcmp(out, sub, 4) == 0, "subtract saturates at 0");

    uint8_t inplace[4] = {0, 10, 200, 255};
    expect_true(mask_invert(inplace, 2, 2, inplace) == 0, "in-place invert");
    expect_true(memcmp(inplace, inv, 4) == 0, "in-place invert pixels");

    uint8_t inplace_a[4] = {0, 10, 200, 255};
    expect_true(mask_subtract(inplace_a, b, 2, 2, inplace_a) == 0, "in-place subtract");
    expect_true(memcmp(inplace_a, sub, 4) == 0, "in-place subtract pixels");
}

static void test_arithmetic_rejects_without_writing(void) {
    uint8_t src[1] = {9};
    uint8_t dst[4];
    memset(dst, 0xAB, sizeof dst);
    expect_true(mask_invert(NULL, 1, 1, dst) == -1, "invert null");
    expect_true(mask_union(src, NULL, 1, 1, dst) == -1, "union null");
    expect_true(mask_intersect(src, src, 0, 1, dst) == -1, "intersect zero width");
    expect_true(mask_subtract(src, src, -1, 1, dst) == -1, "subtract negative");
    expect_true(dst[0] == 0xAB && dst[3] == 0xAB, "failed arithmetic does not write");
}

static void test_inspect_values_and_json(void) {
    const uint8_t empty[4] = {0, 0, 0, 0};
    MaskInspectResult empty_info;
    expect_true(mask_inspect(empty, 2, 2, &empty_info) == 0, "empty inspect");
    expect_true(empty_info.coverage == 0.0, "empty coverage");
    expect_true(!empty_info.has_bounding_box, "empty has no box");
    expect_true(empty_info.component_count == 0 && empty_info.components == NULL, "empty components");
    expect_true(empty_info.foreground_threshold == 128 && empty_info.connectivity == 8, "empty metadata");
    mask_inspect_free(&empty_info);
    expect_json(empty, 2, 2,
                "{\"width\":2,\"height\":2,\"coverage\":0,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":null,\"component_count\":0,\"components\":[]}",
                "empty json");

    const uint8_t below[1] = {127};
    expect_json(below, 1, 1,
                "{\"width\":1,\"height\":1,\"coverage\":0.498039,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":null,\"component_count\":0,\"components\":[]}",
                "127 is coverage but not foreground");

    const uint8_t edge[2] = {128, 127};
    MaskInspectResult edge_info;
    expect_true(mask_inspect(edge, 2, 1, &edge_info) == 0, "threshold inspect");
    expect_true(edge_info.component_count == 1, "128 is foreground, 127 is not");
    expect_true(edge_info.has_bounding_box, "threshold has box");
    expect_true(edge_info.bounding_box.x == 0 && edge_info.bounding_box.y == 0 &&
                    edge_info.bounding_box.width == 1 && edge_info.bounding_box.height == 1,
                "threshold box is the single pixel");
    expect_near(edge_info.coverage, 0.5, "128+127 coverage");
    expect_near(edge_info.components[0].center_x, 0.0, "threshold center x");
    expect_near(edge_info.components[0].center_y, 0.0, "threshold center y");
    mask_inspect_free(&edge_info);
    expect_json(edge, 2, 1,
                "{\"width\":2,\"height\":1,\"coverage\":0.5,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":1,\"height\":1},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":1,\"center\":{\"x\":0,\"y\":0}}]}",
                "threshold json");

    /* 4x2: foreground pixels (1,0), (2,0), (2,1). Soft 128 counts as foreground. */
    const uint8_t blob[8] = {
        0, 255, 255, 0,
        0, 0, 128, 0
    };
    MaskInspectResult blob_info;
    expect_true(mask_inspect(blob, 4, 2, &blob_info) == 0, "blob inspect");
    expect_true(blob_info.component_count == 1, "blob is one component");
    expect_true(blob_info.components[0].area == 3, "blob area");
    expect_near(blob_info.components[0].center_x, 5.0 / 3.0, "blob center x");
    expect_near(blob_info.components[0].center_y, 1.0 / 3.0, "blob center y");
    expect_true(blob_info.bounding_box.x == 1 && blob_info.bounding_box.y == 0 &&
                    blob_info.bounding_box.width == 2 && blob_info.bounding_box.height == 2,
                "blob box");
    expect_true(blob_info.components[0].bounds.x == 1 && blob_info.components[0].bounds.width == 2 &&
                    blob_info.components[0].bounds.height == 2,
                "component bounds match the blob");
    expect_near(blob_info.coverage, 638.0 / (255.0 * 8.0), "blob coverage");
    mask_inspect_free(&blob_info);
    expect_json(blob, 4, 2,
                "{\"width\":4,\"height\":2,\"coverage\":0.312745,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":1,\"y\":0,\"width\":2,\"height\":2},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":3,\"center\":{\"x\":1.666667,\"y\":0.333333}}]}",
                "blob json");

    /* Diagonal touch is one 8-connected component, not two. */
    const uint8_t diag[4] = {255, 0, 0, 255};
    MaskInspectResult diag_info;
    expect_true(mask_inspect(diag, 2, 2, &diag_info) == 0, "diagonal inspect");
    expect_true(diag_info.component_count == 1 && diag_info.components[0].area == 2, "diagonal is 8-connected");
    expect_near(diag_info.components[0].center_x, 0.5, "diagonal center x");
    expect_near(diag_info.components[0].center_y, 0.5, "diagonal center y");
    mask_inspect_free(&diag_info);
    expect_json(diag, 2, 2,
                "{\"width\":2,\"height\":2,\"coverage\":0.5,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":2,\"height\":2},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":2,\"center\":{\"x\":0.5,\"y\":0.5}}]}",
                "diagonal json");

    const uint8_t split[5] = {255, 255, 0, 255, 255};
    expect_json(split, 5, 1,
                "{\"width\":5,\"height\":1,\"coverage\":0.8,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":5,\"height\":1},\"component_count\":2,"
                "\"components\":[{\"index\":0,\"area\":2,\"center\":{\"x\":0.5,\"y\":0}},"
                "{\"index\":1,\"area\":2,\"center\":{\"x\":3.5,\"y\":0}}]}",
                "gap splits components in scan order");

    const uint8_t corners[9] = {
        255, 0, 0,
        0, 0, 0,
        0, 0, 200
    };
    expect_json(corners, 3, 3,
                "{\"width\":3,\"height\":3,\"coverage\":0.198257,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":3,\"height\":3},\"component_count\":2,"
                "\"components\":[{\"index\":0,\"area\":1,\"center\":{\"x\":0,\"y\":0}},"
                "{\"index\":1,\"area\":1,\"center\":{\"x\":2,\"y\":2}}]}",
                "two corners stay separate");

    const uint8_t plus[9] = {
        0, 255, 0,
        255, 255, 255,
        0, 255, 0
    };
    expect_json(plus, 3, 3,
                "{\"width\":3,\"height\":3,\"coverage\":0.555556,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":3,\"height\":3},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":5,\"center\":{\"x\":1,\"y\":1}}]}",
                "plus centroid");

    const uint8_t full[1] = {255};
    expect_json(full, 1, 1,
                "{\"width\":1,\"height\":1,\"coverage\":1,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":1,\"height\":1},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":1,\"center\":{\"x\":0,\"y\":0}}]}",
                "full pixel json");
}

static void test_checkerboard_is_one_component(void) {
    const int w = 8, h = 8, n = 64;
    uint8_t mask[64];
    int area = 0;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int on = ((x + y) % 2) == 0;
            mask[y * w + x] = on ? 255 : 0;
            area += on;
        }
    }
    MaskInspectResult info;
    expect_true(mask_inspect(mask, w, h, &info) == 0, "checkerboard inspect");
    expect_true(area == 32, "checkerboard area precondition");
    expect_true(info.component_count == 1, "8-connected checkerboard is one component");
    expect_true(info.components[0].area == 32, "checkerboard component area");
    expect_near(info.components[0].center_x, 3.5, "checkerboard center x");
    expect_near(info.components[0].center_y, 3.5, "checkerboard center y");
    expect_near(info.coverage, 0.5, "checkerboard coverage");
    mask_inspect_free(&info);
    (void)n;
}

static void test_filled_rect_center(void) {
    const int w = 32, h = 32, n = 32 * 32;
    uint8_t *mask = (uint8_t *)malloc((size_t)n);
    expect_true(mask != NULL, "alloc 32x32");
    if (mask == NULL) return;
    memset(mask, 255, (size_t)n);
    MaskInspectResult info;
    expect_true(mask_inspect(mask, w, h, &info) == 0, "filled inspect");
    expect_true(info.component_count == 1 && info.components[0].area == n, "filled is one component");
    expect_near(info.components[0].center_x, 15.5, "filled center x");
    expect_near(info.components[0].center_y, 15.5, "filled center y");
    expect_true(info.bounding_box.width == 32 && info.bounding_box.height == 32, "filled box");
    expect_near(info.coverage, 1.0, "filled coverage");
    char *json = NULL;
    expect_true(mask_inspect_format_json(mask, w, h, &json) == 0, "filled json rc");
    expect_true(json && strcmp(json,
                "{\"width\":32,\"height\":32,\"coverage\":1,\"foreground_threshold\":128,\"connectivity\":8,"
                "\"bounding_box\":{\"x\":0,\"y\":0,\"width\":32,\"height\":32},\"component_count\":1,"
                "\"components\":[{\"index\":0,\"area\":1024,\"center\":{\"x\":15.5,\"y\":15.5}}]}") == 0,
                "filled json");
    if (json && strstr(json, "15.5") == NULL) {
        fprintf(stderr, "  filled json was %s\n", json);
    }
    mask_inspect_json_free(json);
    mask_inspect_free(&info);
    free(mask);
}

static void test_inspect_rejects(void) {
    MaskInspectResult info;
    memset(&info, 0x5A, sizeof info);
    uint8_t px = 255;
    expect_true(mask_inspect(NULL, 1, 1, &info) == -1, "inspect null mask");
    expect_true(info.components == NULL && info.component_count == 0, "failed inspect is zeroed");
    expect_true(mask_inspect(&px, 0, 1, &info) == -1, "inspect zero width");
    expect_true(mask_inspect(&px, INT_MAX, INT_MAX, &info) == -1, "inspect overflowing dimensions");
    expect_true(mask_inspect_format_json(&px, 1, 1, NULL) == -1, "format null out");

    char tiny[8];
    memset(tiny, 0xAB, sizeof tiny);
    MaskInspectResult one;
    expect_true(mask_inspect(&px, 1, 1, &one) == 0, "one pixel inspect");
    expect_true(mask_inspect_json(&one, tiny, sizeof tiny) == -1, "json buffer too small");
    expect_true(mask_inspect_json(&one, NULL, 32) == -1, "json null buffer");
    mask_inspect_free(&one);
    mask_inspect_free(NULL);
}

int main(void) {
    test_cutout_copies_rgb_and_takes_alpha_from_mask();
    test_cutout_rejects_without_writing();
    test_arithmetic_pixels();
    test_arithmetic_rejects_without_writing();
    test_inspect_values_and_json();
    test_checkerboard_is_one_component();
    test_filled_rect_center();
    test_inspect_rejects();
    if (g_failed) {
        fprintf(stderr, "%d assertion(s) failed\n", g_failed);
        return 1;
    }
    printf("ALL PASSED mask ops\n");
    return 0;
}
