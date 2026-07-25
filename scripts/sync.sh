#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO=""
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --root) ROOT="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

REPOS=(
    "arcade-rallyx_mister https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer.git"
    "openfpga-atarisystem1 https://github.com/obsidian-dot-dev/openFPGA-AtariSystem1.git"
    "openfpga-snes-analogizer https://github.com/RndMnkIII/openfpga-SNES-Analogizer.git"
    "arcade-digdug https://github.com/opengateware/arcade-digdug.git"
)
REPOS_DIR="$ROOT/.repos"

step() { printf '==> %s\n' "$1"; }
ok()   { printf '    %s\n' "$1"; }

run_git() {
    if [ "$DRY_RUN" -eq 1 ]; then printf '    git %s\n' "$*"; return; fi
    git "$@"
}

default_branch() {
    local head
    head=$(git -C "$1" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null) || { echo HEAD; return; }
    echo "${head#refs/remotes/origin/}"
}

targets=("${REPOS[@]}")
if [ -n "$REPO" ]; then
    targets=()
    for r in "${REPOS[@]}"; do
        read -r name _ <<< "$r"
        [ "$name" = "$REPO" ] && targets+=("$r")
    done
    if [ ${#targets[@]} -eq 0 ]; then
        names=""
        for r in "${REPOS[@]}"; do read -r name _ <<< "$r"; names="$names $name"; done
        echo "Unknown repo '$REPO'. Known:$names" >&2
        exit 1
    fi
fi

[ "$DRY_RUN" -eq 1 ] && echo "(dry run -- no changes will be made)"
step "Reference dir: $REPOS_DIR"
[ "$DRY_RUN" -eq 1 ] || mkdir -p "$REPOS_DIR"

synced=0
for r in "${targets[@]}"; do
    read -r name url <<< "$r"
    dest="$REPOS_DIR/$name"
    if [ -d "$dest/.git" ]; then
        ref=$(default_branch "$dest")
        step "$name: update -> $ref"
        run_git -C "$dest" fetch --depth 1 origin "$ref"
        run_git -C "$dest" reset --hard FETCH_HEAD
        run_git -C "$dest" clean -fdx
    else
        step "$name: clone -> default branch"
        run_git clone --depth 1 --single-branch "$url" "$dest"
    fi
    ok "$name ok"
    synced=$((synced + 1))
done

step "Done ($synced repo(s))."
