# Self-Test and Diagnostics

Rally-X tests itself. This is the one part of the manual that describes observable
machine behaviour — what appears on screen, what comes out of the speaker — rather
than parts and screws, and it is the most detailed section in the document.

## Power-on self-test

The test runs automatically at every power-on. From manual page 5:

> When the power in Rally-X is turned on the Self-Test automatically begins. If
> there is no problem in the PC boards it will change automatically into the
> "Attract Mode", when there is a problem the Self-Test is repeated and the words
> "BAD RAM" or "BAD ROM" will appear on the screen.

So the pass path is invisible: boot, test, attract mode, no message. The failure
path **loops** — the test repeats rather than halting, with `BAD RAM` or
`BAD ROM` on screen.

The manual is emphatic that a failure here ends the diagnostic session:

> Even if the problem cannot be located, do not go on to other test switches or
> volume test, but carry out the Self-Test using the Test-Switch.

## Test mode

Held in test mode for as long as the test switch is on. From manual page 6:

> Game is in test mode for a moment immediately after power is turned on or when
> test switch is on. When test switch is returned to "OFF" the game goes into
> attract mode.

Turning the switch on produces figures and words on screen **within 10 seconds**.
The sequence is ROM test, then RAM test, then the switch and sound test, and it
stops at the first failure.

### 1. ROM test

Checks the ROM data 4K at a time, then checks all of it together. On failure it
names the bad ROM by number — `ROM 1`, `ROM 2`, `ROM 3`, `ROM 4` — and **does not
proceed to the RAM test**. On success it displays `ROM OK` and moves on.

> [!IMPORTANT]
> The character ROM is not checked. The manual states this outright: "The
> character ROM is not checked." A board with corrupt graphics data will pass the
> ROM test cleanly. If you are chasing garbled tiles, the self-test will not help
> you.

The number in the message maps to a socket pair, not a single chip — see the
socket table in [boards.md](boards.md). `ROM 1` means `1B` or `1C` on a
2K-populated board, or `1B` alone on a 4K one.

### 2. RAM test

Runs only after `ROM OK`. Tests all twelve 2114s and, on failure, displays a
message naming the bank and nibble — the manual's example is `RAM 1L` — then
stops.

| Message  | Position | Message  | Position |
| -------- | -------- | -------- | -------- |
| `RAM 1L` | `6C`     | `RAM 4L` | `6L`     |
| `RAM 1H` | `6A`     | `RAM 4H` | `6H`     |
| `RAM 2L` | `6D`     | `RAM 5L` | `6M`     |
| `RAM 2H` | `6B`     | `RAM 5H` | `6F`     |
| `RAM 3L` | `6K`     | `RAM 6L` | `6N`     |
| `RAM 3H` | `6J`     | `RAM 6H` | `6E`     |

Only the 2114s are tested. The manual repeats this twice: "The RAM test is
performed only on ICCs numbered 2114."

### 3. Switch and sound test

If the RAM test passes, the game enters a combined input and audio test: each
switch, when pressed, plays one specific sound. This is a genuinely useful table
— it is a list of every distinct sound the game can make, each addressable by a
single button press.

| Switch                | Sound produced                              |
| --------------------- | ------------------------------------------- |
| Coin sw 1, 2          | sound made when coin is deposited           |
| Service sw            | service sound                               |
| 1 player start        | start music                                 |
| 2 players start       | music played before challenging stage       |
| P1 control up         | fuel warning                                |
| P1 control down       | sound made when fuel added to score         |
| P1 control right      | sound made when special check pt cleared    |
| P1 control left       | sound made when check pt cleared            |
| P1 smoke screen       | sound made when bonus car received          |
| P2 control up \*      | sound made when one full pattern is cleared |
| P2 control down \*    | BGM                                         |
| P2 control right \*   | crash noise                                 |
| P2 control left \*    | high score noise                            |
| P2 smoke screen \*    | sound of car running                        |

\* Applies only to the table model. On an upright the Player 2 inputs are not
wired — see [cabinet-io.md](cabinet-io.md) — so five of the fourteen sounds are
unreachable from an upright control panel.

Two combinations do something other than play a sound:

**Both smoke buttons together** — the display flip-flops (screen flip) and the
smoke screen sound plays. This is the only documented way to exercise the `FLIP`
signal from the control panel.

**Test switch off then back on within one second, while both smoke buttons are
held** — a cross-hatch pattern appears. The manual notes the pattern is
deliberately incomplete at the edges:

> In the table model one edge and in the upright model two edges of the pattern
> will not appear.

The missing edges are stated as expected behaviour, not as a fault symptom, and
the count differs by cabinet — one edge on the table model, two on the upright.
The manual does not explain why.

## What the self-test does not tell you

The manual is explicit that a failure message locates a fault to a part, and then
stops:

> When the problem has been located using the results of the Self-Test, contact
> the place of purchase of the machine.

There is no further fault tree, no signal-level troubleshooting, and no symptom
table. A machine that fails in a way the self-test does not name — no picture, no
sound, a fault in the character ROM — is outside what this document covers.

## Service notes from the scan

The scanned manual carries a handwritten annotation on manual page 7, below the
switch and sound test table, in a previous owner's hand:

> `7K BAD CAN CAUSE LOSS OF ALL COLOR OR ALL VIDEO.`

This is **not Midway's text** and is not corroborated anywhere in the manual's
prose. Position `7K` is not on the Board II schematic; Board I's schematic does
carry parts in row 7, and one of the two `7603` colour PROMs sits near `7K` —
which would make the note consistent with a colour PROM failure, though the scan
is not clean enough at that position to confirm the designator. Recorded because
it is on the document, and because it names a failure mode the manual itself does
not: total loss of colour or video, which no self-test message covers.

## Cautions the manual leads with

Reproduced because they say something about how fragile the hardware was
considered to be:

- "Make sure the electric power is shut off when replacing parts or when removing
  connectors."
- "PC board repairs are to be done by the seller — do not handle in any case.
  Above all else, never conduct test with the tester, etc. The voltage in the
  tester can ruin the IC's."
- "When connecting the connectors, be careful not to reverse the direction of the
  connectors."

The middle one is worth reading twice: Midway told operators that probing the
board with a multimeter could destroy it. Whether or not that was true, it
explains why the self-test is as thorough as it is — it was meant to be the
*only* diagnostic an operator ever performed.

The manual also frames the self-test as routine rather than exceptional: "The
self-test is the same as the inspection of an automobile. If possible, it is best
to do this each day."
