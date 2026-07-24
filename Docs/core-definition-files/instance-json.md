# <instance>.json

An instance file is stored in the same place that an asset would be - following platform path conventions (and core name, possibly). The location that a core will expect the instance JSON to be located from will be exactly the same as any other data slot. The Parameters Bitmap of a data slot determines if the data slot will be treated as common to a platform (in the “common” folder) or core-specific (in a subfolder named after the core itself).

To use an instance JSON, the data slot entry in `data.json` must have:

1. an extension list containing “json” so that the file browser filter will display JSON files
2. a Parameters Bitmap with the “Instance JSON” bit set

The filenames listed below should be located starting in the same folder as the instance JSON, but may be located in any number of subfolders.

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

`data_path`: string
Path to assets containing one or more subfolders, using forward slashes only. Maximum length of 255 characters.

## core_select

`id`: integer / hex string
ID of core bitstream to select as part of the load process. Limited to 16-bit unsigned.

`select`: boolean
If `true`, the core bitstream matching ID will be loaded, otherwise the first/only bitstream will be selected.

## data_slots (array)

A maximum of 32 data slots is allowed.

`id`: integer / hex string
ID of `data_slot`. Limited to 16-bit unsigned.

`filename`: string
Exact filename, including any subfolders. Relative paths are not supported. Maximum length of 255 characters.

## memory_writes (array)

A maximum of 32 entries is allowed.

`address`: integer / hex string
Address to write to. 32-bit unsigned.

`data`: integer / hex string
Data to be written. 32-bit unsigned.

## Sample File

```json
{
  "instance": {
    "magic": "APF_VER_1",
    "core_select" : {
      "id" : 123,
      "select" : false
    },
    "data_path": "basefolder1/",
    "data_slots": [
      {
        "id": 1,
        "filename": "samplefolder/sample.bin"
      },
      {
        "id": 99,
        "filename": "samplefolder/sample.wav"
      }
    ],
    "memory_writes": [
      {
        "address": "0x00000004",
        "data": "0x12345678"
      }
    ]
  }
}
```
