# Chip32 VM

> Chip32 is currently being integrated into APF and may have minor changes in the future.

## Overview

Some more complex cores may require additional logic during the load process. For example, reading headers inside an asset, choosing between multiple bitstreams, and writing registers in the core based on input data.

Developers can write a program for the Chip32 to handle the entire load process in a much more hands-on way. When Chip32 is used it takes over the entire load process replacing APF’s normal process of FPGA configuration/data slot upload, deciding itself when and how each asset and bitstream gets loaded.

## Usage Examples

* Intelligent loading
* Bitstream selection
* Handling triggers, processing and assets outside of the FPGA
* Messaging
* Deterministic handling of headers and metadata
* Special case FPGA setup and initialization

## Specifications

* 32 bit CPU
* 16 registers and a stack
* 8Kbyte of address space holding combined memory and program (up to 2k instructions)
* Multiply and divide instructions
* Many custom I/O instructions to speed up development
* Can read/write anywhere in FPGA address space over the BRIDGE bus

## Developing for Chip32

Programs for the virtual machine should be written in assembly. A custom assembler tool based on BASS is provided, with source available along with Windows, Linux, and MacOS Intel/M1 binaries available.

## Errata

Instructions on the Chip32 VM need to be aligned to 16 bits (2 bytes). It is possible to create a situation where instructions become unaligned when an odd number of direct bytes (text or data) precede any following opcodes. See the assembler readme for more notes on this.
