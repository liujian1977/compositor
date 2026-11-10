// PoseLayout.c — Multi-person pose layout and JSON. No CoreML, no Vision.

#include "PoseLayout.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *kCocoNames[17] = {
    "nose", "left_eye", "right_eye", "left_ear", "right_ear",
    "left_shoulder", "right_shoulder", "left_elbow", "right_elbow",
    "left_wrist", "right_wrist", "left_hip", "right_hip",
    "left_knee", "right_knee", "left_ankle", "right_ankle"
};

static int prefer_person(int a, int b, const double *score, const double *y, const double *x) {
    if (score[a] > score[b]) return 1;
    if (score[a] < score[b]) return 0;
    if (y[a] < y[b]) return 1;
    if (y[a] > y[b]) return 0;
    if (x[a] < x[b]) return 1;
    if (x[a] > x[b]) return 0;
    return a < b;
}

int pose_sort_order(const double *x, const double *y, const double *width, const double *height,
                    const double *score, int count, int *order) {
    if (count < 0 || count > 10000) return -1;
    if (count == 0) return 0;
    if (x == NULL || y == NULL || width == NULL || height == NULL || score == NULL || order == NULL) {
        return -1;
    }
    for (int i = 0; i < count; i++) {
        if (!isfinite(x[i]) || !isfinite(y[i]) || !isfinite(width[i]) || !isfinite(height[i]) ||
            !isfinite(score[i]) || !(width[i] > 0.0) || !(height[i] > 0.0)) {
            return -1;
        }
        order[i] = i;
    }
    for (int i = 1; i < count; i++) {
        int key = order[i];
        int j = i - 1;
        while (j >= 0 && prefer_person(key, order[j], score, y, x)) {
            order[j + 1] = order[j];
            j--;
        }
        order[j + 1] = key;
    }
    return 0;
}

int pose_fit(double box_x, double box_y, double box_w, double box_h,
             double padding, double canvas_w, double canvas_h,
             double *scale, double *center_x, double *center_y) {
    if (scale == NULL || center_x == NULL || center_y == NULL) return -1;
    if (!isfinite(box_x) || !isfinite(box_y) || !isfinite(box_w) || !isfinite(box_h) ||
        !isfinite(padding) || !isfinite(canvas_w) || !isfinite(canvas_h)) {
        return -1;
    }
    if (!(box_w > 0.0) || !(box_h > 0.0) || !(padding > 0.0) ||
        !(canvas_w > 0.0) || !(canvas_h > 0.0)) {
        return -1;
    }
    double bbox_w = box_w * padding;
    double bbox_h = box_h * padding;
    double aspect = canvas_w / canvas_h;
    double fixed_w = bbox_w > bbox_h * aspect ? bbox_w : bbox_h * aspect;
    if (!(fixed_w > 0.0) || !isfinite(fixed_w)) return -1;
    *scale = canvas_w / fixed_w;
    *center_x = box_x + box_w * 0.5;
    *center_y = box_y + box_h * 0.5;
    if (!isfinite(*scale)) return -1;
    return 0;
}

int pose_unmap(double canvas_x, double canvas_y,
               double scale, double center_x, double center_y,
               double canvas_w, double canvas_h,
               double *out_x, double *out_y) {
    if (out_x == NULL || out_y == NULL) return -1;
    if (!isfinite(canvas_x) || !isfinite(canvas_y) || !isfinite(scale) ||
        !isfinite(center_x) || !isfinite(center_y) || !isfinite(canvas_w) || !isfinite(canvas_h)) {
        return -1;
    }
    if (!(scale > 0.0) || !(canvas_w > 0.0) || !(canvas_h > 0.0)) return -1;
    *out_x = (canvas_x - canvas_w * 0.5) / scale + center_x;
    *out_y = (canvas_y - canvas_h * 0.5) / scale + center_y;
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

static void jb_number(JsonBuf *b, double value) {
    if (!isfinite(value) || value > 1.0e12 || value < -1.0e12) {
        b->error = 1;
        return;
    }
    int neg = value < 0.0;
    double mag = neg ? -value : value;
    long long ticks = (long long)(mag * 1000000.0 + 0.5);
    long long ip = ticks / 1000000LL;
    int frac = (int)(ticks % 1000000LL);
    char tmp[64];
    int wrote;
    if (frac == 0) {
        wrote = snprintf(tmp, sizeof tmp, "%s%lld", neg ? "-" : "", ip);
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
        wrote = snprintf(tmp, sizeof tmp, "%s%lld.%s", neg ? "-" : "", ip, fracbuf);
    }
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) {
        b->error = 1;
        return;
    }
    jb_puts(b, tmp);
}

static void jb_name(JsonBuf *b, int id) {
    if (id >= 0 && id < 17) {
        jb_puts(b, kCocoNames[id]);
        return;
    }
    char tmp[32];
    int wrote = snprintf(tmp, sizeof tmp, "keypoint_%d", id);
    if (wrote < 0 || (size_t)wrote >= sizeof tmp) {
        b->error = 1;
        return;
    }
    jb_puts(b, tmp);
}

void pose_people_json_free(char *json) {
    free(json);
}

int pose_people_json(int image_w, int image_h,
                     const double *box_x, const double *box_y,
                     const double *box_w, const double *box_h,
                     const double *score, const int *kpt_counts, int person_count,
                     const int *kpt_ids, const double *kpt_x, const double *kpt_y,
                     const double *kpt_conf, char **out_json) {
    if (out_json == NULL) return -1;
    *out_json = NULL;
    if (image_w <= 0 || image_h <= 0 || person_count < 0 || person_count > 10000) return -1;
    if (person_count > 0 && (box_x == NULL || box_y == NULL || box_w == NULL || box_h == NULL ||
                             score == NULL || kpt_counts == NULL)) {
        return -1;
    }

    int kpt_total = 0;
    for (int i = 0; i < person_count; i++) {
        if (kpt_counts[i] < 0) return -1;
        if (kpt_total > 1000000 - kpt_counts[i]) return -1;
        kpt_total += kpt_counts[i];
        if (!isfinite(box_x[i]) || !isfinite(box_y[i]) || !isfinite(box_w[i]) || !isfinite(box_h[i]) ||
            !isfinite(score[i]) || !(box_w[i] > 0.0) || !(box_h[i] > 0.0)) {
            return -1;
        }
    }
    if (kpt_total > 0 && (kpt_ids == NULL || kpt_x == NULL || kpt_y == NULL || kpt_conf == NULL)) {
        return -1;
    }
    for (int k = 0; k < kpt_total; k++) {
        if (!isfinite(kpt_x[k]) || !isfinite(kpt_y[k]) || !isfinite(kpt_conf[k])) return -1;
    }

    size_t cap = 160u + (size_t)person_count * 192u + (size_t)kpt_total * 128u + 1u;
    char *buf = (char *)malloc(cap);
    if (buf == NULL) return -1;
    buf[0] = '\0';
    JsonBuf b = {buf, 0, cap, 0};

    jb_puts(&b, "{\"width\":");
    jb_int(&b, image_w);
    jb_puts(&b, ",\"height\":");
    jb_int(&b, image_h);
    jb_puts(&b, ",\"person_count\":");
    jb_int(&b, person_count);
    jb_puts(&b, ",\"people\":[");

    int kpt_cursor = 0;
    for (int i = 0; i < person_count; i++) {
        if (i > 0) jb_puts(&b, ",");
        jb_puts(&b, "{\"index\":");
        jb_int(&b, i);
        jb_puts(&b, ",\"score\":");
        jb_number(&b, score[i]);
        jb_puts(&b, ",\"bbox\":{\"x\":");
        jb_number(&b, box_x[i]);
        jb_puts(&b, ",\"y\":");
        jb_number(&b, box_y[i]);
        jb_puts(&b, ",\"width\":");
        jb_number(&b, box_w[i]);
        jb_puts(&b, ",\"height\":");
        jb_number(&b, box_h[i]);
        jb_puts(&b, "},\"keypoints\":[");
        for (int k = 0; k < kpt_counts[i]; k++) {
            int at = kpt_cursor + k;
            if (k > 0) jb_puts(&b, ",");
            jb_puts(&b, "{\"id\":");
            jb_int(&b, kpt_ids[at]);
            jb_puts(&b, ",\"name\":\"");
            jb_name(&b, kpt_ids[at]);
            jb_puts(&b, "\",\"x\":");
            jb_number(&b, kpt_x[at]);
            jb_puts(&b, ",\"y\":");
            jb_number(&b, kpt_y[at]);
            jb_puts(&b, ",\"confidence\":");
            jb_number(&b, kpt_conf[at]);
            jb_puts(&b, "}");
        }
        kpt_cursor += kpt_counts[i];
        jb_puts(&b, "]}");
    }
    jb_puts(&b, "]}");

    if (b.error || b.len > (size_t)INT32_MAX) {
        free(buf);
        return -1;
    }
    *out_json = buf;
    return 0;
}
