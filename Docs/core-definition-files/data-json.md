# data.json

Describes up to 32 possible data slots. Each slot can be loaded with an asset, loaded and saved to a nonvolatile save file, and contains a number of options.

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## data_slots (array)

A maximum of 32 data slots is allowed.

`name`: string
Name of the data slot. Maximum length of 15 characters.

`id`: integer / hex string
ID number. Limited to 16-bit unsigned.

`required`: boolean
If `true`, Pocket will check for a filename. If none is present, it will spawn a file browser in the location it expects the file to be in. If `false`, Pocket will try to load the file if it exists, otherwise it will be silently be skipped.

`parameters`: integer / hex string
Bitmap for the slot's configuration. See [Parameters Bitmap](./data-json.md#parameters-bitmap) below.

`nonvolatile`: boolean
If `true`, slot will be both loaded and unloaded on core exit. Related functionality with `parameters` above and [Parameters Bitmap](./data-json.md#parameters-bitmap).

`deferload`: boolean
If `true`, slot will not be loaded, but its size and ID will still be communicated to the core, and the core may read/write it with [Target commands](../host-target-commands.md#target-command-list). If a user reloads this slot, APF will send `[008A Data slot update]`.

`secondary`: boolean
If `true`, slot will be ignored, and will only be loaded if referenced in a selected variant/instance.

`filename`: string
Expected filename for the slot. See [Parameters Bitmap](./data-json.md#parameters-bitmap) below. Maximum length of 31 characters.

`extensions`: string
Array of up to 4 supported file extensions. Each extension may be up to 7 characters. If a file browser is spawned, it will filter the files shown.
Example: `"extensions": ["bin", "sav"]`.

`size_exact`: integer / hex string
If specified, or non-zero, the filesize will be checked and only loaded if the size matches. 32-bit unsigned.

`size_maximum`: integer / hex string
If specified, or non-zero, the file will not load unless it is equal or smaller in size than this value. 32-bit unsigned.

`address`: integer / hex string
Load address. 32-bit unsigned.

## Parameters Bitmap

| Bit Position | Description                                                | Cleared                                                                                                                                                                                   | Set                                                                                                                                                                                                                                                                                                                  |
| ------------ | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0            | User-reloadable                                            |                                                                                                                                                                                           | Slot is reloadable in Core UI                                                                                                                                                                                                                                                                                        |
| 1            | Core-specific file                                         | File common to platform, not any core                                                                                                                                                     | File specific to this core only                                                                                                                                                                                                                                                                                      |
| 2            | Nonvolatile filename                                       | Filename as written in the slot                                                                                                                                                           | Filename cloned from slot 0, with this slot's extension appended                                                                                                                                                                                                                                                     |
| 3            | Read-only                                                  | File may be modified                                                                                                                                                                      | File is read-only                                                                                                                                                                                                                                                                                                    |
| 4            | Instance JSON                                              | Normal asset                                                                                                                                                                              | Treat a JSON loaded into this slot as an instance description. Must also be flagged as "core-specific file", and only valid in first slot.                                                                                                                                                                           |
| 5            | Initialize nonvolatile data on load                        | Data is loaded if it exists, otherwise nothing is written to this nonvolatile slot                                                                                                        | Data is loaded if it exists, otherwise the slot's memory is overwritten with 0xFF's up to size_maximum                                                                                                                                                                                                               |
| 6            | Reset core while loading                                   | [0082 Data slot request write] command is sent before load, and [008F Data slot access all complete] sent after                                                                           | [0010 Reset Enter] before executing the same data slot access/complete sequence, and additionally [0011 Reset Exit] after                                                                                                                                                                                            |
| 7            | Restart of core before/after loading                       | Same as above                                                                                                                                                                             | Entire core is unloaded via the normal process, saving any nonvolatile slots. Then a full restart of the core is done, using the new data along with other already-defined assets                                                                                                                                    |
| 8            | Full reload of core                                        | Same as above                                                                                                                                                                             | Same as above, but the bitstream is also reloaded before the restart process                                                                                                                                                                                                                                         |
| 9            | Persist browsed filename                                   | Normal behavior. File for slot may be chosen by user, at core boot (if required), or during runtime through Interact menu (if marked User-reloadable)                                     | Filenames picked via the browser will be persisted, and the next time the core is loaded, the slot will be reloaded with the same file, overriding any definition or instance filename. The browser cache, which is saved per-core, is cleared when a user uses "Reset All to Defaults" in the core's Interact menu. |
| [25:24]      | Index of platform to look for file in (usually platform 0) | When filename is specified for this slot, selects the platform from core.json's platform_ids array. This will be index 0 by default, or the first or only platform supported by the core. | This may be used to load a required asset from another platform’s Assets folder, so long as that platform is listed in the platform_ids array.                                                                                                                                                                       |

* A core-specific file is distributed with the core itself, and does not share anything with its platform. The path would be: `/Assets/<platform>/AuthorName.CoreName/examplefile.bin`. It could also be a nonvolatile file, which would be located in `/Saves/<platform>/AuthorName.CoreName/examplefile.bin`.
* A nonvolatile data slot, such as a save file, may be generated for every time the core is started based on the filename and path of the primary data slot, which is slot 0. Additionally, this file will take on the extension of the first extension in the nonvolatile data slot's extension list.
* An instance JSON, if specified, will specify exact filenames for some or all other slots and select a variant to load. This can be useful if a core requires many different assets to be loaded.
* Data slots can be optionally re-reloaded with a new file during runtime by the user, through the `interact.json` menu. Please see the Parameters Bitmap section with respect to bits 6, 7, and 8 to configure the behavior when a user reloads one of these slots. Some cores may be able to accept new data at any time, while others might need to be put into reset.
* Slots marked as nonvolatile will be read out back onto the file they were loaded from on SD. The size of the file is determined by the Dataslot ID/Size Table BRAM in the core. This means the filesize will by default be the same as it was when loaded, unless the core has specifically modified the size to be bigger or smaller during runtime. The data flush happens whenever the core is shutdown - when a core is stopped with the root menu "Quit" option, Pocket is turned off, or Pocket is slept.
* When using Chip32, the behavior of bits 6-7 are different. In either case, Chip32 will eventually be restarted with the selected slot ID to decide how to handle the load. Bit 6 has no effect. Bit 7 causes a soft reboot - the core is unloaded but FPGA not reset. Then, Chip32’s register state is reloaded and called again. In this case, a Chip32 program expecting to see a particular data slot with this bit set, must always call `HOST 4002` to set APF back up and start running again. However, reloading the FPGA bitstream is not necessary.

A slot that is both nonvolatile/named from slot0 and read only would have the bitmap computed as follows:

```c
(1 << bit2) + (1 << bit3) = 
4 + 8 = 
12
```

## Sample File

```json
{
  "data": {
    "magic": "APF_VER_1",
    "data_slots": [
      {
        "name": "Background Pic",
        "id": 1,
        "required": true,
        "parameters": 3,
        "extensions": [
          "bin"
        ],
        "size_exact": 0,
        "size_maximum": 8388608,
        "address": "0x00000000"
      },
      {
        "name": "Audio Sample",
        "id": "0xFC0",
        "required": true,
        "parameters": 3,
        "extensions": [
          "wav"
        ],
        "size_maximum": "0x4000000",
        "address": "0x00400000"
      },
      {
        "name": "Save Data",
        "id": 123,
        "required": true,
        "parameters": 7,
        "extensions": [
          "sav"
        ],
        "size_maximum": 8192,
        "address": "0x02000000"
      }
    ]
  }
}
```
