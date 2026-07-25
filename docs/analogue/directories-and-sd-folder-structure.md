# Directories and SD Folder Structure

## Assets

Assets are files that can be loaded by a core and are organized by platform.

In the case of assets common to a platform and independent of any core implementation: `/Assets/ex_platform/common/Example Asset.bin`

If a core for a particular platform requires its own core-specific assets they should be placed in a subfolder named after the core folder itself, and flagged as such in the core definition: `/Assets/ex_platform/ExampleAuthor.BasicAssets/ex_image_1.bin`

If a core uses assets that are not specific to any existing platform they should be placed in a folder called “_none” and within that folder another folder named after the core itself: `/Assets/_none/Analogue.SimpleFramebuffer/image.bin` 
`/Assets/_none/ExampleAuthor.ExampleCore/ExampleAsset.bin`

If desired, custom subdirectories can be used to further organize within these folders.

## Saves

Saves contains all user created files loaded or saved by a core, and like Assets, are organized by platform and function.

Data slots in a core definition that are flagged as `nonvolatile` are placed here.

When a core’s data slot Parameter Map is flagged with 0x4 and also marked as nonvolatile, its filename will be cloned from slot index 0 (the first slot in `data.json`). Example: `/Assets/sampleplatform/common/sample subfolder/Example Asset.bin` when loaded as the primary asset, may be used by other data slots as a basis for their filenames - `/Saves/sampleplatform/common/sample subfolder/Example Asset.sav` When the nonvolatile file is created, any necessary subfolder structure to contain it will also be created automatically.

> The directory structure in the Assets and Saves folders should mirror each other. If folders are organized in one, they should be reorganized in the other as well.

## Cores

Cores contain subfolders of all cores installed following a certain naming convention.

Example: `/Cores/Analogue.SimpleFramebuffer/` `/Cores/ExampleAuthor.ExampleCore/`

The format is `“AuthorName.CoreName”`. This convention must be respected as it allows quick loading and sorting of the cores list.

View the [Core Definition](./core-definition-files.md) section for information about files used to define a core in this folder.

## Memories (beta)

Users can create 128 memories per openFPGA core, which will be displayed on a per-core basis.

Example: `/Memories/Beta/<coreauthor.corename>`

## GB Studio

All .pocket files go here and no subfolders are currently supported.

Save files for GB Studio are placed in `/GB Studio/Saves/`

## Presets

Contains per-asset interact definitions as well as other files for future use.

## Settings

Contains core and per-asset interact values that are persistent.

## System

Additional system files for Pocket are stored in this folder.
