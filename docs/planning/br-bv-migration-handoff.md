# bd -> br + bv Bootstrap Migration Handoff

## Migration Status: COMPLETED

This migration was executed successfully. All `bd` references in first-party files have been replaced with `br`. The `.beads/hooks/` directory was removed (br has no hook system). Install method: direct tarball download from GitHub releases (Option C).

---

## Goal

Prepare a safe migration plan for this repo's bootstrap flow from `bd` (steveyegge/beads) to `br` (Dicklesworthstone/beads_rust), while keeping `bv` (Dicklesworthstone/beads_viewer) functional and format-compatible.

This document is for a planning/implementation agent. It captures validated findings, migration scope, risks, and an execution order.

## Scope Clarification

- The migration target is **this repository itself** (`bootstrap`), not a downstream repo created from the template.
- All recommendations here are intended to modify the first-party bootstrap assets in this repo (especially `bootstrap.sh`, top-level docs, and local beads hook/config artifacts).

## External Repos Confirmed

- `beads_rust` (Dicklesworthstone): `https://github.com/Dicklesworthstone/beads_rust`
  - CLI command is `br`.
  - README explicitly states non-invasive behavior and no automatic git execution.
  - Sync guidance is `br sync --flush-only` followed by manual `git add .beads/` + `git commit`.
  - References direct integration with `bv` in FAQ.
- `beads_viewer` (Dicklesworthstone): `https://github.com/Dicklesworthstone/beads_viewer`
  - CLI command is `bv`.
  - README positions it as a Beads graph/TUI sidecar.
  - Uses `.beads/*` data paths in docs and robot mode examples.

## Key Compatibility Signals (Important)

- `br` keeps `.beads/` conventions (per `beads_rust` README examples), so migration likely does **not** require a directory rename.
- `br` intentionally changes sync semantics versus old `bd` patterns:
  - old docs/habits: `bd sync` with assumptions around built-in sync flows
  - `br`: explicit export via `br sync --flush-only`, then git commands manually
- `bv` is designed as a sidecar and should remain separately installed as `bv` unless `br` later bundles it (no evidence found that `br` bundles `bv`).

## In-Repo Migration Surface (Actionable)

### 1) Bootstrap installer script (highest priority)

- `bootstrap.sh:207` installs `bd` from `github.com/steveyegge/beads/cmd/bd`
- `bootstrap.sh:208` installs `bv` from `github.com/Dicklesworthstone/beads_viewer/cmd/bv`
- `bootstrap.sh:288` / `bootstrap.sh:295` performs beads init and runs `"$BIN_DIR/bd" init -q`
- `bootstrap.sh:341` verifies tool list includes `bd` and `bv`

Expected migration impact:

- swap `bd` binary install target to `br` source/install strategy
- keep `bv` install path unless new evidence says otherwise
- switch init command to `br init`
- update verify tool list from `bd` -> `br`

### 2) Human/agent docs (high priority)

- `README.md:8,61,62,74,82,83`
- `AGENTS.md:41,43,92-102,124,127,169,171,174`
- `CLAUDE.md:41,43,92-102,155,157,160`

Expected migration impact:

- replace command examples `bd ...` -> `br ...`
- replace sync steps to `br sync --flush-only` + explicit git add/commit notes
- keep `bv` references, but update wording to sidecar with `br`

### 3) Existing local beads state and hooks (critical to inspect)

- `.beads/config.yaml` contains `bd`-specific comments and sync assumptions
- `.beads/README.md` contains `bd` commands and steveyegge/beads install docs
- `.beads/hooks/*` scripts are `bd` shims, including:
  - `.beads/hooks/pre-commit`
  - `.beads/hooks/pre-push`
  - `.beads/hooks/post-merge`
  - `.beads/hooks/post-checkout`
  - `.beads/hooks/prepare-commit-msg`

Expected migration impact:

- these hooks likely become invalid when `bd` is removed
- planning decision needed: disable/remove/replace with `br` equivalent hooks (if any)

### 4) Task runner indirection

- `mise.toml` does not call `bd` directly; it calls `bootstrap.sh` tasks (`bootstrap/install/init`)
- migration should focus on `bootstrap.sh` and docs, then re-test `mise run bootstrap` path

## Noise/False Positive Notes

- Exhaustive grep returns many irrelevant `bd`/`br` substrings under tool/runtime caches (`.mise`, `.tools`, vendored assets).
- Migration scope should be constrained to first-party files listed above.

## Recommended Execution Plan (for implementation agent)

1. **External command/format confirmation step**
   - verify exact `br` install command path and minimal supported init/sync workflow from upstream docs
   - verify whether `br` expects/reads `.beads/issues.jsonl` or `.beads/beads.jsonl` in current release
2. **Bootstrap changes**
   - update `bootstrap.sh` install/init/verify entries from `bd` to `br`
   - keep `bv` install intact unless upstream changed
3. **Docs migration**
   - update `README.md`, `AGENTS.md`, `CLAUDE.md` command blocks and sync semantics
4. **Hook strategy decision**
   - evaluate `.beads/hooks/*` migration strategy
   - at minimum, prevent broken hook execution when `bd` is absent
5. **Validation**
   - run bootstrap task(s), confirm `.tools/bin/br` and `.tools/bin/bv` existence
   - smoke test `br init`, `br ready`, `br sync --flush-only`, `bv --robot-help` (or equivalent non-interactive check)
   - run grep check to ensure no first-party `bd` command remnants remain in docs/bootstrap

## Explicit Open Questions for Planner

- Should `.beads/hooks/*` be fully replaced, or disabled with clear migration notes?
- Do we preserve historical `.beads/README.md` as legacy reference, or rewrite to `br` workflow?
- Should `README.md` tool links now point to `beads_rust` as primary and keep `beads_viewer` as sidecar?

## Suggested Acceptance Criteria

- `bootstrap.sh` installs `br` (not `bd`) and still installs `bv`.
- Init path uses `br init` successfully in a clean repo.
- All first-party docs use `br` commands and explicit sync+git semantics.
- No first-party `bd` command invocations remain in bootstrap/docs/hooks unless intentionally documented as legacy.
- `bv` remains callable after bootstrap and can read the project issue graph data path expected by current `br` output.
