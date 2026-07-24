# Overview

## Introduction

Welcome the openFPGA Developer SDK beta. Noted features will be implemented in upcoming releases.

## What is a Core?

A "core" on Pocket refers to an FPGA bitstream packaged with JSON definition files, which configure loading and operation on Pocket.

Pocket uses two FPGAs. The Primary Core FPGA is entirely available to Developers and a smaller System FPGA is used exclusively for Analogue OS.

Operations of a core are managed by the Analogue Platform Framework (APF) implemented in both Pocket embedded functions and the Developer’s core with code supplied by Analogue.

## Pocket Hardware Block Diagram

![FPGA Block Diagram](./images/fpga-diagram.png)

## Capabilities

Cores have full access to the array of hardware and I/O connected to the FPGA, which includes the following:

* Four independently-addressable RAM chips
* 32pin cartridge bus (200mA 3.3v and 5v switch selectable VCC)
* Link port
* IR tx/rx
* Stereo speakers and a 3.5mm headphone connector
* Controller data for up to 4 players (through Dock) by means of APF
* Analogue’s video scaler, which can be customized for best use with each core *(upcoming feature)*
* Four action buttons, left and right triggers, and 2 mode buttons
* Primary FPGA JTAG header

## Operation

1. **Running a Core on Pocket** When a user starts a core the core JSON definitions are read and Pocket makes decisions about which assets need to be loaded. A user may be asked to provide additional files if a core requests them via a file browser interface. Optionally, a custom program provided by the core developer can be run allowing customized loading behavior for complex situations. In either case the FPGA bitstream is loaded and assets are transferred into a core's volatile memory beginning execution.
2. **Options During Runtime** A running core may need adjustable parameters or additional interactive options and/or settings. Custom interactive UI elements can be added by the developer.
3. **Developing a Core** To assist iteration a developer can connect FPGA hardware debugging tools via the JTAG to quickly reload the bitstream for inspection during runtime. Whenever a bitstream is reloaded via the JTAG Pocket will immediately repeat the entire loading process automatically. Additionally, when running a core, Pocket can display metrics such as temperature, power usage (on Pocket Developer Edition), and video sync status.
4. **Packaging a Core** Cores can be packaged as .zip files containing the applicable file structure to be extracted onto an SD card.

## Terminology

### "Platform"

Refers to any unique combination of hardware that the core implements. Platforms can be user-created, multiple cores can support a common platform, and a core can support multiple platforms. Common assets are organized by platform.

### "Host/Target"

When dealing with the framework the “host” refers to Pocket while “target” refers to the running core. Commands may be sent in either direction. For example, a target command would be `[0180 Data slot read]` where the target/core wants to read from an offset in one of its asset files. In this case the device/Pocket would respond with the desired data.

Another example would be when the host wants to stop running the core. Pocket sends a host command to put the target/core back into reset before shutting it down. See the [“Host/Target Commands”](./host-target-commands.md) page.

### "Data Slot"

A core can have up to 32 associated assets, which can be loaded or saved by the core and have various properties such as nonvolatile, read-only, etc. Each slot is given a unique 16-bit ID to provide some abstraction between the ordering of the physical slots and their logical representation.
