# Core Definition Files

A core is comprised of several files, which all must be placed into the core’s folder.

* [core.json](./core-definition-files/core-json.md): *Required*. Main core definition file.
* [audio.json](./core-definition-files/audio-json.md): *Required*. Audio features. (upcoming feature)
* [data.json](./core-definition-files/data-json.md): *Required*. List of all data slots.
* [input.json](./core-definition-files/input-json.md): *Required*. Description of custom button mappings for the core. (remapping coming soon)
* [interact.json](./core-definition-files/interact-json.md): *Required.*List of custom UI elements for the in-core menu, which can be used to interact with the core while running.
* [variants.json](./core-definition-files/variants-json.md): *Required.*Variants list for supporting small variations of a base core. (upcoming feature)
* [video.json](./core-definition-files/video-json.md): *Required.*Video settings. Defines the video scaler settings used, namely resolution for each of the 8 scaler slots.
* info.txt: Extra information that will be shown in the core’s Platform Detail view. Up to 32 lines can be displayed - no special characters. Bullet points can be shown by starting a line with an asterisk (`*`).
* icon.bin: [Icon bitmap](./packaging-a-core.md#image-format) for use in the user interface.

Additionally, a core may allow users to select assets together in a predetermined group as an "instance". These instance JSON files are stored as assets themselves in the Assets folder and follow the same rules for their location.

* [<instance>.json](./core-definition-files/instance-json.md): Instance definition file, stored as an asset.

## Folder Naming Convention

The core folder name should follow this convention: `AuthorName.CoreName` where `AuthorName` and `CoreName` correspond to `author` and `shortname` in `core.json` respectively.
