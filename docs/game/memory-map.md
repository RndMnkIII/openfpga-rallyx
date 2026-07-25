# New Rally-X Memory Map

Single Z80 at 3.072 MHz (18.432 MHz master ÷ 6) with an 8-bit I/O space used for
one register. Addresses below are as decoded by the `rallyx_map` address map that
`nrallyx` shares with `rallyx`.

## Program space

| Address           | Size          | Direction | Function                                                |
| ----------------- | ------------- | --------- | ------------------------------------------------------- |
| `0x0000`–`0x3FFF` | 16 KiB        | R         | Program ROM                                             |
| `0x8000`–`0x8FFF` | 4 KiB         | R/W       | Video RAM (playfield + radar tilemaps, sprite/bullet RAM) |
| `0x9800`–`0x9FFF` | 2 KiB         | R/W       | Work RAM                                                |
| `0xA000`          | 1             | R         | `P1` input port                                         |
| `0xA000`–`0xA00F` | 16            | W         | `radarattr` — bullet shape and X position MSB           |
| `0xA080`          | 1             | R         | `P2` input port (cabinet dip + cocktail controls)       |
| `0xA080`          | 1             | W         | Watchdog reset                                          |
| `0xA100`          | 1             | R         | `DSW` dip switch bank                                   |
| `0xA100`–`0xA11F` | 32            | W         | Namco 3-channel WSG sound registers                     |
| `0xA130`          | 1             | W         | Playfield scroll X                                      |
| `0xA140`          | 1             | W         | Playfield scroll Y                                      |
| `0xA170`          | 1             | W         | Unknown, writes discarded                               |
| `0xA180`–`0xA187` | 8             | W         | `mainlatch` LS259 addressable latch, data on D0         |

Note the deliberate read/write overlap at `0xA000`, `0xA080` and `0xA100` — each
address is an input port on read and an unrelated write target on write.

## I/O space

| Port | Direction | Function                     |
| ---- | --------- | ---------------------------- |
| `00` | W         | Z80 interrupt vector / opcode |

The game uses both IM 2 and IM 0, so this register holds either a vector or an
instruction byte depending on the mode in force.

## `mainlatch` (LS259 at `0xA180`–`0xA187`)

Each address writes bit D0 to one latch output. On Logic Board I this is a 259 at
12M, or a 4099 at 11M.

| Address  | Q | Signal   | Function                       |
| -------- | - | -------- | ------------------------------ |
| `0xA180` | 0 | BANG     | Explosion sound trigger        |
| `0xA181` | 1 | INT ON   | Interrupt enable               |
| `0xA182` | 2 | SOUND ON | Sound enable                   |
| `0xA183` | 3 | FLIP     | Flip screen                    |
| `0xA184` | 4 | —        | 1-player start lamp (`led0`)   |
| `0xA185` | 5 | —        | 2-player start lamp (`led1`)   |
| `0xA186` | 6 | —        | Coin lockout                   |
| `0xA187` | 7 | —        | Coin counter                   |

The MAME driver notes that SOUND ON "doesn't seem to work in New Rally X".

## Input ports

All inputs are active low — a pressed control or closed switch reads `0`.

### `P1` (`0xA000`, read)

| Bit    | Function       |
| ------ | -------------- |
| `0x01` | Service 1      |
| `0x02` | Button 1 (smoke) |
| `0x04` | Joystick left  |
| `0x08` | Joystick right |
| `0x10` | Joystick down  |
| `0x20` | Joystick up    |
| `0x40` | Start 1        |
| `0x80` | Coin 1         |

### `P2` (`0xA080`, read)

| Bit    | Function                          |
| ------ | --------------------------------- |
| `0x01` | Cabinet dip: `1` = Upright, `0` = Cocktail |
| `0x02` | Button 1 (cocktail player 2)      |
| `0x04` | Joystick left (cocktail)          |
| `0x08` | Joystick right (cocktail)         |
| `0x10` | Joystick down (cocktail)          |
| `0x20` | Joystick up (cocktail)            |
| `0x40` | Start 2                           |
| `0x80` | Coin 2                            |

### `DSW` (`0xA100`, read)

See [dip-switch.md](dip-switch.md).

## Board-level decode

The MAME driver header carries a schematic-level map for the RAM chips, which the
flat map above collapses. It is reproduced here because chip designators are useful
when comparing against a real board.

| Address bits       | Dir | Chips     | Description                       |
| ------------------ | --- | --------- | --------------------------------- |
| `1-0000xxxxxxxxxx` | R/W | RAM 6A/6C | Radar tilemap RAM + sprites       |
| `1-0001xxxxxxxxxx` | R/W | RAM 6B/6D | Playfield tilemap RAM             |
| `1-0010xxxxxxxxxx` | R/W | RAM 6J/6K | Radar tilemap RAM + sprites       |
| `1-0011xxxxxxxxxx` | R/W | RAM 6H/6L | Playfield tilemap RAM             |
| `1-0110xxxxxxxxxx` | R/W | RAM 6F/6M | Work RAM                          |
| `1-0111xxxxxxxxxx` | R/W | RAM 6E/6N | Work RAM                          |
| `1-1----10000xxxx` | W   | RAM 2N    | Sound control registers           |
| `1-1----10001xxxx` | W   | RAM 2P    | Sound control registers           |

The driver notes that the map derived from the schematics "doesn't seem to be
entirely correct" and was adjusted to match observed program behaviour, so the
chip names may be assigned incorrectly. `0xA170` (`WR3` on the schematic) is
written a great many times per frame with no known effect.

## Sources

MAME `rallyx.cpp` (driver by Nicola Salmoria) and the
[Arcade Repair DB New Rally-X entry][ardb], which hosts the same driver source
alongside its own memory map table.

[ardb]: https://www.arcaderepairdb.com/game/version/New-Rally-X/New-Rally-X
