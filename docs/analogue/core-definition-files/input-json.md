# input.json

Describes the button input mappings shown in the Core Settings > Controls menu. Currently read-only.

## Per-Asset Functionality

### Default

By default, the Controls menu is loaded from:
`/Cores/AuthorName.CoreName/input.json`

### Per-Asset

It is possible to have completely unique Controls menus for every single primary asset loaded by the core. APF will check in a specific location, generated from the very first data slot 0. If it is found, it will override the core’s existing `input.json`.

A per-asset Controls menu, if it exists, is loaded from:
`/Presets/AuthorName.CoreName/Input/<path_to_slot0_asset>.json`

### Example

For example, with an primary asset loaded into data slot 0 with current path and filename of:
`/Assets/myplatform/common/subfolder1/asset.bin`

APF will check for a JSON file mirroring the same folder structure, but in a different base folder:
`/Presets/AuthorName.CoreName/Input/myplatform/common/subfolder1/asset.json`

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## controllers (array)

A maximum of 4 controllers are allowed.

`type`: string
Type of the controller. Must be "default".

## controllers.mappings (array)

A maximum of 8 mappings are allowed.

`id`: integer / hex string
Limited to 16-bit unsigned.

`name`: string
Name of the button shown in the menu. Maximum length of 19 chars.

`key`: string / keycode
See "Keycode list” below.

## Keycode List

`pad_btn_a`: A button
`pad_btn_b`: B button
`pad_btn_x`: X button
`pad_btn_y`: Y button
`pad_trig_l`: L button
`pad_trig_r`: R button
`pad_btn_start`: Start button
`pad_btn_select`: Select button

## Sample File

```json
{
  "input": {
    "magic": "APF_VER_1",
    "controllers": [
      {
        "type": "default",
        "mappings": [
          {
            "id": 0,
            "name": "A",
            "key": "pad_btn_a"
          },
          {
            "id": 1,
            "name": "B",
            "key": "pad_btn_b"
          },
          {
            "id": 2,
            "name": "X",
            "key": "pad_btn_x"
          },
          {
            "id": 3,
            "name": "Y",
            "key": "pad_btn_y"
          },
          {
            "id": 4,
            "name": "L",
            "key": "pad_trig_l"
          },
          {
            "id": 5,
            "name": "R",
            "key": "pad_trig_r"
          },
          {
            "id": 6,
            "name": "Start",
            "key": "pad_btn_start"
          },
          {
            "id": 7,
            "name": "Select",
            "key": "pad_btn_select"
          }
        ]
      }
    ]
  }
}
```
