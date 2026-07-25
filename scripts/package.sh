#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SD_ROOT=""
ZIP=0

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="$2"; shift 2 ;;
        --sd-root) SD_ROOT="$2"; shift 2 ;;
        --zip) ZIP=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

step() { printf '==> %s\n' "$1"; }
ok()   { printf '    %s\n' "$1"; }

PY=""
for c in python3 python; do
    if "$c" -c 'import sys' >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$PY" ] || { echo "python3 (or python) is required" >&2; exit 1; }

read -r AUTHOR SHORTNAME PLATFORM VERSION DATE < <("$PY" -c '
import json, sys
m = json.load(open(sys.argv[1]))["core"]["metadata"]
print(m["author"], m["shortname"], m["platform_ids"][0], m["version"], m["date_release"])
' "$ROOT/core.json")

CORENAME="$AUTHOR.$SHORTNAME"
FPGA_OUT="$ROOT/src/fpga/output_files/ap_core.rbf"
DIST="$ROOT/dist"
RELEASE="$ROOT/release"
CORE_DIR="$RELEASE/Cores/$CORENAME"
PLAT_DIR="$RELEASE/Platforms"
PLAT_IMG="$PLAT_DIR/_images"
ASSET_DIR="$RELEASE/Assets/$PLATFORM/common"

[ -f "$FPGA_OUT" ] || { echo "Bitstream not found: $FPGA_OUT  (compile in Quartus first)" >&2; exit 1; }

step "Building SD layout under release/"
rm -rf "$RELEASE"
mkdir -p "$CORE_DIR" "$PLAT_IMG" "$ASSET_DIR"

step "Reversing bitstream -> bitstream.rbf_r"
"$PY" -c '
import sys
d = open(sys.argv[1], "rb").read()
open(sys.argv[2], "wb").write(bytes(int(format(b, "08b")[::-1], 2) for b in d))
' "$FPGA_OUT" "$CORE_DIR/bitstream.rbf_r"

cp "$ROOT"/*.json "$CORE_DIR/"
cp "$ROOT/info.txt" "$CORE_DIR/"
cp "$DIST/icon.bin" "$CORE_DIR/"
cp "$DIST/platforms/$PLATFORM.json" "$PLAT_DIR/"
PLAT_BIN="$DIST/platforms/_images/$PLATFORM.bin"
[ -f "$PLAT_BIN" ] && cp "$PLAT_BIN" "$PLAT_IMG/"

ok "Core folder: Cores/$CORENAME"
ok "Bitstream:   $(( $(wc -c < "$CORE_DIR/bitstream.rbf_r") )) bytes"

if [ -n "$SD_ROOT" ]; then
    step "Copying to SD card: $SD_ROOT"
    [ -d "$SD_ROOT" ] || { echo "SD path not found: $SD_ROOT" >&2; exit 1; }
    cp -R "$RELEASE"/* "$SD_ROOT/"
    ok "Copied to $SD_ROOT"
fi

if [ "$ZIP" -eq 1 ]; then
    ZIP_PATH="$ROOT/${CORENAME}_${VERSION}_${DATE}.zip"
    step "Zipping release -> $(basename "$ZIP_PATH")"
    rm -f "$ZIP_PATH"
    ( cd "$RELEASE" && zip -rq "$ZIP_PATH" . )
    ok "Wrote $(basename "$ZIP_PATH")"
fi

step "Done."
