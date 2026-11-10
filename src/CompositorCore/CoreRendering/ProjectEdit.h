// ProjectEdit.h — Numeric edits for a .comp layer stack, plus flatten blending.
// File copies and PNG IO stay in Swift. This file checks the numbers and blends pixels.

#ifndef PROJECT_EDIT_H
#define PROJECT_EDIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ProjectLayerState {
    double opacity;
    double origin_x, origin_y, size_w, size_h, rotation;
    int flip_x, flip_y;
    int blend; /* 0 Normal, 1 Multiply, 2 Screen */
} ProjectLayerState;

/** "Normal" / "Multiply" / "Screen", case-sensitive as stored in the manifest. -1 if unknown. */
int project_blend_code(const char *name);
const char *project_blend_name(int code);

int project_set_opacity(ProjectLayerState *layers, int count, int index, double opacity);
int project_set_blend(ProjectLayerState *layers, int count, int index, const char *name);
int project_set_transform(ProjectLayerState *layers, int count, int index,
                          double origin_x, double origin_y, double size_w, double size_h,
                          double rotation, int flip_x, int flip_y);

/** Compact the array. Returns 0, or -1 if the index is out of range (array unchanged). */
int project_remove_layer(ProjectLayerState *layers, int *count, int index);

/**
 * Lexical path check for a file that will be copied into the project.
 * Rejects empty strings, absolute paths, backslashes, and any "." or ".." segment.
 * 0 means the relative path is acceptable.
 */
int project_relative_path_ok(const char *path);

/**
 * Porter-Duff over of a placed layer onto the canvas.
 * opacity is in [0, 1] and scales the layer alpha.
 * blend 0 Normal, 1 Multiply, 2 Screen. Other codes return -1 and do not write.
 */
int project_flatten_over(uint8_t *canvas_rgb, uint8_t *canvas_a,
                         const uint8_t *layer_rgb, const uint8_t *layer_a,
                         int width, int height, double opacity, int blend);

/**
 * Compact JSON for `project list`. ids[i] and names[i] are required, non-NULL.
 * Free with project_list_json_free.
 */
int project_list_json(int canvas_w, int canvas_h,
                      const char **ids, const char **names,
                      const ProjectLayerState *layers, int count,
                      char **out_json);
void project_list_json_free(char *json);

#ifdef __cplusplus
}
#endif

#endif /* PROJECT_EDIT_H */
