# 1.1 beta 4

Highlighting this OS 1.1 beta 4 release - Developers can now control the entire loading process with the versatile Chip32 virtual machine.

* 32 bit CPU
* 16 registers and a stack
* 8Kbyte of address space holding combined memory and program (up to 2k instructions)
* Multiply and divide instructions
* Many custom I/O instructions to speed up development
* Read/write anywhere in FPGA address space over the BRIDGE bus

## Customized Loading

The [Chip32 virtual machine](../chip32-vm.md) feature enables Developers to customize the entire load process in a hands-on way. For this, a purpose-built assembler tool based on BASS is provided, with source and binaries for Windows, Linux, and MacOS Intel/M1. Additionally, a Chip32 example core will be provided within days on the [openFPGA Github](https://github.com/open-fpga).

## Enhanced Debugging

A logging tool has been added to help developers understand what is happening in their workflow. When enabled, (in **Tools** > **Developer**) a log file per core is written to the `System/Logs/{author}.{core_name}_{timestamp}.txt` path detailing the bootup process. Logs contain information about every file the framework touches and the exact commands the framework sends, providing useful context for troubleshooting. In addition to logs, Developers can now enable the new assets details tool to display more information about each asset’s filename and its load address on the loading screen.

## Organize with Submenus

The Core Settings menu now has better ways to organize settings - a new setting type called `list` shows up to 16 possible options in a sub-menu, reducing clutter.

## Detailed changes and improvements

* Added Chip32 virtual machine for more complex loading behaviors
* Added extensive debug logging when booting cores
* Added asset details Developer tool
* Added list-type options support to Interact menus
* Added better display of long menu items
* Added interlaced video support
* Added controller connection status bits to determine which types of devices are connected when docked
* Added analog stick support for Dock
* Added data slot expected size reporting
* Fixed scaler with some combinations of aspect ratio/resolutions
* Fixed data slot reloads
* Fixed instance JSON parsing bug
* Fixed radio button persistence bug
* Fixed "Request Slot Write" command to pass expected data size first
* Fixed controller mapping bug
