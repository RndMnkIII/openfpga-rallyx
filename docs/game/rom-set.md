# New Rally-X ROM Set (`nrallyx`)

Reference data for the MAME `nrallyx` set and how `scripts/build_rom.ps1` folds it
into the single `nrallyx.rom` image the core loads.

## ROM parts

CRC32 and SHA1 are MAME's. "Fluke" is the Fluke 9010 signature published by
Arcade Repair DB, useful when testing a real board.

### `maincpu` — program ROM, 16 KiB

Each file is 4096 bytes and is split in half by MAME's `ROM_CONTINUE`: the low
2 KiB and high 2 KiB land 4 KiB apart in the Z80 address space.

| File          | Size  | Loads at        | CRC32      | Fluke  | SHA1                                       |
| ------------- | ----- | --------------- | ---------- | ------ | ------------------------------------------ |
| `nrx_prg1.1d` | 4,096 | `0x0000`+`0x1000` | `ba7de9fc` | `D74F` | `2133ca327589600bcbd796c213f034daa0457f72` |
| `nrx_prg2.1e` | 4,096 | `0x0800`+`0x1800` | `eedfccae` | `1A42` | `9fca8500f724864a2b73e38bd40cbaeef41617d7` |
| `nrx_prg3.1k` | 4,096 | `0x2000`+`0x3000` | `b4d5d34a` | `FE22` | `c533470aac040b3471d79fd6d35beb4fd4b5bb19` |
| `nrx_prg4.1l` | 4,096 | `0x2800`+`0x3800` | `7da5496d` | `D579` | `ffac2c07dda57285673073266712fa2987e3b34f` |

### `gfx1` — characters and sprites, 4 KiB

| File          | Size  | Region offset | CRC32      | Fluke  | SHA1                                       |
| ------------- | ----- | ------------- | ---------- | ------ | ------------------------------------------ |
| `nrx_chg1.8e` | 2,048 | `0x0000`      | `1fff38a4` | `3102` | `5f6ccce2e0daad5915d017e8d067f187eb2ed41d` |
| `nrx_chg2.8d` | 2,048 | `0x0800`      | `85d9fffd` | `B3E8` | `12dff66d98a808b9dc952b2d87a56308b46a973e` |

### `gfx2` — bullet/dot shapes, 256 bytes

| File       | Size | Region offset | CRC32      | Fluke  | SHA1                                       | Type            |
| ---------- | ---- | ------------- | ---------- | ------ | ------------------------------------------ | --------------- |
| `rx1-6.8m` | 256  | `0x0000`      | `3c16f62c` | `1701` | `7a3800be410e306cf85753b9953ffc5575afbcd6` | IM5623 — dots   |

### `proms` — palette and lookup, 352 bytes

| File          | Size | Region offset | CRC32      | Fluke  | SHA1                                       | Type                                |
| ------------- | ---- | ------------- | ---------- | ------ | ------------------------------------------ | ----------------------------------- |
| `nrx1-1.11n`  | 32   | `0x0000`      | `a0a49017` | `45A1` | `494c920a157e9f876d533c1b0146275a366c4989` | M3-7603-5 — palette                 |
| `nrx1-7.8p`   | 256  | `0x0020`      | `4e46f485` | `46D3` | `3f013aafba96a76d410f2db16d1d24d2fb257aaf` | IM5623 — colour lookup table        |
| `rx1-2.4n`    | 32   | `0x0120`      | `8f574815` | `6A54` | `4f84162db9d58b64742c67dc689eb665b9862fb3` | N82S123N — video layout, not used   |
| `rx1-3.7k`    | 32   | `0x0140`      | `b8861096` | `11F3` | `26fad384ed7a1a1e0ba719b5578e2dbb09334a25` | M3-7603-5 — video timing, not used  |

### `namco` — sound PROMs, 512 bytes

| File       | Size | Region offset | CRC32      | Fluke  | SHA1                                       | Type                |
| ---------- | ---- | ------------- | ---------- | ------ | ------------------------------------------ | ------------------- |
| `rx1-5.3p` | 256  | `0x0000`      | `4bad7017` | `45C1` | `3e6da9d798f5e07fa18d6ce7d0b148be98c766d5` | IM5623 — waveforms  |
| `rx1-4.2m` | 256  | `0x0100`      | `77245b66` | `E0E5` | `0c4d0bee858b97632411c440bea6948a74759746` | IM5623 — not used   |

## Assembled core image

`scripts/build_rom.ps1` concatenates 14 slices into a flat **21,280-byte**
`nrallyx.rom`, in the order taken from the MiSTer `New Rally-X.mra`. The four
program ROMs are sliced into 2 KiB halves so the first 16 KiB of the image is
already in Z80 address order — no `ROM_CONTINUE` fixup is needed in the core.

| Image offset | Source                       | Length |
| ------------ | ---------------------------- | ------ |
| `0x0000`     | `nrx_prg1.1d` bytes 0–2047   | 2,048  |
| `0x0800`     | `nrx_prg2.1e` bytes 0–2047   | 2,048  |
| `0x1000`     | `nrx_prg1.1d` bytes 2048–4095 | 2,048  |
| `0x1800`     | `nrx_prg2.1e` bytes 2048–4095 | 2,048  |
| `0x2000`     | `nrx_prg3.1k` bytes 0–2047   | 2,048  |
| `0x2800`     | `nrx_prg4.1l` bytes 0–2047   | 2,048  |
| `0x3000`     | `nrx_prg3.1k` bytes 2048–4095 | 2,048  |
| `0x3800`     | `nrx_prg4.1l` bytes 2048–4095 | 2,048  |
| `0x4000`     | `nrx_chg1.8e`                | 2,048  |
| `0x4800`     | `nrx_chg2.8d`                | 2,048  |
| `0x5000`     | `rx1-6.8m`                   | 256    |
| `0x5100`     | `rx1-5.3p`                   | 256    |
| `0x5200`     | `nrx1-7.8p`                  | 256    |
| `0x5300`     | `nrx1-1.11n`                 | 32     |
| `0x5320`     | end                          | —      |

The three PROMs MAME marks "not used" (`rx1-2.4n`, `rx1-3.7k`, `rx1-4.2m`) are not
part of the core image; they must still be present in the zip for the set to
validate in MAME.

## Sources

MAME `rallyx.cpp` (`ROM_START( nrallyx )`), the MiSTer `New Rally-X.mra` for the
assembly order, and the [Arcade Repair DB New Rally-X entry][ardb] for the Fluke
9010 signatures.

[ardb]: https://www.arcaderepairdb.com/game/version/New-Rally-X/New-Rally-X
