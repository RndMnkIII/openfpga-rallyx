# Core Boot Process

> In all states after the bitstream is started, the core constantly produces a heartbeat signal that, when lost, causes Pocket to terminate execution and reload the core with the same initial state.

Here is what a sample Runtime Flow looks like for a core.

## Startup

1. Pocket loads bitstream.
2. Core PLLs and FSMs start up. Core is in [Booting] state.
3. Pocket waits 100ms.
4. Pocket spinlocks `[0000 Request Status]` until core reports it is in [Setup] state.
5. Core becomes ready to accept memory accesses, RAM is ready, etc. No video/audio is produced yet. Core is in [Setup] state.
6. Pocket receives response to `[0000 Request Status].`
7. Pocket checks for any cartridge adapters by briefly turning on cart power. Cartridge I/O should be put in a safe state by the core. Pocket will report the result as well as further information via `[00B1 OS Notify: Cartridge Adapter]`.
8. Pocket writes the combined total of up to 32 (16+16) BRIDGE memory writes from first any specified variant, and secondly any instance JSON, if used.
9. Pocket sends `[0082 Data slot request write]` and loads all data slots in order.
10. Core may choose to watch dataslot accesses. It may look at an image header and decide it wants a different dataslot loaded. It can request this `[0182 Data slot copy]`, and Pocket will service the load next, then resume any remaining loads.
11. Pocket sends `[008F Data slot access all complete]` when done loading slots. Core may still request more slot ops.
12. Pocket sends `[0090 Real-time Clock Data]` to inform core of the current time.
13. Core sends `[0140 Ready to Run]` when no more data ops are required, and moves to [Idle] state.
14. Pocket writes any persistent registers from `interact.json`, if applicable.
15. Pocket turns on power to the cartridge slot if needed.
16. Pocket sends `[0011 Reset Exit]` and core starts execution in [Running] state.

## Runtime

1. During runtime the core may request a data read, write, reload, flush, or message display.
2. Pocket may request a savestate be created. `[00A0 Savestate: Start/Query]` is called once first, and if the core confirms support, Pocket calls the same command again with the "Request start" bit set, polling until completion. Finally, the save data is copied out.
3. Pocket may request a savestate be loaded. `[00A4 Savestate: Load/Query]` is called once first to determine both support and where the savestate data expects the data to be copied. If supported, Pocket copies the data in, calls again with "Request load" set and polls until core signals completion.

## Shutdown

1. Pocket sends `[0010 Reset Enter]` and core stops execution. Core returns to [Idle] state.
2. Pocket reads any persistent registers in `interact.json`, saving them, if applicable.
3. Pocket may reload any data slot and send `[0011 Reset Exit]` if a user wants to restart with new data.
4. Pocket sends `[0080 Data slot request read]` to read out any nonvolatile data, taking into account any changes the core may have written to the Dataslot ID/Size Table, in case the file size should be expanded or shrunk.
5. Pocket wipes bitstream and FPGA is reset.
