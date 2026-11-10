/* Pixel and JSON tests for layer placement, face selection, and pose layout.
 * Build with ASan/UBSan (run_asan.sh). CoreGraphics, Vision, and Core ML are
 * not involved.
 */

#include "CompositeOp.h"
#include "FaceSelect.h"
#include "LayerPlacement.h"
#include "PoseLayout.h"

#include <math.h>
#include <stdio.h>
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

static void expect_json(const char *got, const char *want, const char *name) {
    if (got == NULL || strcmp(got, want) != 0 || strchr(got, '\n') != NULL) {
        fprintf(stderr, "FAIL %s\n  got  %s\n  want %s\n", name, got ? got : "(null)", want);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
}

static void fill_rgb(uint8_t *dst, int n, uint8_t r, uint8_t g, uint8_t b) {
    for (int i = 0; i < n; i++) {
        dst[i * 3] = r;
        dst[i * 3 + 1] = g;
        dst[i * 3 + 2] = b;
    }
}

static void test_place_rejects_without_writing(void) {
    uint8_t fg[3] = {1, 2, 3};
    uint8_t alpha[1] = {255};
    uint8_t rgb[12];
    uint8_t out_a[4];
    memset(rgb, 0xAB, sizeof rgb);
    memset(out_a, 0xCD, sizeof out_a);
    expect_true(layer_place(NULL, alpha, 1, 1, 2, 2, 0, 0, 1, 1, 0, 0, 0, 0, rgb, out_a) == -1,
                "place null fg");
    expect_true(layer_place(fg, alpha, 1, 1, 0, 2, 0, 0, 1, 1, 0, 0, 0, 0, rgb, out_a) == -1,
                "place zero background");
    expect_true(layer_place(fg, alpha, 1, 1, 2, 2, 0, 0, 0, 1, 0, 0, 0, 0, rgb, out_a) == -1,
                "place zero size");
    expect_true(layer_place(fg, alpha, 1, 1, 2, 2, 0, 0, INFINITY, 1, 0, 0, 0, 0, rgb, out_a) == -1,
                "place inf size");
    expect_true(layer_place(fg, alpha, 1, 1, 2, 2, 0, 0, 1, 1, NAN, 0, 0, 0, rgb, out_a) == -1,
                "place nan rotation");
    expect_true(layer_place(fg, alpha, 1, 1, 2, 2, 0, 0, 1, 1, 0, 0, 0, 7, rgb, out_a) == -1,
                "place bad sampling");
    int untouched = 1;
    for (size_t i = 0; i < sizeof rgb; i++) if (rgb[i] != 0xAB) untouched = 0;
    for (size_t i = 0; i < sizeof out_a; i++) if (out_a[i] != 0xCD) untouched = 0;
    expect_true(untouched, "failed place does not write");
}

static void test_identity_and_scale(void) {
    uint8_t fg[12] = {
        10, 0, 0,  20, 0, 0,
        30, 0, 0,  40, 0, 0
    };
    uint8_t alpha[4] = {255, 255, 255, 255};
    uint8_t rgb[12], a[4];
    expect_true(layer_place(fg, alpha, 2, 2, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, rgb, a) == 0, "identity place");
    expect_true(memcmp(rgb, fg, 12) == 0, "identity rgb");
    expect_true(a[0] == 255 && a[3] == 255, "identity alpha");

    uint8_t one[3] = {9, 8, 7};
    uint8_t one_a[1] = {255};
    uint8_t big[12], big_a[4];
    expect_true(layer_place(one, one_a, 1, 1, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, big, big_a) == 0, "scale place");
    int scaled = 1;
    for (int i = 0; i < 4; i++) {
        if (big[i * 3] != 9 || big[i * 3 + 1] != 8 || big[i * 3 + 2] != 7 || big_a[i] != 255) scaled = 0;
    }
    expect_true(scaled, "1x1 scaled onto 2x2");
}

static void test_rotate_flip_translate_clip(void) {
    uint8_t fg[12] = {
        10, 0, 0,  20, 0, 0,
        30, 0, 0,  40, 0, 0
    };
    uint8_t alpha[4] = {255, 255, 255, 255};
    uint8_t rgb[12], a[4];
    expect_true(layer_place(fg, alpha, 2, 2, 2, 2, 0, 0, 2, 2, 180, 0, 0, 0, rgb, a) == 0, "rot180");
    expect_true(rgb[0] == 40 && rgb[3] == 30 && rgb[6] == 20 && rgb[9] == 10, "rot180 pixels");

    expect_true(layer_place(fg, alpha, 2, 2, 2, 2, 0, 0, 2, 2, 0, 1, 0, 0, rgb, a) == 0, "flip x");
    expect_true(rgb[0] == 20 && rgb[3] == 10 && rgb[6] == 40 && rgb[9] == 30, "flip x pixels");

    uint8_t row[6] = {7, 0, 0, 8, 0, 0};
    uint8_t row_a[2] = {255, 200};
    uint8_t wide[18], wide_a[6];
    memset(wide, 0x11, sizeof wide);
    expect_true(layer_place(row, row_a, 2, 1, 3, 2, 1, 0, 2, 1, 0, 0, 0, 0, wide, wide_a) == 0,
                "translate");
    expect_true(wide_a[0] == 0 && wide[0] == 0, "left of layer is clear");
    expect_true(wide[1 * 3] == 7 && wide_a[1] == 255, "translated first pixel");
    expect_true(wide[2 * 3] == 8 && wide_a[2] == 200, "translated second pixel keeps alpha");
    expect_true(wide_a[3] == 0 && wide_a[4] == 0 && wide_a[5] == 0, "row below is clear");

    uint8_t clip_rgb[12], clip_a[4];
    expect_true(layer_place(fg, alpha, 2, 2, 2, 2, -1, -1, 2, 2, 0, 0, 0, 0, clip_rgb, clip_a) == 0,
                "clip place");
    expect_true(clip_a[0] == 255 && clip_rgb[0] == 40, "overlap keeps source (1,1)");
    expect_true(clip_a[1] == 0 && clip_a[2] == 0 && clip_a[3] == 0, "pixels outside the layer are empty");

    /* A huge displayed size must still only touch the background buffer. */
    uint8_t tiny_fg[3] = {5, 5, 5};
    uint8_t tiny_a[1] = {255};
    uint8_t bg3[27], a3[9];
    expect_true(layer_place(tiny_fg, tiny_a, 1, 1, 3, 3, -100, -100, 1e6, 1e6, 37, 0, 0, 1, bg3, a3) == 0,
                "huge layer stays inside the background buffer");
}

static void test_bilinear_midpoint(void) {
    uint8_t fg[6] = {0, 0, 0, 255, 0, 0};
    uint8_t alpha[2] = {255, 255};
    uint8_t rgb[3], a[1];
    expect_true(layer_place(fg, alpha, 2, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, rgb, a) == 0, "bilinear");
    expect_true(rgb[0] == 128 && rgb[1] == 0 && rgb[2] == 0 && a[0] == 255, "bilinear midpoint is 128");
    expect_true(layer_place(fg, alpha, 2, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, rgb, a) == 0, "nearest midpoint");
    expect_true(rgb[0] == 255, "nearest midpoint picks the right pixel");
}

static void test_poisson_after_place(void) {
    const int n = 16;
    uint8_t bg[48];
    fill_rgb(bg, n, 30, 30, 30);
    uint8_t fg[3] = {200, 200, 200};
    uint8_t fa[1] = {255};
    uint8_t placed[48], alpha[16], out[48];
    expect_true(layer_place(fg, fa, 1, 1, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0, placed, alpha) == 0,
                "full coverage place");
    int opaque = 1;
    for (int i = 0; i < n; i++) if (alpha[i] != 255 || placed[i * 3] != 200) opaque = 0;
    expect_true(opaque, "scaled constant covers the background");
    expect_true(composite_images("alpha", bg, placed, alpha, 4, 4, out) == 0, "alpha of placed layer");
    expect_true(out[0] == 200 && out[45] == 200, "alpha blend copies the placed color");
    expect_true(composite_images("poisson", bg, placed, alpha, 4, 4, out) == 0, "poisson of constant layer");
    expect_true(memcmp(out, bg, sizeof bg) == 0, "constant layer poisson stays on the background");

    uint8_t patch[12] = {200, 0, 0, 200, 0, 0, 200, 0, 0, 200, 0, 0};
    uint8_t patch_a[4] = {255, 255, 255, 255};
    expect_true(layer_place(patch, patch_a, 2, 2, 4, 4, 6, 0, 2, 2, 0, 0, 0, 0, placed, alpha) == 0,
                "layer entirely outside");
    int clear = 1;
    for (int i = 0; i < n; i++) if (alpha[i] != 0 || placed[i * 3] != 0) clear = 0;
    expect_true(clear, "outside layer contributes nothing");
    expect_true(composite_images("poisson", bg, placed, alpha, 4, 4, out) == 0, "poisson of empty layer");
    expect_true(memcmp(out, bg, sizeof bg) == 0, "empty layer poisson is the background");

    expect_true(layer_place(patch, patch_a, 2, 2, 4, 4, -1, 1, 2, 2, 0, 0, 0, 0, placed, alpha) == 0,
                "layer hanging off the left");
    expect_true(composite_images("poisson", bg, placed, alpha, 4, 4, out) == 0, "poisson of clipped layer");
    int outside_ok = 1;
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            int i = y * 4 + x;
            if (alpha[i] == 0 && memcmp(out + i * 3, bg + i * 3, 3) != 0) outside_ok = 0;
        }
    }
    expect_true(outside_ok, "clipped poisson leaves uncovered pixels on the background");
    expect_true(alpha[0] == 0 && alpha[4] != 0, "hanging layer covers only the overlap");
}

static void test_face_select(void) {
    double x[3] = {0, 100, 0};
    double y[3] = {0, 0, 100};
    double w[3] = {10, 20, 20};
    double h[3] = {10, 20, 20};
    double c[3] = {0.4, 0.4, 0.9};
    expect_true(face_select(x, y, w, h, c, 3, -1, 0, 0, 0, 0, 0) == 2, "default is larger higher-confidence face");
    expect_true(face_select(x, y, w, h, c, 3, 0, 0, 0, 0, 0, 0) == 2, "index 0 is the sorted primary face");
    expect_true(face_select(x, y, w, h, c, 3, 1, 0, 0, 0, 0, 0) == 1, "index 1");
    expect_true(face_select(x, y, w, h, c, 3, 2, 0, 0, 0, 0, 0) == 0, "index 2");
    expect_true(face_select(x, y, w, h, c, 3, 3, 0, 0, 0, 0, 0) == -1, "index out of range");
    expect_true(face_select(x, y, w, h, c, 3, -1, 1, 0, 0, 10, 10) == 0, "target box picks the overlap");
    expect_true(face_select(x, y, w, h, c, 3, -1, 1, 500, 500, 10, 10) == -1, "box with no overlap");
    expect_true(face_select(x, y, w, h, c, 3, 0, 1, 0, 0, 10, 10) == -1, "box and index disagree");
    expect_true(face_select(x, y, w, h, c, 3, 2, 1, 0, 0, 10, 10) == 0, "box and index agree");
    expect_true(face_select(x, y, w, h, c, 0, -1, 0, 0, 0, 0, 0) == -1, "no faces");

    double hx[1] = {0}, hy[1] = {0}, hw[1] = {10}, hh[1] = {10}, hc[1] = {1};
    expect_true(face_select(hx, hy, hw, hh, hc, 1, -1, 1, 5, 0, 10, 10) == 0, "partial overlap still matches");
}

static void test_pose_order_fit_and_json(void) {
    double x[3] = {0, 5, 1};
    double y[3] = {10, 0, 0};
    double w[3] = {4, 4, 4};
    double h[3] = {4, 4, 4};
    double score[3] = {0.2, 0.9, 0.9};
    int order[3] = {-1, -1, -1};
    expect_true(pose_sort_order(x, y, w, h, score, 3, order) == 0, "sort people");
    expect_true(order[0] == 2 && order[1] == 1 && order[2] == 0, "score, then y, then x");
    expect_true(pose_sort_order(x, y, w, h, score, 3, NULL) == -1, "sort null order");
    expect_true(order[0] == 2, "failed sort leaves the previous order");

    double scale = 0, cx = 0, cy = 0;
    expect_true(pose_fit(10, 20, 40, 80, 1, 40, 80, &scale, &cx, &cy) == 0, "fit");
    expect_near(scale, 1.0, "fit scale");
    expect_near(cx, 30.0, "fit center x");
    expect_near(cy, 60.0, "fit center y");
    double ox = 0, oy = 0;
    expect_true(pose_unmap(0, 0, scale, cx, cy, 40, 80, &ox, &oy) == 0, "unmap corner");
    expect_near(ox, 10.0, "unmap x");
    expect_near(oy, 20.0, "unmap y");
    expect_true(pose_unmap(20, 40, scale, cx, cy, 40, 80, &ox, &oy) == 0, "unmap center");
    expect_near(ox, 30.0, "center x");
    expect_near(oy, 60.0, "center y");

    expect_true(pose_fit(0, 0, 100, 50, 1.25, 192, 256, &scale, &cx, &cy) == 0, "full-frame fit");
    expect_true(pose_unmap(96, 128, scale, cx, cy, 192, 256, &ox, &oy) == 0, "full-frame unmap");
    expect_near(ox, 50.0, "full-frame center x");
    expect_near(oy, 25.0, "full-frame center y");
    expect_true(pose_fit(0, 0, 10, 10, 0, 10, 10, &scale, &cx, &cy) == -1, "fit rejects zero padding");

    double bx = 0, by = 0, bw = 4, bh = 2, sc = 1;
    int counts = 1;
    int ids = 0;
    double kx = 1.5, ky = 0.5, kc = 0.25;
    char *json = NULL;
    expect_true(pose_people_json(4, 2, &bx, &by, &bw, &bh, &sc, &counts, 1, &ids, &kx, &ky, &kc, &json) == 0,
                "json rc");
    expect_json(json,
                "{\"width\":4,\"height\":2,\"person_count\":1,\"people\":[{\"index\":0,\"score\":1,"
                "\"bbox\":{\"x\":0,\"y\":0,\"width\":4,\"height\":2},\"keypoints\":[{\"id\":0,\"name\":\"nose\","
                "\"x\":1.5,\"y\":0.5,\"confidence\":0.25}]}]}",
                "one person json");
    pose_people_json_free(json);

    expect_true(pose_people_json(4, 2, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, &json) == 0,
                "empty json rc");
    expect_json(json, "{\"width\":4,\"height\":2,\"person_count\":0,\"people\":[]}", "empty people json");
    pose_people_json_free(json);

    double bx2[2] = {1, 8};
    double by2[2] = {2, 3};
    double bw2[2] = {4, 5};
    double bh2[2] = {6, 7};
    double sc2[2] = {0.5, -0.25};
    int counts2[2] = {1, 1};
    int ids2[2] = {5, 17};
    double kx2[2] = {1, 2};
    double ky2[2] = {3, 4};
    double kc2[2] = {0.5, -0.5};
    expect_true(pose_people_json(20, 10, bx2, by2, bw2, bh2, sc2, counts2, 2, ids2, kx2, ky2, kc2, &json) == 0,
                "two people rc");
    expect_json(json,
                "{\"width\":20,\"height\":10,\"person_count\":2,\"people\":["
                "{\"index\":0,\"score\":0.5,\"bbox\":{\"x\":1,\"y\":2,\"width\":4,\"height\":6},"
                "\"keypoints\":[{\"id\":5,\"name\":\"left_shoulder\",\"x\":1,\"y\":3,\"confidence\":0.5}]},"
                "{\"index\":1,\"score\":-0.25,\"bbox\":{\"x\":8,\"y\":3,\"width\":5,\"height\":7},"
                "\"keypoints\":[{\"id\":17,\"name\":\"keypoint_17\",\"x\":2,\"y\":4,\"confidence\":-0.5}]}]}",
                "two people json");
    pose_people_json_free(json);
    expect_true(pose_people_json(0, 2, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, &json) == -1,
                "json rejects zero width");
    expect_true(json == NULL, "failed json does not allocate");
}

int main(void) {
    test_place_rejects_without_writing();
    test_identity_and_scale();
    test_rotate_flip_translate_clip();
    test_bilinear_midpoint();
    test_poisson_after_place();
    test_face_select();
    test_pose_order_fit_and_json();
    if (g_failed) {
        fprintf(stderr, "%d assertion(s) failed\n", g_failed);
        return 1;
    }
    printf("ALL PASSED layer/pose\n");
    return 0;
}
