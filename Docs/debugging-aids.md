# Debugging Aids

## Developer Options Menu

In the **Tools** > **Developer** menu are several options for helping the debug process. Only the first two are remembered, and the others are reset on power-off.

### Builds

A list of all currently installed cores, sorted alphabetically. If a core folder exists, it will be shown here, even if its platform association is broken or missing. When a core appears here but not in the openFPGA menu, make sure that its platform shortname matches an existing platform JSON and that this JSON has valid syntax.

### USB SD Access

When enabled, plugging in a USB-C cable to a computer or phone will mount Pocket’s SD card onto the host system. Small files can be read/transferred. While there isn’t actually any limit enforced on file size, because the speed is very slow (about 700KB/sec) it isn’t recommended for large files. Unplug the cable or press B to unmount the card and return to the menu.

Since 2.1, there is now a global hotkey to soft-attach and soft-detach the USB cable: Press Analogue + X to attach, Analogue + Y to detach. The hotkeys work anywhere in the menu.

### Statistics

Displays an information overlay at the top right of the screen when running any core.

* **Power Usage**: On Developer units, the power usage in milliwatts of the Aristotle FPGA’s 1.1V internal fabric is shown live. Typical values range from 50mW to 300mW. The power usage measured does not reflect the entire usage of the core — other unmeasured draws are the cartridge bus level translators, link port translation, cartridge power supply, RAM chips, and I/O banks of the FPGA. Higher resolution scaler modes and display modes increase power draw.
* **Temperature**: Approximate adjusted temperature of Aristotle. Brighter backlight settings will increase the temperature.
* **Video sync rate**: Refresh rate in Hz of the core’s video output, down to three decimal places.
* **Video sync status**: Video sync can be too low, too high, or ok (within allowable range). If sync is missing altogether, Pocket will provide its own 60hz internal sync to continue driving the display.

### Pause Core Boot

When enabled, APF will halt immediately after loading the FPGA bitstream. Press A to continue with APF host command handling and core bringup. Has no effect when Chip32 is run.

### Pause Load Data

When enabled, APF will halt immediately before loading any data slots. Can be used to arm a SignalTap trigger on the FPGA to troubleshoot data loads. Press A to continue. Has no effect when Chip32 is run.

### Asset Load Detail

Displays information about which file and data slot is being loaded. Files smaller than 512KB may not be visible.

### Debug Logging

When enabled, produces a detailed text log file on the SD card (/System/Logs/) as the boot process proceeds. If Chip32 is used, some opcodes (namely file access) will also appear.

### Chip32 Exec Log

When enabled along with Debug Logging, additionally prints out every instruction executed by the Chip32 VM interspersed into the rest of the log. May drastically slow down boot process in programs with long cycle counts.

## General Tips

### Force Power-Off a Pocket

In situations where Pocket can not be powered off normally - Remove the Pocket from the Dock (if docked). Press and hold the power button for 5 seconds to force power-off. Any changes or savegames in progress will be lost.

### Stop Chip32 Execution

If Chip32 gets hung, stuck in an infinite loop, or simply takes too long to execute, press and hold B to cancel execution.
