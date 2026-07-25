# 1.1 beta 5

## Customized Controls

Existing openFPGA cores are now fully remappable on a per-core basis via the OS. Users can remap specific controls, reset to defaults, or remap-all with an easy and familiar guided process. Developers do not need to update cores as long as `input.json` has been included in the current release.

## Enhanced Core Organization

Now users can optionally organize their growing list of openFPGA cores using categories. When the new “Group openFPGA” setting is enabled (**Settings** > **Analogue OS**), the openFPGA root menu will alphabetically group and sort cores by the category key defined in `<platform>.json`. Platforms with no defined category will be added to the “Uncategorized” list.

## Documentation Updates

* Added [Debugging Aids](../debugging-aids.md) section
* Added [Chip32 Opcode Mnemonic table](../chip32-vm/opcode-mnemonic.md)
* Added various clarifications for Chip32

## Detailed changes and improvements

* Added Chip32 automatic reinitialization via JTAG
* Added Chip32 cycle limit during crash
* Added Chip32 full instruction execution to the logging tool
* Added logging to explain why a data slot may not have been saved
* Added Chip32 execution halt with B button
* Fixed Chip32 bug where HOST 4002 a second time while reloading a core would hang
* Fixed Chip32 bug where reloading a data slot would not correctly choose the new file
* Fixed Chip32 bug where PMP reads/writes weren't logged
* Fixed Chip32 CORE instruction - if user reloads FPGA with a new bitstream via JTAG, the CORE instruction will be skipped
* Fixed Chip32 LOADF instruction - now issues Host: Request Write and also respects any ADJFO parameters given
* Fixed Chip32 XFILL to handle zero length
* Fixed nonvolatile slot saving bug
