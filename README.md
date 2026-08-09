> [!NOTE]
> 🤖 Development of this core was made with Claude Opus 5 (1M context) in
> Claude Code.

# openFPGA-RallyX

An Analogue Pocket core that plays both Rally-X and New Rally-X.

## Installation

The core installs two ways. The game ROM is on you either way.

### With Pupdate

[Pupdate](https://github.com/mattpannella/pupdate/releases) is the short path.
This core is on its list, so Pupdate downloads it, installs it to
`Cores/MorganVieira.Rally-X`, and picks up every later release without you
watching this page for one. It is also what generates the `analogizer.bin` an
Analogizer adapter needs, which [ANALOGIZER.md](ANALOGIZER.md) covers.

### By hand

Download the [latest release](https://github.com/morgan-vieira/openFPGA-RallyX/releases/latest),
unzip it, and merge `Cores`, `Platforms` and `Assets` into the root of your
Pocket's SD card. The archive is already laid out the way the Pocket expects, so
nothing needs renaming or moving once it is across.

### The game ROM

Both paths stop here. The core ships with no ROM data in it and never will, so
you obtain a MAME set yourself: `rallyx.zip` for Rally-X, `nrallyx.zip` for New
Rally-X. Pupdate does not change that. A core is not a game.

The Pocket cannot read a MAME zip, so `tools/build_rom.py` assembles the parts
into the one image the core loads:

```
python tools/build_rom.py --zip path/to/rallyx.zip
```

The script works out which of the two sets the zip holds from the parts inside,
checks every part against its CRC32, and writes `build/rallyx.rom` or
`build/nrallyx.rom`, 21,280 bytes either way. The CRC32 check earns its keep:
wrong or half-renamed parts assemble to exactly the right size and boot to a
black screen, which reads as a broken core rather than a bad zip. The script
refuses them at the door instead.

Copy the image onto the SD card at `Assets/rallyx/common/`, creating that folder
if it does not exist. Both games can sit in it at once. The Pocket asks which one
to load each time the core starts, and the core menu switches between them while
running.

Python 3 and nothing else is all the script needs.