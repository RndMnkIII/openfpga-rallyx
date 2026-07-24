# External Hardware

All interfaces are documented in the `core_top.v` project template file. Check the HDL source for exact pin descriptions.

## Physical RAM Available in User Cores

### 8Mx16 PSRAM

* Latency: Very low
* Bandwidth: Average to High
* Part Number: AS1C8M16PL-70BIN
* Type: Cellular PSRAM
* Size in bytes: 16 Mbyte
* Voltage: 1.8v
* [Datasheet](https://www.alliancememory.com/wp-content/uploads/pdf/psram/AllianceMemory_128M_LP-PSRAM-CellularRAM_x2stack_AS1C8M16PL-70BIN_August2018-v1.0.pdf)

This type of pseudo-SRAM is a bit unique in that it can be accessed asynchronously with very low latency, but also be configured for 133mhz max speed synchronous bursts.

Each chip contains 2 separate dies with all signals wired in parallel except for the chip enables. Simple implementations can use the chip enable as an upper address bit.

> Be careful to never assert both chip enable pins (CE0#, CE1#) to avoid bus contention.

Cores that that read/write often to PSRAM need to take note of a potential pitfall — each die’s configuration registers can be accessed via a specific read/write sequence to the last word of the die’s address space. While intended as a workaround for not needing to use the CRE pin, it presents a possible problem.

If the core’s usage pattern happens to exactly match this sequence (see page 19, “Software Access” on the datasheet) then both reads and writes in this area may result in unintended behavior. There are two PSRAM chips on Pocket, containing two dies each, for a total of 4 potential affected memory addresses.

Cores with possible usage patterns matching the Software Access sequence and also accessing these die’s highest location (word address `3FFFFFh`) should instead special-case this address and use FPGA registers to store the value.

### 128Kx16 SRAM

* Latency: Very low
* Bandwidth: Average
* Part Number: AS6C2016-55BIN
* Type: Asynchronous SRAM
* Size in bytes: 256 Kbyte
* Voltage: 3.3v
* [Datasheet](https://www.alliancememory.com/wp-content/uploads/pdf/lp_sram/AllianceMemory_2M_LPSRAM_AS6C2016%20May%202021_v1.1_May2021.pdf)

Standard asynchronous SRAM. Drive an address, strobe write enable or output enable. Latency is marginally faster than PSRAM but possible bandwidth is lower.

### 32Mx16 SDRAM

* Latency: Average
* Bandwidth: High
* Part Number: AS4C32M16MSA-6BIN
* Type: Mobile SDRAM
* Size in bytes: 64 Mbyte
* Voltage: 1.8v
* [Datasheet](https://www.alliancememory.com/wp-content/uploads/pdf/mobile_sdram/20180115_AllianceMemory_512M_LPSDRAM_AS4C32M16MSA-6BIN(TR)_rev1.0_Dec2017.pdf)

Standard synchronous DRAM. Comparable to PC133 SDRAM, except using a different voltage standard, its maximum frequency is increased to 166MHz. SDRAM is best accessed in bursts since every access requires activation and precharge overhead. DQM(H/L) are wired for byte-granular write masking.

Be mindful of the additional mode registers necessary to program during initialization. Consider referencing the industry-standard [Micron 256M SDRAM datasheet](https://media-www.micron.com/-/media/client/global/documents/products/data-sheet/dram/256mb_sdr.pdf?rev=04b1a709222e4fa4911891d6cc573b11) for further details about how to use SDRAM.

## Cartridge Bus + Link Port

Cores have complete access to the cartridge bus

* Cartridge voltage is determined in hardware by a mechanical voltage selection switch (5v when the switch is depressed, 3.3v when not)
* Cart power is enabled with the appropriate setting in `core.json`
* Additional circuitry is present to prevent reset glitching. In 5v mode, pin30 is clamped low until a particular control pin is asserted. A core using pin30 should assert this pin (view the template HDL).
* All pins are run through level translators and their direction can only be input or output. Most I/O pin directions are controlled in groups. For example, the data bus bits[7:0] are switched from input to output as one group. Some pins’ directions can be controlled independently (view the template HDL).
* Link port power is voltage-controlled and power switched on the same rail as the cartridge bus.

> Leave all cartridge pins in the default settings per the template HDL unless actively using the port. If the level translators are improperly configured while cartridge power is turned on, a user may lose data from an inserted cartridge.

## Infrared Interface

Pocket contains an infrared transmitter LED and receiver circuit.

### Transmit

Located in the same lightpipe as the power LED, the IR LED drive signal is active high. Because the LED is running near its maximum rated current, it should never be driven with DC. Only use PWM-type pulses to drive the LED at a duty cycle lower than 100%.

### Receive

The receiver circuit has automatic gain control (AGC) to adjust for ambient light levels and expects to see typical PWM-type waveforms.

The receiver must be disabled whenever not in use as it consumes a nontrivial amount of power. Allow a few milliseconds for the AGC to stabilize when enabled.
