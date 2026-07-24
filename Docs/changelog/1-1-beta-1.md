# 1.1 beta 1

Today we are introducing essential features adding flexibility and clarity for developers and users.

* Customized setting menu - a toolkit for core settings and runtime options
* Clarified controls - view core controls via the menu
* Organize platforms - categories add grouping to platforms
* Present your core - author icons and a detailed core info section
* Simplified browser and APF menu signaling

You can start using openFPGA 1.1 beta 1 today by updating to the [latest version of Analogue OS](https://analogue.link/pocket-firmware).

## Customized setting menu with `interact.json`

Authors can now create bespoke interact menus and tie them to certain primary assets. Up to 16 customized UI elements such as checkboxes, radio buttons, action buttons, and sliders can be shown in the new Core Settings menu. Options and settings can directly interface with the core and may be saved for later runs or reloading data slots. [View more details in `interact.json`](../core-definition-files.md#interact.json).

## Clarified controls menu with `input.json`

Defining and understanding a core’s control mappings now has a place in the new Controls menu. Authors can quickly assign mappings from a table with easily recognized icons. User personalization will soon be available in an upcoming OS update. [View more details in `input.json`](../core-definition-files.md#input.json).

## Organize platforms with categories

`<platform>.json` now has a “category” key for additional organization in the openFPGA menu. Authors and users can define this key to nest platforms within categories. A categories view option, which uses the new key, will be available in an upcoming OS update. Platforms without this key defined will be listed as uncategorized if the view option is enabled. [View more details in `platform.json`](../platform-metadata.md#platform.json).

## Present your core with personalized icons and `info.txt`

The Platform Detail menu now includes an Author's personalized icon. From here, an optional detailed description of a core can be added and viewed in the About section. Present core features and context to users using `info.txt`. [View more details in Core Definition Files](../core-definition-files.md).

## Simplified browser and APF menu signaling

The browser now remembers location, clarifies the path, and users optionally can see what the Author is filtering. A new APF Host command is added telling the core when the user is in the menu. Authors can optionally pause a core and customize the menu state.

## Detailed changes and improvements

* EULA and APF License - clarified compatibility with MIT and GNU
* Updated [core-template](https://github.com/open-fpga/core-template)
* Added example core - [interact](https://github.com/open-fpga/core-example-interact)
* Added example core - [basic assets](https://github.com/open-fpga/core-example-basicassets)
* Added directories for `interact.json`
* Added memories directory information and available slots per core
* Added `info.txt`. This can be viewed in the openFPGA About section of the currently selected core. `info.txt` is not required to run a core.
* Clarified which core definition files are required to run a core.
* Added reset, restart and reload core.
* Clarified sleep_supported in `core.json`
* Added data slot reload via `interact.json`
* Corrected `data_path` description
* Added documentation explaining `input.json`
* Added documentation explaining `interact.json`
* Clarified video end-of-line bits
* Clarified audio signal sample rate requirement
* Clarified SDRAM size and added memory details table
* A notable save file bug affecting data slots loaded with Parameter Bitmap bit 5 (file fill) is fixed.
* Added optional menu state notification
* Added behavior for `interact.json`
* Replaced interact UI description
* Added description of library image naming and formatting
* Clarified platform shortname naming rules
* Added category. This will not break existing `<platform>.json`
