# video.json

Describes up to 8 video preset scaling configurations.

Cores may switch between any of these resolutions at runtime.

## JSON Definition

`magic`: string
Must be `APF_VER_1`.

## scaler_modes (array)

Maximum of 8 scaler modes.

`width`: integer
Active width in pixels.

`height`: integer
Active height in pixels.

`aspect_w`: integer
Aspect ratio width.

`aspect_h`: integer
Aspect ratio height.

`dock_aspect_w`: integer *(optional)*
Aspect ratio width when docked.

`dock_aspect_h`: integer *(optional)*
Aspect ratio height when docked

`rotation`: integer
Degrees to rotate the image. Valid values are `0, 90, 180, 270`.

`mirror`: integer
Reflect the display direction. May be combined with rotation. Bit1: left/right mirror Bit0: up/down mirror.

## display_modes (array)

Maximum of 16 display modes.

`id`: string/hex
ID of display mode that can be used with the core. Refer to the below Display Mode ID Table.

## defaults

`sharpness`: integer *(optional)*
The default pixel sharpness when no display mode is used. 0 is the softest and is suitable for photos and video content. 3 is maximum sharpness.

## Display Modes

Cores can use any of Pocket’s built-in display modes, plus a new customizable CRT Trinitron mode.

For cores wanting to use a LCD mode, it’s recommended to use the “generic” modes instead of the Original modes, for forward compatibility.

When using the CRT Trinitron mode, the display size will be quantized to the nearest integer multiple of the source image height in pixels. This is necessary to prevent artifacts. Next, the final width of the image will be calculated based on the specified aspect ratio. In all cases, the aspect ratio will be respected.

> To work properly, the CRT mode requires that the core produce an image with no horizontal pixel duplication. While duplicated pixels won’t affect a simple scaler, they will negatively impact the functionality of the CRT mode.

When using the LCD modes, the display size will be integer scaled in the same way. However, both the width and height will be separately converted to integer multiples of the original resolution. The aspect ratio may not be possible to completely respect when using these modes. LCD modes are best suited for square pixels (when the aspect ratio matches the core’s video resolution).

When a Display Mode is selected, APF will send a Host command `[00B8 OS Notify: Display Mode]` to tell the core which one the user selected. Acknowledging this command is optional, as are the other OS Notify commands.

However, the non-color LCD modes (`0x20` through `0x23`) require the core to send pure grayscale video from RGB(0,0,0) to RGB(255,255,255). This command contains a parameter bit that needs to be respected by the core. Also, the core must provide the correct response for these particular display modes to function.

> If there are multiple scaler slots used with different rotations, Aperture Grille with CRT Trinitron will only function for slot 0.

## **Display Mode ID Table**

| ID   | Description          | Notes                                                                                                  |
| ---- | -------------------- | ------------------------------------------------------------------------------------------------------ |
| 0x00 | None                 | Not valid in JSON, only sent in the Host command [00B8 OS Notify: Display Mode]                        |
| 0x10 | CRT Trinitron        |                                                                                                        |
| 0x20 | Grayscale LCD        | Generic, has no restriction on source content. Adjusted for better operation with denser image sources |
| 0x21 | Original GB DMG      | Requires core response                                                                                 |
| 0x22 | Original GBP         | Requires core response                                                                                 |
| 0x23 | Original GBP Light   | Requires core response                                                                                 |
| 0x30 | Reflective Color LCD | Generic                                                                                                |
| 0x31 | Original GBC LCD     |                                                                                                        |
| 0x32 | Original GBC LCD+    |                                                                                                        |
| 0x40 | Backlit Color LCD    | Generic                                                                                                |
| 0x41 | Original GBA LCD     |                                                                                                        |
| 0x42 | Original GBA SP 101  |                                                                                                        |
| 0x51 | Original GG          |                                                                                                        |
| 0x52 | Original GG+         |                                                                                                        |
| 0x61 | Original NGP         |                                                                                                        |
| 0x62 | Original NGPC        |                                                                                                        |
| 0x63 | Original NGPC+       |                                                                                                        |
| 0x71 | TurboExpress         |                                                                                                        |
| 0x72 | PC Engine LT         |                                                                                                        |
| 0x81 | Original Lynx        |                                                                                                        |
| 0x82 | Original Lynx+       |                                                                                                        |
| 0xE0 | Pinball Neon Matrix  |                                                                                                        |
| 0xE1 | Vacuum Fluorescent   |                                                                                                        |

## Sample File

```json
{
  "video": {
    "magic": "APF_VER_1",
    "scaler_modes": [
      {
        "width": 320,
        "height": 240,
        "aspect_w": 4,
        "aspect_h": 3,
        "rotation": 0,
        "mirror": 0
      },
      {
        "width": 512,
        "height": 240,
        "aspect_w": 4,
        "aspect_h": 3,
        "rotation": 0,
        "mirror": 0
      },
      {
        "width": 480,
        "height": 270,
        "aspect_w": 16,
        "aspect_h": 9,
        "rotation": 0,
        "mirror": 0
      }
    ],
    "display_modes": [
      {
        "id": "0x10"
      },
      {
        "id": "0xE0"
      }
    ]
  }
}
```
