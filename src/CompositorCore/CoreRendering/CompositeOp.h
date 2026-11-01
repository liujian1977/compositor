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
 * @param operation   Blend operation: "alpha", "difference", or "poisson"
 * @param background  Background image (RGB, w*h*3 bytes)
 * @param foreground  Foreground image (RGB, w*h*3 bytes)
 * @param alpha       Alpha mask (grayscale, w*h bytes, values [0,255])
 * @param width       Image width
 * @param height      Image height
 * @param result      Output buffer (caller must allocate w*h*3 bytes)
 */
void composite_images(const char *operation, const uint8_t *background,
                     const uint8_t *foreground, const uint8_t *alpha,
                     int width, int height, uint8_t *result);

#ifdef __cplusplus
}
#endif

#endif /* CompositeOp_h */
