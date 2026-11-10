// LayerPlacement.c — Inverse-mapped layer rasterizer. No CoreGraphics.

#include "LayerPlacement.h"

#include <math.h>
#include <stdint.h>
#include <stdlib.h>

static int pixel_count(int width, int height, size_t *out_count) {
    if (width <= 0 || height <= 0 || out_count == NULL) return -1;
    size_t w = (size_t)width;
    size_t h = (size_t)height;
    if (w > SIZE_MAX / h) return -1;
    size_t n = w * h;
    if (n > (size_t)INT32_MAX) return -1;
    if (n > SIZE_MAX / 4) return -1;
    *out_count = n;
    return 0;
}

static int finite_pair(double a, double b) {
    return isfinite(a) && isfinite(b);
}

static uint8_t u8_from_double(double v) {
    if (v <= 0.0) return 0;
    if (v >= 255.0) return 255;
    return (uint8_t)(v + 0.5);
}

static void sample_nearest(const uint8_t *rgb, const uint8_t *alpha,
                           int w, int h, double u, double v,
                           double *r, double *g, double *b, double *a) {
    if (!(u >= 0.0) || !(v >= 0.0) || !(u < (double)w) || !(v < (double)h)) {
        *r = *g = *b = *a = 0.0;
        return;
    }
    int x = (int)floor(u);
    int y = (int)floor(v);
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= w) x = w - 1;
    if (y >= h) y = h - 1;
    size_t i = (size_t)y * (size_t)w + (size_t)x;
    *r = rgb[i * 3];
    *g = rgb[i * 3 + 1];
    *b = rgb[i * 3 + 2];
    *a = alpha ? (double)alpha[i] : 255.0;
}

static double texel(const uint8_t *rgb, const uint8_t *alpha, int w, int h,
                     int x, int y, int channel, double *covered) {
    if (x < 0 || y < 0 || x >= w || y >= h) {
        *covered = 0.0;
        return 0.0;
    }
    *covered = 1.0;
    size_t i = (size_t)y * (size_t)w + (size_t)x;
    if (channel == 3) return alpha ? (double)alpha[i] : 255.0;
    return (double)rgb[i * 3 + channel];
}

static void sample_bilinear(const uint8_t *rgb, const uint8_t *alpha,
                            int w, int h, double u, double v,
                            double *r, double *g, double *b, double *a) {
    if (!(u >= 0.0) || !(v >= 0.0) || !(u < (double)w) || !(v < (double)h)) {
        *r = *g = *b = *a = 0.0;
        return;
    }
    double x = u - 0.5;
    double y = v - 0.5;
    int x0 = (int)floor(x);
    int y0 = (int)floor(y);
    double tx = x - (double)x0;
    double ty = y - (double)y0;
    double w00 = (1.0 - tx) * (1.0 - ty);
    double w10 = tx * (1.0 - ty);
    double w01 = (1.0 - tx) * ty;
    double w11 = tx * ty;
    double acc[4] = {0, 0, 0, 0};
    int xs[2] = {x0, x0 + 1};
    int ys[2] = {y0, y0 + 1};
    double ws[4] = {w00, w10, w01, w11};
    for (int channel = 0; channel < 4; channel++) {
        for (int k = 0; k < 4; k++) {
            double covered = 0.0;
            double sample = texel(rgb, alpha, w, h, xs[k & 1], ys[k >> 1], channel, &covered);
            acc[channel] += ws[k] * covered * sample;
        }
    }
    *r = acc[0];
    *g = acc[1];
    *b = acc[2];
    *a = acc[3];
}

int layer_place(const uint8_t *fg_rgb, const uint8_t *fg_alpha,
                int fg_w, int fg_h, int bg_w, int bg_h,
                double origin_x, double origin_y,
                double size_w, double size_h,
                double rotation_deg, int flip_x, int flip_y, int sampling,
                uint8_t *out_rgb, uint8_t *out_alpha) {
    size_t fg_n = 0, bg_n = 0;
    if (fg_rgb == NULL || out_rgb == NULL || out_alpha == NULL) return -1;
    if (pixel_count(fg_w, fg_h, &fg_n) != 0) return -1;
    if (pixel_count(bg_w, bg_h, &bg_n) != 0) return -1;
    if (!finite_pair(origin_x, origin_y) || !finite_pair(size_w, size_h) || !isfinite(rotation_deg)) {
        return -1;
    }
    if (!(size_w > 1e-6) || !(size_h > 1e-6) || size_w > 1e7 || size_h > 1e7) return -1;
    if (origin_x > 1e9 || origin_x < -1e9 || origin_y > 1e9 || origin_y < -1e9) return -1;
    if (sampling != 0 && sampling != 1) return -1;
    (void)fg_n;

    double deg = fmod(rotation_deg, 360.0);
    if (deg < 0.0) deg += 360.0;
    double theta = deg * (3.14159265358979323846 / 180.0);
    double c = cos(theta);
    double s = sin(theta);
    double cx = origin_x + size_w * 0.5;
    double cy = origin_y + size_h * 0.5;

    for (int y = 0; y < bg_h; y++) {
        for (int x = 0; x < bg_w; x++) {
            double dx = ((double)x + 0.5) - cx;
            double dy = ((double)y + 0.5) - cy;
            /* Inverse of clockwise rotation in y-down coordinates. */
            double lx = c * dx + s * dy;
            double ly = -s * dx + c * dy;
            if (flip_x) lx = -lx;
            if (flip_y) ly = -ly;
            double u = (lx + size_w * 0.5) / size_w * (double)fg_w;
            double v = (ly + size_h * 0.5) / size_h * (double)fg_h;
            double r, g, b, a;
            if (sampling == 0) sample_nearest(fg_rgb, fg_alpha, fg_w, fg_h, u, v, &r, &g, &b, &a);
            else sample_bilinear(fg_rgb, fg_alpha, fg_w, fg_h, u, v, &r, &g, &b, &a);
            size_t i = (size_t)y * (size_t)bg_w + (size_t)x;
            out_rgb[i * 3] = u8_from_double(r);
            out_rgb[i * 3 + 1] = u8_from_double(g);
            out_rgb[i * 3 + 2] = u8_from_double(b);
            out_alpha[i] = u8_from_double(a);
        }
    }
    return 0;
}
