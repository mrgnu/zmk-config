#pragma once

#include <lvgl.h>
#include "util.h"

struct caps_lock_status_state {
    bool active;
};

void draw_caps_lock_status(lv_obj_t *canvas, const struct status_state *state);
