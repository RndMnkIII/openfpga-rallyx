> [!NOTE]
> 🤖 This core's openFPGA port, tooling, and documentation was written with Claude Opus 5 (1M context) in Claude Code.

# openFPGA-RallyX

## Analogizer
* Pocket Menu: __Enable Analogizer: Off, On__: if you don't enable this option all functionality related to Analogizer will be disabled.

For more info about Analogizer adapter check the [wiki](https://github.com/RndMnkIII/Analogizer/wiki).

Analogizer uses a configuration file to select Analogizer adapter remaining options, not based on the Pocket's menu system. It is necessary to run an external utility [Pupdate >= 4.4.0](https://github.com/mattpannella/pupdate/releases)  or [AnalogizerConfigurator >= 0.4](https://github.com/RndMnkIII/AnalogizerConfigurator/releases) to generate such a file. Once generated, you must copy the `analogizer.bin` file to the `/Assets/analogizer/common` folder on the Pocket SD card. If this folder does not exist, you must create it. Check the refered utility for the relevant options for the Analogizer adapter: SNAC controller, SNAC controller assigments (how to map physical SNAC game controllers to the Pocket openFPGA framework PAD format), Video output and Blank the Pocket Screen (On/Off).

The core can output RGBS, RGsB, YPbPr, Y/C and SVGA scandoubler (50% scanlines) video signals.
| Video output | Status | SOG Switch(Only R2,R3 Analogizer) |
| :----------- | :----: | :-------------------------------: |     
| RGBS         |  ✅    |     Off                           |
| RGsB         |  ✅    |     On                            |
| YPbPr        |  ✅🔹  |     On                            |
| Y/C NTSC     |  ✅    |     Off                           |
| Y/C PAL      |  ✅    |     Off                           |
| Scandoubler  |  ✅    |     Off                           |

🔹 Tested with Sony PVM-9044D

| :SNAC game controller:  | Analogizer A/B config Switch | Status |
| :---------------------- | :--------------------------- | :----: |
| DB15                    | A                            |  ✅    |
| NES                     | A                            |  ✅    |
| SNES                    | A                            |  ✅    |
| PCENGINE                | A                            |  ✅    |
| PCE MULTITAP            | A                            |  ✅    |
| PSX DS/DS2 Digital DPAD | B                            |  ✅    |
| PSX DS/DS2 Analog  DPAD | B                            |  ✅    |

The Analogizer interface allow to mix game inputs from compatible SNAC gamepads supported by Analogizer (DB15 Neogeo, NES, SNES, PCEngine, PSX) with Analogue Pocket built-in controls or from Dock USB or wireless supported controllers (Analogue support).

All Analogizer adapter versions (v1, v2 and v3) has a side slide switch labeled as 'A B' that must be configured based on the used SNAC game controller.
For example for use it with PSX Dual Shock or Dual Shock 2 native gamepad you must position the switch lever on the B side position. For the remaining
game controllers you must switch the lever on the A side position. 
Be careful when handling this switch. Use something with a thin, flat tip such as a precision screwdriver with a 2.0mm flat blade for example. Place the tip on the switch lever and press gently until it slides into the desired position:

```
     ---
   B|O  |A  A/B switch on position B
     ---   
     ---
   B|  O|A  A/B switch on position A
     ---
``` 

* **Analogizer** is responsible for generating the correct encoded Y/C signals from RGB and outputs to R,G pins of VGA port. Also redirects the CSync to VGA HSync pin.
The required external Y/C adapter that connects to VGA port is responsible for output Svideo o composite video signal using his internal electronics. Oficially
only the Mike Simone Y/C adapters (active) designs will be supported by Analogizer and will be the ones to use.
However, depending on the type of screen you have, passive Y/C adapters could work with different degrees of success.

Support native PCEngine/TurboGrafx-16 2btn, 6 btn gamepads and 5 player multitap using SNAC adapter
and PC Engine cable harness (specific for Analogizer). Many thanks to [Mike Simone](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder) for his great Y/C Encoder project.

You will need to connect an active VGA to Y/C adapter to the VGA port (the 5V power is provided by VGA pin 9). I'll recomend one of these (active):
* [MiSTerAddons - Active Y/C Adapter](https://misteraddons.com/collections/parts/products/yc-active-encoder-board/)
* [MikeS11 Active VGA to Composite / S-Video](https://ultimatemister.com/product/mikes11-active-composite-svideo/)
* [Active VGA->Composite/S-Video adapter](https://antoniovillena.com/product/mikes1-vga-composite-adapter/)

Using another type of Y/C adapter not tested to be used with Analogizer will not receive official support.

TBD