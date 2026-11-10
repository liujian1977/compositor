// ModelPrep.h — Model-independent prep for SAM2 and LaMa.
// No Core ML. The Swift side owns the actual prediction and must fail
// visibly when the package is missing or its inputs do not match.

#ifndef MODEL_PREP_H
#define MODEL_PREP_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Letterbox {
    int src_w, src_h;
    int dst_w, dst_h;
    int pad_x, pad_y;
    int content_w, content_h;
    double scale; /* source pixels to content pixels */
} Letterbox;

/** Fit src inside dst, centered. Returns 0, or -1 if a dimension is invalid. */
int model_letterbox_plan(int src_w, int src_h, int dst_w, int dst_h, Letterbox *out);

/** Nearest-neighbor letterbox. dst is dst_w*dst_h*3. Pad is a solid color. */
int model_letterbox_rgb(const uint8_t *src, int src_w, int src_h,
                        int dst_w, int dst_h, uint8_t pad_r, uint8_t pad_g, uint8_t pad_b,
                        uint8_t *dst, Letterbox *plan);

int model_letterbox_gray(const uint8_t *src, int src_w, int src_h,
                         int dst_w, int dst_h, uint8_t pad,
                         uint8_t *dst, Letterbox *plan);

/** mode 0: byte/255 into NCHW. mode 1: ImageNet mean/std on top of that. */
int model_normalize_nchw(const uint8_t *rgb, int width, int height, int mode, float *out);

/**
 * Map image-space points and boxes into letterboxed model pixels.
 * A box is x,y,width,height and becomes two corners labeled 2 and 3.
 * A point is labeled 1. With no prompts, a box around the whole source is used
 * and *used_default_box is set to 1.
 * coords is out_count*2 floats, labels is out_count floats.
 * A point outside the source image returns -1.
 */
int sam_encode_prompts(const Letterbox *box,
                       const double *points_xy, int point_count,
                       const double *boxes_xywh, int box_count,
                       float *coords, float *labels, int cap,
                       int *out_count, int *used_default_box);

/**
 * Threshold a mask. Values outside [0, 1] are treated as logits and passed
 * through a sigmoid first. Output is 0 or 255.
 */
int model_mask_threshold(const float *src, int width, int height, float threshold, uint8_t *dst);

int model_upsample_nearest(const uint8_t *src, int src_w, int src_h,
                           int dst_w, int dst_h, uint8_t *dst);

/** Crop the letterbox content and nearest-resize it to the original image. */
int model_mask_unletterbox(const uint8_t *model_mask, int model_w, int model_h,
                           const Letterbox *box, int out_w, int out_h, uint8_t *out);

typedef struct LamaTile {
    int x, y;             /* origin in the source image */
    int width, height;    /* valid pixels copied from the source */
    int pad_right, pad_bottom;
} LamaTile;

/** fast=512/32, balanced=512/64, high=1024/128. Unknown name returns -1. */
int lama_preset_params(const char *name, int *tile, int *overlap);

/**
 * Cover the image with tiles of `tile` (the model square). The last tile is
 * shifted so it stays inside when the image is larger than the tile. Images
 * smaller than the tile produce one padded tile.
 * Returns the number of tiles, or -1. *needed is set even when cap is too small.
 */
int lama_plan_tiles(int image_w, int image_h, int tile, int overlap,
                    LamaTile *out, int cap, int *needed);

int lama_extract_tile(const uint8_t *rgb, const uint8_t *mask,
                      int image_w, int image_h, const LamaTile *tile, int tile_size,
                      uint8_t *tile_rgb, uint8_t *tile_mask);

/** Accumulate a tile's RGB (only the valid region) and divide in finish. */
int lama_blend_begin(float *acc_rgb, float *weight, int pixel_count);
int lama_blend_add(float *acc_rgb, float *weight, int image_w, int image_h,
                   const LamaTile *tile, const uint8_t *tile_rgb, int tile_size);
int lama_blend_finish(const float *acc_rgb, const float *weight, int pixel_count, uint8_t *out_rgb);

/**
 * Download acceptance. 0 means keep the file.
 * -1 bad HTTP status (anything other than 200), -2 empty body,
 * -3 body looks like HTML or a JSON error page.
 * head may be NULL when head_len is 0; status and size are still checked.
 */
int model_http_payload_ok(int http_status, long long nbytes, const uint8_t *head, size_t head_len);

#ifdef __cplusplus
}
#endif

#endif /* MODEL_PREP_H */
