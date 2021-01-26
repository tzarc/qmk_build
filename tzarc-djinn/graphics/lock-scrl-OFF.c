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
 * This file was auto-generated by `qmk painter-convert-graphics -i lock-scrl-OFF.png -f mono4 -c -s 16384`
 */

#include <progmem.h>
#include <stdint.h>
#include <qp.h>
#include <qp_internal.h>

#ifndef QUANTUM_PAINTER_COMPRESSION_ENABLE
#    error Compression is not available on your selected platform. Please regenerate lock_scrl_OFF without compression.
#endif

#if (QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE < 16384)
#    error Need to "#define QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE 16384" or greater in your config.h
#endif

// clang-format off

static const uint32_t gfx_lock_scrl_OFF_chunk_offsets[1] PROGMEM = {
         0,  // chunk   0 // compressed size:    133 bytes /  51.95% of 256 bytes
};

static const uint8_t gfx_lock_scrl_OFF_chunk_data[133] PROGMEM = {
    0x01, 0x00, 0x00, 0x80, 0x00, 0x01, 0xFC, 0xFF, 0x20, 0x00, 0x00, 0x0F, 0xA0, 0x07, 0x03, 0x3F, 0x00, 0x00, 0x3C, 0x40, 0x16, 0x00, 0xFC, 0xA0, 0x07, 0x01, 0xF0, 0x03, 0x80, 0x0F, 0x01, 0xC0,
    0x0F, 0x80, 0x07, 0x01, 0x00, 0x3F, 0xA0, 0x07, 0x00, 0xFC, 0x40, 0x07, 0x01, 0xC0, 0x03, 0x20, 0x20, 0x20, 0x2F, 0x20, 0x07, 0x01, 0xC0, 0x0F, 0x80, 0x07, 0x01, 0x00, 0x3F, 0xA0, 0x07, 0x00,
    0x3C, 0xE0, 0x29, 0x07, 0x02, 0xC0, 0xC0, 0x03, 0x20, 0x6E, 0x04, 0x3C, 0x00, 0xF0, 0xC3, 0xC3, 0x20, 0x6E, 0x20, 0x0F, 0x01, 0xCF, 0xF3, 0x60, 0x0F, 0x02, 0x00, 0xFF, 0xFF, 0x80, 0x4F, 0x00,
    0xFC, 0x40, 0x9E, 0x20, 0x0F, 0x00, 0xF0, 0x20, 0xAE, 0x20, 0x07, 0x00, 0xF0, 0x40, 0xB7, 0xE0, 0x02, 0x07, 0x60, 0x00, 0x20, 0x0F, 0x60, 0x00, 0xE0, 0x00, 0x07, 0x60, 0xDF, 0x20, 0xD9, 0xC0,
    0x07, 0x60, 0x1D, 0x20, 0x00,
};

static const painter_compressed_image_descriptor_t gfx_lock_scrl_OFF_compressed PROGMEM = {
    .base = {
        .image_format = IMAGE_FORMAT_GRAYSCALE,
        .image_bpp    = 2,
        .compression  = IMAGE_COMPRESSED_LZF,
        .width        = 32,
        .height       = 32
    },
    .image_palette   = NULL,
    .chunk_count     = 1,
    .chunk_size      = 16384,
    .chunk_offsets   = gfx_lock_scrl_OFF_chunk_offsets,
    .compressed_data = gfx_lock_scrl_OFF_chunk_data,
    .compressed_size = 133 // original = 256 bytes (2bpp) / 51.95% of original // rgb24 = 3072 bytes / 4.33% of rgb24
};

painter_image_t gfx_lock_scrl_OFF PROGMEM = (painter_image_t)&gfx_lock_scrl_OFF_compressed;

// clang-format on
