#!/usr/bin/env python3
import argparse
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

from _common import REPO_ROOT, Fail, ok, run, step

PROJECT = "ap_core"

# Where Quartus lands by default, newest version first once sorted.
INSTALL_GLOBS = (
    "C:/intelFPGA_lite/*/quartus",
    "C:/intelFPGA/*/quartus",
    "~/intelFPGA_lite/*/quartus",
    "~/intelFPGA/*/quartus",
    "/opt/intelFPGA_lite/*/quartus",
)


def find_quartus_sh(override):
    if override:
        if not override.is_file():
            raise Fail(f"quartus_sh not found: {override}")
        return override

    exe = "quartus_sh.exe" if os.name == "nt" else "quartus_sh"

    rootdir = os.environ.get("QUARTUS_ROOTDIR")
    if rootdir:
        for bindir in ("bin64", "bin"):
            candidate = Path(rootdir) / bindir / exe
            if candidate.is_file():
                return candidate

    on_path = shutil.which("quartus_sh")
    if on_path:
        return Path(on_path)

    found = []
    for pattern in INSTALL_GLOBS:
        for quartus in glob.glob(os.path.expanduser(pattern)):
            for bindir in ("bin64", "bin"):
                candidate = Path(quartus) / bindir / exe
                if candidate.is_file():
                    found.append(candidate)
    if found:
        # crude but adequate: the path carries the version, so the highest sorts newest
        return max(found)

    raise Fail(
        "Could not find quartus_sh. Set QUARTUS_ROOTDIR, put it on PATH, "
        "or pass --quartus /path/to/quartus_sh"
    )


def report_utilization(fpga_dir):
    summary = fpga_dir / "output_files" / f"{PROJECT}.fit.summary"
    if not summary.is_file():
        return
    wanted = ("Logic utilization", "Total registers", "Total block memory bits")
    for line in summary.read_text(encoding="utf-8", errors="replace").splitlines():
        if any(line.strip().startswith(key) for key in wanted):
            ok(line.strip())


def build(root, quartus_sh, do_package, sd_root, make_zip):
    fpga_dir = root / "src" / "fpga"
    if not (fpga_dir / f"{PROJECT}.qpf").is_file():
        raise Fail(f"Quartus project not found: {fpga_dir / (PROJECT + '.qpf')}")

    quartus_sh = find_quartus_sh(quartus_sh)
    step(f"Quartus: {quartus_sh}")

    step(f"Compiling {PROJECT} (this takes a while)")
    result = subprocess.run(
        [str(quartus_sh), "--flow", "compile", PROJECT],
        cwd=str(fpga_dir),
        check=False,
    )
    if result.returncode != 0:
        raise Fail(
            f"Quartus compile failed (exit {result.returncode}). "
            f"See {fpga_dir / 'output_files' / (PROJECT + '.flow.rpt')}"
        )

    rbf = fpga_dir / "output_files" / f"{PROJECT}.rbf"
    if not rbf.is_file():
        raise Fail(
            f"Compile finished but no bitstream at {rbf}. "
            "Check that GENERATE_RBF_FILE is ON in ap_core.qsf."
        )

    ok(f"Bitstream: {rbf} ({rbf.stat().st_size} bytes)")
    report_utilization(fpga_dir)

    if not do_package:
        step("Done. Run tools/package.py to lay out the SD payload.")
        return

    step("Packaging")
    args = [sys.executable, str(Path(__file__).with_name("package.py"))]
    if sd_root:
        args += ["--sd-root", str(sd_root)]
    if make_zip:
        args.append("--zip")
    result = subprocess.run(args, check=False)
    if result.returncode != 0:
        raise Fail(f"package.py failed (exit {result.returncode})")


def main():
    parser = argparse.ArgumentParser(
        description="Compile the Quartus project into a bitstream, optionally packaging it."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="repository root (default: %(default)s)",
    )
    parser.add_argument(
        "--quartus", type=Path, help="path to quartus_sh (default: autodetect)"
    )
    parser.add_argument(
        "--package",
        action="store_true",
        help="also run package.py to build the SD layout",
    )
    parser.add_argument(
        "--sd-root", type=Path, help="with --package, copy the layout onto this SD root"
    )
    parser.add_argument(
        "--zip", action="store_true", help="with --package, write a release archive"
    )
    args = parser.parse_args()

    if (args.sd_root or args.zip) and not args.package:
        raise Fail("--sd-root and --zip only apply with --package")

    build(args.root, args.quartus, args.package, args.sd_root, args.zip)


if __name__ == "__main__":
    run(main)
