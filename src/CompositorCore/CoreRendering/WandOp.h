// WandOp.h — Magic Wand flood-fill selection.
#ifndef WAND_OP_H
#define WAND_OP_H

#include <stdint.h>

// Select pixels by color similarity (magic wand).
// image: RGBA8 data, width*height*4 bytes.
// px, py: seed point (top-left origin).
// tolerance: per-channel absolute color difference [0,255].
// sampleSize: 1, 3, or 5 — averaging window around the seed point.
// contiguous: 1 = 4-connected flood fill from seed; 0 = global color key.
// output: width*height bytes, 255 = selected, 0 = not selected.
// Returns: 0 on success, -1 on invalid parameters.
int wand_select(const uint8_t *image, int width, int height,
                int px, int py, int tolerance, int sampleSize,
                int contiguous, uint8_t *output);

#endif /* WAND_OP_H */
