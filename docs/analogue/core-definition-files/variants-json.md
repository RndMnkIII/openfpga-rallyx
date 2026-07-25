# variants.json

Describes up to 8 core variations. These can be used to describe very similar hardware with just a few asset changes. This is an upcoming feature.

Each variant may select a particular bitstream and override data slots with alternate ones as well as write arbitrary data into the core’s address space.

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## variant_list (array)

Maximum of 8 variants.

`name`: string
Maximum length of 15 characters.

`id`: integer / hex string
ID number. Limited to 16-bit unsigned.

`core_select`: object
Contains a child integer object `core_id` which specifies the bitstream ID to load.

`data_overridemagic`: array
List of data slot overrides.

`memory_writes`: array
List of memory writes to tell the bitstream about the selected variant.

## data_override (array)

Maximum of 8 variants.

`data_id_to`: integer / hex string
ID number of the data slot to be replaced. Limited to 16-bit unsigned.

`data_id_from`: integer / hex string
ID number of the data slot replacing the above. It may be flagged as secondary. Limited to 16-bit unsigned.

## memory_writes (array)

Maximum of 16 variants.

`address`: integer / hex string
Address to write to. 32-bit unsigned.

`data`: integer / hex string
Data to be written. It may be flagged as secondary. 32-bit unsigned.

## Sample File

```json
{
  "variants": {
    "magic": "APF_VER_1",
    "variant_list": [
      {
        "name": "Variant1",
        "id": 0,
        "core_select": {
          "core_id": 0
        },
        "data_override": [
          {
            "data_id": 3,
            "data_id_override": 300
          }
        ],
        "memory_writes": [
          {
            "address": "0x00000004",
            "data": "0x12345678"
          },
          {
            "address": "0x02000200",
            "data": "0xabcdabcd"
          }
        ]
      },
      {
        "name": "Variant2",
        "id": 1,
        "core_select": {
          "core_id": 1
        },
        "data_override": [
          {
            "data_id": "0x100",
            "data_id_override": "0x103"
          }
        ]
      }
    ]
  }
}
```
