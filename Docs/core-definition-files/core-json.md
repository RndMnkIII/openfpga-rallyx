# core.json

Describes the core in general terms, framework requirements, and a list of bitstreams.

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## metadata

`platform_ids`: array
Array of supported platform strings. Refer to platform list. If no platforms are specified (empty array) then core is standalone. This affects where assets and saves are stored in the filesystem.

Maximum 4 platforms.

`shortname`: string
Short name used for filesystem. Maximum length 31 characters.

`description`: string
Short description. Maximum length 63 characters.

`author`: string
Name of the core author. Maximum length 31 characters.

`url`: string
URL to more information about core. Maximum length 63 characters.

`version`: string
Version of the release. SemVer is highly encouraged. Maximum length 31 characters.

`date_release`: string
Date of the release in this format: `2022-12-31`. The date the release was made. Maximum length 10 characters.

## framework

`target_product`: string
Must be "Analogue Pocket".

`version_required`: string
Minimum firmware version required, in the format "1.1"

`sleep_supported`: boolean
If sleep is supported by the core. Additionally, a core can selectively allow or deny each individual save state creation request. The sleep/wake system uses the host commands `[00A0 Savestate: Start/Query]` and `[00A4 Savestate: Load/Query]`.

`chip32_vm`: string
Filename of Chip32 program. If present, the program will take over all loading operations. File must be present in the root of the core’s folder. Maximum length 15 characters.

## dock

`supported`: boolean
Whether Dock should be allowed. Must be true.

`analog_output`: boolean
Does core support analog output timing modes? Upcoming feature.

## hardware

`link_port`: boolean
Whether link port is utilized.

`cartridge_adapter`: integer / hex string
**`Bit [31] set:`**Leave cart power off.

**`Bit [31] clear:`** Turn on cart power, if bit 24 is not set, or if it's set AND the user selects the 'Play Cartridge' option. (default).

**`Bit [30] set:`**Turn on cart power always.

**`Bit [24] set:`** Enable 'Play Cartridge' option in Asset browser when starting core. If user selects this option, data slot 0 and any other slots that derive their filenames from it will not be loaded.

**`Bit [17] set:`** Enforce strict adapter ID check. If the found adapter doesn't match the below ID code, core loading will fail.

**`Bit [16] set:`** Enforce soft adapter ID check. If user selects "Play Cartridge" option and adapter doesn't match, core loading will fail. However, if user does not pick "Play Cartridge", core loading will proceed despite whatever adapter may be inserted.

**`Bit [7:0]:`** cart adapter ID code.

The default value is simply `0`, which will preserve backwards compatibility. A value of `0` will turn on cart power and bypass all other checks.

In all cases, a Host command will be sent informing the core if any cartridge adapter was found, if cartridge power was turned on, and whether the user wants to run the cartridge instead of an Asset. This Host command will be issued while the core is in reset.

If Play Cartridge is selected, any data slots such as nonvolatile save files that derive their filenames from data slot 0 will not be loaded or saved.

For backwards compatibility, values of `-1` will be automatically corrected `0x80000000` (Leave cart power off).

## cores

A maximum of 8 cores is allowed.

`name`: string
Identifier for the bitstream used in debugging. Optional. For debugging purposes. Maximum length 15 characters.

`id`: integer / hex string
Identifier.

`filename`: string
Filename of the bitstream (bit-reversed). Maximum length 15 characters.

## Sample File

```json
{
  "core": {
    "magic": "APF_VER_1",
    "metadata": {
      "platform_ids": [],
      "/": "SampleCore",
      "description": "This is a sample core",
      "author": "developer",
      "url": "https://",
      "version": "1.0.0-preview",
      "date_release": "2022-04-20"
    },
    "framework": {
      "target_product": "Analogue Pocket",
      "version_required": "1.1",
      "sleep_supported": true,
      "dock": {
        "supported": true,
        "analog_output": false
      },
      "hardware": {
        "link_port": false,
        "cartridge_adapter": -1
      }
    },
    "cores": [
      {
        "name": "default",
        "id": 0,
        "filename": "bitstream.rbf_r"
      }
    ]
  }
}
```
