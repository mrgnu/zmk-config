#include <zephyr/kernel.h>
#include "logo.h"

LV_IMG_DECLARE(logo);

void draw_logo(lv_obj_t *canvas) {
    lv_draw_img_dsc_t img_dsc;
    lv_draw_img_dsc_init(&img_dsc);

    lv_canvas_draw_img(canvas, 0, 0, &logo, &img_dsc);
}
