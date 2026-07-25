#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$HOME/Downloads/nrallyx.zip"
OUT="$ROOT/build/nrallyx.rom"

while [ $# -gt 0 ]; do
    case "$1" in
        --zip) ZIP="$2"; shift 2 ;;
        --out) OUT="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

step() { printf '==> %s\n' "$1"; }

PARTS=(
    "nrx_prg1.1d 0 2048"
    "nrx_prg2.1e 0 2048"
    "nrx_prg1.1d 2048 2048"
    "nrx_prg2.1e 2048 2048"
    "nrx_prg3.1k 0 2048"
    "nrx_prg4.1l 0 2048"
    "nrx_prg3.1k 2048 2048"
    "nrx_prg4.1l 2048 2048"
    "nrx_chg1.8e 0 2048"
    "nrx_chg2.8d 0 2048"
    "rx1-6.8m 0 256"
    "rx1-5.3p 0 256"
    "nrx1-7.8p 0 256"
    "nrx1-1.11n 0 32"
)
EXPECTED_TOTAL=21280

[ -f "$ZIP" ] || { echo "ROM zip not found: $ZIP" >&2; exit 1; }

step "Extracting $ZIP"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -oq "$ZIP" -d "$TMP"

step "Assembling ROM blob per MRA layout"
mkdir -p "$(dirname "$OUT")"
: > "$OUT"
offset=0
for p in "${PARTS[@]}"; do
    read -r file off len <<< "$p"
    src="$TMP/$file"
    [ -f "$src" ] || { echo "Missing ROM file in zip: $file" >&2; exit 1; }
    size=$(( $(wc -c < "$src") ))
    end=$((off + len))
    [ "$size" -ge "$end" ] || { echo "$file is $size bytes, need $end (off $off len $len)" >&2; exit 1; }
    tail -c "+$((off + 1))" "$src" | head -c "$len" >> "$OUT"
    printf '    0x%04X  %-13s off %4d len %4d\n' "$offset" "$file" "$off" "$len"
    offset=$((offset + len))
done

total=$(( $(wc -c < "$OUT") ))
[ "$total" -eq "$EXPECTED_TOTAL" ] || { echo "Assembled $total bytes, expected $EXPECTED_TOTAL" >&2; exit 1; }
step "Wrote $OUT ($total bytes)"
