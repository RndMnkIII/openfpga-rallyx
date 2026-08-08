#!/usr/bin/env python3
import argparse
import glob
import os
import re
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

# VHDL half of the suite. Icarus cannot read VHDL, so the T80 testbench runs
# under GHDL instead. winget puts ghdl.exe outside PATH until the shell is
# restarted, hence the package-dir glob.
GHDL_GLOBS = (
    "~/AppData/Local/Microsoft/WinGet/Packages/ghdl.ghdl*/bin",
    "C:/ghdl/bin",
    "/usr/local/bin",
)
# Analysis order matters in VHDL: the package first, the top last.
T80_SOURCES = (
    "src/fpga/rtl/cpu/T80_Pack.vhd",
    "src/fpga/rtl/cpu/T80_ALU.vhd",
    "src/fpga/rtl/cpu/T80_MCode.vhd",
    "src/fpga/rtl/cpu/T80_Reg.vhd",
    "src/fpga/rtl/cpu/T80.vhd",
    "src/fpga/rtl/cpu/T80s.vhd",
)
# --std=93 because T80 is VHDL-93; -fsynopsys for its non-standard IEEE
# packages; --syn-binding because T80's component is declared in a package,
# which GHDL's strict default binding refuses to resolve.
GHDL_FLAGS = ("--std=93", "-fsynopsys")
GHDL_ELAB_FLAGS = ("--syn-binding",)


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


def find_ghdl(override):
    if override:
        if not override.is_file():
            raise Fail(f"ghdl not found: {override}")
        return override
    found = shutil.which("ghdl")
    if found:
        return Path(found)
    exe = "ghdl.exe" if os.name == "nt" else "ghdl"
    for pattern in GHDL_GLOBS:
        for bindir in glob.glob(os.path.expanduser(pattern)):
            candidate = Path(bindir) / exe
            if candidate.is_file():
                return candidate
    return None


def run_one_vhdl(ghdl, bench, root, workdir):
    """Analyse the T80 sources plus one VHDL bench, then run it."""
    lib = workdir / bench.stem
    lib.mkdir(parents=True, exist_ok=True)
    srcs = [str(root / s) for s in T80_SOURCES] + [str(bench)]

    built = subprocess.run(
        [str(ghdl), "-a", *GHDL_FLAGS, f"--workdir={lib}", *srcs],
        capture_output=True,
        text=True,
        check=False,
    )
    if built.returncode != 0:
        print(built.stdout, end="")
        print(built.stderr, end="", file=sys.stderr)
        return False

    result = subprocess.run(
        [
            str(ghdl),
            "-r",
            *GHDL_FLAGS,
            *GHDL_ELAB_FLAGS,
            f"--workdir={lib}",
            bench.stem,
            "--ieee-asserts=disable",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    # GHDL's `report` goes to stderr, prefixed with file:line:col:@time:(level):
    # The path is matched non-greedily -- on Windows it contains a drive colon.
    merged = result.stdout + result.stderr
    prefix = re.compile(r"^.*?:\d+:\d+:@[^:]*:\([^)]*\): ?")
    for line in merged.splitlines():
        print(prefix.sub("", line).rstrip())

    return result.returncode == 0 and "FAIL" not in merged


def discover(sim_dir, only):
    benches = sorted(sim_dir.glob("tb_*.v")) + sorted(
        (sim_dir / "vhdl").glob("tb_*.vhd")
    )
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
        "-I",
        str(sim_dir),
        "-s",
        bench.stem,
        "-o",
        str(vvp_out),
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


def simulate(root, only, iverilog, ghdl_path):
    sim_dir = root / "sim"
    iverilog = find_iverilog(iverilog)
    step(f"Icarus: {iverilog}")

    ghdl = find_ghdl(ghdl_path)
    if ghdl:
        step(f"GHDL: {ghdl}")
    else:
        step("GHDL not found — VHDL testbenches will be skipped")

    srcs, defines = sources(root)
    benches = discover(sim_dir, only)
    step(f"Running {len(benches)} testbench(es)")
    print()

    passed, failed, skipped = [], [], []
    with tempfile.TemporaryDirectory(prefix="rallyx-sim-") as tmp:
        for bench in benches:
            if bench.suffix == ".vhd":
                if ghdl is None:
                    step(f"{bench.stem}: SKIPPED — ghdl not found (VHDL bench)")
                    skipped.append(bench.stem)
                    print()
                    continue
                ok_run = run_one_vhdl(ghdl, bench, root, Path(tmp))
            else:
                ok_run = run_one(iverilog, bench, srcs, defines, sim_dir, Path(tmp))
            if ok_run:
                passed.append(bench.stem)
            else:
                failed.append(bench.stem)
            print()

    tail = f", {len(skipped)} skipped" if skipped else ""
    step(f"{len(passed)} passed, {len(failed)} failed{tail}")
    for name in passed:
        ok(f"pass  {name}")
    for name in failed:
        print(f"    fail  {name}")
    for name in skipped:
        print(f"    skip  {name}")

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
    parser.add_argument(
        "--ghdl",
        type=Path,
        help="path to ghdl for the VHDL benches (default: autodetect)",
    )
    args = parser.parse_args()
    simulate(args.root, args.test, args.iverilog, args.ghdl)


if __name__ == "__main__":
    run(main)
