# 1.1 beta 6

## Image Support

In addition to Memories save state images, all openFPGA cores now automatically support the newly added Memories screenshots feature. When taking a screenshot (menu+start), Pocket will generate a clean native resolution PNG image with thumbnail and place it in the memories/screenshots folder on the SD card. All metadata is contained within the PNG file, which can be easily backed up or transferred to a new Pocket via the SD card.

## Large File Support

New Target Commands allow cores to read and write large files, up to 4GB in size, on the SD card.

## New Controller Support

In addition to controllers, Dock now supports generic USB keyboards and mice. Cores can see the keyboard on the Player 3 slot, and mouse on Player 4.

## Real-time Clock Support

Cores get notified of the current Pocket date and time when they start, and Chip32 has a new opcode to return the RTC data in several formats.

## Documentation Updates

* Updated template example core
* Added variants and target command example core

## **Detailed changes and improvements**

* Added APF Host command: [008A Data slot update]
* Added APF Target commands: [0180 Data slot read] [0184 Data slot write] for access of very large files
* Added APF further support for data slots marked as "deferload"
* Added Chip32 instruction GETTIME
* Added Host command [0090 Real-time Clock Data] to Core Boot Process
* Fixed Chip32 JTAG reload to always ignore CORE until unloaded
* Fixed Chip32 data slot reload to disregard parameter bits 7/8
* Fixed Chip32 GETNAME instruction
* Fixed Chip32 GETEXT instruction
* Fixed Chip32 LOADF with <512k sizes to update the data slot BRAM
* Fixed Chip32 data slot reloading on parameter bit 7
* Fixed APF debug log closing and not re-opening on a slot reload
* Fixed controllers 2-4 not updating values when undocked
* Fixed button mapping for unmapped keys
