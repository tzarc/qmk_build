/* Copyright 2021 Nick Brassel (@tzarc)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include QMK_KEYBOARD_H
#include <string.h>
#include <printf.h>
#include <backlight.h>
#include <qp.h>
#include <serial.h>

#include "graphics/djinn.c"
#include "graphics/lock-caps.c"
#include "graphics/lock-scrl.c"
#include "graphics/lock-num.c"
#include "graphics/redalert13.c"

#define MEDIA_KEY_DELAY 2

enum { USER_STATE_SYNC = SAFE_USER_SERIAL_TRANSACTION_ID };

enum { _QWERTY, _LOWER, _RAISE, _ADJUST };
#define KC_LWR MO(_LOWER)
#define KC_RSE MO(_RAISE)

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_QWERTY] = LAYOUT_all(
        KC_ESC,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,    KC_GRV,                           KC_DEL,  KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_BSPC,
        KC_TAB,   KC_Q,   KC_W,    KC_E,    KC_R,    KC_T,    KC_LBRC,                          KC_RBRC, KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSLS,
        KC_LCTL,  KC_A,   KC_S,    KC_D,    KC_F,    KC_G,    KC_HOME,                          KC_PGUP, KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,
        KC_LSFT,  KC_Z,   KC_X,    KC_C,    KC_V,    KC_B,    KC_END,                           KC_PGDN, KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_ENT,
                                   KC_LGUI, KC_LWR,  KC_SPC,  KC_NO,                            KC_NO,   KC_SPC,  KC_RSE,  KC_LALT,
                                                                      RGB_RMOD,         RGB_MOD,
                                                     KC_UP,                                              KC_UP,
                                            KC_LEFT, _______, KC_RIGHT,                         KC_LEFT, _______, KC_RIGHT,
                                                     KC_DOWN,                                            KC_DOWN
    ),
    [_LOWER] = LAYOUT_all(
        KC_F12,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   _______,                         _______, KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,
        _______, _______, KC_UP,   _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
        _______, KC_LEFT, KC_DOWN, KC_RIGHT,_______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
        _______, _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
                                   _______, _______, _______, _______,                         _______, _______, _______, _______,
                                                                     BL_DEC,             BL_INC,
                                                     _______,                                           _______,
                                            _______, _______, _______,                         _______, _______, _______,
                                                     _______,                                           _______
    ),
    [_RAISE] = LAYOUT_all(
        KC_F12,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   _______,                         _______, KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,
        _______,_______, KC_UP,    _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
        _______,KC_LEFT, KC_DOWN, KC_RIGHT, _______, KC_UNDS, KC_NO,                           KC_NO,   KC_EQL,  _______, _______, _______, _______, _______,
        _______, _______, _______, _______, _______, KC_MINS, KC_NO,                           KC_NO,   KC_PLUS, _______, _______, _______, _______, _______,
                                   _______, _______, _______, _______,                         _______, _______, _______, _______,
                                                                     _______,           _______,
                                                     _______,                                           _______,
                                            _______, _______, _______,                         _______, _______, _______,
                                                     _______,                                           _______
    ),
    [_ADJUST] = LAYOUT_all(
        _______, KC_CLCK, KC_NLCK, KC_SLCK, _______, _______, _______,                         _______, _______, _______, _______, DEBUG,   EEP_RST, RESET,
        _______, _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
        _______, _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
        _______, _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, _______,
                                   _______, _______, _______, _______,                         _______, _______, _______, _______,
                                                                     _______,           _______,
                                                     _______,                                           _______,
                                            _______, _______, _______,                         _______, _______, _______,
                                                     _______,                                           _______
    )
};
// clang-format on

layer_state_t layer_state_set_user(layer_state_t state) {
    // Default handler for lower/raise/adjust
    return update_tri_layer_state(state, _LOWER, _RAISE, _ADJUST);
}

void encoder_update_user(uint8_t index, bool clockwise) {
    uint8_t temp_mod = get_mods();
    uint8_t temp_osm = get_oneshot_mods();
    bool    is_ctrl  = (temp_mod | temp_osm) & MOD_MASK_CTRL;
    bool    is_shift = (temp_mod | temp_osm) & MOD_MASK_SHIFT;

    if (is_shift) {
        if (index == 0) { /* First encoder */
            if (clockwise) {
                tap_code16(KC_MS_WH_DOWN);
            } else {
                tap_code16(KC_MS_WH_UP);
            }
        } else if (index == 1) { /* Second encoder */
            if (clockwise) {
                rgblight_decrease_sat();
            } else {
                rgblight_increase_sat();
            }
        }
    } else if (is_ctrl) {
        if (index == 0) { /* First encoder */
            if (clockwise) {
                rgblight_increase_val();
            } else {
                rgblight_decrease_val();
            }
        } else if (index == 1) { /* Second encoder */
            if (clockwise) {
                rgblight_increase_speed();
            } else {
                rgblight_decrease_speed();
            }
        }
    } else {
        if (index == 0) { /* First encoder */
            if (clockwise) {
                rgblight_increase_hue();
            } else {
                rgblight_decrease_hue();
            }
        } else if (index == 1) { /* Second encoder */
            uint16_t held_keycode_timer = timer_read();
            uint16_t mapped_code        = 0;
            if (clockwise) {
                mapped_code = KC_VOLD;
            } else {
                mapped_code = KC_VOLU;
            }
            register_code(mapped_code);
            while (timer_elapsed(held_keycode_timer) < MEDIA_KEY_DELAY)
                ; /* no-op */
            unregister_code(mapped_code);
        }
    }
}

//----------------------------------------------------------
// Sync

#pragma pack(push)
#pragma pack(1)

typedef struct user_runtime_config {
    uint32_t          layer_state;
    led_t             led_state;
} user_runtime_config;

#pragma pack(pop)

_Static_assert(sizeof(user_runtime_config) == 5, "Invalid data transfer size for user sync data");

user_runtime_config user_state;

void keyboard_post_init_user(void) {
    // Register keyboard state sync split transaction
    static uint8_t dummy_transaction_status;
    soft_serial_register_transaction(USER_STATE_SYNC, &dummy_transaction_status, sizeof(user_state), &user_state, sizeof(user_state), &user_state);

    // Reset the initial shared data value between master and slave
    memset(&user_state, 0, sizeof(user_state));
}


void user_state_update(void) {
    if (is_keyboard_master()) {
        // Keep the LED state in sync
        user_state.led_state = host_keyboard_led_state();

        // Keep the layer state in sync
        user_state.layer_state = layer_state;
    }
}

void user_state_sync(void) {
    if (is_keyboard_master()) {
        // Keep track of the last state, so that we can tell if we need to propagate to slave
        static user_runtime_config last_user_state;
        static uint32_t          last_sync;
        bool                     needs_sync = false;

        // Check if the state values are different
        if (memcmp(&user_state, &last_user_state, sizeof(user_runtime_config))) {
            needs_sync = true;
            memcpy(&last_user_state, &user_state, sizeof(user_runtime_config));
        }

        // Send to slave every 500ms regardless of state change
        if (timer_elapsed32(last_sync) > 500) {
            needs_sync = true;
        }

        // Perform the sync if requested
        if (needs_sync) {
            last_sync = timer_read32();
            if (soft_serial_transaction(USER_STATE_SYNC) != TRANSACTION_END) {
                dprint("Failed to perform data transaction\n");
            }
        }
    }
}

void housekeeping_task_user(void) {
    // Update kb_state so we can send to slave
    user_state_update();

    // Data sync from master to slave
    user_state_sync();
}

//----------------------------------------------------------
// Display

void draw_ui_user(void) {
    bool            redraw_required = false;
    static uint16_t last_hue        = 0xFFFF;
    uint8_t         curr_hue        = rgblight_get_hue();
    if (last_hue != curr_hue) {
        last_hue        = curr_hue;
        redraw_required = true;
    }

    // Show the Djinn logo and two vertical bars on both sides
    if (redraw_required) {
        qp_drawimage_recolor(lcd, 120 - gfx_djinn->width / 2, 32, gfx_djinn, curr_hue, 255, 255);
        qp_rect(lcd, 0, 0, 8, 319, curr_hue, 255, 255, true);
        qp_rect(lcd, 231, 0, 239, 319, curr_hue, 255, 255, true);
    }

    // Show layer info on the left side
    if (is_keyboard_left()) {
        static uint32_t last_layer_state = 0;
        if (redraw_required || last_layer_state != user_state.layer_state) {
            last_layer_state = user_state.layer_state;

            const char *layer_name = "unknown";
            switch (get_highest_layer(user_state.layer_state)) {
                case _QWERTY:
                    layer_name = "qwerty";
                    break;
                case _LOWER:
                    layer_name = "lower";
                    break;
                case _RAISE:
                    layer_name = "raise";
                    break;
                case _ADJUST:
                    layer_name = "adjust";
                    break;
            }

            int  xpos    = 12;
            int  ypos    = 3;
            char buf[32] = {0};
            snprintf(buf, sizeof(buf), "layer: %s", layer_name);
            xpos = qp_drawtext_recolor(lcd, xpos, ypos, font_redalert13, buf, curr_hue, 255, 255, curr_hue, 255, 0);
            qp_rect(lcd, xpos, 3, 120, 3 + font_redalert13->glyph_height, 0, 0, 0, true);
        }
    }

    // Show LED lock indicators on the right side
    if (!is_keyboard_left()) {
        static led_t last_led_state = {0};
        if (redraw_required || last_led_state.raw != user_state.led_state.raw) {
            last_led_state.raw = user_state.led_state.raw;
            qp_drawimage_recolor(lcd, 239 - 12 - (32 * 3), 0, gfx_lock_caps, curr_hue, 255, last_led_state.caps_lock ? 255 : 32);
            qp_drawimage_recolor(lcd, 239 - 12 - (32 * 2), 0, gfx_lock_num, curr_hue, 255, last_led_state.num_lock ? 255 : 32);
            qp_drawimage_recolor(lcd, 239 - 12 - (32 * 1), 0, gfx_lock_scrl, curr_hue, 255, last_led_state.scroll_lock ? 255 : 32);
        }
    }
}