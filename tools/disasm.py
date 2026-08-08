#!/usr/bin/env python3
"""Disassemble Z80 code out of a Rally-X core ROM image.

The program ROM occupies 0x0000-0x3FFF of the image and is addressed by the Z80
at those same addresses, so a file offset here is also a CPU address -- no
relocation to reason about.

Why this exists: some behaviour is only explicable from the game code. The
attract-mode CAST screen looked like a video bug for a long time; it is actually
gated on the credit counter at 0x8024, which this tool made visible in about ten
minutes:

    python tools/disasm.py .roms/nrallyx.rom --start 0x057F --end 0x0586
    057F  3A 24 80   LD A,($8024)
    0582  A7         AND A
    0583  C2 5A 07   JP NZ,$075A     ; any credit -> skip the CAST draw

Start with --strings to find the data, then point --start at the code near it.

Coverage: unprefixed, CB, ED and DD/FD opcodes. Two known gaps, both harmless
for reading control flow: DD/FD prefixes on register-only operations are shown
as the IX/IY form only when the mnemonic names HL (so DD-prefixed `LD H,B` prints
as `LD H,B`, not `LD IXh,B`), and undocumented ED opcodes print as `DB $ED,$xx`.
Anything it cannot decode becomes a `DB` byte rather than desynchronising the
rest of the listing.
"""

import argparse
from pathlib import Path

from _common import Fail, run

PRG_END = 0x4000
ROM_SIZE = 21280

R = ["B", "C", "D", "E", "H", "L", "(HL)", "A"]
RP = ["BC", "DE", "HL", "SP"]
RP2 = ["BC", "DE", "HL", "AF"]
CC = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"]
ALU = ["ADD A,", "ADC A,", "SUB ", "SBC A,", "AND ", "XOR ", "OR ", "CP "]
ROT = ["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"]
ACC = ["RLCA", "RRCA", "RLA", "RRA", "DAA", "CPL", "SCF", "CCF"]
MISC = ["", "", "", "", "EX (SP),HL", "EX DE,HL", "DI", "EI"]
ED67 = ["LD I,A", "LD R,A", "LD A,I", "LD A,R", "RRD", "RLD", "NOP", "NOP"]
BLOCK = {
    0xA0: "LDI",
    0xA1: "CPI",
    0xA2: "INI",
    0xA3: "OUTI",
    0xA8: "LDD",
    0xA9: "CPD",
    0xAA: "IND",
    0xAB: "OUTD",
    0xB0: "LDIR",
    0xB1: "CPIR",
    0xB2: "INIR",
    0xB3: "OTIR",
    0xB8: "LDDR",
    0xB9: "CPDR",
    0xBA: "INDR",
    0xBB: "OTDR",
}


class Disassembler:
    def __init__(self, rom):
        self.rom = rom

    def byte(self, addr):
        return self.rom[addr]

    def word(self, addr):
        return self.byte(addr) | (self.byte(addr + 1) << 8)

    def disp(self, addr):
        d = self.byte(addr)
        return d - 256 if d > 127 else d

    def decode(self, addr):
        """Return (length, text) for the instruction at addr."""
        op = self.byte(addr)
        if op == 0xCB:
            return self._cb(addr + 1)
        if op == 0xED:
            return self._ed(addr + 1)
        if op in (0xDD, 0xFD):
            return self._indexed(addr + 1, "IX" if op == 0xDD else "IY")
        return self._plain(addr)

    def _cb(self, addr):
        op = self.byte(addr)
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        if x == 0:
            return 2, f"{ROT[y]} {R[z]}"
        return 2, f"{['', 'BIT', 'RES', 'SET'][x]} {y},{R[z]}"

    def _cb_indexed(self, addr, mem):
        op = self.byte(addr)
        x, y = op >> 6, (op >> 3) & 7
        if x == 0:
            return 4, f"{ROT[y]} {mem}"
        return 4, f"{['', 'BIT', 'RES', 'SET'][x]} {y},{mem}"

    def _ed(self, addr):
        op = self.byte(addr)
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        if op in BLOCK:
            return 2, BLOCK[op]
        if x == 1:
            if z == 0:
                return 2, f"IN {R[y]},(C)"
            if z == 1:
                return 2, f"OUT (C),{R[y]}"
            if z == 2:
                return 2, f"{'SBC' if not y & 1 else 'ADC'} HL,{RP[y >> 1]}"
            if z == 3:
                nn = self.word(addr + 1)
                if y & 1:
                    return 4, f"LD {RP[y >> 1]},(${nn:04X})"
                return 4, f"LD (${nn:04X}),{RP[y >> 1]}"
            if z == 4:
                return 2, "NEG"
            if z == 5:
                return 2, "RETI" if y == 1 else "RETN"
            if z == 6:
                return 2, f"IM {[0, 0, 1, 2, 0, 0, 1, 2][y]}"
            return 2, ED67[y]
        return 2, f"DB $ED,${op:02X}"

    def _indexed(self, addr, ix):
        """Decode the opcode at addr, already past its DD/FD prefix.

        Lengths include the prefix byte. Any opcode naming (HL) grows a
        displacement byte, and LD (IX+d),n puts it before the immediate.
        """
        op = self.byte(addr)
        if op == 0xCB:
            return self._cb_indexed(addr + 2, f"({ix}{self.disp(addr + 1):+d})")
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        names_mem = (
            (x == 1 and op != 0x76 and (y == 6 or z == 6))
            or (x == 2 and z == 6)
            or (x == 0 and z in (4, 5) and y == 6)
            or op == 0x36
        )
        if names_mem:
            mem = f"({ix}{self.disp(addr + 1):+d})"
            if op == 0x36:
                return 4, f"LD {mem},${self.byte(addr + 2):02X}"
            if x == 0:
                return 3, f"{'INC' if z == 4 else 'DEC'} {mem}"
            if x == 2:
                return 3, f"{ALU[y]}{mem}"
            if z == 6:
                return 3, f"LD {R[y]},{mem}"
            return 3, f"LD {mem},{R[z]}"
        length, text = self._plain(addr)
        return length + 1, text.replace("HL", ix)

    def _plain(self, addr):
        op = self.byte(addr)
        x, y, z, p, q = op >> 6, (op >> 3) & 7, op & 7, (op >> 4) & 3, (op >> 3) & 1
        if op == 0x76:
            return 1, "HALT"
        if x == 1:
            return 1, f"LD {R[y]},{R[z]}"
        if x == 2:
            return 1, f"{ALU[y]}{R[z]}"
        if x == 0:
            return self._x0(addr, y, z, p, q)
        return self._x3(addr, y, z, p, q)

    def _x0(self, addr, y, z, p, q):
        if z == 0:
            if y == 0:
                return 1, "NOP"
            if y == 1:
                return 1, "EX AF,AF'"
            target = (addr + 2 + self.disp(addr + 1)) & 0xFFFF
            if y == 2:
                return 2, f"DJNZ ${target:04X}"
            if y == 3:
                return 2, f"JR ${target:04X}"
            return 2, f"JR {CC[y - 4]},${target:04X}"
        if z == 1:
            if q == 0:
                return 3, f"LD {RP[p]},${self.word(addr + 1):04X}"
            return 1, f"ADD HL,{RP[p]}"
        if z == 2:
            if y < 4:
                return 1, ["LD (BC),A", "LD A,(BC)", "LD (DE),A", "LD A,(DE)"][y]
            nn = self.word(addr + 1)
            return 3, [
                f"LD (${nn:04X}),HL",
                f"LD HL,(${nn:04X})",
                f"LD (${nn:04X}),A",
                f"LD A,(${nn:04X})",
            ][y - 4]
        if z == 3:
            return 1, f"{'INC' if q == 0 else 'DEC'} {RP[p]}"
        if z == 4:
            return 1, f"INC {R[y]}"
        if z == 5:
            return 1, f"DEC {R[y]}"
        if z == 6:
            return 2, f"LD {R[y]},${self.byte(addr + 1):02X}"
        return 1, ACC[y]

    def _x3(self, addr, y, z, p, q):
        if z == 0:
            return 1, f"RET {CC[y]}"
        if z == 1:
            if q == 0:
                return 1, f"POP {RP2[p]}"
            return 1, ["RET", "EXX", "JP (HL)", "LD SP,HL"][p]
        if z == 2:
            return 3, f"JP {CC[y]},${self.word(addr + 1):04X}"
        if z == 3:
            if y == 0:
                return 3, f"JP ${self.word(addr + 1):04X}"
            if y == 2:
                return 2, f"OUT (${self.byte(addr + 1):02X}),A"
            if y == 3:
                return 2, f"IN A,(${self.byte(addr + 1):02X})"
            return 1, MISC[y]
        if z == 4:
            return 3, f"CALL {CC[y]},${self.word(addr + 1):04X}"
        if z == 5:
            if q == 0:
                return 1, f"PUSH {RP2[p]}"
            return 3, f"CALL ${self.word(addr + 1):04X}"
        if z == 6:
            return 2, f"{ALU[y]}${self.byte(addr + 1):02X}"
        return 1, f"RST ${y * 8:02X}"

    def listing(self, start, end):
        addr = start
        while addr < end:
            try:
                length, text = self.decode(addr)
            except (IndexError, KeyError):
                length, text = 1, f"DB ${self.byte(addr):02X}"
            raw = " ".join(f"{self.byte(addr + i):02X}" for i in range(length))
            print(f"{addr:04X}  {raw:<12}  {text}")
            addr += length


# Screen text uses the same ASCII codes as the character ROM, with 0x40 as the
# space glyph and 0x20 as the string separator. See tools/dump_chars.py.
PRINTABLE = set(range(0x30, 0x5B)) | set(b" -.,!()'")


def show_strings(rom, minimum):
    runs, current, start = [], bytearray(), 0
    for i, byte in enumerate(rom[:PRG_END]):
        if byte in PRINTABLE:
            if not current:
                start = i
            current.append(byte)
            continue
        if len(current) >= minimum:
            runs.append((start, bytes(current)))
        current.clear()
    if len(current) >= minimum:
        runs.append((start, bytes(current)))
    for addr, text in runs:
        print(f"{addr:04X}  {text.decode('ascii')}")
    print(f"\n{len(runs)} run(s) of {minimum}+ printable bytes in 0x0000-0x3FFF")


def auto_int(text):
    return int(text, 0)


def main():
    parser = argparse.ArgumentParser(
        description="Disassemble Z80 code from a Rally-X core ROM image. File "
        "offsets equal CPU addresses across the 0x0000-0x3FFF program ROM."
    )
    parser.add_argument(
        "rom", type=Path, help="core ROM image (rallyx.rom or nrallyx.rom)"
    )
    parser.add_argument(
        "--start",
        type=auto_int,
        help="first address to disassemble, accepts 0x notation",
    )
    parser.add_argument(
        "--end",
        type=auto_int,
        help="one past the last address (default: --start + 0x80)",
    )
    parser.add_argument(
        "--strings",
        type=auto_int,
        nargs="?",
        const=6,
        metavar="MINLEN",
        help="instead of disassembling, list printable runs of MINLEN+ bytes "
        "(default 6) to find the data before pointing --start at the code",
    )
    args = parser.parse_args()

    if not args.rom.is_file():
        raise Fail(f"ROM image not found: {args.rom}")
    rom = args.rom.read_bytes()
    if len(rom) != ROM_SIZE:
        raise Fail(
            f"{args.rom} is {len(rom)} bytes, expected {ROM_SIZE} -- this wants a "
            "core ROM image from build_rom.py, not a raw MAME part"
        )

    if args.strings is not None:
        if args.strings < 1:
            raise Fail("--strings length must be at least 1")
        show_strings(rom, args.strings)
        return

    if args.start is None:
        raise Fail("give --start <addr>, or --strings to look for text first")
    end = args.end if args.end is not None else args.start + 0x80
    if not 0 <= args.start < end <= PRG_END:
        raise Fail(
            f"range must satisfy 0 <= start < end <= 0x{PRG_END:04X} (the program "
            f"ROM), got start=0x{args.start:04X} end=0x{end:04X}"
        )

    Disassembler(rom).listing(args.start, end)


if __name__ == "__main__":
    run(main)
