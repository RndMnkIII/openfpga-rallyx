#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path
from typing import NamedTuple, Optional

from _common import REPO_ROOT, Fail, ok, run, skip, step


class Repo(NamedTuple):
    name: str
    url: str
    ref: Optional[str] = None


REFERENCE_REPOS = (
    Repo(
        "arcade-rallyx_mister",
        "https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer.git",
    ),
    Repo(
        "openfpga-atarisystem1",
        "https://github.com/obsidian-dot-dev/openFPGA-AtariSystem1.git",
    ),
    Repo(
        "openfpga-snes-analogizer",
        "https://github.com/RndMnkIII/openfpga-SNES-Analogizer.git",
    ),
    Repo("arcade-digdug", "https://github.com/opengateware/arcade-digdug.git"),
)


def git(args, dry_run):
    if dry_run:
        skip("git " + " ".join(str(a) for a in args))
        return
    result = subprocess.run(["git", *[str(a) for a in args]])
    if result.returncode != 0:
        raise Fail(
            f"git {' '.join(str(a) for a in args)} failed (exit {result.returncode})"
        )


def default_branch(path):
    result = subprocess.run(
        ["git", "-C", str(path), "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"],
        capture_output=True,
        text=True,
    )
    head = result.stdout.strip()
    if result.returncode == 0 and head:
        return head.removeprefix("refs/remotes/origin/")
    return "HEAD"


def select(name):
    if not name:
        return list(REFERENCE_REPOS)
    targets = [r for r in REFERENCE_REPOS if r.name == name]
    if not targets:
        known = ", ".join(r.name for r in REFERENCE_REPOS)
        raise Fail(f"Unknown repo '{name}'. Known: {known}")
    return targets


def sync(root, name, dry_run):
    targets = select(name)
    repos_dir = root / ".repos"

    if dry_run:
        print("(dry run -- no changes will be made)")
    step(f"Reference dir: {repos_dir}")
    if not dry_run:
        repos_dir.mkdir(parents=True, exist_ok=True)

    for repo in targets:
        dest = repos_dir / repo.name
        if (dest / ".git").is_dir():
            ref = repo.ref or default_branch(dest)
            step(f"{repo.name}: update -> {ref}")
            git(["-C", dest, "fetch", "--depth", "1", "origin", ref], dry_run)
            git(["-C", dest, "reset", "--hard", "FETCH_HEAD"], dry_run)
            git(["-C", dest, "clean", "-fdx"], dry_run)
        else:
            step(f"{repo.name}: clone -> {repo.ref or 'default branch'}")
            args = ["clone", "--depth", "1"]
            if repo.ref:
                args += ["--branch", repo.ref]
            args += ["--single-branch", repo.url, dest]
            git(args, dry_run)
        ok(f"{repo.name} ok")

    step(f"Done ({len(targets)} repo(s)).")


def main():
    parser = argparse.ArgumentParser(
        description="Clone or update the vendored reference repositories under .repos/."
    )
    parser.add_argument("--repo", help="sync only this repo (default: all)")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the git commands without running them",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="repository root (default: %(default)s)",
    )
    args = parser.parse_args()
    sync(args.root, args.repo, args.dry_run)


if __name__ == "__main__":
    run(main)
