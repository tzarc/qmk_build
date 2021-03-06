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
#include <assert.h>
#include <quantum.h>
#include "tzarc_layout.h"

#ifndef __cplusplus
#    define static_assert _Static_assert
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common functionality

extern bool     config_enabled;
extern uint16_t repeat_mode;

void tzarc_common_init(void);

uint8_t prng(void);

bool process_record_keymap(uint16_t keycode, keyrecord_t *record);
bool process_record_user(uint16_t keycode, keyrecord_t *record);

void matrix_scan_keymap(void);
void matrix_scan_user(void);

layer_state_t layer_state_set_keymap(layer_state_t state);
layer_state_t layer_state_set_user(layer_state_t state);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// EEPROM

#define BITMASK_BYTES_REQUIRED(last, first) ((((last) - (first) + 1) + 7) / 8)
#define BITMASK_BYTE_INDEX(n, first) (((n) - (first)) / 8)
#define BITMASK_BIT_INDEX(n, first) (((n) - (first)) % 8)
#define BITMASK_BIT_SET(array, n, first) ((array)[BITMASK_BYTE_INDEX((n), (first))] |= 1 << BITMASK_BIT_INDEX((n), (first)))
#define BITMASK_BIT_CLEAR(array, n, first) ((array)[BITMASK_BYTE_INDEX((n), (first))] &= ~(1 << BITMASK_BIT_INDEX((n), (first))))
#define BITMASK_BIT_GET(array, n, first) (((array)[BITMASK_BYTE_INDEX((n), (first))] & (1 << BITMASK_BIT_INDEX((n), (first)))) ? 1 : 0)
#define BITMASK_BIT_ASSIGN(array, value, n, first) (value ? BITMASK_BIT_SET((array), (n), (first)) : BITMASK_BIT_CLEAR((array), (n), (first)))

#define TZARC_EEPROM_LOCATION ((uint8_t *)EECONFIG_SIZE)
#define TZARC_EEPROM_MAGIC_SEED (uint8_t)((uint8_t)__TIME__[0] + (uint8_t)__TIME__[1] + (uint8_t)__TIME__[3] + (uint8_t)__TIME__[4] + (uint8_t)__TIME__[6] + (uint8_t)__TIME__[7])  // HH:MM::SS

__attribute__((packed)) struct tzarc_eeprom_cfg_t {
    uint8_t magic1;
    uint8_t wow_enabled[BITMASK_BYTES_REQUIRED(KC_0, KC_A)];
    uint8_t d3_enabled[BITMASK_BYTES_REQUIRED(KC_4, KC_1)];
    uint8_t magic2;
};

extern struct tzarc_eeprom_cfg_t tzarc_eeprom_cfg;

// Make sure if/when we ever use VIA we have a block of settings that still fits
static_assert(sizeof(struct tzarc_eeprom_cfg_t) <= TZARC_EEPROM_ALLOCATION, "EEPROM settings greater than TZARC_EEPROM_ALLOCATION, need to change users/tzarc/config.h");

void tzarc_eeprom_init(void);
void tzarc_eeprom_reset(void);
void tzarc_eeprom_save(void);
void tzarc_eeprom_load(void);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WoW

#define WOW_BUTTON_COUNT (KC_0 - KC_A + 1)

struct wow_config_t {
    uint8_t  keydown[BITMASK_BYTES_REQUIRED(KC_0, KC_A)];
    uint8_t  released[BITMASK_BYTES_REQUIRED(KC_0, KC_A)];
    uint32_t last_keydown[WOW_BUTTON_COUNT];
    uint32_t next_trigger[WOW_BUTTON_COUNT];
};

extern struct wow_config_t wow_config;

void tzarc_wow_init(void);
bool process_record_wow(uint16_t keycode, keyrecord_t *record);
void matrix_scan_wow(void);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Diablo III

struct diablo3_config_t {
    bool dummy;
};

extern struct diablo3_config_t diablo3_config;

void tzarc_diablo3_init(void);
bool process_record_diablo3(uint16_t keycode, keyrecord_t *record);
void matrix_scan_diablo3(void);
