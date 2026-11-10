// FaceSelect.h — Pick one detected face. No Vision, no CoreGraphics.
//
// Sort order (used by --face-index, and as the tie break):
//   confidence descending, area descending, y ascending, x ascending,
//   original index ascending.
//
// Default (face_index < 0 and no target box): largest area, then the sort
// order above.
// --face-index is the position in that sorted list, 0-based.
// --target-box picks the greatest IoU. IoU must be > 0.
// When both are set, the box winner must sit at that sorted index.

#ifndef FACE_SELECT_H
#define FACE_SELECT_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Returns the chosen index into the original arrays, or -1 when nothing
 * matches or the arguments are invalid. Does not allocate on the failure path
 * except a temporary index list, which is always freed.
 *
 * face_index < 0 means "unset". has_box is 0 or 1.
 * Boxes are top-left origin, y down, in pixels.
 */
int face_select(const double *x, const double *y, const double *width, const double *height,
                const double *confidence, int count,
                int face_index, int has_box,
                double box_x, double box_y, double box_w, double box_h);

#ifdef __cplusplus
}
#endif

#endif /* FACE_SELECT_H */
