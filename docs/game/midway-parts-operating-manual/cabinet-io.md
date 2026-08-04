# Cabinet I/O

Everything the logic board set exchanges with the outside world crosses one
44-pin edge connector: five control inputs per player, three start/credit
inputs, four video lines, one audio line, the coin path, and power.

The connector is on Game Logic Board I. Transcribed from the three cabinet wiring
schematics, and cross-checked against the connector list on Board I's own logic
schematic — see [boards.md](boards.md):

| Cabinet        | Game no. | Drawing           |
| -------------- | -------- | ----------------- |
| Upright        | 935      | `M051-00935-A033` |
| Cocktail table | 936      | `M051-00936-A002` |
| Mini           | 937      | `M051-00937-A002` |

All three are dated 1/27/81 and all three drive the same board pair.

## The 44-pin edge connector

Pins are numbered `1`–`22` on one side and lettered on the other, the usual
arcade convention. Two key slots are cut, between `C` and `D` and between `E`
and `F`.

### Numbered side

| Pin | Signal             | Wire    | Notes                                     |
| --- | ------------------ | ------- | ----------------------------------------- |
| 1   | Logic GND          | `R-B`   | tied to pin `A`                           |
| 2   | Logic GND          | `R-B`   | tied to pin `B`                           |
| 3   | +5V                | `R-W`   | tied to pin `C`                           |
| 4   | +5V                | `R-W`   |                                           |
| 6   | Coin meter         | `G-W`   | drives the mechanical counter             |
| 8   | Player 2 Start     | `B-Y`   |                                           |
| 9   | P2 Move Up         | `BLU-Y` | **cocktail only**                         |
| 10  | P2 Move Down       | `O-R`   | **cocktail only**                         |
| 11  | P2 Move Right      | `R-BLU` | **cocktail only**                         |
| 12  | P2 Move Left       | `O-G`   | **cocktail only**                         |
| 13  | P2 Smoke button    | `BLU-R` | **cocktail only**                         |
| 14  | Test switch        | `O-W`   |                                           |
| 15  | Cabinet-type strap | `Y-G`   | grounded on the cocktail only — see below |
| 16  | Video RED          | `RED`   | monitor colour interface pin 3            |
| 17  | Video GREEN        | `GRN`   | monitor colour interface pin 5            |
| 18  | Composite sync     | `ORN`   | monitor sync connector pin 1              |
| 19  | Speaker            | `W-Y`   |                                           |
| 20  | +V Audio           | `W-BRN` | supply, not signal                        |
| 21  | Logic GND          | `Y-G`   | tied to pin `Z`                           |
| 22  | Logic GND          | `Y-G`   |                                           |

### Lettered side

| Pin | Signal             | Wire    | Notes                             |
| --- | ------------------ | ------- | --------------------------------- |
| `A` | Logic GND          | `R-B`   | tied to pin 1                     |
| `B` | Logic GND          | `R-B`   | tied to pin 2                     |
| `C` | +5V                | `R-W`   | tied to pin 3. Key slot after     |
| `D` | +5V                | `R-W`   |                                   |
| `E` | (to Credit Bypass) | `BLU-B` | Key slot after                    |
| `H` | Coin switch        | `O-G`   |                                   |
| `J` | Player 1 Start     | `BR-B`  |                                   |
| `K` | P1 Move Up         | `W-B`   |                                   |
| `L` | P1 Move Down       | `BR-W`  |                                   |
| `M` | P1 Move Right      | `Y-R`   |                                   |
| `N` | P1 Move Left       | `BLU-W` |                                   |
| `P` | P1 Smoke button    | `W-R`   |                                   |
| `R` | Credit switch      | `W-O`   | the cash-box test button          |
| `T` | – Sense            | `R-G`   | supply sense, back to power board |
| `U` | Video (4th line)   | `R-Y`   | monitor colour interface pin 6    |
| `V` | Video BLUE         | `BLU`   | monitor colour interface pin 4    |
| `W` | Speaker            | `G-B`   |                                   |
| `Y` | Logic GND          | `Y-G`   |                                   |
| `Z` | Logic GND          | `Y-G`   | tied to pin 21                    |

### The board's own names for these pins

The tables above were read off the cabinet wiring schematics, which label pins by
wire colour and destination. Board I's logic schematic (`M051-00935-C023`) lists
the same connector with Midway's functional signal names, and where the two
differ the board drawing is the better source:

| Pin  | Board I name   | Pin  | Board I name           |
| ---- | -------------- | ---- | ---------------------- |
| `14` | `TEST POS.`    | `9`  | `P2 UP`                |
| `H`  | `COIN S.W.`    | `10` | `P2 DN`                |
| `J`  | `1 PLY SELECT` | `11` | `P2 RT`                |
| `K`  | `P1 UP`        | `12` | `P2 LT`                |
| `L`  | `P1 DN`        | `13` | `P2 SMOKE`             |
| `M`  | `P1 RT`        | `15` | `TO GND FOR C.T. ONLY` |
| `N`  | `P1 LT`        | `19` | `SPKR`                 |
| `P`  | `P1 SMOKE`     | `W`  | `SPKR`                 |
| `R`  | `CREDIT S.W.`  | `7`  | `NC`                   |
| `8`  | `2 PLY SELECT` |      |                        |

Two corrections fall out of this list:

**Pin 7 is `NC`.** Not merely undrawn on the cabinet harnesses — the board
drawing marks it explicitly as no-connect.

**Pin 15 is a cabinet-type strap, not just a ground.** The board names it
`TO GND FOR C.T. ONLY` — grounded on the cocktail table and left open otherwise.
It is an input that tells the board which cabinet it is in, and it is the only
such input on the connector. The cabinet wiring schematics obscure this by
drawing it as one more logic ground on the cocktail sheet and omitting it
elsewhere.

Note also that the start buttons are named `1 PLY SELECT` and `2 PLY SELECT`
rather than "start", and the test switch `TEST POS.` rather than "test".

Letters `F`, `S` and `X` and pin `5` appear on neither the cabinet harnesses nor
the Board I connector list. `F` is a key position.

> [!NOTE]
> Pin `U` carries the fourth wire of the 6-position monitor colour interface, on
> a red/yellow wire. The other three are labelled `RED`, `BLU` and `GRN` on the
> drawing; this one is labelled only by wire colour. It is most likely the video
> return, but the manual does not say, and it is recorded here as unknown rather
> than assumed.

## Controls

Four-way joystick and one button per player. The button is the smoke screen.

The **upright and mini wire Player 1 only.** Player 2's five inputs on pins
`9`–`13` exist solely on the cocktail, where the second control shelf plugs into
them; the cocktail schematic brackets those five pins and labels them
`PLAYER #2 CONTROL`. On an upright, two-player games alternate on the Player 1
stick and pins `9`–`13` are dead.

The two start buttons are wired on both cabinets regardless — `J` for one player,
`8` for two.

## Video

Four lines to the monitor plus separate composite sync:

```
   board                             monitor
   pin 16  RED  --------------------> colour interface 3
   pin V   BLU  --------------------> colour interface 4
   pin 17  GRN  --------------------> colour interface 5
   pin U   (R-Y wire) --------------> colour interface 6
   pin 18  ORN  --------------------> sync connector 1
```

Composite sync is its own 3-position connector, separate from colour. The
inter-board connector calls this signal `/CMPSYNC` (see
[boards.md](boards.md)) — the cabinet harness carries it on the orange wire.

## Audio

One audio line off the board on pin 19, returning on pin `W`, into a 6" x 9"
8-ohm 9-watt speaker (Midway part `0017-00003-0187`). Audio supply comes back
the other way on pin 20 as `+V Audio`.

There is one amplifier and one speaker. The volume pot on Board I sets the level
of everything.

## Coin and credit path

Three separate things get called "credit" in this manual and they are not the
same:

**Coin switch** (pin `H`) — the actual coin mechanism switch in the door.
Deposits a coin, advances the mechanical coin meter on pin 6, and awards credits
according to the coinage dip setting.

**Credit switch** (pin `R`) — a push button in the cash box area, reachable by
opening the coin door. The manual is explicit about what makes it different:

> This switch is provided as a test aid and awards one credit without advancing
> coin meter.

**Credit Bypass P.C.** (`A082-91109-A000`, via pin `E`) — a small board in the
harness of all three cabinets, between the coin switches and the game board.

The optional **Credit Multiplier** board is a fourth thing again and is not
fitted by default. See [boards.md](boards.md).

## Test switch

Pin 14. On the **mini and cocktail** this is a slide switch to the right of the
cash box, next to the credit push button. Sliding it to `ON` puts the game in
test mode; it is normally `OFF`.

The **upright** page of the manual describes only the credit push button and
never mentions a test slide, though the upright wiring schematic clearly shows a
switch on pin 14 labelled `TEST` / `ON`. Either the upright's switch is
elsewhere in the cabinet or its page is simply incomplete. The manual does not
resolve this.

What the test switch does is in [diagnostics.md](diagnostics.md).

## Tilt

A tilt switch appears on all three wiring schematics, on a blue wire, wired in
series with the control ground rail rather than to its own connector pin. The
manual never mentions tilt in any of its text — no setup instruction, no test
procedure, no parts callout. It is drawn and then ignored.

## Line voltage safety switch

Not a logic signal, but the thing most likely to confuse someone servicing a real
cabinet, and the manual leads with it on every cabinet page:

| Cabinet       | Location                               | Opens when           |
| ------------- | -------------------------------------- | -------------------- |
| Upright, mini | Right rear side, in the back door area | Back door is removed |
| Cocktail      | In the cabinet, left of the coin door  | Coin door is opened  |

To restore power while servicing, pull the switch fully out. The transformer also
has extra taps to compensate for a low or high supply line — see
[power.md](power.md).
