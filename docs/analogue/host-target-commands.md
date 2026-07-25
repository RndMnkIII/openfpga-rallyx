# Host/Target Commands

During startup, runtime, and shutdown, both the Host (Pocket) and Target (Core) need the ability to issue and respond to commands.

Commands are handled over the BRIDGE bus, and the `0xF8xxxxxx` region in its address space is reserved.

There are effectively two separate command/response systems. Host can send commands and poll for a response and Target can send commands and wait for a response.

## Host/Target Command Memory Map

Base address: `0xF8000000`

Implementation of the command system register space can be done either with a couple block rams and a softcore CPU/state machine or just a handful of fabric registers and a FSM.

Commands may require additional parameter data. The target will provide pointers to where it wants the host to write this data when sending a command. The same goes for response data and finally again in both directions Host > Target and Target > Host.

The second and third columns denote whether the register can be read or written by the (H)ost or (T)arget.

**0x00**`R: H, T`
`W: H, T`

Host (Pocket > Core) command/status.

#### Stage 1

```
[31:16] 0x434D 'CM'
[15: 0] command word
```

Pocket writes here to execute a command. Just before, Pocket checks 0x4 to see where it should write any additional parameters, if applicable.

#### Stage 2

```
[31:16] 0x4255 'BU'
[15: 0] busy status
```

Core traps the write and updates the status. Pocket sees this flag and knows it's in progress. Status/progress information may be encoded in the lower 16 bits, such as a percentage.

#### Stage3

```
[31:16] 0x4F4B 'OK'
[15: 0] result code
```

Core updates with result code. Exact result code depends on the command. Additional data must be encoded in a response format.

### 0x4

`R: H`
`W: T`

Host (Pocket > Core) parameter data pointer.

`[31:0]` Address to put applicable parameter data. May be within this bram, or anywhere in the bridge address space. Must have enough room for the longest parameter list.

### 0x8

`R: H`
`W: T`

Host (Pocket > Core) response data pointer.

`[31:0]` Address to put applicable response data. May be within this bram, or anywhere in the bridge address space. Pocket will read this address to find where to read a command response from the core.

**0x1000**`R: H, T`
`W: H, T`

Target (Core > Pocket) command/status.

#### Stage 1

```
[31:16] 0x636D 'cm'
[15: 0] command word
```

Core writes here to request command execution. Pocket polls and sees flag set

#### Stage 2

```
[31:16] 0x6275 'bu'
[15: 0] busy status
```

Pocket starts execution, updating status. Core watches this flag for progress. Status/progress information may be encoded in the lower 16 bits, such as a percentage.

#### Stage3

```
[31:16] 0x6F6B 'ok'
[15: 0] result code
```

Pocket updates with result code. Additional data must be encoded in a response format.

### 0x1004

`R: H`
`W: T`

Target (Core > Pocket) parameter data pointer. `[31:0]` Address to put applicable parameter data. May be within this bram, or anywhere in the bridge address space. Must have enough room for the longest parameter list.

### 0x1008

`R: H`
`W: T`

Target (Core > Pocket) response data pointer. `[31:0]` Address to put applicable response data. May be within this bram, or anywhere in the bridge address space. Must have enough room for the longest parameter list.

### 0x2000-0x20FF

`R: H, T`
`W: H, T`

Data slot size table. Word0: `[15:0]` ID of the data slot Word1: `[31:0]` Size of the data slot. Zero if the slot is not used. Repeat these 8 bytes for all 32 possible slots. When core is loaded, Pocket will write the filesize as loaded. Core may update the value during setup, idle, or run. Pocket will read the value back during a flush operation and update the filesize on SD if it changed.

### 0x2380-0x238B

`R: H`
`W: -`

Build date and version information.

APF has a Tcl script to populate this area of the bram on compile to include the build date/time, as well as a 32bit randomized ID to identify the build.

```
[31:0]	Build Date in BCD, e.g. 0x20220531 (2022-May-31)
[31:0]	Build Time in BCD, e.g. 0x00231159 (23:11:59)
[31:0]	Build Unique ID
```

## Dataslot ID / Size Table

Part of the address space is reserved for a 32-entry table. In the example implementations this is a small block ram.

Each item contains two 32-bit words describing the 16-bit ID of that data slot corresponding to the Core Definition JSON, and the size in bytes of that slot.

While the core runs it may read this table to know how large of an asset was loaded, or in the case of a nonvolatile data slot (save file), it may write a revised size in case it changed.

If the data slot in question is marked with `deferload`, the size and ID will still be written even though the file data itself will not be automatically loaded.

If the data slot in question has a file size exceeding 4 gigabytes, then 48-bit addressing will be used. The upper 16 bits will be packed in the unused space of the first word. For example:

```
Word 0 [31:16]  Size (upper 16 bits)
Word 0 [15:0]   ID
Word 1 [31:0]   Size (lower 32 bits)
```

There will not be any impact if the file size is smaller than 4 gigabytes, as the extra addressing bits will simply be zero.

## Host Command List

### 0x0000

**Request Status**
*Parameters*: 0
*Response*: 0
*Result Codes*:

* `0x00`: Undefined
* `0x01`: booting (Core clocks/FSM starting, PLL initialization)
* `0x02`: setup (Pocket loads assets, core may request dataslot reads)
* `0x03`: idle (held in reset, not executing)
* `0x04`: running

### 0x0010

**Reset Enter**
*Parameters*: 0
*Response*: 0
*Result Codes*: -

### 0x0011

**Reset Exit**
*Parameters*: 0
*Response*: 0
*Result Codes*: -

### 0x0080

**Data slot request read**
*Parameters*: 1

* `[15:0]` Slot id (0-65535)

*Response*: 0
*Result Codes*:

* `0`: ready to read
* `1`: not allowed ever
* `2`: check later

### 0x0082

**Data slot request write**
*Parameters*: 2

* `[31:16]` Expected size in bytes (upper 16 bits)
* `[15:0]` Slot id (0-65535)
* `[31:0]` Expected size in bytes (lower 32 bits)

*Response*: 0
*Result Codes*:

* `0`: ready to write
* `1`: not allowed ever
* `2`: check later

### 0x008A

**Data slot update***Parameters*: 2

* `[15:0]` Slot id (0-65535)
* `[31:0]` Expected size in bytes

*Response*: 0*Result Codes:*0

### 0x008F

**Data slot access all complete**
*Parameters*: 0
*Response*: 0
*Result Codes*:

* `0`: ok

### 0x0090

**Real-time Clock Data***Parameters*: 3

* `[31:0]` Unsigned uint32_t of seconds elapsed since the epoch of 1970.
* `[31:0]` BCD of current date - *example* `0x20221031`
* `[31:0]` BCD of current time - *example* `0x00235959`
* `[27:24]` day of week, from 0 to 6
* `[23:0]` BCD of current time - *example* `0x235959`

*Response*: 0

Pocket sends this command during core boot once, with the current time. It is not continuously sent/updated.

### 0x00A0

**Savestate: Start/Query**
*Parameters*: 1

* `[0]` Request start. If not set, simply gives the below result without creating the state.

*Response*: 3

* `[0]` Set if savestate can be/was created
* `[31:0]` Address of savestate blob when ready.
* `[31:0]` Size of savestate blob when ready.

*Result Codes*:

* `0`: ok, no operation
* `1`: busy creating blob
* `2`: done, blob is ready
* `3`: error, failed

### 0x00A4

**Savestate: Load/Query**
*Parameters*: 1

* `[0]` Request load. If not set, simply gives the below result without loading the state.

*Response*: 3

* `[0]` Set if savestate can be/was loaded
* `[31:0]` Address of where savestate blob should be written.
* `[31:0]` Maximum size of savestate blob to be written.

*Result Codes*:

* `0`: ok, no operation
* `1`: busy creating blob
* `2`: done, blob is ready
* `3`: error, failed

### 0x00B0

**OS Notify: Menu State***Parameters:* 1

* `[0]` If set, user is in the OS menus and the core has lost focus.

*Response:* 0

*Result Codes:*

Pocket sends this command during core operation as the user enters and exits the menu. To maintain compatibility, the command may be ignored by the core.

### 0x00B1

**OS Notify: Cartridge Adapter***Parameters:* 1

* `[24]` User selected ‘Play Cartridge’
* `[16]` If cart power will be turned on immediately after reset exit
* `[7:0]` Value of the detected cartridge adapter during boot.

*Response:* 0

*Result Codes:*

Pocket sends this command during the core bootup to let the core know which cartridge adapter a user may have plugged in. Valid values are from `0x01` to `0x04`.

Intended for use when [core.json's](./core-definition-files/core-json.md) `cartridge_adapter` checks are enabled, but will always be sent.

In this way, a core could optionally take advantage of at least one types of adapter(s) if one exists.

### 0x00B2

**OS Notify: Docked State***Parameters:* 1

* `[0]` If set, Pocket is inserted into Dock

*Response:* 0

*Result Codes:*

Pocket sends this command during core operation as the user inserts and removes Pocket from Dock.

### 0x00B8

**OS Notify: Display Mode***Parameters:* 1

* `[15:8]` Display mode ID
* `[0]` Core should output grayscale only

*Response:* 1

* `[15:0]` Response code to affirm core has switched to grayscale video output.

*Result Codes:*

Pocket sends this command each time the user selects a new Display Mode. Some modes (LCD) mandate the core produce only grayscale video output. In that case, parameter bit 0 will be set, and the core must have a response word of `16’h444D` to allow that particular display mode to be used. See the [video.json](./core-definition-files/video-json.md) page.

## Target Command List

### 0x0140

Ready to run.
*Parameters*: 0
*Response*: 0
*Result Codes*: -

### 0x0152

Debug Event Log.
*Parameters*: 1

`[31:0]` Custom event ID to print in Debug Log
*Response*: 0
*Result Codes*: -

### 0x0180

**Data slot read**.
*Parameters*: 4

`[15:0]` Slot id (0-65535).

`[31:0]` Slot offset

`[31:0]` BRIDGE address

`[31:0]` Length
*Response*: 0
*Result Codes*:

* `0`: all bytes read ok
* `1`: slot not defined
* `2`: error or out of range. If length is `0xFFFFFFFF`, the length will be sized to maximum legal value

### 0x0181

**Data slot read (48-bit)***Parameters:* 4

`[31:16]` Slot offset (upper 16 bits)

`[15:0]` Slot id (0-65535)

`[31:0]` Slot offset (lower 32 bits)

`[31:0]` BRIDGE address

`[31:0]` Length
*Response*: 0
*Result Codes*:

* `0`: all bytes read ok
* `1`: slot not defined
* `2`: error or out of range. If length is `0xFFFFFFFF`, the length will be sized to maximum legal value

### 0x0184

**Data slot write**.
*Parameters*: 4

`[15:0]` Slot id (0-65535).

`[31:0]` Slot offset

`[31:0]` BRIDGE address

`[31:0]` Length
*Response*: 0
*Result Codes*:

* `0`: all bytes written ok
* `1`: slot not defined
* `2`: error or out of range. If length is `0xFFFFFFFF`, the length will be sized to maximum legal value

### 0x0185

**Data slot write (48-bit)***Parameters*: 4

`[31:16]` Slot offset (upper 16 bits)

`[15:0]` Slot id (0-65535)

`[31:0]` Slot offset (lower 32 bits)

`[31:0]` BRIDGE address

`[31:0]` Length
*Response*: 0
*Result Codes*:

* `0`: all bytes written ok
* `1`: slot not defined
* `2`: error or out of range If length is `0xFFFFFFFF`, the length will be sized to maximum legal value

### 0x0188

**Data slot flush**
*Parameters*: 1

`[15:0]` Slot id (0-65535)
*Response*: 0
*Result Codes:*

* `0`: all bytes written ok
* `1`: slot not defined

### 0x0190

**Get filename of data slot***Parameters:* 2

`[15:0]` Slot id (0-65535)

`[31:0]` Pointer to `get_dataslot_file_t` struct

*Response:* 0
Struct written by Host before command completion

*Result Codes*:

* `0`: ok
* `1`: slot not defined

### 0x0192

**Open new file into data slot***Parameters:* 2

`[15:0]` Slot id (0-65535)

`[31:0]` Pointer to `get_dataslot_file_t` struct

*Response:* 0
Struct read by Host on command start

*Result Codes*:

* `0`: opened ok
* `1`: created and opened ok (no error)
* `2`: slot not defined
* `3`: file not found
* `4`: malformed path
* `5`: general error

## Target Command Structs

### `get_dataslot_file_t`

**Byte Offset**: 0x0
**Length**: 256
**Name**: Full path including filename

Null-terminated string of the path and file selected for a given slot.

For example, the filename could include additional subdirectories: `/Assets/abcd/common/directory1/data.bin`

### `open_dataslot_file_t`

**Byte Offset**: 0x0
**Length**: 256
**Name**: Full path including filename

Null-terminated string of the full path and file. The file can be in the Assets folder or the Saves folder, in any of the platforms supported by the core (if the data slot was not marked as core-specific).

For example, a data slot not marked as “core-specific”, belonging to the “abcd” platform, with the relative path `directory1/data.bin` would be: `/Assets/abcd/common/directory1/data.bin`

If the core also supported the “xyz” platform, the following would also be valid: `/Saves/xyz/common/directory1/save.bin`

**Byte Offset**: 0x100
**Length**: 4
**Name**: Operation flags

Bit 0: Create if it doesn’t exist (slot must not be read-only).
Bit 1: Resize/truncate the file (slot must not be read-only).
Bits 2-31: Reserved, must be 0.

**Byte Offset**: 0x104
**Length**: 4
**Name**: Desired file size

Size to resize/truncate the file to, if flagged.

Target slot read/write commands are provided to allow working with much larger files - up to 4GByte in size. They should be used with data slots marked with `deferload` set. In this case, APF will not load the file itself, but will still update the Dataslot ID/Size table with the file size.

Additionally, if the data slot is marked with the “User Reloadable” bit set in its Parameters Bitmap, APF will allow choosing a new file in the Interact menu, like any other. However, APF will handle this differently - instead of sending `[0082 Data slot request write]` and then `[008F Data slot access all complete]`, APF will only send `[008A Data slot updated]` and update the Dataslot ID/Size table with the new information.

A core can retrieve the full path information for a file currently loaded in a data slot via the `[0190 Get filename of data slot]` command. The core should supply a pointer to where APF will write the resulting filename. A core could use this path and filename information to request additional files by using `[0192 Open new file into data slot]`. New files can also be created, or resized. Only assets or saves may be opened, and within platform folders that are supported in `core.json`. A data slot must not be marked as read-only for a file to be modified. Once opened, the data slot can be read/written using other Target commands.
