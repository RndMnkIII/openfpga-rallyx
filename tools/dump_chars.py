#!/usr/bin/env python3
"""Render the Rally-X character ROM as ASCII art.

Both romsets put a 4 KiB character generator at 0x4000 of the core ROM image:
256 tiles, 8x8 pixels, 2 bits per pixel. The layout is not a plain bitmap, it is
whatever NRX_VIDEO reads, so this decoder mirrors that module exactly:

    CHRA  = { CHRC, HP[2], VP[2:0] }        -> offset = code*16 + 8*half + y
    BGCOL = { BGPL, CHRO[4+k], CHRO[0+k] }  -> pixel k of that 4-pixel group

So byte (code*16 + 8*half + y) holds x = 4*half .. 4*half+3 of row y, and the
shifter clocks those four pixels out right-to-left. Get the mirroring wrong and
every glyph comes out backwards, which is the one mistake worth knowing about
before you doubt the ROM.

Useful thing this establishes: the glyphs are plain ASCII (0x30-0x39 digits,
0x41-0x5A letters, 0x40 blank). That is why screen text is greppable straight
out of the program ROM at 0x0000-0x3FFF -- searching nrallyx.rom for "CAST"
finds the attract-mode string table at 0x22C8 with no tooling at all.

Sprites share this same 4 KiB, addressed differently (SPCHRADR in NRX_SPRITE
reads it as 64 16x16 tiles), so a code here is not a sprite number.
"""

import argparse
from pathlib import Path

from _common import Fail, run

CHR_OFF = 0x4000
CHR_LEN = 0x1000
TILE_BYTES = 16
TILE_COUNT = CHR_LEN // TILE_BYTES
ROM_SIZE = 21280

# Two bits per pixel. Colour 0 is the transparent/background entry, so a blank
# tile reads as all dots.
SHADE = {0: ".", 1: "+", 2: "*", 3: "#"}


def tile(rom, code):
    """Return the 8 rows of one tile, each an 8-character string."""
    rows = []
    for y in range(8):
        row = ""
        for half in range(2):
            byte = rom[CHR_OFF + code * TILE_BYTES + 8 * half + y]
            for k in range(4):
                row += SHADE[((byte >> (4 + k)) & 1) << 1 | ((byte >> k) & 1)]
        rows.append(row[::-1])
    return rows


def dump(rom, first, last, per_row):
    for base in range(first, last, per_row):
        codes = [c for c in range(base, min(base + per_row, last))]
        glyphs = [tile(rom, c) for c in codes]
        labels = []
        for c in codes:
            ch = chr(c) if 0x21 <= c <= 0x7E else " "
            labels.append(f"--{c:02X}{ch}---".ljust(8))
        print("  ".join(labels))
        for y in range(8):
            print("  ".join(g[y] for g in glyphs))
        print()


def auto_int(text):
    return int(text, 0)


def main():
    parser = argparse.ArgumentParser(
        description="Render the character ROM of a Rally-X core ROM image as "
        "ASCII art. Tile codes are ASCII: 0x41 is 'A', 0x30 is '0'."
    )
    parser.add_argument(
        "rom", type=Path, help="core ROM image (rallyx.rom or nrallyx.rom)"
    )
    parser.add_argument(
        "--first",
        type=auto_int,
        default=0,
        help="first tile code, accepts 0x notation (default: 0)",
    )
    parser.add_argument(
        "--last",
        type=auto_int,
        default=TILE_COUNT,
        help=f"one past the last tile code (default: {TILE_COUNT})",
    )
    parser.add_argument(
        "--per-row",
        type=auto_int,
        default=8,
        help="tiles printed side by side (default: 8)",
    )
    args = parser.parse_args()

    if not args.rom.is_file():
        raise Fail(f"ROM image not found: {args.rom}")
    rom = args.rom.read_bytes()
    if len(rom) != ROM_SIZE:
        raise Fail(
            f"{args.rom} is {len(rom)} bytes, expected {ROM_SIZE} -- this wants a "
            "core ROM image from build_rom.py, not a raw MAME part"
        )
    if not 0 <= args.first < args.last <= TILE_COUNT:
        raise Fail(
            f"tile range must satisfy 0 <= first < last <= {TILE_COUNT}, "
            f"got first={args.first} last={args.last}"
        )
    if args.per_row < 1:
        raise Fail("--per-row must be at least 1")

    dump(rom, args.first, args.last, args.per_row)


if __name__ == "__main__":
    run(main)
