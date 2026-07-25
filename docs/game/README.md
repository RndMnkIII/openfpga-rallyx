# Game Reference

Arcade-hardware reference for **New Rally-X** (`nrallyx`, Namco 1981) — the romset
this core boots. Where Rally-X (`rallyx` / `rallyxa`, 1980) differs, the difference
is called out in the relevant page.

| Page                             | Contents                                                                 |
| -------------------------------- | ------------------------------------------------------------------------ |
| [hardware.md](hardware.md)       | Clocks, CPU, video and sound parameters, custom chips, controls           |
| [memory-map.md](memory-map.md)   | Z80 program and I/O maps, input port bits, LS259 main latch outputs       |
| [rom-set.md](rom-set.md)         | ROM parts with CRC32/SHA1/Fluke signatures, and the assembled core image  |
| [dip-switch.md](dip-switch.md)   | Both dip switch banks with exact switch positions and factory defaults    |

These pages document the original arcade hardware, not this core's
implementation of it. Where the core deviates, the core is what ships — treat a
mismatch as something to investigate rather than as a spec.

## Sources

- MAME `rallyx.cpp`, driver by Nicola Salmoria (BSD-3-Clause) — address maps,
  input ports, ROM definitions, machine configuration, and the schematic-level
  notes in the driver header.
- [Arcade Repair DB — New Rally-X][ardb] — memory map, ROM table with Fluke 9010
  signatures, dip switch diagrams, chip and display data. Contributed by
  Arcadenut and AzureOz.
- [International Arcade Museum — Rally-X dips][iam] — Rally-X (`rallyxa`) dip
  switch settings, used for the Rally-X comparison in `dip-switch.md`.

[ardb]: https://www.arcaderepairdb.com/game/version/New-Rally-X/New-Rally-X
[iam]: https://www.arcade-museum.com/tech-center/game-dips/rallyxa
