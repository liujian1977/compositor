// FaceSelect.c — Deterministic face picking.

#include "FaceSelect.h"

#include <math.h>
#include <stdlib.h>

static int positive_finite(double v) {
    return isfinite(v) && v > 0.0;
}

static int prefer(int a, int b, const double *confidence, const double *area,
                  const double *y, const double *x) {
    if (confidence[a] > confidence[b]) return 1;
    if (confidence[a] < confidence[b]) return 0;
    if (area[a] > area[b]) return 1;
    if (area[a] < area[b]) return 0;
    if (y[a] < y[b]) return 1;
    if (y[a] > y[b]) return 0;
    if (x[a] < x[b]) return 1;
    if (x[a] > x[b]) return 0;
    return a < b;
}

static double intersection_over_union(double ax, double ay, double aw, double ah,
                                      double bx, double by, double bw, double bh) {
    double ax2 = ax + aw, ay2 = ay + ah;
    double bx2 = bx + bw, by2 = by + bh;
    double ix0 = ax > bx ? ax : bx;
    double iy0 = ay > by ? ay : by;
    double ix1 = ax2 < bx2 ? ax2 : bx2;
    double iy1 = ay2 < by2 ? ay2 : by2;
    double iw = ix1 - ix0;
    double ih = iy1 - iy0;
    if (!(iw > 0.0) || !(ih > 0.0)) return 0.0;
    double inter = iw * ih;
    double uni = aw * ah + bw * bh - inter;
    if (!(uni > 0.0)) return 0.0;
    return inter / uni;
}

int face_select(const double *x, const double *y, const double *width, const double *height,
                const double *confidence, int count,
                int face_index, int has_box,
                double box_x, double box_y, double box_w, double box_h) {
    if (count < 0) return -1;
    if (count == 0) return -1;
    if (x == NULL || y == NULL || width == NULL || height == NULL || confidence == NULL) return -1;
    if (count > 10000) return -1;
    if (has_box != 0 && has_box != 1) return -1;

    double *area = (double *)malloc((size_t)count * sizeof(double));
    int *order = (int *)malloc((size_t)count * sizeof(int));
    if (area == NULL || order == NULL) {
        free(area);
        free(order);
        return -1;
    }

    for (int i = 0; i < count; i++) {
        if (!isfinite(x[i]) || !isfinite(y[i]) || !positive_finite(width[i]) ||
            !positive_finite(height[i]) || !isfinite(confidence[i])) {
            free(area);
            free(order);
            return -1;
        }
        area[i] = width[i] * height[i];
        order[i] = i;
    }
    if (has_box) {
        if (!isfinite(box_x) || !isfinite(box_y) || !positive_finite(box_w) || !positive_finite(box_h)) {
            free(area);
            free(order);
            return -1;
        }
    }

    for (int i = 1; i < count; i++) {
        int key = order[i];
        int j = i - 1;
        while (j >= 0 && prefer(key, order[j], confidence, area, y, x)) {
            order[j + 1] = order[j];
            j--;
        }
        order[j + 1] = key;
    }

    int chosen_sorted = -1;
    if (has_box) {
        double best = 0.0;
        for (int s = 0; s < count; s++) {
            int i = order[s];
            double score = intersection_over_union(x[i], y[i], width[i], height[i],
                                                   box_x, box_y, box_w, box_h);
            if (score > best) {
                best = score;
                chosen_sorted = s;
            }
        }
        if (!(best > 0.0)) chosen_sorted = -1;
    } else if (face_index >= 0) {
        if (face_index < count) chosen_sorted = face_index;
    } else {
        double best_area = -1.0;
        for (int s = 0; s < count; s++) {
            int i = order[s];
            if (area[i] > best_area) {
                best_area = area[i];
                chosen_sorted = s;
            }
        }
    }

    int result = -1;
    if (chosen_sorted >= 0) {
        if (face_index >= 0 && has_box && chosen_sorted != face_index) {
            result = -1;
        } else if (!has_box && face_index >= 0 && chosen_sorted != face_index) {
            result = -1;
        } else {
            result = order[chosen_sorted];
        }
    }

    free(area);
    free(order);
    return result;
}
