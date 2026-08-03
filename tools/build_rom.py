#!/usr/bin/env python3
import argparse
import zipfile
from pathlib import Path

from _common import REPO_ROOT, Fail, ok, run, step

PARTS = (
    ("nrx_prg1.1d", 0, 2048),
    ("nrx_prg2.1e", 0, 2048),
    ("nrx_prg1.1d", 2048, 2048),
    ("nrx_prg2.1e", 2048, 2048),
    ("nrx_prg3.1k", 0, 2048),
    ("nrx_prg4.1l", 0, 2048),
    ("nrx_prg3.1k", 2048, 2048),
    ("nrx_prg4.1l", 2048, 2048),
    ("nrx_chg1.8e", 0, 2048),
    ("nrx_chg2.8d", 0, 2048),
    ("rx1-6.8m", 0, 256),
    ("rx1-5.3p", 0, 256),
    ("nrx1-7.8p", 0, 256),
    ("nrx1-1.11n", 0, 32),
)
EXPECTED_TOTAL = 21280


def assemble(zip_path):
    blob = bytearray()
    with zipfile.ZipFile(zip_path) as archive:
        members = {}
        for info in archive.infolist():
            if not info.is_dir():
                members.setdefault(Path(info.filename).name.lower(), info)
        step("Assembling ROM blob per MRA layout")
        for name, off, length in PARTS:
            info = members.get(name.lower())
            if info is None:
                raise Fail(f"Missing ROM file in zip: {name}")
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
    blob = assemble(zip_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(blob)
    step(f"Wrote {out} ({len(blob)} bytes)")


def main():
    parser = argparse.ArgumentParser(
        description="Assemble nrallyx.rom from a MAME New Rally-X ROM set."
    )
    parser.add_argument(
        "--zip",
        type=Path,
        default=Path.home() / "Downloads" / "nrallyx.zip",
        help="MAME nrallyx.zip ROM set (default: %(default)s)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=REPO_ROOT / "build" / "nrallyx.rom",
        help="output ROM image (default: %(default)s)",
    )
    args = parser.parse_args()
    build(args.zip, args.out)


if __name__ == "__main__":
    run(main)
