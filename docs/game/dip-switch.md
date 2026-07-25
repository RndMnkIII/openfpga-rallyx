# New Rally-X Dip Switch Settings

Dip switch settings for the **`nrallyx`** romset — the set this core boots. Rally-X
(`rallyx` / `rallyxa`, 1980) uses the same banks at the same addresses but different
Bonus Life and Difficulty tables; do not mix the two.

Both banks are read by the Z80 as active-low ports, so **a closed (`On`) switch reads
as a `0` bit and an open (`Off`) switch reads as a `1` bit**:

| Bank  | Address  | Switch 1 | 2      | 3      | 4      | 5      | 6      | 7      | 8      |
| ----- | -------- | -------- | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| `DSW` | `0xA100` | `0x01`   | `0x02` | `0x04` | `0x08` | `0x10` | `0x20` | `0x40` | `0x80` |
| `P2`  | `0xA080` | `0x01`   | —      | —      | —      | —      | —      | —      | —      |

`P2` bits `0x02`–`0x80` are the cocktail player-2 controls, not switches. See
[memory-map.md](memory-map.md) for the full port bit assignments.

## Factory defaults

| Bank  | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |
| ----- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DSW` | Off | Off | On  | On  | On  | On  | Off | Off |
| `P2`  | Off | —   | —   | —   | —   | —   | —   | —   |

Which is: Service Mode Off, Bonus Life 20000/80000, Difficulty 3 Cars/Easy,
Coinage 1 Coin/1 Credit, Cabinet Upright.

## Dip Switch: DSW (`0xA100`)

Bonus Life is conditional — switches 2–3 select one of three thresholds, and which
three depends on the Difficulty set on switches 4–6. The bold prefix is the
Difficulty that a row applies to.

| 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | Function     | Option                          |
| --- | --- | --- | --- | --- | --- | --- | --- | ------------ | ------------------------------- |
| Off |     |     |     |     |     |     |     | Service Mode | Off*                            |
| On  |     |     |     |     |     |     |     |              | On                              |
|     | Off | On  |     |     |     |     |     | Bonus Life   | **3 Cars, Easy** 20000/80000*   |
|     | On  | Off |     |     |     |     |     |              | **3 Cars, Easy** 20000/100000   |
|     | Off | Off |     |     |     |     |     |              | **3 Cars, Easy** 20000/120000   |
|     | Off | On  |     |     |     |     |     |              | **4 Cars, Easy** 20000          |
|     | On  | Off |     |     |     |     |     |              | **4 Cars, Easy** 40000          |
|     | Off | Off |     |     |     |     |     |              | **4 Cars, Easy** 60000          |
|     | Off | On  |     |     |     |     |     |              | **1 Car, Medium** 20000/80000   |
|     | On  | Off |     |     |     |     |     |              | **1 Car, Medium** 20000/100000  |
|     | Off | Off |     |     |     |     |     |              | **1 Car, Medium** 20000/120000  |
|     | Off | On  |     |     |     |     |     |              | **2 Cars, Medium** 20000        |
|     | On  | Off |     |     |     |     |     |              | **2 Cars, Medium** 40000        |
|     | Off | Off |     |     |     |     |     |              | **2 Cars, Medium** 60000        |
|     | Off | On  |     |     |     |     |     |              | **3 Cars, Medium** 20000/80000  |
|     | On  | Off |     |     |     |     |     |              | **3 Cars, Medium** 20000/100000 |
|     | Off | Off |     |     |     |     |     |              | **3 Cars, Medium** 20000/120000 |
|     | Off | On  |     |     |     |     |     |              | **1 Car, Hard** 20000           |
|     | On  | Off |     |     |     |     |     |              | **1 Car, Hard** 40000           |
|     | Off | Off |     |     |     |     |     |              | **1 Car, Hard** 60000           |
|     | Off | On  |     |     |     |     |     |              | **2 Cars, Hard** 20000/80000    |
|     | On  | Off |     |     |     |     |     |              | **2 Cars, Hard** 20000/100000   |
|     | Off | Off |     |     |     |     |     |              | **2 Cars, Hard** 20000/120000   |
|     | Off | On  |     |     |     |     |     |              | **3 Cars, Hard** 20000/80000    |
|     | On  | Off |     |     |     |     |     |              | **3 Cars, Hard** 20000/100000   |
|     | Off | Off |     |     |     |     |     |              | **3 Cars, Hard** 20000/120000   |
|     |     |     | On  | On  | On  |     |     | Difficulty   | 3 Cars, Easy*                   |
|     |     |     | Off | On  | On  |     |     |              | 4 Cars, Easy                    |
|     |     |     | On  | Off | On  |     |     |              | 1 Car, Medium                   |
|     |     |     | Off | Off | On  |     |     |              | 2 Cars, Medium                  |
|     |     |     | On  | On  | Off |     |     |              | 3 Cars, Medium                  |
|     |     |     | Off | On  | Off |     |     |              | 1 Car, Hard                     |
|     |     |     | On  | Off | Off |     |     |              | 2 Cars, Hard                    |
|     |     |     | Off | Off | Off |     |     |              | 3 Cars, Hard                    |
|     |     |     |     |     |     | Off | Off | Coinage      | 1 Coin/1 Credit*                |
|     |     |     |     |     |     | On  | Off |              | 1 Coin/2 Credits                |
|     |     |     |     |     |     | Off | On  |              | 2 Coins/1 Credit                |
|     |     |     |     |     |     | On  | On  |              | Free Play                       |

Unlike Rally-X, New Rally-X has no "Bonus Life: None" setting and no
"2 Cars, Easy" difficulty; it has "4 Cars, Easy" instead.

## Dip Switch: P2 (`0xA080`)

| 1   | Function | Option   |
| --- | -------- | -------- |
| Off | Cabinet  | Upright* |
| On  |          | Cocktail |

`*` marks the factory default.

## Differences from Rally-X (`rallyx` / `rallyxa`)

Switch positions and functions are identical; only the option tables differ.

| Function   | Rally-X                                         | New Rally-X                                       |
| ---------- | ----------------------------------------------- | ------------------------------------------------- |
| Difficulty | 2 Cars/Easy … 3 Cars/Hard (default 3 Cars/Easy) | 4 Cars/Easy replaces 2 Cars/Easy (default 3/Easy) |
| Bonus Life | Single thresholds (10000–60000) plus `None`     | Repeating thresholds (20000/80000 …), no `None`   |

## Sources

Cross-checked between MAME's `rallyx.cpp` driver (`INPUT_PORTS_START( nrallyx )`)
and the [Arcade Repair DB New Rally-X entry][ardb]. Switch positions above were
derived from the MAME bit masks and `PORT_DIPLOCATION` annotations, then verified
against the Arcade Repair DB default-switch diagram.

**NOTE: Dip switch setting information is contributed by the community and although
is believed to be correct, has not been verified on real hardware by this project.**

[ardb]: https://www.arcaderepairdb.com/game/version/New-Rally-X/New-Rally-X
