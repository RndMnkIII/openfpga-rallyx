# Custom Palettes

Starting in OS 2.0, Pocket can load custom palette files in a new format called APGB. This is supported by cartridges and openFPGA that target GB.

1. Place `.pal` files on the SD card in the folder `/Assets/gb/common/palettes`
2. Enter Settings>Pocket>Systems>GB>Video>Color Palettes and select Custom, then Load Custom.
3. Select a file from the list.

## APGB File Format

* File extension: `.pal`
* File size: 56 bytes
* File structure: A series of RGB colors in 24-bit format, followed by a footer.

The Game Boy, while it has a grayscale display, actually has three distinct palettes. Each palette is represented by 4 intensities from dark to bright. In this file format, each intensity is mapped to a 24-bit RGB color (3 bytes). Thus, each palette is 12 bytes, and with four palettes total, this is 48 bytes altogether. We will call each color 0 to 3 from darkest to brightest.

A complete palette set is structured as follows:

* BG Palette `0 1 2 3`
* OBJ0 Palette `0 1 2 3`
* OBJ1 Palette `0 1 2 3`
* Window Palette `0 1 2 3`
* LCD Off Color `3`

## When does GB use each palette?

* BG is used on all background/tile layers.
* OBJ0 is used on most if not all sprites, depending on the game.
* OBJ1 is less common though used by some games for certain sprites.
* Window is used for static elements like status bars. Only Pocket and the BGB emulator are known to support this feature. Normally it should be the same as the BG palette.

Finally, there is a color specified for when the LCD is turned off. Normally, this should be a very light (or white) color. This color will be seen during loading screens in many games. For example, Pokemon Pinball turns the LCD off when moving the pinball between the top and bottom sections of the playfield.

At the end of the file are 5 extra bytes - 0x81 and the ASCII characters `APGB`. These must be present for the palette to be correctly recognized.

### Example

Here is a sample hex listing for a blue and orange palette:

```
000000 52528C 8C8CDE FFFFFF   ; BG
000000 944A4A FF8484 FFFFFF   ; OBJ0
000000 843100 FFAD63 FFFFFF   ; OBJ1
000000 555555 AAAAAA FFFFFF   ; Window
FFFFFF 81 41504742            ; LCDoff and footer
```
