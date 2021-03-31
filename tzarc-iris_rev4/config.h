/* Copyright 2018-2020 Nick Brassel (@tzarc)
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

#pragma once

//#define USE_I2C
#define EE_HANDS

#undef RGBLED_NUM
#define RGBLED_NUM 12
#define RGBLIGHT_HUE_STEP 8
#define RGBLIGHT_SAT_STEP 8
#define RGBLIGHT_VAL_STEP 8

#ifdef RGBLIGHT_ENABLE
#    undef RGBLIGHT_ANIMATIONS
#    if defined(__AVR__) && !defined(__AVR_AT90USB1286__)
#        define RGBLIGHT_SLEEP
#        define RGBLIGHT_EFFECT_BREATHING
#        define RGBLIGHT_EFFECT_SNAKE
#        define RGBLIGHT_EFFECT_KNIGHT
#    else
#        define RGBLIGHT_ANIMATIONS
#    endif
#endif  // RGBLIGHT_ENABLE

#define NO_ACTION_MACRO
#define NO_ACTION_FUNCTION

// Allow for an extra sync command over the split
#define SERIAL_USE_MULTI_TRANSACTION
#define I2C_SLAVE_USER_REG_COUNT 9

#define SPLIT_TRANSACTION_IDS_USER USER_STATE_SYNC, USER_SLAVE_SYNC