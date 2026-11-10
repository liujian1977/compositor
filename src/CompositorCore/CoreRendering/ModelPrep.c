// ModelPrep.c — Letterbox, prompts, mask post, LaMa tiles, download checks.

#include "ModelPrep.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

static int dims_ok(int w, int h) {
    if (w <= 0 || h <= 0) return 0;
    if (w > 16384 || h > 16384) return 0;
    size_t n = (size_t)w * (size_t)h;
    if (n > (size_t)w * (size_t)h) return 0;
    if ((size_t)w > SIZE_MAX / (size_t)h) return 0;
    if (n > SIZE_MAX / 4) return 0;
    return 1;
}

int model_letterbox_plan(int src_w, int src_h, int dst_w, int dst_h, Letterbox *out) {
    if (out == NULL || !dims_ok(src_w, src_h) || !dims_ok(dst_w, dst_h)) return -1;
    double scale = (double)dst_w / (double)src_w;
    double scale_h = (double)dst_h / (double)src_h;
    if (scale_h < scale) scale = scale_h;
    int content_w = (int)floor((double)src_w * scale + 0.5);
    int content_h = (int)floor((double)src_h * scale + 0.5);
    if (content_w < 1) content_w = 1;
    if (content_h < 1) content_h = 1;
    if (content_w > dst_w) content_w = dst_w;
    if (content_h > dst_h) content_h = dst_h;
    out->src_w = src_w;
    out->src_h = src_h;
    out->dst_w = dst_w;
    out->dst_h = dst_h;
    out->content_w = content_w;
    out->content_h = content_h;
    out->pad_x = (dst_w - content_w) / 2;
    out->pad_y = (dst_h - content_h) / 2;
    out->scale = scale;
    return 0;
}

static int sample_src(int dst_local, int content, int src_extent) {
    if (content <= 0) return 0;
    int s = (int)(((long long)dst_local * src_extent) / content);
    if (s < 0) s = 0;
    if (s >= src_extent) s = src_extent - 1;
    return s;
}

int model_letterbox_rgb(const uint8_t *src, int src_w, int src_h,
                        int dst_w, int dst_h, uint8_t pad_r, uint8_t pad_g, uint8_t pad_b,
                        uint8_t *dst, Letterbox *plan) {
    Letterbox box;
    if (src == NULL || dst == NULL || model_letterbox_plan(src_w, src_h, dst_w, dst_h, &box) != 0) {
        return -1;
    }
    if (plan) *plan = box;
    size_t n = (size_t)dst_w * (size_t)dst_h;
    for (size_t i = 0; i < n; i++) {
        dst[i * 3] = pad_r;
        dst[i * 3 + 1] = pad_g;
        dst[i * 3 + 2] = pad_b;
    }
    for (int y = 0; y < box.content_h; y++) {
        int sy = sample_src(y, box.content_h, src_h);
        for (int x = 0; x < box.content_w; x++) {
            int sx = sample_src(x, box.content_w, src_w);
            size_t si = ((size_t)sy * (size_t)src_w + (size_t)sx) * 3;
            size_t di = ((size_t)(y + box.pad_y) * (size_t)dst_w + (size_t)(x + box.pad_x)) * 3;
            dst[di] = src[si];
            dst[di + 1] = src[si + 1];
            dst[di + 2] = src[si + 2];
        }
    }
    return 0;
}

int model_letterbox_gray(const uint8_t *src, int src_w, int src_h,
                         int dst_w, int dst_h, uint8_t pad,
                         uint8_t *dst, Letterbox *plan) {
    Letterbox box;
    if (src == NULL || dst == NULL || model_letterbox_plan(src_w, src_h, dst_w, dst_h, &box) != 0) {
        return -1;
    }
    if (plan) *plan = box;
    size_t n = (size_t)dst_w * (size_t)dst_h;
    memset(dst, pad, n);
    for (int y = 0; y < box.content_h; y++) {
        int sy = sample_src(y, box.content_h, src_h);
        for (int x = 0; x < box.content_w; x++) {
            int sx = sample_src(x, box.content_w, src_w);
            dst[(y + box.pad_y) * dst_w + (x + box.pad_x)] = src[sy * src_w + sx];
        }
    }
    return 0;
}

int model_normalize_nchw(const uint8_t *rgb, int width, int height, int mode, float *out) {
    if (rgb == NULL || out == NULL || !dims_ok(width, height)) return -1;
    if (mode != 0 && mode != 1) return -1;
    static const float mean[3] = {0.485f, 0.456f, 0.406f};
    static const float stdv[3] = {0.229f, 0.224f, 0.225f};
    size_t n = (size_t)width * (size_t)height;
    for (int c = 0; c < 3; c++) {
        for (size_t i = 0; i < n; i++) {
            float v = (float)rgb[i * 3 + (size_t)c] / 255.0f;
            if (mode == 1) v = (v - mean[c]) / stdv[c];
            out[(size_t)c * n + i] = v;
        }
    }
    return 0;
}

static int map_point(const Letterbox *box, double image_x, double image_y, float *ox, float *oy) {
    if (!isfinite(image_x) || !isfinite(image_y)) return -1;
    if (image_x < 0.0 || image_y < 0.0 || image_x > (double)box->src_w || image_y > (double)box->src_h) {
        return -1;
    }
    double mx = (double)box->pad_x + (image_x / (double)box->src_w) * (double)box->content_w;
    double my = (double)box->pad_y + (image_y / (double)box->src_h) * (double)box->content_h;
    *ox = (float)mx;
    *oy = (float)my;
    return 0;
}

int sam_encode_prompts(const Letterbox *box,
                       const double *points_xy, int point_count,
                       const double *boxes_xywh, int box_count,
                       float *coords, float *labels, int cap,
                       int *out_count, int *used_default_box) {
    if (box == NULL || coords == NULL || labels == NULL || out_count == NULL || used_default_box == NULL) {
        return -1;
    }
    if (point_count < 0 || box_count < 0 || cap < 0) return -1;
    if (point_count > 0 && points_xy == NULL) return -1;
    if (box_count > 0 && boxes_xywh == NULL) return -1;
    *used_default_box = 0;
    int needed = point_count + box_count * 2;
    int use_default = 0;
    if (needed == 0) {
        needed = 2;
        use_default = 1;
    }
    if (needed > cap) return -1;

    int written = 0;
    for (int i = 0; i < point_count; i++) {
        float x, y;
        if (map_point(box, points_xy[i * 2], points_xy[i * 2 + 1], &x, &y) != 0) return -1;
        coords[written * 2] = x;
        coords[written * 2 + 1] = y;
        labels[written] = 1.0f;
        written++;
    }
    if (use_default) {
        float x0, y0, x1, y1;
        if (map_point(box, 0, 0, &x0, &y0) != 0) return -1;
        if (map_point(box, (double)box->src_w, (double)box->src_h, &x1, &y1) != 0) return -1;
        coords[0] = x0; coords[1] = y0; labels[0] = 2.0f;
        coords[2] = x1; coords[3] = y1; labels[1] = 3.0f;
        written = 2;
        *used_default_box = 1;
    }
    for (int i = 0; i < box_count; i++) {
        double x = boxes_xywh[i * 4];
        double y = boxes_xywh[i * 4 + 1];
        double w = boxes_xywh[i * 4 + 2];
        double h = boxes_xywh[i * 4 + 3];
        if (!(w > 0.0) || !(h > 0.0)) return -1;
        float x0, y0, x1, y1;
        if (map_point(box, x, y, &x0, &y0) != 0) return -1;
        if (map_point(box, x + w, y + h, &x1, &y1) != 0) return -1;
        coords[written * 2] = x0;
        coords[written * 2 + 1] = y0;
        labels[written] = 2.0f;
        written++;
        coords[written * 2] = x1;
        coords[written * 2 + 1] = y1;
        labels[written] = 3.0f;
        written++;
    }
    *out_count = written;
    return 0;
}

static float sigmoid_stable(float x) {
    if (x > 20.0f) return 1.0f;
    if (x < -20.0f) return 0.0f;
    return 1.0f / (1.0f + expf(-x));
}

int model_mask_threshold(const float *src, int width, int height, float threshold, uint8_t *dst) {
    if (src == NULL || dst == NULL || !isfinite(threshold) || !dims_ok(width, height)) return -1;
    size_t n = (size_t)width * (size_t)height;
    int logits = 0;
    for (size_t i = 0; i < n; i++) {
        if (!isfinite(src[i])) return -1;
        if (src[i] < -0.001f || src[i] > 1.001f) logits = 1;
    }
    for (size_t i = 0; i < n; i++) {
        float p = logits ? sigmoid_stable(src[i]) : src[i];
        if (p < 0.0f) p = 0.0f;
        if (p > 1.0f) p = 1.0f;
        dst[i] = p >= threshold ? 255 : 0;
    }
    return 0;
}

int model_upsample_nearest(const uint8_t *src, int src_w, int src_h,
                           int dst_w, int dst_h, uint8_t *dst) {
    if (src == NULL || dst == NULL || !dims_ok(src_w, src_h) || !dims_ok(dst_w, dst_h)) return -1;
    for (int y = 0; y < dst_h; y++) {
        int sy = sample_src(y, dst_h, src_h);
        for (int x = 0; x < dst_w; x++) {
            int sx = sample_src(x, dst_w, src_w);
            dst[y * dst_w + x] = src[sy * src_w + sx];
        }
    }
    return 0;
}

int model_mask_unletterbox(const uint8_t *model_mask, int model_w, int model_h,
                           const Letterbox *box, int out_w, int out_h, uint8_t *out) {
    if (model_mask == NULL || box == NULL || out == NULL) return -1;
    if (box->dst_w != model_w || box->dst_h != model_h) return -1;
    if (!dims_ok(out_w, out_h) || box->content_w < 1 || box->content_h < 1) return -1;
    uint8_t *crop = (uint8_t *)malloc((size_t)box->content_w * (size_t)box->content_h);
    if (crop == NULL) return -1;
    for (int y = 0; y < box->content_h; y++) {
        const uint8_t *row = model_mask + ((size_t)(y + box->pad_y) * (size_t)model_w + (size_t)box->pad_x);
        memcpy(crop + (size_t)y * (size_t)box->content_w, row, (size_t)box->content_w);
    }
    int rc = model_upsample_nearest(crop, box->content_w, box->content_h, out_w, out_h, out);
    free(crop);
    return rc;
}

int lama_preset_params(const char *name, int *tile, int *overlap) {
    if (name == NULL || tile == NULL || overlap == NULL) return -1;
    if (strcmp(name, "fast") == 0) { *tile = 512; *overlap = 32; return 0; }
    if (strcmp(name, "balanced") == 0) { *tile = 512; *overlap = 64; return 0; }
    if (strcmp(name, "high") == 0) { *tile = 1024; *overlap = 128; return 0; }
    return -1;
}

static int push_unique(int *starts, int *n, int cap, int value) {
    for (int i = 0; i < *n; i++) if (starts[i] == value) return 0;
    if (*n >= cap) return -1;
    starts[(*n)++] = value;
    return 0;
}

int lama_plan_tiles(int image_w, int image_h, int tile, int overlap,
                    LamaTile *out, int cap, int *needed) {
    if (needed == NULL || !dims_ok(image_w, image_h) || tile < 2 || tile > 4096) return -1;
    if (overlap < 0 || overlap >= tile) return -1;
    int stride = tile - overlap;
    int xs[64], ys[64];
    int nx = 0, ny = 0;
    if (image_w <= tile) {
        if (push_unique(xs, &nx, 64, 0) != 0) return -1;
    } else {
        for (int x = 0; x < image_w; x += stride) {
            int start = x;
            if (start + tile > image_w) start = image_w - tile;
            if (push_unique(xs, &nx, 64, start) != 0) return -1;
            if (start == image_w - tile) break;
        }
    }
    if (image_h <= tile) {
        if (push_unique(ys, &ny, 64, 0) != 0) return -1;
    } else {
        for (int y = 0; y < image_h; y += stride) {
            int start = y;
            if (start + tile > image_h) start = image_h - tile;
            if (push_unique(ys, &ny, 64, start) != 0) return -1;
            if (start == image_h - tile) break;
        }
    }
    int count = nx * ny;
    *needed = count;
    if (out == NULL || cap < count) return -1;
    int k = 0;
    for (int iy = 0; iy < ny; iy++) {
        for (int ix = 0; ix < nx; ix++) {
            LamaTile t;
            t.x = xs[ix];
            t.y = ys[iy];
            int avail_w = image_w - t.x;
            int avail_h = image_h - t.y;
            t.width = avail_w < tile ? avail_w : tile;
            t.height = avail_h < tile ? avail_h : tile;
            t.pad_right = tile - t.width;
            t.pad_bottom = tile - t.height;
            out[k++] = t;
        }
    }
    return 0;
}

int lama_extract_tile(const uint8_t *rgb, const uint8_t *mask,
                      int image_w, int image_h, const LamaTile *tile, int tile_size,
                      uint8_t *tile_rgb, uint8_t *tile_mask) {
    if (rgb == NULL || mask == NULL || tile == NULL || tile_rgb == NULL || tile_mask == NULL) return -1;
    if (!dims_ok(image_w, image_h) || tile_size < 1) return -1;
    if (tile->x < 0 || tile->y < 0 || tile->width < 1 || tile->height < 1) return -1;
    if (tile->x + tile->width > image_w || tile->y + tile->height > image_h) return -1;
    if (tile->width + tile->pad_right != tile_size || tile->height + tile->pad_bottom != tile_size) return -1;
    memset(tile_rgb, 0, (size_t)tile_size * (size_t)tile_size * 3);
    memset(tile_mask, 0, (size_t)tile_size * (size_t)tile_size);
    for (int y = 0; y < tile->height; y++) {
        for (int x = 0; x < tile->width; x++) {
            size_t si = ((size_t)(tile->y + y) * (size_t)image_w + (size_t)(tile->x + x));
            size_t di = ((size_t)y * (size_t)tile_size + (size_t)x);
            tile_rgb[di * 3] = rgb[si * 3];
            tile_rgb[di * 3 + 1] = rgb[si * 3 + 1];
            tile_rgb[di * 3 + 2] = rgb[si * 3 + 2];
            tile_mask[di] = mask[si];
        }
    }
    return 0;
}

int lama_blend_begin(float *acc_rgb, float *weight, int pixel_count) {
    if (acc_rgb == NULL || weight == NULL || pixel_count <= 0) return -1;
    memset(acc_rgb, 0, (size_t)pixel_count * 3 * sizeof(float));
    memset(weight, 0, (size_t)pixel_count * sizeof(float));
    return 0;
}

int lama_blend_add(float *acc_rgb, float *weight, int image_w, int image_h,
                   const LamaTile *tile, const uint8_t *tile_rgb, int tile_size) {
    if (acc_rgb == NULL || weight == NULL || tile == NULL || tile_rgb == NULL) return -1;
    if (!dims_ok(image_w, image_h) || tile_size < 1) return -1;
    if (tile->width < 1 || tile->height < 1) return -1;
    if (tile->x < 0 || tile->y < 0 || tile->x + tile->width > image_w || tile->y + tile->height > image_h) {
        return -1;
    }
    for (int y = 0; y < tile->height; y++) {
        for (int x = 0; x < tile->width; x++) {
            size_t di = ((size_t)(tile->y + y) * (size_t)image_w + (size_t)(tile->x + x));
            size_t si = ((size_t)y * (size_t)tile_size + (size_t)x);
            acc_rgb[di * 3] += (float)tile_rgb[si * 3];
            acc_rgb[di * 3 + 1] += (float)tile_rgb[si * 3 + 1];
            acc_rgb[di * 3 + 2] += (float)tile_rgb[si * 3 + 2];
            weight[di] += 1.0f;
        }
    }
    return 0;
}

int lama_blend_finish(const float *acc_rgb, const float *weight, int pixel_count, uint8_t *out_rgb) {
    if (acc_rgb == NULL || weight == NULL || out_rgb == NULL || pixel_count <= 0) return -1;
    for (int i = 0; i < pixel_count; i++) {
        float w = weight[i];
        if (!(w > 0.0f)) {
            out_rgb[i * 3] = 0;
            out_rgb[i * 3 + 1] = 0;
            out_rgb[i * 3 + 2] = 0;
            continue;
        }
        for (int c = 0; c < 3; c++) {
            float v = acc_rgb[i * 3 + c] / w;
            if (v < 0.0f) v = 0.0f;
            if (v > 255.0f) v = 255.0f;
            out_rgb[i * 3 + c] = (uint8_t)(v + 0.5f);
        }
    }
    return 0;
}

int model_http_payload_ok(int http_status, long long nbytes, const uint8_t *head, size_t head_len) {
    if (http_status != 200) return -1;
    if (nbytes <= 0) return -2;
    size_t i = 0;
    if (head != NULL) {
        while (i < head_len && (head[i] == ' ' || head[i] == '\n' || head[i] == '\r' || head[i] == '\t')) i++;
        if (i < head_len && (head[i] == '<' || head[i] == '{')) return -3;
    }
    return 0;
}
