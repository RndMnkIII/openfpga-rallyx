# Platform Metadata

> Platform data is supplied by the user and not by Analogue.

Each core may choose to implement a platform, as described in [core.json.](./core-definition-files.md#core.json) While not strictly necessary for a core to run, the platforms can be described in further detail.

Every platform has a shortname, which is a unique name to identify a platform in a human-readable way. For example, the PDP-1 might have a shortname of `pdp1`.

A core can signal that is supports a platform by specifying a platform shortname in the `metadata.platform_ids` property of its `core.json` file. Additional data about this platform can be specified in a file located at `/Platforms/<platform_shortname>.json`.

> Core shortnames shall only contain lowercase alphanumeric characters (`a-z`, `0-9`, underscore `_`) and have a maximum length of 15 characters. The first character of the name may not be an underscore.

For example, a core might specify that it supports the `pdp1` platform. The device will look for a file at `/Platforms/pdp1.json` to display additional user-supplied information about the platform, such as release year and manufacturer.

> Core shortnames shall only contain lowercase alphanumeric characters (a-z, 0-9, underscore ‘_’) and have a maximum length of 15 characters.

All cores that specify a platform but no matching file is found for that platform will not display any additional information about the platform nor be able to access future features in Analogue OS.

## Platform Image

A platform may have a graphic associated with it. The format is described in [Graphical Asset Formats](./packaging-a-core.md#graphical-asset-formats).

If present, the platform image should reside in `/Platforms/_images/`. For example, the “pdp1” platform’s image would be located at: `/Platforms/_images/pdp1.bin`.

## <platform>.json

`category`: string
Category this platform belongs to. Platforms are grouped into similar categories. Maximum length of 31 chars.

`name`: string
Full name of the platform. Maximum length of 31 characters.

`manufacturer`: string
Full name of the manufacturer. Maximum length of 31 characters.

`year`: Integer
Year of release.

## Sample File

```json
{
  "platform": {
    "category": "Computers",
    "name": "Computer",
    "manufacturer": "Computer Co.",
    "year": 2022
  }
}
```
