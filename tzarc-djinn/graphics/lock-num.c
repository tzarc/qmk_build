/* Copyright 2021 QMK
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

/*
 * This file was auto-generated by `qmk painter-convert-graphics -i lock-num.png -f mono4 -c -s 4096`
 */

#include <progmem.h>
#include <stdint.h>
#include <qp.h>
#include <qp_internal.h>

#ifndef QUANTUM_PAINTER_COMPRESSION_ENABLE
#    error Compression is not available on your selected platform. Please regenerate lock_num without compression.
#endif

#if (QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE < 4096)
#    error Need to "#define QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE 4096" or greater in your config.h
#endif

// clang-format off

static const uint32_t gfx_lock_num_chunk_offsets[1] PROGMEM = {
         0,  // chunk   0 // compressed size:    124 bytes /   3.03% of 4096 bytes
};

static const uint8_t gfx_lock_num_chunk_data[124] PROGMEM = {
    0x01, 0x00, 0x00, 0xA0, 0x00, 0x09, 0x40, 0xFE, 0xFF, 0xFF, 0xBF, 0x01, 0x00, 0x00, 0xF4, 0xFF, 0x20, 0x00, 0x02, 0x1F, 0x00, 0x00, 0x20, 0x0E, 0x20, 0x10, 0x01, 0x00, 0x80, 0x20, 0x05, 0x20,
    0x00, 0x01, 0x02, 0xD0, 0x20, 0x04, 0x20, 0x00, 0x01, 0x07, 0xF0, 0x20, 0x04, 0x20, 0x00, 0x00, 0x0F, 0x20, 0x26, 0x01, 0x7F, 0xF5, 0x20, 0x28, 0x03, 0xF8, 0xFF, 0xFF, 0x1B, 0x20, 0x13, 0x01,
    0x2F, 0xFC, 0x20, 0x23, 0x20, 0x07, 0x04, 0x3F, 0xFC, 0xFF, 0x7F, 0x50, 0x80, 0x07, 0x01, 0xFF, 0x78, 0xA0, 0x07, 0x00, 0x7F, 0xE0, 0x4B, 0x07, 0x20, 0x77, 0x00, 0xBF, 0x20, 0x57, 0x00, 0x2F,
    0x20, 0x87, 0x40, 0x07, 0x00, 0x1F, 0x20, 0x0B, 0x40, 0x00, 0x00, 0x0F, 0xC0, 0xA7, 0xC0, 0xB7, 0xC0, 0xC7, 0xE0, 0x00, 0xD7, 0xC0, 0xE7, 0x60, 0x00, 0x01, 0x00, 0x00,
};

static const painter_compressed_image_descriptor_t gfx_lock_num_compressed PROGMEM = {
    .base = {
        .image_format = IMAGE_FORMAT_GRAYSCALE,
        .image_bpp    = 2,
        .compression  = IMAGE_COMPRESSED_LZF,
        .width        = 32,
        .height       = 32
    },
    .image_palette   = NULL,
    .chunk_count     = 1,
    .chunk_size      = 4096,
    .chunk_offsets   = gfx_lock_num_chunk_offsets,
    .compressed_data = gfx_lock_num_chunk_data,
    .compressed_size = 124 // original = 256 bytes (2bpp) / 48.44% of original // rgb24 = 3072 bytes / 4.04% of rgb24
};

painter_image_t gfx_lock_num PROGMEM = (painter_image_t)&gfx_lock_num_compressed;

// clang-format on
