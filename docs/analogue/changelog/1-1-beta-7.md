# 1.1 beta 7

## Library

Library is a reference level database to catalog your game collection and the games you play. Every time you Play a game cartridge it will be automatically added to Library showing the date added and total game play time. For the best experience we suggest adding user generated game images onto your SD card.

## Screenshots

openFPGA cores now automatically support the new Screenshot feature. Taking a Screenshot (Menu + Start) saves a PNG image to the SD card using the video mode resolution of the currently running core. Screenshots and game details can be viewed in Memories.

## Instances and Multiple Bitstreams

Cores using `<instance>.json` files to start up can now select between up to 8 possible core bitstream files upon load. The number of possible memory writes from the JSON has been increased to 32.

## Documentation Changes

* Updated Core Definition Files: [`data.json`](../core-definition-files/data-json.md) with new Parameter Bitmap flag
* Updated Core Definition Files: [`<instance>.json`](../core-definition-files/instance-json.md) with new bitstream selection mechanism and removed variant selection.

## Detailed Changes and Improvements

* Added `core_select` node in [`<instance>.json`](../core-definition-files/instance-json.md)
* Removed `variant_select` node in [`<instance>.json`](../core-definition-files/instance-json.md)
* Added Parameters Bitmap: bit 9 - Persist browsed filename in [`data.json`](../core-definition-files/data-json.md)
* Fixed truncation bug in APF Target command [0184 Data slot write]
