#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import math
import argparse
import sys
import os
import socket
import re
import lzf
try:
    from PIL import Image
    from PIL import ImageDraw
    from PIL import ImageFont
    from PIL import ImageChops
    from PIL import ImageOps
except ImportError:
    print("%s depends on the Python Image Library, please install:" % sys.argv[0])
    print("pip3 install Pillow")
    sys.exit(0)

def rescale(val,maxval):
    return int(round(val * maxval / 255.0))

def rgb888_to_rgb565(r,g,b):
    rgb565 = (
        rescale(r, 31) << 11 |
        rescale(g, 63) << 5 |
        rescale(b, 31)
    )
    return rgb565

fileHeader = """\
/* Copyright 2020 QMK
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
 * This file was auto-generated by util/convert_gfx.py!
 */

"""

def palettize_image(im, ncolors, mono=False):
    """Convert an image to a palette and packed byte array combo
    """

    # Work out where we're getting the bytes from
    if mono:
        # If mono, convert input to grayscale, then to RGB, then grab the raw bytes corresponding to the intensity of the red channel
        image_bytes = ImageOps.grayscale(im).convert("RGB").tobytes("raw","R")
    else:
        # If color, convert input to RGB, palettize based on the supplied number of colours, then get the raw palette bytes
        image_bytes = im.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=ncolors).tobytes("raw", "P")

    # Work out how much data we're actually processing
    image_bytes_len = len(image_bytes)
    shifter = math.log2(ncolors)
    pixels_per_byte = int(8 / shifter)

    # If in RGB mode, convert the palette to rgb triplet
    palette = []
    if not mono:
        pal = im.getpalette()
        for n in range(0, ncolors * 3, 3):
            palette.append([pal[n + 0], pal[n + 1], pal[n + 2]])

    # Convert to packed pixel byte array
    bytearray = []
    for x in range(int(image_bytes_len / pixels_per_byte)):
        byte = 0
        for n in range(pixels_per_byte):
            byte_offset = x*pixels_per_byte + n
            if byte_offset < image_bytes_len:
                if mono:
                    # If mono, each input byte is a grayscale [0,255] pixel -- rescale to the range we want then pack together
                    byte = byte | (rescale(image_bytes[byte_offset], ncolors - 1) << int(n*shifter))
                else:
                    # If color, each input byte is the index into the colour palette -- pack them together
                    byte = byte | ((image_bytes[byte_offset] & (ncolors - 1)) << int(n*shifter))
        bytearray.append(byte)
    return (palette, bytearray)

"""Convert an image to a 8bpp (256-colour) palette image
"""
def image_to_palette8bpp(im):
    return palettize_image(im, 256)

"""Convert an image to a 4bpp (16-colour) palette image
"""
def image_to_palette4bpp(im):
    return palettize_image(im, 16)

"""Convert an image to a 2bpp (4-colour) palette image
"""
def image_to_palette2bpp(im):
    return palettize_image(im, 4)

"""Convert an image to a 1bpp (2-colour) palette image
"""
def image_to_palette1bpp(im):
    return palettize_image(im, 2)

"""Convert an image to a packed mono 4bpp byte array
"""
def image_to_mono4bpp(im):
    return palettize_image(im, 16, True)

"""Convert an image to a packed mono 2bpp byte array
"""
def image_to_mono2bpp(im):
    return palettize_image(im, 4, True)

"""Convert an image to a packed mono 1bpp byte array
"""
def image_to_mono1bpp(im):
    return palettize_image(im, 2, True)

"""Convert an image to a rgb565 byte array
"""
def image_to_rgb565(im):
    im = im.convert("RGB")
    image_bytes = im.tobytes("raw","RGB") # Create a byte array in 24 bit RGB format from an image
    image_bytes_len = len(image_bytes)

    # Convert 24-bit RGB to 16-bit BGR
    rgb565array = []
    for x in range(int(image_bytes_len / 3)):
        r = image_bytes[x*3+0]
        g = image_bytes[x*3+1]
        b = image_bytes[x*3+2]
        rgb565 = rgb888_to_rgb565(r, g, b)
        rgb565array.append((rgb565 >> 8) & 0xFF)
        rgb565array.append(rgb565 & 0xFF)

    return rgb565array

"""
Measure the size of an image and return the coordinates of the (left, upper, right, lower) bounding box
"""
def measure(im, border=(0,0,0,0)):
    bg = Image.new(im.mode, im.size, border)
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    return diff.getbbox()

"""
Convert the specified font to a pair of .c/.h C language lookup tables in BGR565 format
"""
def convert_graphic_to_c(graphic_fname, output_filename, compress, chunksize, fmt_rgb565, fmt_pal8bpp, fmt_pal4bpp, fmt_pal2bpp, fmt_pal1bpp, fmt_mono4bpp, fmt_mono2bpp, fmt_mono1bpp):
    print("Converting %s to gfx-%s.c/h" % (graphic_fname, output_filename))
    sane_name = re.sub(r"[^a-zA-Z0-9]", "_", output_filename)
    graphic_image = Image.open(graphic_fname)
    has_palette = False

    if compress == True:
        if chunksize < 64:
            raise Exception("Chunk size must be >= 64")
        if chunksize > 4096:
            raise Exception("Chunk size must be <= 4096")

    # Get image dimensions
    (width, height) = graphic_image.size

    # Convert image to rgb565 byte list
    if fmt_rgb565:
        graphic_data = image_to_rgb565(graphic_image)
        newline_counter = int(width * 2)
        image_format = "IMAGE_FORMAT_RGB565"
        format_name = "rgb565"
        image_bpp = 16,
    elif fmt_pal8bpp:
        graphic_data = image_to_palette8bpp(graphic_image)
        newline_counter = 32
        image_format = "IMAGE_FORMAT_PALETTE"
        format_name = "pal8bpp"
        has_palette = True
        palette_size = 256
        image_bpp = 8
    elif fmt_pal4bpp:
        graphic_data = image_to_palette4bpp(graphic_image)
        newline_counter = 32
        image_format = "IMAGE_FORMAT_PALETTE"
        format_name = "pal4bpp"
        has_palette = True
        palette_size = 16
        image_bpp = 4
    elif fmt_pal2bpp:
        graphic_data = image_to_palette2bpp(graphic_image)
        newline_counter = 32
        image_format = "IMAGE_FORMAT_PALETTE"
        format_name = "pal2bpp"
        has_palette = True
        palette_size = 4
        image_bpp = 2
    elif fmt_pal1bpp:
        graphic_data = image_to_palette1bpp(graphic_image)
        newline_counter = 32
        image_format = "IMAGE_FORMAT_PALETTE"
        format_name = "pal1bpp"
        has_palette = True
        palette_size = 2
        image_bpp = 1
    elif fmt_mono4bpp:
        graphic_data = image_to_mono4bpp(graphic_image)
        newline_counter = int(width / 2)
        image_format = "IMAGE_FORMAT_GRAYSCALE"
        format_name = "4bpp"
        image_bpp = 4
    elif fmt_mono2bpp:
        graphic_data = image_to_mono2bpp(graphic_image)
        newline_counter = int(width / 4)
        image_format = "IMAGE_FORMAT_GRAYSCALE"
        format_name = "2bpp"
        image_bpp = 2
    elif fmt_mono1bpp:
        graphic_data = image_to_mono1bpp(graphic_image)
        newline_counter = int(width / 8)
        image_format = "IMAGE_FORMAT_GRAYSCALE"
        format_name = "1bpp"
        image_bpp = 1

    # Generate the output filenames
    gfx_source_filename = "gfx-%s.c" % (output_filename)
    gfx_header_filename = "gfx-%s.h" % (output_filename)

    # Generate the C source file
    gfx_source_file = open(gfx_source_filename, "w")
    gfx_source_file.write(fileHeader)

    gfx_source_file.write("/* generated from %s */\n\n" % (graphic_fname))

    gfx_source_file.write("#include <progmem.h>\n")
    gfx_source_file.write("#include <stdint.h>\n")
    gfx_source_file.write("#include <qp.h>\n")
    gfx_source_file.write("#include <qp_internal.h>\n\n")

    # Compile-time safety check: if compressed, ensure the buffer size is large enough
    if compress == True:
        gfx_source_file.write("#ifndef QUANTUM_PAINTER_COMPRESSION_ENABLE\n")
        gfx_source_file.write("#    error Compression is not available on your selected platform. Please regenerate %s without compression.\n" % (output_filename))
        gfx_source_file.write("#endif\n\n")

        gfx_source_file.write("#if (QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE < %d)\n" % (int(chunksize)))
        gfx_source_file.write("#    error Need to \"#define QUANTUM_PAINTER_COMPRESSED_CHUNK_SIZE %d\" or greater in your config.h\n" % (int(chunksize)))
        gfx_source_file.write("#endif\n\n")

    # Compile-time safety check: if using 256-colour palette, make sure we support 256 colours in the driver
    if has_palette and image_bpp == 8:
        gfx_source_file.write("#if (!(QUANTUM_PAINTER_SUPPORTS_256_PALETTE))\n")
        gfx_source_file.write("#    error Need to \"#define QUANTUM_PAINTER_SUPPORTS_256_PALETTE TRUE\" in your config.h (requires extra RAM)\n")
        gfx_source_file.write("#endif\n\n")

    gfx_source_file.write("// clang-format off\n\n")

    # Generate image palette lookup table
    if has_palette:
        image_palette = graphic_data[0]
        gfx_source_file.write("static const uint8_t gfx_%s_palette[%d] PROGMEM = {\n" % (sane_name, len(image_palette)*3))
        count = 0
        for j in image_palette:
            gfx_source_file.write("  0x{0:02X}, 0x{1:02X}, 0x{2:02X},  // {3:3d} / 0x{3:02X}\n".format(j[0], j[1], j[2], count))
            count += 1
        gfx_source_file.write("};\n\n")

    if compress == True:
        image_data = graphic_data[1]
        compressed_data = []
        compressed_chunk_offsets = []
        uncompressed_graphic_data = image_data.copy()
        while len(uncompressed_graphic_data) > 0:
            chunk_size = min(chunksize,len(uncompressed_graphic_data))
            uncompressed_chunk = uncompressed_graphic_data[0:chunk_size]
            uncompressed_graphic_data = uncompressed_graphic_data[chunk_size:]
            compressed = lzf.compress(bytes(uncompressed_chunk), int(len(uncompressed_chunk)*2))
            compressed_chunk_offsets.append((len(compressed_data),len(compressed))) # keep track of where this chunk starts
            compressed_data.extend(compressed)

        # Write out the compressed chunk offsets
        gfx_source_file.write("static const uint32_t gfx_%s_chunk_offsets[%d] PROGMEM = {\n" % (sane_name, len(compressed_chunk_offsets)))
        for n in range(0,len(compressed_chunk_offsets)):
            gfx_source_file.write("  %6d,  // chunk %-6d // compressed size: %4d / %6.2f%%\n" % (compressed_chunk_offsets[n][0], n, compressed_chunk_offsets[n][1], (100*compressed_chunk_offsets[n][1]/chunksize)))
        gfx_source_file.write("};\n\n")

        # Write out the compressed chunk data
        gfx_source_file.write("static const uint8_t gfx_%s_chunk_data[%d] PROGMEM = {\n " % (sane_name, len(compressed_data)))
        count = 0
        for j in compressed_data:
            gfx_source_file.write(" 0x{0:02X}".format(j))
            count += 1
            if count < len(compressed_data):
                gfx_source_file.write(",")
                if (count % 32) == 0: # Place a new line when we reach the same number of pixels as each row
                    gfx_source_file.write("\n ")
        gfx_source_file.write("\n};\n\n")

        # Write out the image descriptor
        gfx_source_file.write("static const painter_compressed_image_descriptor_t gfx_%s_compressed PROGMEM = {" % (sane_name))
        gfx_source_file.write("\n  .base = {")
        gfx_source_file.write("\n    .image_format = %s," % (image_format))
        gfx_source_file.write("\n    .compression  = IMAGE_COMPRESSED_LZF,")
        gfx_source_file.write("\n    .width        = %d," % (width))
        gfx_source_file.write("\n    .height       = %d" % (height))
        gfx_source_file.write("\n  },")
        gfx_source_file.write("\n  .image_bpp       = %d," % (image_bpp))
        gfx_source_file.write("\n  .image_palette   = %s," % ("gfx_%s_palette" % (sane_name) if has_palette else "NULL"))
        gfx_source_file.write("\n  .chunk_count     = %d," % (len(compressed_chunk_offsets)))
        gfx_source_file.write("\n  .chunk_size      = %d," % (chunksize))
        gfx_source_file.write("\n  .chunk_offsets   = gfx_%s_chunk_offsets," % (sane_name))
        gfx_source_file.write("\n  .compressed_data = gfx_%s_chunk_data," % (sane_name))
        gfx_source_file.write("\n  .compressed_size = %d  // original = %d bytes (%s) / %6.2f%% of original // rgb24 = %d bytes / %6.2f%% of rgb24" % (len(compressed_data), len(image_data), format_name, (100*len(compressed_data)/len(image_data)), (3*width*height), (100*len(compressed_data)/(3*width*height))))
        gfx_source_file.write("\n};\n\n")
        gfx_source_file.write("painter_image_t gfx_%s PROGMEM = (painter_image_t)&gfx_%s_compressed;\n\n" % (sane_name, sane_name))

    else:
        # Generate image data lookup table
        image_data = graphic_data[1]
        gfx_source_file.write("static const uint8_t gfx_%s_data[%d] PROGMEM = {\n " % (sane_name, len(image_data)))
        count = 0
        for j in image_data:
            gfx_source_file.write(" 0b{0:08b}".format(j))
            count += 1
            if count < len(image_data):
                gfx_source_file.write(",")
                if (count % newline_counter) == 0: # Place a new line when we reach the same number of pixels as each row
                    gfx_source_file.write("\n ")
        gfx_source_file.write("\n};\n\n")

        # Write out the image descriptor
        gfx_source_file.write("const painter_raw_image_descriptor_t gfx_%s_raw PROGMEM = {" % (sane_name))
        gfx_source_file.write("\n  .base = {")
        gfx_source_file.write("\n    .image_format = %s," % (image_format))
        gfx_source_file.write("\n    .compression  = IMAGE_UNCOMPRESSED,")
        gfx_source_file.write("\n    .width        = %d," % (width))
        gfx_source_file.write("\n    .height       = %d" % (height))
        gfx_source_file.write("\n  },")
        gfx_source_file.write("\n  .image_bpp     = %d," % (image_bpp))
        gfx_source_file.write("\n  .image_palette = %s," % ("gfx_%s_palette" % (sane_name) if has_palette else "NULL"))
        gfx_source_file.write("\n  .byte_count    = %d," % (len(image_data)))
        gfx_source_file.write("\n  .image_data    = gfx_%s_data," % (sane_name))
        gfx_source_file.write("\n};\n\n")
        gfx_source_file.write("painter_image_t gfx_%s PROGMEM = (painter_image_t)&gfx_%s_raw;\n\n" % (sane_name, sane_name))

    gfx_source_file.write("// clang-format on\n")
    gfx_source_file.close()

    # Generate the C header file
    gfx_header_file = open(gfx_header_filename, "w")
    gfx_header_file.write(fileHeader)
    gfx_header_file.write("/* generated from %s */\n\n" % (graphic_fname))
    gfx_header_file.write("#pragma once\n\n")
    gfx_header_file.write("#include <qp.h>\n\n")
    gfx_header_file.write("extern painter_image_t gfx_%s PROGMEM;\n" % (sane_name))
    gfx_header_file.close()

def main():
    global args
    parser = argparse.ArgumentParser(description="Convert images to RGB565, 1bpp, 2bpp, or 4bpp for QMK Firmware's quantum_painter")
    parser.add_argument('-o',  '--output',       help="The output file name",             type=str,  required=True)
    parser.add_argument('-c',  '--compress',     help="Compresses the output using LZF",             dest="compress",   action="store_true")
    parser.add_argument('-k',  '--chunk-size',   help="The compression chunk size",       type=int,  dest="chunksize")
    parser.set_defaults(compress=False)
    parser.set_defaults(chunksize=128)

    group_fmt = parser.add_mutually_exclusive_group(required=True)
    group_fmt.add_argument('-r',  '--rgb565',    help="Output format of RGB565",                    dest="fmt_rgb565",   action="store_true")
    group_fmt.add_argument('-4',  '--4bpp',      help="Output format of monochrome 4bpp",           dest="fmt_mono4bpp", action="store_true")
    group_fmt.add_argument('-2',  '--2bpp',      help="Output format of monochrome 2bpp",           dest="fmt_mono2bpp", action="store_true")
    group_fmt.add_argument('-1',  '--1bpp',      help="Output format of monochrome 1bpp",           dest="fmt_mono1bpp", action="store_true")
    group_fmt.add_argument(       '--pal8bpp',   help="Output format of 8bpp (256-colour) palette", dest="fmt_pal8bpp",  action="store_true")
    group_fmt.add_argument(       '--pal4bpp',   help="Output format of 4bpp (16-colour) palette",  dest="fmt_pal4bpp",  action="store_true")
    group_fmt.add_argument(       '--pal2bpp',   help="Output format of 2bpp (4-colour) palette",   dest="fmt_pal2bpp",  action="store_true")
    group_fmt.add_argument(       '--pal1bpp',   help="Output format of 1bpp (2-colour) palette",   dest="fmt_pal1bpp",  action="store_true")
    group_fmt.set_defaults(fmt_rgb565=False)
    group_fmt.set_defaults(fmt_mono4bpp=False)
    group_fmt.set_defaults(fmt_mono2bpp=False)
    group_fmt.set_defaults(fmt_mono1bpp=False)
    group_fmt.set_defaults(fmt_pal8bpp=False)
    group_fmt.set_defaults(fmt_pal4bpp=False)
    group_fmt.set_defaults(fmt_pal2bpp=False)
    group_fmt.set_defaults(fmt_pal1bpp=False)

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-i',  '--image-file',   type=str, help="The image file to use")

    args, unknown = parser.parse_known_args()

    if args.image_file:

        # Check image file actually exists
        if not os.path.exists(args.image_file):
            print("Can't find file %s" % (args.image_file))
            sys.exit(1)

        convert_graphic_to_c(args.image_file, args.output, args.compress, args.chunksize,
        args.fmt_rgb565,
        args.fmt_pal8bpp, args.fmt_pal4bpp, args.fmt_pal2bpp, args.fmt_pal1bpp,
        args.fmt_mono4bpp, args.fmt_mono2bpp, args.fmt_mono1bpp)

if __name__ == "__main__":
    main()
