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
| `tb_fpga_nrx` | Z80 at 3.072 MHz; frame interrupt on line 224, inside vblank, at 60.606 Hz |
| `tb_nrx_video` | PCLK at 6.144 MHz, 50% duty; sprite divider holds constant phase against it |
| `tb_nrx_sprite` | 95-pixel blanking budget, and the sprite scan finishing inside it |
| `tb_nrx_sound` | 96.000 kHz WSG sampling; pitch = 96000 x freq / 2^20; wave ROM outruns sampling |
| `tb_nrx_bang` | 2000.000 Hz noise clock, 3584-tick burst = 1.792 s |
| `tb_pocket_i2s` | MCLK 12.288 MHz, SCLK 3.072 MHz, LRCK 48.000 kHz, 64 bit clocks per frame |
| `tb_rams` | One-clock registered read latency on every memory primitive |

## Two things you need to know

**The clock dividers have no initial value and no reset.** `_CCLK`,
`VCLKx2`/`VCLK`, `clkcnt`, `ccnt` and NPSG_WAV's `ad` all power up to 0 on
Cyclone V, but under Icarus they stay X forever and the clocks never start — the
module just looks dead. Every testbench here opens with an `initial` block
forcing them to 0. Copy that pattern for any new one.

**The Z80's instruction timing is not tested.** `T80s` is VHDL, and there is no
working VHDL simulator on this machine — Questa FSE ships with Quartus Lite but
needs a license file from Intel, and GHDL is not installed. `sim/stubs.v`
therefore supplies an inert `T80s` so the surrounding glue elaborates. What is
proven is that the CPU is *clocked* at 3.072 MHz and interrupted once per frame.
What is **not** proven is that T80 takes the same number of cycles per
instruction as a real Z80. Closing that needs either a free Questa FSE license
or GHDL installed, plus a cycle-counting test ROM.

`LINEBUF` is the better case: it wraps an `altsyncram` megafunction, and
`tools/sim.py` compiles Quartus's own simulation model
(`quartus/eda/sim_lib/altera_mf.v`) so the real thing is under test. Only if
that model cannot be found does it fall back to the behavioural stand-in in
`stubs.v`, and it says so when it does.

## Not covered

- `core_top.v` — the 96 kHz to 48 kHz audio decimation lives inline in a module
  that also instantiates the PLL, the APF bridge and the Analogizer, so it is
  not reachable as a unit without restructuring it.
- `core_bridge_cmd.v`, `data_loader.sv` — host bridge and ROM download. Their
  behaviour is protocol, not clock timing.
- `mf_pllbase` — a hard PLL; its output frequencies are a fitter constraint,
  checked by the Quartus compile rather than by simulation.
