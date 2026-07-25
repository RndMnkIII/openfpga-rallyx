# New Rally-X Hardware

Namco, 1981. Two-board set: video and sound are split across the two boards,
driven by a single Z80. Rally-X (1980) uses the same hardware; the differences
between the two are in ROM content and dip switch tables, not in the board design.

## Clocks

| Signal        | Frequency    | Derivation          |
| ------------- | ------------ | ------------------- |
| Master        | 18.432 MHz   | XTAL                |
| Z80           | 3.072 MHz    | Master ÷ 6          |
| Namco WSG     | 96 kHz       | Master ÷ 6 ÷ 32     |

## CPU

Single Zilog Z80 at 3.072 MHz. The interrupt vector/opcode register lives in I/O
space at port `0x00`; the game uses both IM 0 and IM 2, so that register holds
either an instruction byte or a vector depending on the mode currently set.

Interrupt enable is not a CPU-side setting — it is `INT ON`, bit 1 of the LS259
main latch. See [memory-map.md](memory-map.md).

## Video

| Property        | Value                          |
| --------------- | ------------------------------ |
| Type            | Raster                         |
| Refresh         | 60.606060 Hz                   |
| Total size      | 288 × 256 (36 × 32 tiles)      |
| Visible area    | 288 × 224 (`0..287`, `16..239`) |
| Orientation     | Horizontal                     |
| Palette entries | 64 × 4 + 4, from a 32-colour PROM |

Shadows are enabled in the MAME palette device. Flip screen is `FLIP`, bit 3 of
the main latch.

### Graphics decode

| Region | Layout   | Size    | Planes | Colours | Contents                       |
| ------ | -------- | ------- | ------ | ------- | ------------------------------ |
| `gfx1` | chars    | 8 × 8   | 2      | 64      | Playfield and radar tiles      |
| `gfx1` | sprites  | 16 × 16 | 2      | 64      | Cars, flags, rocks             |
| `gfx2` | dots     | —       | —      | 1       | Bullet/dot shapes, offset 64×4 |

Characters and sprites share the same `gfx1` region with different layouts; the
plane offsets are `{ 0, 4 }` (Rally-X ordering — the Konami derivatives such as
Jungler use `{ 4, 0 }`).

### Scroll and radar

Playfield scroll is two write-only registers, X at `0xA130` and Y at `0xA140`.
The radar strip is a separate tilemap; bullet shape and X position MSB are written
to the 16-byte `radarattr` window at `0xA000`–`0xA00F` (the driver notes only
locations `4`–`F` are used).

## Sound

Namco 3-channel WSG at 96 kHz, registers at `0xA100`–`0xA11F`, waveform data in
the `rx1-5.3p` PROM. Explosions are a separate discrete trigger, `BANG`, on bit 0
of the main latch.

MAME also attaches a samples device for the explosion. `SOUND ON` (main latch bit
2) is documented in the driver as not working in New Rally-X.

## Custom chips

Rally-X has two Namco customs, both described in the MAME driver as "nothing more
than simple logic" that can be replaced by TTL daughter boards:

| Part   | Package | Function                  | TTL replacement board |
| ------ | ------- | ------------------------- | --------------------- |
| NVC285 | DIP28   | Z80 sync bus controller   | A082-91383-B000       |
| NVC293 | DIP18   | Video shifter             | A082-91388-A000       |

## Controls

Two players, alternating, sharing one control panel in upright mode.

| Player | Controller     | Ways | Buttons |
| ------ | -------------- | ---- | ------- |
| 1      | Joystick       | 4    | 1       |
| 2      | Joystick       | 4    | 1       |

The single button is the smoke screen. Player 2's inputs are on the `P2` port and
are only wired to a second stick in cocktail cabinets; the `P2` bit `0x01` dip
selects upright or cocktail.

## Watchdog

A watchdog timer is reset by writing to `0xA080`. The same address reads back the
`P2` port.

## Sources

MAME `rallyx.cpp` (driver by Nicola Salmoria, BSD-3-Clause) and the
[Arcade Repair DB New Rally-X entry][ardb].

[ardb]: https://www.arcaderepairdb.com/game/version/New-Rally-X/New-Rally-X
