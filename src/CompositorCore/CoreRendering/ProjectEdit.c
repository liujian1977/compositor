// ProjectEdit.c — Layer edits and flatten blending. No file IO.

#include "ProjectEdit.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int project_blend_code(const char *name) {
    if (name == NULL) return -1;
    if (strcmp(name, "Normal") == 0) return 0;
    if (strcmp(name, "Multiply") == 0) return 1;
    if (strcmp(name, "Screen") == 0) return 2;
    return -1;
}

const char *project_blend_name(int code) {
    if (code == 0) return "Normal";
    if (code == 1) return "Multiply";
    if (code == 2) return "Screen";
    return NULL;
}

static int index_ok(int count, int index) {
    return count > 0 && index >= 0 && index < count;
}

int project_set_opacity(ProjectLayerState *layers, int count, int index, double opacity) {
    if (layers == NULL || !index_ok(count, index)) return -1;
    if (!isfinite(opacity) || opacity < 0.0 || opacity > 1.0) return -1;
    layers[index].opacity = opacity;
    return 0;
}

int project_set_blend(ProjectLayerState *layers, int count, int index, const char *name) {
    if (layers == NULL || !index_ok(count, index)) return -1;
    int code = project_blend_code(name);
    if (code < 0) return -1;
    layers[index].blend = code;
    return 0;
}

int project_set_transform(ProjectLayerState *layers, int count, int index,
                          double origin_x, double origin_y, double size_w, double size_h,
                          double rotation, int flip_x, int flip_y) {
    if (layers == NULL || !index_ok(count, index)) return -1;
    if (!isfinite(origin_x) || !isfinite(origin_y) || !isfinite(size_w) || !isfinite(size_h) ||
        !isfinite(rotation)) {
        return -1;
    }
    if (!(size_w > 0.0) || !(size_h > 0.0) || size_w > 30000.0 || size_h > 30000.0) return -1;
    if (origin_x < -100000.0 || origin_x > 100000.0 || origin_y < -100000.0 || origin_y > 100000.0) {
        return -1;
    }
    if ((flip_x != 0 && flip_x != 1) || (flip_y != 0 && flip_y != 1)) return -1;
    ProjectLayerState *layer = &layers[index];
    layer->origin_x = origin_x;
    layer->origin_y = origin_y;
    layer->size_w = size_w;
    layer->size_h = size_h;
    layer->rotation = rotation;
    layer->flip_x = flip_x;
    layer->flip_y = flip_y;
    return 0;
}

int project_remove_layer(ProjectLayerState *layers, int *count, int index) {
    if (layers == NULL || count == NULL || !index_ok(*count, index)) return -1;
    int n = *count;
    memmove(&layers[index], &layers[index + 1], (size_t)(n - index - 1) * sizeof(ProjectLayerState));
    *count = n - 1;
    return 0;
}

int project_relative_path_ok(const char *path) {
    if (path == NULL || path[0] == '\0') return -1;
    if (path[0] == '/' || path[0] == '\\') return -1;
    if (strchr(path, '\\') != NULL) return -1;
    const char *p = path;
    while (*p) {
        const char *slash = strchr(p, '/');
        size_t len = slash ? (size_t)(slash - p) : strlen(p);
        if (len == 0) return -1;
        if ((len == 1 && p[0] == '.') || (len == 2 && p[0] == '.' && p[1] == '.')) return -1;
        if (!slash) break;
        p = slash + 1;
        if (*p == '\0') return -1;
    }
    return 0;
}

static float channel_blend(float src, float dst, int blend) {
    if (blend == 1) return src * dst / 255.0f;
    if (blend == 2) return 255.0f - ((255.0f - src) * (255.0f - dst) / 255.0f);
    return src;
}

int project_flatten_over(uint8_t *canvas_rgb, uint8_t *canvas_a,
                         const uint8_t *layer_rgb, const uint8_t *layer_a,
                         int width, int height, double opacity, int blend) {
    if (canvas_rgb == NULL || canvas_a == NULL || layer_rgb == NULL || layer_a == NULL) return -1;
    if (width <= 0 || height <= 0 || (size_t)width > SIZE_MAX / (size_t)height) return -1;
    if (!isfinite(opacity) || opacity < 0.0 || opacity > 1.0) return -1;
    if (blend < 0 || blend > 2) return -1;
    size_t n = (size_t)width * (size_t)height;
    for (size_t i = 0; i < n; i++) {
        float sa = ((float)layer_a[i] / 255.0f) * (float)opacity;
        if (sa < 0.0f) sa = 0.0f;
        if (sa > 1.0f) sa = 1.0f;
        float da = (float)canvas_a[i] / 255.0f;
        float out_a = sa + da * (1.0f - sa);
        for (int c = 0; c < 3; c++) {
            float s = layer_rgb[i * 3 + (size_t)c];
            float d = canvas_rgb[i * 3 + (size_t)c];
            float mixed = channel_blend(s, d, blend);
            float pre = mixed * sa + d * da * (1.0f - sa);
            float straight = out_a > 0.0f ? pre / out_a : 0.0f;
            if (straight < 0.0f) straight = 0.0f;
            if (straight > 255.0f) straight = 255.0f;
            canvas_rgb[i * 3 + (size_t)c] = (uint8_t)(straight + 0.5f);
        }
        float a_byte = out_a * 255.0f;
        if (a_byte < 0.0f) a_byte = 0.0f;
        if (a_byte > 255.0f) a_byte = 255.0f;
        canvas_a[i] = (uint8_t)(a_byte + 0.5f);
    }
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
    if (b->len >= b->cap || n > b->cap - b->len - 1) { b->error = 1; return; }
    memcpy(b->data + b->len, s, n);
    b->len += n;
    b->data[b->len] = '\0';
}

static void jb_int(JsonBuf *b, int v) {
    char tmp[16];
    int wrote = snprintf(tmp, sizeof tmp, "%d", v);
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) { b->error = 1; return; }
    jb_puts(b, tmp);
}

static void jb_num(JsonBuf *b, double value) {
    if (!isfinite(value) || value > 1.0e12 || value < -1.0e12) { b->error = 1; return; }
    int neg = value < 0.0;
    double mag = neg ? -value : value;
    long long ticks = (long long)(mag * 1000000.0 + 0.5);
    long long ip = ticks / 1000000LL;
    int frac = (int)(ticks % 1000000LL);
    char tmp[64];
    int wrote;
    if (frac == 0) wrote = snprintf(tmp, sizeof tmp, "%s%lld", neg ? "-" : "", ip);
    else {
        char fracbuf[8];
        int fw = snprintf(fracbuf, sizeof fracbuf, "%06d", frac);
        if (fw < 0 || (size_t)fw >= sizeof fracbuf) { b->error = 1; return; }
        int end = 5;
        while (end > 0 && fracbuf[end] == '0') end--;
        fracbuf[end + 1] = '\0';
        wrote = snprintf(tmp, sizeof tmp, "%s%lld.%s", neg ? "-" : "", ip, fracbuf);
    }
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) { b->error = 1; return; }
    jb_puts(b, tmp);
}

static void jb_string(JsonBuf *b, const char *s) {
    jb_puts(b, "\"");
    if (s == NULL) { b->error = 1; return; }
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        char tmp[8];
        if (*p == '"' || *p == '\\') {
            tmp[0] = '\\'; tmp[1] = (char)*p; tmp[2] = 0;
            jb_puts(b, tmp);
        } else if (*p < 0x20) {
            snprintf(tmp, sizeof tmp, "\\u%04x", *p);
            jb_puts(b, tmp);
        } else {
            tmp[0] = (char)*p; tmp[1] = 0;
            jb_puts(b, tmp);
        }
    }
    jb_puts(b, "\"");
}

void project_list_json_free(char *json) { free(json); }

int project_list_json(int canvas_w, int canvas_h,
                      const char **ids, const char **names,
                      const ProjectLayerState *layers, int count,
                      char **out_json) {
    if (out_json == NULL) return -1;
    *out_json = NULL;
    if (canvas_w <= 0 || canvas_h <= 0 || count < 0 || count > 10000) return -1;
    if (count > 0 && (ids == NULL || names == NULL || layers == NULL)) return -1;
    for (int i = 0; i < count; i++) {
        if (ids[i] == NULL || names[i] == NULL) return -1;
        if (project_blend_name(layers[i].blend) == NULL) return -1;
    }
    size_t cap = 128u + (size_t)count * 256u;
    char *buf = (char *)malloc(cap);
    if (buf == NULL) return -1;
    buf[0] = '\0';
    JsonBuf b = {buf, 0, cap, 0};
    jb_puts(&b, "{\"width\":");
    jb_int(&b, canvas_w);
    jb_puts(&b, ",\"height\":");
    jb_int(&b, canvas_h);
    jb_puts(&b, ",\"layer_count\":");
    jb_int(&b, count);
    jb_puts(&b, ",\"layers\":[");
    for (int i = 0; i < count; i++) {
        if (i) jb_puts(&b, ",");
        const ProjectLayerState *L = &layers[i];
        jb_puts(&b, "{\"index\":");
        jb_int(&b, i);
        jb_puts(&b, ",\"id\":");
        jb_string(&b, ids[i]);
        jb_puts(&b, ",\"name\":");
        jb_string(&b, names[i]);
        jb_puts(&b, ",\"opacity\":");
        jb_num(&b, L->opacity);
        jb_puts(&b, ",\"blend\":");
        jb_string(&b, project_blend_name(L->blend));
        jb_puts(&b, ",\"origin\":[");
        jb_num(&b, L->origin_x);
        jb_puts(&b, ",");
        jb_num(&b, L->origin_y);
        jb_puts(&b, "],\"size\":[");
        jb_num(&b, L->size_w);
        jb_puts(&b, ",");
        jb_num(&b, L->size_h);
        jb_puts(&b, "],\"rotation\":");
        jb_num(&b, L->rotation);
        jb_puts(&b, ",\"flip_x\":");
        jb_puts(&b, L->flip_x ? "true" : "false");
        jb_puts(&b, ",\"flip_y\":");
        jb_puts(&b, L->flip_y ? "true" : "false");
        jb_puts(&b, "}");
    }
    jb_puts(&b, "]}");
    if (b.error) { free(buf); return -1; }
    *out_json = buf;
    return 0;
}
