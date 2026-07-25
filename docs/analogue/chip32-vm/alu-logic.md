# ALU Logic

## Opcodes

| Opcode            | Action          | Flags | Description                                                                                                                                                                                                  |
| ----------------- | --------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `NOP`             | PC ++           |       | No operation and will increase the PC counter by 2                                                                                                                                                           |
| `AND Rx,#`        | Rx <= Rx & Imm  | Z     | Rx is ANDed with an Immediate 16 or 32 bit value and the result is placed back into Rx. The Z flag is set if the result is zero.                                                                             |
| `OR Rx,#`         | Rx <= Rx \| Imm | Z     | Rx is ORed with an Immediate 16 or 32 bit value and then result placed back into Rx. The Z flag is set if the result is zero.                                                                                |
| `XOR Rx,#`        | Rx <= Rx ^ Imm  | Z     | Rx is XORed with an Immediate 16 or 32 bit value and then result placed back into Rx. The Z flag is set if the result is zero.                                                                               |
| `BIT Rx,#`        | Z <= Rx & Imm   | Z     | Rx is ANDed with an immediate 16 or 32 bit value, but the result is not written back. This allows testing bits in a register without changing the register's value. The Z flag is set if the result is zero. |
| `AND Rx,Ry`       | Rx <= Rx & Ry   | Z     | Rx is ANDed with Ry and the result placed back into Rx. The Z flag is set if the result is zero                                                                                                              |
| `OR Rx,Ry`        | Rx <= Rx \| Ry  | Z     | Rx is ORed with Ry and the result is placed back into Rx. The Z flag is set if the result is zero                                                                                                            |
| `XOR Rx,Ry`       | Rx <= Rx ^ Ry   | Z     | Rx is XORed with Ry and the result is placed back into Rx. The Z flag is set if the result is zero.                                                                                                          |
| `BIT Rx,Ry`       | Z <= Rx & Imm   | Z     | Rx is ANDed with Ry but the result is not written back. The Z flag is set if the result is zero.                                                                                                             |
| `CRC Rx,Ry,Rz,#n` | CRC Rx,Ry,Rz,#n |       | CRC16's data in RAM at Rx for length Ry using Rz for the CRC accumulator, and polynomial N.                                                                                                                  |

## Notes

* Z Flag used for result is zero
* C Flag used for overflow on ALU
