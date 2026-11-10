/* Prep, prompt mapping, LaMa tiles, download checks, and project edits.
 * No Core ML and no image files.
 */

#include "ModelPrep.h"
#include "ProjectEdit.h"

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
    if (!(d < 1e-4)) {
        fprintf(stderr, "FAIL %s got %.8g want %.8g\n", name, got, want);
        g_failed++;
    } else {
        printf("ok   %s\n", name);
    }
}

static void test_letterbox_and_normalize(void) {
    uint8_t src[12] = {
        10, 0, 0,  20, 0, 0,
        30, 0, 0,  40, 0, 0
    };
    uint8_t dst[48];
    Letterbox box;
    expect_true(model_letterbox_rgb(src, 2, 2, 4, 4, 0, 0, 0, dst, &box) == 0, "letterbox 2x2 to 4x4");
    expect_true(box.pad_x == 0 && box.pad_y == 0 && box.content_w == 4 && box.content_h == 4, "square fills the canvas");
    expect_true(dst[0] == 10 && dst[2 * 3] == 20 && dst[2 * 4 * 3] == 30 && dst[(2 * 4 + 2) * 3] == 40,
                "nearest blocks");

    uint8_t wide[6] = {1, 2, 3, 4, 5, 6};
    uint8_t square[2 * 4 * 3];
    expect_true(model_letterbox_rgb(wide, 2, 1, 2, 4, 9, 9, 9, square, &box) == 0, "wide letterbox");
    expect_true(box.content_w == 2 && box.content_h == 1 && box.pad_x == 0 && box.pad_y == 1, "wide plan");
    expect_true(square[0] == 9 && square[(1 * 2) * 3] == 1 && square[(1 * 2 + 1) * 3] == 4, "pad and content");

    float nchw[3];
    uint8_t red[3] = {255, 0, 0};
    expect_true(model_normalize_nchw(red, 1, 1, 0, nchw) == 0, "normalize unit");
    expect_near(nchw[0], 1.0, "red plane");
    expect_near(nchw[1], 0.0, "green plane");
    expect_true(model_normalize_nchw(red, 1, 1, 1, nchw) == 0, "imagenet");
    expect_near(nchw[0], (1.0 - 0.485) / 0.229, "imagenet red");
    expect_true(model_normalize_nchw(red, 1, 1, 3, nchw) == -1, "bad normalize mode");
}

static void test_prompts_and_mask(void) {
    Letterbox box;
    expect_true(model_letterbox_plan(100, 50, 100, 100, &box) == 0, "plan");
    expect_true(box.pad_x == 0 && box.pad_y == 25 && box.content_w == 100 && box.content_h == 50, "centered vertically");
    float coords[8], labels[4];
    int count = -1, used = -1;
    double point[2] = {50, 25};
    expect_true(sam_encode_prompts(&box, point, 1, NULL, 0, coords, labels, 4, &count, &used) == 0, "point prompt");
    expect_true(count == 1 && used == 0 && labels[0] == 1.0f, "point label");
    expect_near(coords[0], 50.0, "point x");
    expect_near(coords[1], 25.0 + 25.0, "point y includes pad");

    double bad[2] = {-1, 0};
    expect_true(sam_encode_prompts(&box, bad, 1, NULL, 0, coords, labels, 4, &count, &used) == -1, "point outside");

    double rect[4] = {0, 0, 100, 50};
    expect_true(sam_encode_prompts(&box, NULL, 0, rect, 1, coords, labels, 4, &count, &used) == 0, "box prompt");
    expect_true(count == 2 && labels[0] == 2.0f && labels[1] == 3.0f, "box labels");
    expect_near(coords[0], 0.0, "box x0");
    expect_near(coords[1], 25.0, "box y0");
    expect_near(coords[2], 100.0, "box x1");
    expect_near(coords[3], 75.0, "box y1");

    expect_true(sam_encode_prompts(&box, NULL, 0, NULL, 0, coords, labels, 4, &count, &used) == 0, "default box");
    expect_true(used == 1 && count == 2 && labels[0] == 2.0f && labels[1] == 3.0f, "default is a full box");

    float probs[4] = {0.2f, 0.5f, 0.9f, 0.49f};
    uint8_t bin[4];
    expect_true(model_mask_threshold(probs, 2, 2, 0.5f, bin) == 0, "threshold probs");
    expect_true(bin[0] == 0 && bin[1] == 255 && bin[2] == 255 && bin[3] == 0, "threshold bytes");

    float logits[2] = {0.0f, -2.0f};
    expect_true(model_mask_threshold(logits, 2, 1, 0.5f, bin) == 0, "threshold logits");
    expect_true(bin[0] == 255 && bin[1] == 0, "sigmoid split");

    uint8_t model[16] = {
        0, 0, 0, 0,
        0, 255, 255, 0,
        0, 255, 255, 0,
        0, 0, 0, 0
    };
    Letterbox fit;
    expect_true(model_letterbox_plan(2, 2, 4, 4, &fit) == 0, "unletter plan");
    fit.pad_x = 1; fit.pad_y = 1; fit.content_w = 2; fit.content_h = 2; fit.dst_w = 4; fit.dst_h = 4;
    uint8_t back[4];
    expect_true(model_mask_unletterbox(model, 4, 4, &fit, 2, 2, back) == 0, "unletterbox");
    expect_true(back[0] == 255 && back[1] == 255 && back[2] == 255 && back[3] == 255, "content is the mask");
}

static void test_lama_tiles_and_download(void) {
    int tile = 0, overlap = 0;
    expect_true(lama_preset_params("fast", &tile, &overlap) == 0 && tile == 512 && overlap == 32, "fast preset");
    expect_true(lama_preset_params("balanced", &tile, &overlap) == 0 && tile == 512 && overlap == 64, "balanced preset");
    expect_true(lama_preset_params("high", &tile, &overlap) == 0 && tile == 1024 && overlap == 128, "high preset");
    expect_true(lama_preset_params("nope", &tile, &overlap) == -1, "unknown preset");

    LamaTile tiles[8];
    int needed = 0;
    expect_true(lama_plan_tiles(8, 4, 4, 0, tiles, 8, &needed) == 0 && needed == 2, "two tiles");
    expect_true(tiles[0].x == 0 && tiles[1].x == 4 && tiles[0].width == 4 && tiles[0].pad_right == 0, "tile geometry");

    uint8_t rgb[8 * 4 * 3];
    uint8_t mask[8 * 4];
    for (int i = 0; i < 32; i++) {
        rgb[i * 3] = (uint8_t)i;
        rgb[i * 3 + 1] = 0;
        rgb[i * 3 + 2] = 0;
        mask[i] = (i % 2) ? 255 : 0;
    }
    uint8_t trgb[4 * 4 * 3], tmask[16];
    expect_true(lama_extract_tile(rgb, mask, 8, 4, &tiles[1], 4, trgb, tmask) == 0, "extract second tile");
    expect_true(trgb[0] == 4 && tmask[0] == 0, "second tile starts at x=4");

    float acc[32 * 3], weight[32];
    uint8_t out[32 * 3];
    uint8_t first[4 * 4 * 3], second[4 * 4 * 3];
    expect_true(lama_blend_begin(acc, weight, 32) == 0, "blend begin");
    expect_true(lama_extract_tile(rgb, mask, 8, 4, &tiles[0], 4, first, tmask) == 0, "extract first tile");
    expect_true(lama_blend_add(acc, weight, 8, 4, &tiles[0], first, 4) == 0, "blend first");
    expect_true(lama_extract_tile(rgb, mask, 8, 4, &tiles[1], 4, second, tmask) == 0, "extract for blend");
    expect_true(lama_blend_add(acc, weight, 8, 4, &tiles[1], second, 4) == 0, "blend second");
    expect_true(lama_blend_finish(acc, weight, 32, out) == 0, "blend finish");
    expect_true(memcmp(out, rgb, sizeof out) == 0, "non-overlapping tiles round-trip");

    expect_true(lama_plan_tiles(3, 2, 4, 1, tiles, 8, &needed) == 0 && needed == 1, "small image is one tile");
    expect_true(tiles[0].width == 3 && tiles[0].height == 2 && tiles[0].pad_right == 1 && tiles[0].pad_bottom == 2,
                "small tile is padded");

    uint8_t html[] = "<html>nope";
    uint8_t json[] = "{\"error\":1}";
    uint8_t bin[] = {0x00, 0x01, 0x02, 0x03};
    expect_true(model_http_payload_ok(404, 100, bin, 4) == -1, "http 404 rejected");
    expect_true(model_http_payload_ok(200, 0, bin, 4) == -2, "empty body rejected");
    expect_true(model_http_payload_ok(200, 10, html, sizeof html - 1) == -3, "html rejected");
    expect_true(model_http_payload_ok(200, 12, json, sizeof json - 1) == -3, "json error page rejected");
    expect_true(model_http_payload_ok(200, 4, bin, 4) == 0, "binary payload accepted");
    expect_true(model_http_payload_ok(200, 4, NULL, 0) == 0, "status and size alone can pass");
}

static void test_project_edits_and_flatten(void) {
    expect_true(project_blend_code("Normal") == 0, "normal code");
    expect_true(project_blend_code("Multiply") == 1, "multiply code");
    expect_true(project_blend_code("Overlay") == -1, "unsupported blend");
    expect_true(project_relative_path_ok("layers/photo.png") == 0, "relative path ok");
    expect_true(project_relative_path_ok("../secret.png") == -1, "parent segment rejected");
    expect_true(project_relative_path_ok("/etc/passwd") == -1, "absolute rejected");
    expect_true(project_relative_path_ok("a/./b.png") == -1, "dot segment rejected");
    expect_true(project_relative_path_ok("") == -1, "empty rejected");

    ProjectLayerState layers[2];
    memset(layers, 0, sizeof layers);
    layers[0].opacity = 1;
    layers[0].size_w = 10;
    layers[0].size_h = 10;
    layers[1] = layers[0];
    layers[1].opacity = 0.25;
    expect_true(project_set_opacity(layers, 2, 1, 0.5) == 0 && layers[1].opacity == 0.5, "set opacity");
    expect_true(project_set_opacity(layers, 2, 1, 1.5) == -1 && layers[1].opacity == 0.5, "opacity stays on failure");
    expect_true(project_set_blend(layers, 2, 0, "Screen") == 0 && layers[0].blend == 2, "set blend");
    expect_true(project_set_transform(layers, 2, 0, 4, 6, 20, 30, 15, 1, 0) == 0, "set transform");
    expect_true(layers[0].origin_x == 4 && layers[0].size_h == 30 && layers[0].flip_x == 1 && layers[0].rotation == 15,
                "transform fields");
    expect_true(project_set_transform(layers, 2, 0, 0, 0, 0, 10, 0, 0, 0) == -1 && layers[0].size_w == 20,
                "zero size rejected");
    int count = 2;
    expect_true(project_remove_layer(layers, &count, 0) == 0 && count == 1 && layers[0].opacity == 0.5, "remove compacts");
    expect_true(project_remove_layer(layers, &count, 3) == -1 && count == 1, "bad remove");

    const char *ids[] = {"ABC"};
    const char *names[] = {"Sky"};
    char *json = NULL;
    expect_true(project_list_json(100, 80, ids, names, layers, 1, &json) == 0, "list json");
    expect_true(json && strcmp(json,
                "{\"width\":100,\"height\":80,\"layer_count\":1,\"layers\":[{\"index\":0,\"id\":\"ABC\",\"name\":\"Sky\","
                "\"opacity\":0.5,\"blend\":\"Normal\",\"origin\":[0,0],\"size\":[10,10],\"rotation\":0,"
                "\"flip_x\":false,\"flip_y\":false}]}") == 0,
                "list json text");
    if (json && strstr(json, "\"opacity\":0.5") == NULL) fprintf(stderr, "  json %s\n", json ? json : "");
    project_list_json_free(json);

    uint8_t canvas_rgb[3] = {255, 0, 0};
    uint8_t canvas_a[1] = {255};
    uint8_t layer_rgb[3] = {0, 0, 255};
    uint8_t layer_a[1] = {255};
    expect_true(project_flatten_over(canvas_rgb, canvas_a, layer_rgb, layer_a, 1, 1, 1.0, 0) == 0, "flatten opaque");
    expect_true(canvas_rgb[0] == 0 && canvas_rgb[2] == 255 && canvas_a[0] == 255, "normal replaces");

    canvas_rgb[0] = 255; canvas_rgb[1] = 0; canvas_rgb[2] = 0; canvas_a[0] = 255;
    expect_true(project_flatten_over(canvas_rgb, canvas_a, layer_rgb, layer_a, 1, 1, 0.5, 0) == 0, "flatten half");
    expect_true(canvas_rgb[0] == 128 && canvas_rgb[1] == 0 && canvas_rgb[2] == 128, "half opacity mixes");

    canvas_rgb[0] = 255; canvas_rgb[1] = 0; canvas_rgb[2] = 0; canvas_a[0] = 255;
    layer_rgb[0] = 0; layer_rgb[1] = 0; layer_rgb[2] = 0;
    expect_true(project_flatten_over(canvas_rgb, canvas_a, layer_rgb, layer_a, 1, 1, 1.0, 1) == 0, "multiply");
    expect_true(canvas_rgb[0] == 0 && canvas_rgb[2] == 0, "multiply by black is black");
    expect_true(project_flatten_over(canvas_rgb, canvas_a, layer_rgb, layer_a, 1, 1, 1.0, 9) == -1, "bad blend does not pretend");
}

int main(void) {
    test_letterbox_and_normalize();
    test_prompts_and_mask();
    test_lama_tiles_and_download();
    test_project_edits_and_flatten();
    if (g_failed) {
        fprintf(stderr, "%d assertion(s) failed\n", g_failed);
        return 1;
    }
    printf("ALL PASSED model/project\n");
    return 0;
}
