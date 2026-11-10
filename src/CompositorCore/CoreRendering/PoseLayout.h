// PoseLayout.h — Person ordering, pose-crop fit, and multi-person JSON.
// Pure numbers. Person detection and the Core ML model stay on macOS.

#ifndef POSE_LAYOUT_H
#define POSE_LAYOUT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Write sorted positions into `order` (length count).
 * order[0] is the original index of the first person.
 * Sort: score descending, y ascending, x ascending, original index ascending.
 * Returns 0, or -1 on invalid input. `order` is not written on failure.
 */
int pose_sort_order(const double *x, const double *y, const double *width, const double *height,
                    const double *score, int count, int *order);

/**
 * Fit one person box into a model canvas the way the full-image pose path does:
 * expand width and height by `padding` around the box center, then expand the
 * box to the canvas aspect, then uniform-scale that box onto the canvas.
 * Returns 0 and writes scale plus the source-space center. -1 on bad input.
 */
int pose_fit(double box_x, double box_y, double box_w, double box_h,
             double padding, double canvas_w, double canvas_h,
             double *scale, double *center_x, double *center_y);

/** Inverse of pose_fit. Canvas coordinates are y-down. */
int pose_unmap(double canvas_x, double canvas_y,
               double scale, double center_x, double center_y,
               double canvas_w, double canvas_h,
               double *out_x, double *out_y);

/**
 * Compact JSON, no trailing newline. Key order is fixed (see command-spec.md).
 * Keypoints are concatenated in person order. `kpt_counts[i]` may be 0.
 * COCO-17 names are filled from `kpt_ids`. Other ids become "keypoint_<id>".
 * On success *out_json is malloc'd; free with pose_people_json_free.
 * On failure *out_json is NULL and the return is -1.
 */
int pose_people_json(int image_w, int image_h,
                     const double *box_x, const double *box_y,
                     const double *box_w, const double *box_h,
                     const double *score, const int *kpt_counts, int person_count,
                     const int *kpt_ids, const double *kpt_x, const double *kpt_y,
                     const double *kpt_conf, char **out_json);
void pose_people_json_free(char *json);

#ifdef __cplusplus
}
#endif

#endif /* POSE_LAYOUT_H */
