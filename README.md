## openFPGA-RallyX

An openFPGA port of the **New Rally-X** arcade hardware for the Analogue Pocket,
based on the [MiSTer Rally-X core] by [MiSTer-X].

## Overview

Rally-X (Namco, 1980) is a maze-chase game: you drive a blue car through a
scrolling maze collecting all the yellow flags while evading pursuing red cars.
A radar shows the flags and enemies, a limited **smoke screen** briefly disables
chasers, and rocks block the way.

## Technical specifications

- **Main CPU:**     Zilog Z80 @ 3.072 MHz
- **Sound Chip:**   Namco 3-channel WSG
- **Resolution:**   288×224, 16 colors
- **Display Box:**  384×264 @ 6.144 MHz
- **Aspect Ratio:** 4:3
- **Orientation:**  Horizontal

## Compatible Platforms

- Analogue Pocket

## Compatible Games

> **ROMs NOT INCLUDED:** By using this gateware you agree to provide your own ROMs.

| **Game**              | Region | Status |
| :-------------------- | :----: | :----: |
| New Rally-X (nrallyx) |  JPN   |   ✅    |

### ROM Instructions

This core loads a single **`nrallyx.rom`** image (**21,280 bytes**) assembled from
your legally-owned **New Rally-X** (`nrallyx`) MAME ROM set. `scripts/build_rom.ps1`
performs the assembly and validates every ROM part (byte layout from the
[MiSTer New Rally-X MRA]).

1. Obtain the `nrallyx.zip` MAME ROM set — you must provide your own.
2. Assemble the ROM image (PowerShell):
   ```powershell
   pwsh scripts/build_rom.ps1 -Zip path\to\nrallyx.zip
   ```
   This writes `build/nrallyx.rom` (21,280 bytes).
3. Copy `build/nrallyx.rom` to your SD card at `/Assets/rallyx/common/nrallyx.rom`.
4. Copy the `Cores` and `Platforms` folders from a [release] to the root of your SD card.

## Status of Features

- [x] Video (288×224)
- [x] Controls
- [x] Audio (Namco 3-channel WSG)
- [x] Free Play
- [ ] Dip Switch menu (difficulty / coinage / cars)
- [ ] Hi-Score save
- [ ] Pause

### Controls

| Pocket | Action       |
| :----- | :----------- |
| D-Pad  | Drive        |
| A      | Smoke screen |
| Start  | Start        |
| Select | Coin         |

## Building

The FPGA project lives in `src/fpga/` (Intel Quartus Prime Lite 21.1, Cyclone V
`5CEBA4`). Helper scripts (PowerShell):

- `scripts/sync.ps1` — clone reference cores into a local `.repos/`
- `scripts/package.ps1 [-SdRoot E:/] [-Zip]` — bit-reverse the bitstream and
  assemble the Pocket SD layout (add `-Zip` for a distributable archive)

## Credits and acknowledgment

- [MiSTer-X] — Rally-X arcade hardware RTL
- [Daniel Wallner] — T80 Z80 CPU core
- [Adam Gastineau] — APF Data Loader
- [Analogue] — openFPGA / APF framework and core template
- [opengateware] — `pocket_i2s` audio serializer (from their Dig Dug core)

## Powered by Open-Source Software

| Module            | Author                                         |
| :---------------- | :--------------------------------------------- |
| [Rally-X RTL]     | 2005 (c) MiSTer-X                              |
| [T80]             | 2001 (c) Daniel Wallner                        |
| [Data Loader]     | 2022 (c) Adam Gastineau (MIT)                  |
| [pocket_i2s]      | Analogue APF example, packaged by opengateware |
| APF core template | (c) Analogue                                   |

## License

Released under the [GNU General Public License v3.0](LICENSE), inherited from the
GPLv3 MiSTer Rally-X core this is based on. Bundled components keep their own
licenses: the APF Data Loader (MIT) and the T80 CPU (BSD-style).

## Legal Notices

Rally-X © 1980 NAMCO LTD. All rights reserved. Rally-X is a trademark of BANDAI
NAMCO ENTERTAINMENT INC. All other trademarks, logos, and copyrights are property
of their respective owners.

The author and contributors are in no way associated with or endorsed by Bandai
Namco Entertainment Inc.

[Rally-X]: https://en.wikipedia.org/wiki/Rally-X
[MiSTer Rally-X core]: https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer
[Rally-X RTL]: https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer/tree/master/rtl
[MiSTer New Rally-X MRA]: https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer/tree/master/releases
[Data Loader]: https://github.com/agg23/analogue-pocket-utils
[pocket_i2s]: https://github.com/opengateware/arcade-digdug/tree/master/modules/pocket-i2s
[T80]: https://opencores.org/projects/t80
[release]: https://github.com/morgan-vieira/openfpga-rallyx/releases
[MiSTer-X]: https://github.com/MrX-8B
[Adam Gastineau]: https://github.com/agg23
[Analogue]: https://www.analogue.co/developer
[opengateware]: https://github.com/opengateware
[Daniel Wallner]: https://opencores.org/projects/t80
