#!/usr/bin/env python3
import argparse
import zipfile
from pathlib import Path

from _common import REPO_ROOT, Fail, ok, run, step

# Both games assemble to the same 21,280-byte layout, so the core's download
# decode (CPU 0x0000, chars 0x4000, dots 0x5000, waves 0x5100, CLUT 0x5200,
# palette 0x5300) is identical for either image. Only the parts differ:
# New Rally-X splits its program ROMs in half (MAME's ROM_CONTINUE) and uses two
# 2 KiB character ROMs; Rally-X uses four flat 4 KiB program ROMs and one 4 KiB
# character ROM. Parts are (filename, offset, length, crc32).
SETS = {
    "nrallyx": (
        "New Rally-X",
        (
            ("nrx_prg1.1d", 0, 2048, 0xBA7DE9FC),
            ("nrx_prg2.1e", 0, 2048, 0xEEDFCCAE),
            ("nrx_prg1.1d", 2048, 2048, 0xBA7DE9FC),
            ("nrx_prg2.1e", 2048, 2048, 0xEEDFCCAE),
            ("nrx_prg3.1k", 0, 2048, 0xB4D5D34A),
            ("nrx_prg4.1l", 0, 2048, 0x7DA5496D),
            ("nrx_prg3.1k", 2048, 2048, 0xB4D5D34A),
            ("nrx_prg4.1l", 2048, 2048, 0x7DA5496D),
            ("nrx_chg1.8e", 0, 2048, 0x1FFF38A4),
            ("nrx_chg2.8d", 0, 2048, 0x85D9FFFD),
            ("rx1-6.8m", 0, 256, 0x3C16F62C),
            ("rx1-5.3p", 0, 256, 0x4BAD7017),
            ("nrx1-7.8p", 0, 256, 0x4E46F485),
            ("nrx1-1.11n", 0, 32, 0xA0A49017),
        ),
    ),
    "rallyx": (
        "Rally-X (32k Ver)",
        (
            ("1b", 0, 4096, 0x5882700D),
            ("rallyxn.1e", 0, 4096, 0xED1EBA2B),
            ("rallyxn.1h", 0, 4096, 0x4F98DD1C),
            ("rallyxn.1k", 0, 4096, 0x9AACCCF0),
            ("8e", 0, 4096, 0x277C1DE5),
            ("rx1-6.8m", 0, 256, 0x3C16F62C),
            ("rx1-5.3p", 0, 256, 0x4BAD7017),
            ("rx1-7.8p", 0, 256, 0x834D4FDA),
            ("rx1-1.11n", 0, 32, 0xC7865434),
        ),
    ),
}
EXPECTED_TOTAL = 21280


def read_members(zip_path):
    with zipfile.ZipFile(zip_path) as archive:
        members = {}
        for info in archive.infolist():
            if not info.is_dir():
                members.setdefault(Path(info.filename).name.lower(), info)
        return members


def identify(members):
    """Pick the set whose parts are all present in the zip."""
    matches = [
        setname
        for setname, (_, parts) in SETS.items()
        if all(name.lower() in members for name, _, _, _ in parts)
    ]
    if not matches:
        raise Fail(
            "Zip matches neither romset. Expected a MAME rallyx.zip or "
            "nrallyx.zip; found: " + ", ".join(sorted(members)[:8])
        )
    if len(matches) > 1:
        raise Fail(f"Zip matches more than one romset: {', '.join(sorted(matches))}")
    return matches[0]


def assemble(zip_path, members, setname):
    title, parts = SETS[setname]
    blob = bytearray()
    checked = set()
    with zipfile.ZipFile(zip_path) as archive:
        step(f"Assembling {title} ({setname}) per MRA layout")
        for name, off, length, crc in parts:
            info = members[name.lower()]
            if name not in checked:
                if info.CRC != crc:
                    raise Fail(
                        f"{name} has CRC32 {info.CRC:08x}, expected {crc:08x} "
                        f"— wrong or corrupt file for the {setname} set"
                    )
                checked.add(name)
            data = archive.read(info)
            end = off + length
            if len(data) < end:
                raise Fail(
                    f"{name} is {len(data)} bytes, need {end} (off {off} len {length})"
                )
            ok(f"0x{len(blob):04X}  {name:<13} off {off:>4} len {length:>4}")
            blob += data[off:end]
    if len(blob) != EXPECTED_TOTAL:
        raise Fail(f"Assembled {len(blob)} bytes, expected {EXPECTED_TOTAL}")
    return bytes(blob)


def build(zip_path, out):
    if not zip_path.is_file():
        raise Fail(f"ROM zip not found: {zip_path}")
    step(f"Reading {zip_path}")
    members = read_members(zip_path)
    setname = identify(members)
    blob = assemble(zip_path, members, setname)
    if out is None:
        out = REPO_ROOT / "build" / f"{setname}.rom"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(blob)
    step(f"Wrote {out} ({len(blob)} bytes)")


def main():
    parser = argparse.ArgumentParser(
        description="Assemble a core ROM image from a MAME Rally-X or "
        "New Rally-X set. The romset is detected from the zip contents."
    )
    parser.add_argument(
        "--zip",
        type=Path,
        required=True,
        help="MAME rallyx.zip or nrallyx.zip ROM set",
    )
    parser.add_argument(
        "--out",
        type=Path,
        help="output ROM image (default: build/<setname>.rom)",
    )
    args = parser.parse_args()
    build(args.zip, args.out)


if __name__ == "__main__":
    run(main)
