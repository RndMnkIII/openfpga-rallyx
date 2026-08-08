#!/usr/bin/env python3
import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from _common import REPO_ROOT, Fail, ok, run, step

# Modules outside src/fpga/rtl/ that testbenches reach into. Listed explicitly
# rather than globbed: core_top.v pulls in the PLL and the Analogizer, which
# would drag most of the project into every compile.
EXTRA_SOURCES = (
    "src/fpga/core/pocket_i2s.v",
    "src/fpga/apf/common.v",
)

# Quartus's own simulation model for altsyncram, which backs LINEBUF. Found ->
# the suite tests the real megafunction; not found -> sim/stubs.v supplies a
# behavioural stand-in instead and we say so.
ALTERA_MF = "quartus/eda/sim_lib/altera_mf.v"
QUARTUS_GLOBS = (
    "C:/intelFPGA_lite/*",
    "C:/intelFPGA/*",
    "~/intelFPGA_lite/*",
    "/opt/intelFPGA_lite/*",
)


def find_iverilog(override):
    if override:
        if not override.is_file():
            raise Fail(f"iverilog not found: {override}")
        return override
    found = shutil.which("iverilog")
    if not found:
        raise Fail(
            "Could not find iverilog. Install Icarus Verilog and put it on PATH, "
            "or pass --iverilog /path/to/iverilog"
        )
    return Path(found)


def find_altera_mf():
    env = os.environ.get("QUARTUS_ROOTDIR")
    if env:
        candidate = Path(env).parent / ALTERA_MF
        if candidate.is_file():
            return candidate
    found = []
    for pattern in QUARTUS_GLOBS:
        for install in glob.glob(os.path.expanduser(pattern)):
            candidate = Path(install) / ALTERA_MF
            if candidate.is_file():
                found.append(candidate)
    return max(found) if found else None


def sources(root):
    rtl = root / "src" / "fpga" / "rtl"
    files = sorted(rtl.glob("*.v"))
    if not files:
        raise Fail(f"No RTL found under {rtl}")

    for extra in EXTRA_SOURCES:
        path = root / extra
        if not path.is_file():
            raise Fail(f"Missing source: {path}")
        files.append(path)

    files.append(root / "sim" / "stubs.v")

    altera_mf = find_altera_mf()
    if altera_mf:
        step(f"altsyncram model: {altera_mf}")
        files.append(altera_mf)
        return files, []

    step("altsyncram model not found -- LINEBUF falls back to sim/stubs.v")
    files = [f for f in files if f.name != "LINEBUF.v"]
    return files, ["-DLINEBUF_STUB"]


def discover(sim_dir, only):
    benches = sorted(sim_dir.glob("tb_*.v"))
    if not benches:
        raise Fail(f"No testbenches found under {sim_dir}")
    if not only:
        return benches
    wanted = [b for b in benches if only in b.stem]
    if not wanted:
        known = ", ".join(b.stem for b in benches)
        raise Fail(f"No testbench matching '{only}'. Known: {known}")
    return wanted


def run_one(iverilog, bench, srcs, defines, sim_dir, workdir):
    vvp_out = workdir / f"{bench.stem}.vvp"
    compile_cmd = [
        str(iverilog),
        "-g2012",
        "-I", str(sim_dir),
        "-s", bench.stem,
        "-o", str(vvp_out),
        *defines,
        str(bench),
        *[str(s) for s in srcs],
    ]
    built = subprocess.run(compile_cmd, capture_output=True, text=True, check=False)
    if built.returncode != 0:
        print(built.stdout, end="")
        print(built.stderr, end="", file=sys.stderr)
        return False

    result = subprocess.run(
        ["vvp", str(vvp_out)], capture_output=True, text=True, check=False
    )
    print(result.stdout, end="")
    if result.stderr.strip():
        print(result.stderr, end="", file=sys.stderr)

    # the testbenches report their own verdict; trust it over the exit code,
    # which vvp leaves at 0 even when $display printed failures
    return result.returncode == 0 and "FAIL" not in result.stdout


def simulate(root, only, iverilog):
    sim_dir = root / "sim"
    iverilog = find_iverilog(iverilog)
    step(f"Icarus: {iverilog}")

    srcs, defines = sources(root)
    benches = discover(sim_dir, only)
    step(f"Running {len(benches)} testbench(es)")
    print()

    passed, failed = [], []
    with tempfile.TemporaryDirectory(prefix="rallyx-sim-") as tmp:
        for bench in benches:
            if run_one(iverilog, bench, srcs, defines, sim_dir, Path(tmp)):
                passed.append(bench.stem)
            else:
                failed.append(bench.stem)
            print()

    step(f"{len(passed)} passed, {len(failed)} failed")
    for name in passed:
        ok(f"pass  {name}")
    for name in failed:
        print(f"    fail  {name}")

    if failed:
        raise Fail(f"{len(failed)} testbench(es) failed")


def main():
    parser = argparse.ArgumentParser(
        description="Run the Icarus Verilog timing testbenches under sim/."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="repository root (default: %(default)s)",
    )
    parser.add_argument(
        "--test", help="run only testbenches whose name contains this substring"
    )
    parser.add_argument(
        "--iverilog", type=Path, help="path to iverilog (default: autodetect)"
    )
    args = parser.parse_args()
    simulate(args.root, args.test, args.iverilog)


if __name__ == "__main__":
    run(main)
