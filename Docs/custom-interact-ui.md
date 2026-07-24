# Custom Interact UI

Cores may have a custom menu with a number of ways for the user to set options and interact with the core state through memory-mapped IO.

Up to 16 items may be in the menu.

### Runtime data reload

Data slots with “User-reloadable” set in their Parameter Bitmap will show up in this list so that the user can pick a new file at runtime. See the [`data.json`](./core-definition-files.md#data.json) definition.

### Per-asset flexibility

Each core can have as many bespoke interact menus as it has assets. When loaded, a per-asset interact menu will override the core’s default menu.

### Persistence

Each entry in the menu can be flagged for automatic save/reload.

## Element Types

Each element has a 16-bit ID and contains a pointer in the BRIDGE address space to the value it either reflects or modifies. All elements support an optional 32-bit data mask to facilitate read-modify-writes on selected bits inside a register.

### Checkbox

* Short text description
* BRIDGE 32-bit address
* 32-bit compare value to set/read at the pointer

### Radio Box

* Short text description
* Group ID for connecting multiple boxes
* BRIDGE 32-bit address
* 32-bit compare value to set/read at the pointer

### Slider Adjust

* Short text description
* BRIDGE 32-bit address
* Adjustable step size along with minimum/maximums

### Action Button

* Short text description
* BRIDGE 32-bit address
* 32-bit value to write at the pointer

### Hex Register Display

* Short text description
* BRIDGE 32-bit address

See [interact.json](./core-definition-files.md#interact.json) for more information.
