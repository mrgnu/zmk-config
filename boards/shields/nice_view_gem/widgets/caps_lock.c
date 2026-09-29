#include <zephyr/kernel.h>
#include "caps_lock.h"
#include "../assets/custom_fonts.h"

void draw_caps_lock_status(lv_obj_t *canvas, const struct status_state *state) {
    if (!state->caps_lock) {
        return;
    }

    lv_draw_label_dsc_t label_dsc;
    init_label_dsc(&label_dsc, LVGL_FOREGROUND, &pixel_operator_mono, LV_TEXT_ALIGN_CENTER);
    lv_canvas_draw_text(canvas, 0, 146 + BUFFER_OFFSET_BOTTOM, BUFFER_SIZE, &label_dsc, "CAPS");
}
