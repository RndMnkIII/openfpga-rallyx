# 1.1 beta 3

This release of OS 1.1 beta 3 continues with incremental improvements for developers

* Per-asset controls button mapping
* Additions to checkboxes and instances
* New Developer option to facilitate core boot process debugging (Pause Core Load)

## More granular control over Controls button mapping

In the same way that each individual asset may already have its own custom interact menu (`interact.json`), now Controls (`input.json`) can be assigned to each one. This lays the foundation for Pocket to remember user button mappings in the future. User mapping options will be added to complete the input.json features in an upcoming OS release.

## Improvements to checkboxes and instances

Checkboxes in the `interact.json` menu now can have two values - one for checked and one for unchecked. `<instance>.json` files may have up to 16 arbitrary BRIDGE writes, up from 8.

## Improved core boot debugging

In addition to Pause Data Load the newly added Pause Core Boot option allows a developer to load a bitstream and troubleshoot the handshaking process as Pocket starts the core.

## Detailed changes and improvements

* Added per-asset core control mappings
* Added Interact checkbox given "off" value
* Added "Pause Core Boot" setting to delay handshake after the bitstream is loaded
* Increased instance memory writes from 8 to 16
* Fixed video rotation/mirroring on Dock
* Fixed data slot reload with nonvolatile slots causing data loss
