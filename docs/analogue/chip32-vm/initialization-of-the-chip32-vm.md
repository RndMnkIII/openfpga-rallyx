# Initialization of The Chip32 VM

Chip32 is a virtual machine that runs periodically on demand to facilitate loading data, but does not run constantly along with the core.

## Registers

`R0`: When a file is selected, its JSON ID will be loaded into `R0`. This allows the Chip 32 code to perform different actions based on which slot was selected. i.e. load an asset, palette, or similar.

If the core is being cold booted from the menu, it will be passed the ID of data slot index 0.

`R1-15`:On the first time booting a core, these registers are all zeroed out. However, if a core is reset these registers keep their previous state from the last run.

This can be used for remembering the state of a core with respect to the files loaded. For example, if a user reloaded a particular asset with the Interact menu, which palette is used, and other assets that might be treated differently based on another asset being present or having certain contents. A Chip32 program could exploit this to prevent reloading any more data than necessary, and only loading changed data.

## Boot Vectors

`0x0000`: This is the error address vector. If some kind of error occurs during execution, the PC is set to `0x0000`, and the internal error register is loaded with the error that caused it.

`0x0002`: This is the start address vector. The start address for where the code is to be started.

## Memory Initialization

When the Chip32VM is initialized for the project, any RAM outside of the area loaded by the program binary can be random upon restart of the VM. It shouldn’t be used to store state between runs as the data will become lost.

## Theory of Operation

Chip32 takes over the entire load process. The program must load a bitstream itself, load any data slots, and hand over control back to APF when it is complete.

The minimum implementation for a Chip32 program would be:

1. CORE to load bitstream ID 0
2. LOADF to load any applicable data slots
3. HOST `0x4002` to pass back control to APF and continue core bringup.

Additionally, whenever a data slot is marked as “reloadable” via the Interact menu, Chip32 will also again be called. The contents of the registers will be saved from the initial bootup run, but R0 will be loaded with the ID the user has selected. In this case, Chip32 again is solely responsible for deciding what load actions to take based on this new information.
