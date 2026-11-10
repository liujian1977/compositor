// CompositeOp.h — Image compositing operations (alpha blend, difference, Poisson)

#ifndef CompositeOp_h
#define CompositeOp_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * Composite foreground onto background using the specified blend mode and alpha mask.
 *
 * @param operation   Blend operation: "alpha", "difference", or "poisson".
 *                    Any other name selects alpha blending.
 * @param background  Background image (RGB, w*h*3 bytes)
 * @param foreground  Foreground image (RGB, w*h*3 bytes)
 * @param alpha       Alpha mask (one byte per pixel, row-major, values [0,255])
 * @param width       Image width, must be > 0
 * @param height      Image height, must be > 0
 * @param result      Output buffer (caller must allocate w*h*3 bytes).
 *                    Written only when the function returns 0.
 * @return 0 on success. -1 if arguments are invalid, a buffer cannot be
 *         allocated, or the Poisson solve does not converge. On -1, `result`
 *         is left untouched.
 *
 * Poisson notes: pixels with alpha >= 128, excluding the one-pixel image
 * border, are the unknown domain. The border and alpha < 128 stay on the
 * background (Dirichlet). The solve matches the foreground Laplacian inside
 * that domain. The final pixel is mixed back toward the background by alpha.
 */
int composite_images(const char *operation, const uint8_t *background,
                     const uint8_t *foreground, const uint8_t *alpha,
                     int width, int height, uint8_t *result);

#ifdef __cplusplus
}
#endif

#endif /* CompositeOp_h */
