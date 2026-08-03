# CLAUDE.md

## Task Completion Requirements

- Any change under `src/fpga/` (`.v`, `.sv`, `.vhd`, `.qsf`, `.qpf`, `.sdc`) must
  compile before the task is considered done. Run the smallest relevant check;
  Quartus 21.1 is installed but not on `PATH`
  (`/c/intelFPGA_lite/21.1/quartus/bin64/`).
  - Fast syntax/elaboration pass for most edits: run `quartus_map ap_core` from
    `src/fpga/`, then confirm `output_files/ap_core.map.rpt` reports 0 errors and
    that Analysis & Synthesis succeeded.
  - Full compile (fit + timing), required before packaging or cutting a release:
    run `quartus_sh --flow compile ap_core` from `src/fpga/`, then confirm 0
    errors and met timing across `output_files/ap_core.*.rpt`.
- Any changed core definition JSON (`core.json`, `interact.json`, `input.json`,
  `data.json`, `video.json`, `audio.json`, `variants.json`) must parse cleanly
  before completion.
- A clean compile is not proof the change works on hardware. State plainly what
  was compiled versus what still needs an on-device boot check by the user; do
  not claim a hardware-facing feature works from synthesis alone.

## Code Style

- Generated code contains no comments — no docstrings, no inline or block
  comments, in any language. Explanations belong in the chat reply or commit
  message, not the source. Leave pre-existing comments in files you edit alone.

## Core Priorities

If a tradeoff is required, choose correctness and robustness over short-term convenience.

## Vendored Repositories

This project vendors external repositories under `.repos/` as read-only
reference material for coding agents.

- Prefer examples and patterns from the vendored source code over generated
  guesses or web search results.
- Do not edit files under `.repos/` unless explicitly asked.
- Do not build from `.repos/`; the Quartus project under `src/fpga/` must only
  reference RTL that lives under `src/`. Copy any needed reference RTL into
  `src/` rather than pointing the project at `.repos/`.
- Repos are declared in the `REFERENCE_REPOS` tuple in `tools/sync.py` — edit
  that tuple to add or remove vendored repos.
- Sync with `python tools/sync.py` (all repos) or
  `python tools/sync.py --repo <name>` (one repo). Add `--dry-run` to print the
  planned git commands without executing them. Each repo tracks its default
  branch (no version pinning).