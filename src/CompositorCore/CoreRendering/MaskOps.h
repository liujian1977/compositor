// MaskOps.h — Cutout, mask arithmetic, and mask inspection.
// Pure byte buffers. No CoreGraphics. Safe to unit-test on Linux.

#ifndef MASK_OPS_H
#define MASK_OPS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/** Foreground test for bounds and connected components. Coverage ignores this. */
#define MASK_INSPECT_FOREGROUND_THRESHOLD 128
/** Components are 8-connected (same neighborhood as morph_dilate / morph_erode). */
#define MASK_INSPECT_CONNECTIVITY 8

/**
 * Build a straight RGBA image whose color is `rgb` and whose alpha is `mask`.
 *
 * rgb:      width*height*3 bytes, row-major R,G,B. Copied unchanged.
 * mask:     width*height bytes. 0 = transparent, 255 = opaque. Not thresholded.
 * out_rgba: width*height*4 bytes, row-major R,G,B,A. Must not overlap `rgb` or `mask`.
 *
 * Existing source alpha is not an input: the mask replaces alpha.
 * Returns 0 on success. Returns -1 on NULL or non-positive / overflowing
 * dimensions and does not write `out_rgba`.
 */
int cutout_apply_mask(const uint8_t *rgb, const uint8_t *mask,
                      int width, int height, uint8_t *out_rgba);

/**
 * Per-byte mask arithmetic. `dst` may alias `src` / `a` / `b`.
 *   invert:    255 - src
 *   union:     max(a, b)
 *   intersect: min(a, b)
 *   subtract:  a >= b ? a - b : 0     (a minus b; saturating)
 * On 0/255 masks these are set complement, union, intersection, and difference.
 * Returns 0 on success. Returns -1 on NULL or bad dimensions and does not write `dst`.
 */
int mask_invert(const uint8_t *src, int width, int height, uint8_t *dst);
int mask_union(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst);
int mask_intersect(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst);
int mask_subtract(const uint8_t *a, const uint8_t *b, int width, int height, uint8_t *dst);

typedef struct MaskRect {
    int x;       /* column of the left edge, 0-based */
    int y;       /* row of the top edge, 0-based, y grows downward */
    int width;   /* inclusive span in pixels */
    int height;
} MaskRect;

typedef struct MaskComponent {
    int index;           /* discovery order, row-major seed, starting at 0 */
    int area;            /* number of foreground pixels */
    double center_x;     /* mean column of member pixels */
    double center_y;     /* mean row of member pixels */
    MaskRect bounds;     /* tight box of this component; not part of the JSON schema */
} MaskComponent;

typedef struct MaskInspectResult {
    int width;
    int height;
    double coverage;             /* mean(mask) / 255, in [0, 1]; soft values count fractionally */
    int has_bounding_box;        /* 0 when no foreground pixel */
    MaskRect bounding_box;       /* tight box of every foreground pixel */
    int component_count;
    MaskComponent *components;   /* malloc'd; release with mask_inspect_free */
    int foreground_threshold;    /* MASK_INSPECT_FOREGROUND_THRESHOLD */
    int connectivity;            /* MASK_INSPECT_CONNECTIVITY */
} MaskInspectResult;

/**
 * Measure a grayscale mask.
 * Foreground (bounds + components) is mask[i] >= MASK_INSPECT_FOREGROUND_THRESHOLD.
 * Coverage uses every sample, including values below that threshold.
 * On success, `out->components` is NULL when component_count is 0, otherwise
 * a malloc'd array. On failure `*out` is zeroed and nothing is allocated.
 * Returns 0 on success, -1 on NULL / bad dimensions / allocation failure.
 */
int mask_inspect(const uint8_t *mask, int width, int height, MaskInspectResult *out);
void mask_inspect_free(MaskInspectResult *result);

/**
 * Write one compact JSON object, no trailing newline, NUL-terminated.
 * Numbers use up to 6 decimal places, half-up, trailing zeros stripped.
 * Returns the length excluding NUL, or -1 if `buf` is too small or `result` is NULL.
 * Key order is fixed (see command-spec.md). `bounding_box` is null when empty.
 */
int mask_inspect_json(const MaskInspectResult *result, char *buf, size_t buf_size);

/**
 * mask_inspect + mask_inspect_json into a malloc'd string (*out_json).
 * Free with mask_inspect_json_free. On failure *out_json is NULL and the return is -1.
 */
int mask_inspect_format_json(const uint8_t *mask, int width, int height, char **out_json);
void mask_inspect_json_free(char *json);

#ifdef __cplusplus
}
#endif

#endif /* MASK_OPS_H */
