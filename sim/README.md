# sim/

Icarus Verilog testbenches asserting this core's timing against the numbers the
original Namco board ran at. Run them with:

```
python tools/sim.py              # everything
python tools/sim.py --test sound # one
```

The runner exits non-zero if any testbench fails, and each testbench prints
what it measured rather than just a verdict — the numbers are the point.

## What each one pins down

| Testbench | Asserts |
|---|---|
| `tb_hvgen` | 384x264 raster, 288x224 active, 16.000 kHz line rate, 60.6061 Hz frame rate |
| `tb_fpga_nrx` | Z80 at 3.072 MHz; frame interrupt on line 224, inside vblank, at 60.606 Hz; IN0/IN1/DSW decode at $A000/$A080/$A100, read unlatched |
| `tb_nrx_video` | PCLK at 6.144 MHz, 50% duty; sprite divider holds constant phase against it |
| `tb_nrx_sprite` | 95-pixel blanking budget, and the sprite scan finishing inside it |
| `tb_nrx_sound` | 96.000 kHz WSG sampling; pitch = 96000 x freq / 2^20; wave ROM outruns sampling |
| `tb_nrx_bang` | 2000.000 Hz noise clock, 3584-tick burst = 1.792 s |
| `tb_pocket_i2s` | MCLK 12.288 MHz, SCLK 3.072 MHz, LRCK 48.000 kHz, 64 bit clocks per frame |
| `tb_rams` | One-clock registered read latency on every memory primitive |
| `tb_t80_timing` | Z80 instruction cycle counts — T-states per unprefixed instruction, measured M1-to-M1 |
| `tb_t80_prefixed` | T-states for the CB/ED/DD/FD instructions the game uses — LDIR 21/16, IX/IY, `DD CB` |
| `tb_t80_interrupt` | Mode 0 interrupt acknowledge: the EI shadow, the vector taken off the bus, RST 30h, 13 T-states |
| `tb_t80_exerciser` | T80's actual results and flags, against prelim.com — and zexdoc/zexall on demand |

## Two things you need to know

**The clock dividers have no initial value and no reset.** `_CCLK`,
`VCLKx2`/`VCLK`, `clkcnt`, `ccnt` and NPSG_WAV's `ad` all power up to 0 on
Cyclone V, but under Icarus they stay X forever and the clocks never start — the
module just looks dead. Every testbench here opens with an `initial` block
forcing them to 0. Copy that pattern for any new one.

**The Z80 runs under GHDL, not Icarus.** `T80s` is VHDL, so the four `tb_t80_*`
benches live in `sim/vhdl/` and `tools/sim.py` routes them to GHDL automatically. If GHDL
is missing the runner skips it and says so rather than failing. The Verilog
benches still use the inert `T80s` in `stubs.v` — they measure the glue around
the CPU, not the CPU.

Three GHDL flags are load-bearing: `--std=93` (T80 is VHDL-93), `-fsynopsys`
(its non-standard IEEE packages), and `--syn-binding`. Without the last one
GHDL refuses to bind `T80` inside `T80s` — the component is declared in
`T80_Pack` rather than in the architecture, and GHDL's strict default-binding
rule will not resolve that. The symptom is a silent `instance "u0" of component
"T80" is not bound` warning and a CPU that never executes anything.

**The vendored T80 has one local timing correction.** Its original microcode
gave unconditional `RET` a five-state opcode-fetch cycle, making the instruction
take 11 T-states. The Z80 uses the normal four-state fetch and takes 10. The
local change corrects that fetch while leaving conditional returns alone: a
not-taken `RET cc` takes 5 T-states and a taken one takes 11. The timing bench
checks all three paths as hard failures.

**The CPU is tested for answers, not just for timing.** `tb_t80_timing` proves
T80 spends the right number of clocks per instruction; it says nothing about
whether the instruction computed the right result, and it covers unprefixed
opcodes only. A census of `rallyx.rom` says that is the smaller half: the game
executes 163 distinct unprefixed opcodes and 708 prefixed sites — `LDIR`, `NEG`,
`SBC HL`, IX/IY loads and arithmetic, `DD CB` bit operations.

`tb_t80_exerciser` covers the rest by running the canonical Z80 exercisers under
a minimal CP/M rather than by inventing expectations. Fetch them first:

```
python tools/sync.py --repo z80-exercisers
```

Without them the bench reports a skip and passes. `prelim.com` is the default and
finishes in 9,972 T-states, so it stays in the normal suite. Frank Cringle's
exerciser is the thorough one and is opt-in:

```
python tools/sim.py --test t80_exerciser \
    --image .repos/z80-exercisers/roms/zexdoc.cim
```

Budget for it. GHDL's mcode backend runs this design at roughly 98,000 T-states
per second, so zexdoc is an overnight job, not a pre-commit check —
`--max-mcycles` bounds a shorter look, in millions of T-states. It prints a
heartbeat every 250M so a long run is visibly alive, and `tools/sim.py` streams
GHDL's output instead of buffering it, so an interrupted run still leaves its
progress on screen. The exerciser CRCs come from real hardware, which is the
point: they do not depend on this repository's reading of the datasheet.

`LINEBUF` is the better case: it wraps an `altsyncram` megafunction, and
`tools/sim.py` compiles Quartus's own simulation model
(`quartus/eda/sim_lib/altera_mf.v`) so the real thing is under test. Only if
that model cannot be found does it fall back to the behavioural stand-in in
`stubs.v`, and it says so when it does.

## Not covered

- `core_top.v` — the 96 kHz to 48 kHz audio decimation lives inline in a module
  that also instantiates the PLL, the APF bridge and the Analogizer, so it is
  not reachable as a unit without restructuring it.
- The clock-domain crossings in `core_top.v`, including the controller
  synchroniser feeding `CTR1`. Icarus has no metastability model: a missing
  synchroniser simulates exactly like a correct one. Read those against the
  reference cores and confirm them on hardware, never in a waveform.
- `core_bridge_cmd.v`, `data_loader.sv` — host bridge and ROM download. Their
  behaviour is protocol, not clock timing.
- `mf_pllbase` — a hard PLL; its output frequencies are a fitter constraint,
  checked by the Quartus compile rather than by simulation.
- Instruction timing outside the opcodes the two benches name. `tb_t80_timing`
  and `tb_t80_prefixed` between them measure 63 instructions chosen from what
  `rallyx.rom` executes, not the whole instruction set. Results and flags are
  the broad net — that is what `tb_t80_exerciser` is for.
