// MaskOps.c — Cutout, mask arithmetic, and mask inspection.

#include "MaskOps.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int pixel_count(int width, int height, size_t *out_count) {
    if (width <= 0 || height <= 0 || out_count == NULL) return -1;
    size_t w = (size_t)width;
    size_t h = (size_t)height;
    if (w > SIZE_MAX / h) return -1;
    size_t n = w * h;
    /* Indices and component fields are ints. RGBA byte length must fit size_t. */
    if (n > (size_t)INT_MAX) return -1;
    if (n > SIZE_MAX / 4) return -1;
    *out_count = n;
    return 0;
}

int cutout_apply_mask(const uint8_t *rgb, const uint8_t *mask,
                      int width, int height, uint8_t *out_rgba) {
    size_t n = 0;
    if (rgb == NULL || mask == NULL || out_rgba == NULL) return -1;
    if (pixel_count(width, height, &n) != 0) return -1;

    for (size_t i = 0; i < n; i++) {
        out_rgba[i * 4] = rgb[i * 3];
        out_rgba[i * 4 + 1] = rgb[i * 3 + 1];
        out_rgba[i * 4 + 2] = rgb[i * 3 + 2];
        out_rgba[i * 4 + 3] = mask[i];
    }
    return 0;
}

int mask_invert(const uint8_t *src, int width, int height, uint8_t *dst) {
    size_t n = 0;
    if (src == NULL || dst == NULL) return -1;
    if (pixel_count(width, height, &n) != 0) return -1;
    for (size_t i = 0; i < n; i++) dst[i] = (uint8_t)(255u - src[i]);
    return 0;
}

int mask_union(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst) {
    size_t n = 0;
    if (a == NULL || b == NULL || dst == NULL) return -1;
    if (pixel_count(width, height, &n) != 0) return -1;
    for (size_t i = 0; i < n; i++) dst[i] = a[i] > b[i] ? a[i] : b[i];
    return 0;
}

int mask_intersect(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst) {
    size_t n = 0;
    if (a == NULL || b == NULL || dst == NULL) return -1;
    if (pixel_count(width, height, &n) != 0) return -1;
    for (size_t i = 0; i < n; i++) dst[i] = a[i] < b[i] ? a[i] : b[i];
    return 0;
}

int mask_subtract(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst) {
    size_t n = 0;
    if (a == NULL || b == NULL || dst == NULL) return -1;
    if (pixel_count(width, height, &n) != 0) return -1;
    for (size_t i = 0; i < n; i++) dst[i] = a[i] >= b[i] ? (uint8_t)(a[i] - b[i]) : 0;
    return 0;
}

void mask_inspect_free(MaskInspectResult *result) {
    if (result == NULL) return;
    free(result->components);
    result->components = NULL;
    result->component_count = 0;
}

int mask_inspect(const uint8_t *mask, int width, int height, MaskInspectResult *out) {
    if (out == NULL) return -1;
    memset(out, 0, sizeof *out);

    size_t n = 0;
    if (mask == NULL || pixel_count(width, height, &n) != 0) return -1;
    if (n > SIZE_MAX / sizeof(size_t)) return -1;

    size_t *queue = (size_t *)malloc(n * sizeof *queue);
    int *labels = (int *)calloc(n, sizeof *labels);
    MaskComponent *comps = NULL;
    int comp_cap = 0;
    int comp_count = 0;
    int failed = 0;

    if (queue == NULL || labels == NULL) {
        free(queue);
        free(labels);
        return -1;
    }

    const int threshold = MASK_INSPECT_FOREGROUND_THRESHOLD;
    static const int dx[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    static const int dy[8] = {-1, -1, -1, 0, 0, 1, 1, 1};

    int has_bb = 0;
    int bb_minx = 0, bb_miny = 0, bb_maxx = 0, bb_maxy = 0;
    unsigned long long coverage_sum = 0;

    for (size_t i = 0; i < n; i++) {
        coverage_sum += mask[i];
        if (mask[i] < threshold || labels[i] != 0) continue;

        int minx = width, miny = height, maxx = 0, maxy = 0;
        long long sum_x = 0, sum_y = 0;
        int area = 0;
        size_t qh = 0, qt = 0;
        labels[i] = comp_count + 1;
        queue[qt++] = i;

        while (qh < qt) {
            size_t p = queue[qh++];
            int y = (int)(p / (size_t)width);
            int x = (int)(p - (size_t)y * (size_t)width);
            area++;
            sum_x += x;
            sum_y += y;
            if (x < minx) minx = x;
            if (y < miny) miny = y;
            if (x > maxx) maxx = x;
            if (y > maxy) maxy = y;

            for (int k = 0; k < 8; k++) {
                int nx = x + dx[k];
                int ny = y + dy[k];
                if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
                size_t ni = (size_t)ny * (size_t)width + (size_t)nx;
                if (mask[ni] < threshold || labels[ni] != 0) continue;
                labels[ni] = comp_count + 1;
                queue[qt++] = ni;
            }
        }

        if (comp_count >= comp_cap) {
            int next = comp_cap == 0 ? 4 : comp_cap * 2;
            if (next < comp_cap) {
                failed = 1;
                break;
            }
            MaskComponent *grown = (MaskComponent *)realloc(comps, (size_t)next * sizeof *comps);
            if (grown == NULL) {
                failed = 1;
                break;
            }
            comps = grown;
            comp_cap = next;
        }

        MaskComponent *c = &comps[comp_count];
        c->index = comp_count;
        c->area = area;
        c->center_x = (double)sum_x / (double)area;
        c->center_y = (double)sum_y / (double)area;
        c->bounds.x = minx;
        c->bounds.y = miny;
        c->bounds.width = maxx - minx + 1;
        c->bounds.height = maxy - miny + 1;
        comp_count++;

        if (!has_bb) {
            has_bb = 1;
            bb_minx = minx;
            bb_miny = miny;
            bb_maxx = maxx;
            bb_maxy = maxy;
        } else {
            if (minx < bb_minx) bb_minx = minx;
            if (miny < bb_miny) bb_miny = miny;
            if (maxx > bb_maxx) bb_maxx = maxx;
            if (maxy > bb_maxy) bb_maxy = maxy;
        }
    }

    free(queue);
    free(labels);

    if (failed) {
        free(comps);
        memset(out, 0, sizeof *out);
        return -1;
    }

    double coverage = (double)coverage_sum / (255.0 * (double)n);
    if (coverage < 0.0) coverage = 0.0;
    if (coverage > 1.0) coverage = 1.0;

    out->width = width;
    out->height = height;
    out->coverage = coverage;
    out->has_bounding_box = has_bb;
    if (has_bb) {
        out->bounding_box.x = bb_minx;
        out->bounding_box.y = bb_miny;
        out->bounding_box.width = bb_maxx - bb_minx + 1;
        out->bounding_box.height = bb_maxy - bb_miny + 1;
    }
    out->component_count = comp_count;
    out->components = comps;
    out->foreground_threshold = threshold;
    out->connectivity = MASK_INSPECT_CONNECTIVITY;
    return 0;
}

typedef struct JsonBuf {
    char *data;
    size_t len;
    size_t cap;
    int error;
} JsonBuf;

static void jb_puts(JsonBuf *b, const char *s) {
    if (b->error || s == NULL) return;
    size_t n = strlen(s);
    if (b->len >= b->cap || n > b->cap - b->len - 1) {
        b->error = 1;
        return;
    }
    memcpy(b->data + b->len, s, n);
    b->len += n;
    b->data[b->len] = '\0';
}

static void jb_int(JsonBuf *b, int v) {
    char tmp[16];
    int wrote = snprintf(tmp, sizeof tmp, "%d", v);
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) {
        b->error = 1;
        return;
    }
    jb_puts(b, tmp);
}

/* Up to 6 decimal places, half away from zero for non-negative values, trailing zeros stripped. */
static void jb_number(JsonBuf *b, double value) {
    if (!(value >= 0.0) || value > 1.0e12) {
        b->error = 1;
        return;
    }
    long long ticks = (long long)(value * 1000000.0 + 0.5);
    long long ip = ticks / 1000000LL;
    int frac = (int)(ticks % 1000000LL);
    char tmp[64];
    int wrote;
    if (frac == 0) {
        wrote = snprintf(tmp, sizeof tmp, "%lld", ip);
    } else {
        char fracbuf[8];
        int frac_wrote = snprintf(fracbuf, sizeof fracbuf, "%06d", frac);
        if (frac_wrote < 0 || (size_t)frac_wrote >= sizeof fracbuf) {
            b->error = 1;
            return;
        }
        int end = 5;
        while (end > 0 && fracbuf[end] == '0') end--;
        fracbuf[end + 1] = '\0';
        wrote = snprintf(tmp, sizeof tmp, "%lld.%s", ip, fracbuf);
    }
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) {
        b->error = 1;
        return;
    }
    jb_puts(b, tmp);
}

static void jb_rect(JsonBuf *b, MaskRect r) {
    jb_puts(b, "{\"x\":");
    jb_int(b, r.x);
    jb_puts(b, ",\"y\":");
    jb_int(b, r.y);
    jb_puts(b, ",\"width\":");
    jb_int(b, r.width);
    jb_puts(b, ",\"height\":");
    jb_int(b, r.height);
    jb_puts(b, "}");
}

int mask_inspect_json(const MaskInspectResult *result, char *buf, size_t buf_size) {
    if (result == NULL || buf == NULL || buf_size == 0) return -1;
    if (result->component_count < 0) return -1;
    if (result->component_count > 0 && result->components == NULL) return -1;

    buf[0] = '\0';
    JsonBuf b = {buf, 0, buf_size, 0};

    jb_puts(&b, "{\"width\":");
    jb_int(&b, result->width);
    jb_puts(&b, ",\"height\":");
    jb_int(&b, result->height);
    jb_puts(&b, ",\"coverage\":");
    jb_number(&b, result->coverage);
    jb_puts(&b, ",\"foreground_threshold\":");
    jb_int(&b, result->foreground_threshold);
    jb_puts(&b, ",\"connectivity\":");
    jb_int(&b, result->connectivity);
    jb_puts(&b, ",\"bounding_box\":");
    if (result->has_bounding_box) jb_rect(&b, result->bounding_box);
    else jb_puts(&b, "null");
    jb_puts(&b, ",\"component_count\":");
    jb_int(&b, result->component_count);
    jb_puts(&b, ",\"components\":[");
    for (int i = 0; i < result->component_count; i++) {
        const MaskComponent *c = &result->components[i];
        if (i > 0) jb_puts(&b, ",");
        jb_puts(&b, "{\"index\":");
        jb_int(&b, c->index);
        jb_puts(&b, ",\"area\":");
        jb_int(&b, c->area);
        jb_puts(&b, ",\"center\":{\"x\":");
        jb_number(&b, c->center_x);
        jb_puts(&b, ",\"y\":");
        jb_number(&b, c->center_y);
        jb_puts(&b, "}}");
    }
    jb_puts(&b, "]}");

    if (b.error || b.len > (size_t)INT_MAX) return -1;
    return (int)b.len;
}

int mask_inspect_format_json(const uint8_t *mask, int width, int height, char **out_json) {
    if (out_json == NULL) return -1;
    *out_json = NULL;

    MaskInspectResult result;
    if (mask_inspect(mask, width, height, &result) != 0) return -1;

    size_t cap = 384u + (size_t)result.component_count * 160u + 1u;
    char *buf = (char *)malloc(cap);
    if (buf == NULL) {
        mask_inspect_free(&result);
        return -1;
    }
    int n = mask_inspect_json(&result, buf, cap);
    mask_inspect_free(&result);
    if (n < 0) {
        free(buf);
        return -1;
    }
    *out_json = buf;
    return 0;
}

void mask_inspect_json_free(char *json) {
    free(json);
}
