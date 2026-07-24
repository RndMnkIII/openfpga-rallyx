# interact.json

Describes any custom UI elements to be displayed in the Core Settings menu.

The Core Settings menu is built up dynamically from the following sources:

1. Submenu for Display Modes (future use)
2. Submenu for Controls (from `input.json`)
3. Zero or more actions to reload data slots while the core is running (`data.json`, any data slot marked as “User-reloadable” in its Parameter Bitmap
4. Zero or more UI elements described in this `interact.json` file.
5. If at least one UI element was added, Pocket will provide “Reset all to defaults” action.

## Limitations

Up to 16 UI entries from `interact.json` can be shown. However, if more than 4 reloadable data slots are also present, additional entries will be dropped to maintain a maximum of 20 combined interact+data menu entries.

It is recommended to use `list` items since each one can have up to 16 of its own possible options within itself, and does not count towards the overall limit.

## Operation

> See the `data.json` section for an explanation on what happens when a user reloads a data slot through this menu - the behavior can be customized.

The following UI elements are supported:

1. Check box - `check`
2. Radio box - `radio`
3. Slider adjustments - `slider_u32`
4. List options - `list`
5. Action buttons - `action`
6. Hexadecimal number readouts - `number_u32`

Each frame, all of the UI elements are read back from the core at a specified 32-bit BRIDGE address, updated with new user-adjusted values, and finally written back. This read-modify-write cycle requires the core to have both read and write support at each desired address, unless the element is flagged as `writeonly`.

Elements with a `mask` can be used to selectively modify any number of bits in a register. The readback value where the mask bits are set will be preserved when writing back.

If any persistent elements are found and loaded, they will be written into the core’s register space on boot immediately before the APF sends the `[0011 Reset Exit]` host command.

### Per-Asset Functionality and Persistence

Persistent values will be saved out by their ID. If you update your core to add or remove some interact elements, APF will try to match up all the settings by their ID, so all IDs should be unique.

#### Default

By default, the interact menu is loaded from:
`/Cores/AuthorName.CoreName/Interact/interact.json`

By default, the interact menu’s persistent values are saved to:
`/Settings/AuthorName.CoreName/Interact/interact_persist.json`

#### Per-Asset

It is possible to have completely unique interact menus for every single primary asset loaded by the core. APF will check in a specific location, generated from the very first data slot 0. If it is found, it will override the core’s existing `interact.json`.

A per-asset interact menu, if it exists, is loaded from:
`/Presets/AuthorName.CoreName/Interact/<path_to_slot0_asset>.json`

A per-asset interact menu, if it exists, will save persistent values to:
`/Settings/AuthorName.CoreName/Interact/<path_to_slot0_asset>.json`

#### Example

For example, with an primary asset loaded into data slot 0 with current path and filename of
`/Assets/myplatform/common/subfolder1/asset.bin`

APF will check for a JSON file mirroring the same folder structure, but in a different base folder:
`/Presets/AuthorName.CoreName/Interact/myplatform/common/subfolder1/asset.json`

Similarly, any persistent values will be saved to:
`/Settings/AuthorName.CoreName/Interact/myplatform/common/subfolder1/asset.json`

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## variables

The following are common to all elements, regardless of type:

`name`: string
Name as displayed in UI. Maximum length of 23 chars.

`id`: integer / hex string
Id number. Limited to 16-bit unsigned.

`type`: stringType of the UI element. Values: `radio`, `check`, `slider_u32`, `list`, `number_u32`, `action`

`enabled`: boolean
Whether or not the element can be interacted with.

`address`: integer / hex string
32-bit address into BRIDGE space for reading/write the value.

The following a specific to `radio` checkboxes:

`group`: integer / hex string
Group identifier. Radio boxes can be ganged up by assigning them all the same arbitrary group number.

`persist`: boolean
Retains the value set by the user after the core is shut own. *Optional.*

`writeonly`: boolean
If present and true, the value will only be stored in JSON and written to the core, but never read back from the core. *Optional.*

`defaultval`: integer / hex string
Initial value. May be `0` (unchecked) or `1` (checked). Restored when user selects Reset to Defaults.

`value`: integer / hex string
Value that is written when selecting the radio box, or compared against when reading the register.

`value_off`: integer / hex string
Value that is written when unchecked. *Optional. Defaults to 0.*

`mask`: integer / hex string
Mask. Bits set to ‘1’ will be left untouched in the register. Bits set to ‘0’ may be modified by the UI element. *Optional.*

The following are specific to `check` checkboxes.

`persist`: boolean
Retains the value set by the user after the core is shut own. *Optional.*

`writeonly`: boolean
If present and true, the value will only be stored in JSON and written to the core, but never read back from the core. *Optional.*

`defaultval`: integer / hex string
Initial value. May be `0` (unchecked) or `1` (checked). Also when user selects Reset to Defaults.

`value`: integer / hex string
Value that is written when selecting the check box, or compared against when reading the register.

`value_off`: integer / hex string
Value that is written when unchecked.

`mask`: integer / hex string
Mask. Bits set to ‘1’ will be left untouched in the register. Bits set to ‘0’ may be modified by the UI element. *Optional.*

The following are specific to `slider_u32` sliders:

`persist`: boolean
Retains the value set by the user after the core is shut own. *Optional.*

`writeonly`: boolean
If present and true, the value will only be stored in JSON and written to the core, but never read back from the core. *Optional.*

`defaultval`: integer / hex string
Initial value used for the slider. Restored when user selects Reset to Defaults.

`mask`: integer / hex string
Mask. Bits set to ‘1’ will be left untouched in the register. Bits set to ‘0’ may be modified by the UI element. *Optional.*

`graphical`: object
object

`signed`: boolean
Displays ‘+’ when the value is positive. *Optional.*

`min`: integer / hex string
Minimum allowable value. (-2147483648 to 2147483647).

`max`: integer / hex string
Maximum allowable value. (-2147483648 to 2147483647).

`adjust_small`: integer / hex string
Adjustment step for fine adjustments. (-2147483648 to 2147483647).

`adjust_large`: integer / hex string
Adjustment step for coarse adjustments. (-2147483648 to 2147483647).

The following are specific to `list` menu items:
An array of up to 16 objects to comprise the list options, each of which contains the following:

`value`: integer / hex string
Value that is written when selecting the menu item.

`name`: string
Name as displayed in UI. Maximum length of 23 chars.

The following are specific to `action` menu items:

`value`: integer / hex string
Value that is written when selecting the menu item.

`mask`: integer / hex string
Mask. Bits set to ‘1’ will be left untouched in the register. Bits set to ‘0’ may be modified by `value`. *Optional.*

## Sample File

```json
{
  "interact": {
    "magic": "APF_VER_1",
    "variables": [
      {
        "name": "All RGB",
        "id": 2,
        "type": "radio",
        "group": 100,
        "enabled": true,
        "persist": true,
        "address": "0x00F0000C",
        "defaultval": 1,
        "value": 7
      },
      {
        "name": "Red only",
        "id": 3,
        "type": "radio",
        "group": 100,
        "enabled": true,
        "persist": true,
        "address": "0x00F0000C",
        "value": "0x4"
      },
      {
        "name": "Green only",
        "id": 4,
        "type": "radio",
        "group": 100,
        "enabled": true,
        "persist": true,
        "address": "0x00F0000C",
        "value": "0x2"
      },
      {
        "name": "Blue only",
        "id": 5,
        "type": "radio",
        "group": 100,
        "enabled": true,
        "persist": true,
        "address": "0x00F0000C",
        "value": "0x1",
        "mask": "0xFFFF0000"
      },
      {
        "name": "Difficulty",
        "id": 99,
        "type": "list",
        "enabled": true,
        "persist": true,
        "address": "0x00E00000",
        "writeonly": true,
        "defaultval": 2,
        "mask": "0xFFFF0000",
        "options": [
          {
            "value": "0x0000",
            "name": "Hard"
          },
          {
            "value": "0x0100",
            "name": "Normal"
          },
          {
            "value": "0x0200",
            "name": "Easy"
          },
          {
            "value": "0x0300",
            "name": "Very Easy"
          }
        ]
      },
      {
        "name": "Reset Square",
        "id": 6,
        "type": "action",
        "enabled": true,
        "address": "0x00F00010",
        "value": 64
      },
      {
        "name": "Square X",
        "id": 8,
        "type": "slider_u32",
        "enabled": true,
        "persist": true,
        "address": "0x00200000",
        "defaultval": 100,
        "graphical": {
          "signed": false,
          "min": 0,
          "max": 320,
          "adjust_small": 1,
          "adjust_large": "0x10"
        }
      },
      {
        "name": "Square Y",
        "id": 9,
        "type": "slider_u32",
        "enabled": true,
        "persist": true,
        "address": "0x00200004",
        "defaultval": 100,
        "graphical": {
          "signed": false,
          "min": 0,
          "max": 240,
          "adjust_small": 1,
          "adjust_large": "0x10"
        }
      },
      {
        "name": "Animation",
        "id": 1,
        "type": "check",
        "enabled": true,
        "address": "0x00100000",
        "defaultval": 1,
        "value": 1,
        "mask": "0xFFFF0000"
      },
      {
        "name": "Reset Frame",
        "id": 10,
        "type": "action",
        "enabled": true,
        "address": "0x00F00014",
        "value": 0
      },
      {
        "name": "Increment Frame",
        "id": 11,
        "type": "action",
        "enabled": true,
        "address": "0x00F00018",
        "value": 0
      },
      {
        "name": "Frame",
        "id": 12,
        "type": "number_u32",
        "enabled": false,
        "address": "0x20000000"
      },
      {
        "name": "Mask Write Debug",
        "id": 13,
        "type": "action",
        "enabled": true,
        "address": "0x00100004",
        "value": "0x00340000",
        "mask": "0xFF00FFFF"
      },
      {
        "name": "Debug",
        "id": 14,
        "type": "number_u32",
        "enabled": false,
        "address": "0x00100004"
      },
      {
        "name": "Signed Value",
        "id": 15,
        "type": "slider_u32",
        "enabled": true,
        "address": "0x00300000",
        "defaultval": 5000,
        "graphical": {
          "signed": true,
          "min": -100000,
          "max": 100000,
          "adjust_small": 1,
          "adjust_large": 1000
        }
      }
    ]
  }
}
```
