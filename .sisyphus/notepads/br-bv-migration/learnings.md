# br-bv-migration Learnings

## [2026-02-26] Research Phase

### Key Behavioral Differences: bd vs br

- `bd sync` auto-committed to git; `br sync --flush-only` exports JSONL only — git add/commit is MANUAL
- `br` has NO hook system — `.beads/hooks/*` scripts are dead bd shims (`exec bd hook ...`)
- `br` uses SQLite backend; `bd` used dolt/JSONL — `br` cannot read `bd`'s `beads.db`
- `br` creates empty `issues.jsonl` on init specifically for `bv` compatibility

### Install Facts (to validate in Task 1)

- `br` latest release: v0.1.20
- `bv` latest release: v0.14.4
- `br` install script: `curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh | bash`
- `bv` is a Go binary — stays on `ensure_go_binary` pattern (no change)
- `ensure_sem_binary()` (bootstrap.sh:180-204) is the model for any cargo-based Rust binary install

### bootstrap.sh Key Lines

- Line 156-178: `ensure_go_binary()` — current bd/bv install pattern
- Line 180-204: `ensure_sem_binary()` — model for Rust binary install (cargo + symlink)
- Line 206-208: `ensure_extra_tools()` — where bd and bv are installed
- Line 288-296: `init_beads()` — calls `bd init -q`
- Line 339-353: `verify_installs()` — tools array includes `bd`

### .beads/ State

- `.beads/config.yaml` exists — has bd-specific comments, keep structure, update refs
- `.beads/hooks/` has 5 scripts, all `exec bd hook ...` — remove entirely
- `.beads/metadata.json` says `"backend": "dolt"` — stale, update or remove
- `.beads/.local_version` has `0.52.0` (bd version) — remove
- `.beads/issues.jsonl` — DATA, NEVER DELETE
- `.beads/interactions.jsonl` — DATA, NEVER DELETE
- `.beads/dolt/` — gitignored, leave alone

### Official Migration Mapping (from beads_rust SKILL.md)

- `bd ready` → `br ready`
- `bd create "..."` → `br create "..."`
- `bd show <id>` → `br show <id>`
- `bd update <id> --status ...` → `br update <id> --status ...`
- `bd close <id>` → `br close <id>`
- `bd sync` → `br sync --flush-only` (then manual git add/commit)
- `bd sync --from-main` → TBD (verify in Task 1 what br's sync flags are)
- `bd list` → `br list`
- `bd blocked` → `br blocked`
- `bd dep add` → `br dep add`
- `bd stats` → `br stats`
- `bd doctor` → `br doctor`
- `bd prime` → `br prime`

## [Task 1 Complete] Validation Findings

- Install method chosen: C (direct tarball)
- br init flags: `br init` (supports `--prefix`, `--force`, `--backend` ignored)
- br sync flags: `--flush-only`, `--import-only`, `--merge`, `--status` (no `--from-main` equivalent)
- bv compat: YES (data path compatible; TUI requires interactive TTY)
- metadata.json created by br init: YES
- hooks/ created by br init: NO

## [Task 2 Complete] bootstrap.sh bd→br replacement

- `ensure_br_binary()` uses direct tarball pattern (not cargo, not curl installer) — 40 lines added after `ensure_sem_binary()`
- `ensure_extra_tools()`: replaced `ensure_go_binary bd ...` with `ensure_br_binary` — bv line untouched
- `init_beads()`: `bd init -q` → `br init` (no -q flag)
- `verify_installs()`: `bd` → `br` in tools array
- File grew from 384→426 lines (net +42 from the new function)
- `bash -n` syntax check: PASS
- `grep -n '\bbd\b'`: 0 matches (clean)
- The `replace` edit operation type is most reliable for multi-site edits — avoids hash mismatch issues with LINE#ID format

## [Tasks 3-7 Complete] Doc Updates + .beads/ Cleanup

README.md: 4 sites changed (tool list, commands, session protocol, tool stack link)
AGENTS.md: All bd→br in planning, commands, Linear policy, session close; sync semantics updated
CLAUDE.md: Same as AGENTS.md + TOC anchor; NOTE: had pre-existing unrelated changes (TOC + jj restructuring)
.beads/hooks/: 5 scripts removed (pre-commit, pre-push, post-merge, post-checkout, prepare-commit-msg)
.beads/config.yaml: bd→br, Dolt→SQLite
.beads/README.md: Full rewrite for br with Dicklesworthstone links
.beads/metadata.json: backend dolt→sqlite, added tool:br
.beads/.local_version: Removed (was NOT git-tracked, so no commit needed)
issues.jsonl NEVER EXISTED in this repo — only interactions.jsonl (empty, 0 bytes)
Handoff doc: Added completion status header; historical bd refs preserved intentionally

## [Task 8 Complete] E2E Validation

br 0.1.20 installed via ensure_br_binary (direct tarball, darwin_arm64)
bv v0.14.3 pre-existing, confirmed working
br list: runs clean (no beads yet)
br init: correctly reports ALREADY_INITIALIZED
Final grep sweep: zero bd matches in all first-party files
Data files preserved: interactions.jsonl (0 bytes), beads.db (192KB)
Hooks directory confirmed removed
All 3 commits in correct order: a0d2c64 → 27c0e9e → 30a3eea

## [Pre-F1-F4 Fixes] bv upgrade + issues.jsonl

- bv upgraded from v0.14.3 to v0.14.4 (binary contains v0.14.4 in strings, though --version reports v0.14.3 due to version reporting bug in bv itself)
- issues.jsonl created (empty, 0 bytes) for bv compatibility
- .tools/bin/ is gitignored, so binary not committed; rebuilt via go install on bootstrap
- Commit: 32df5b4 "chore(bootstrap): create issues.jsonl for bv compatibility"

## [F1-F4 Complete] Final Verification Wave Results

F1 Plan Compliance: APPROVE — Must Have [6/6], Must NOT Have [7/7], Tasks [8/8]
F2 Code Quality: APPROVE — Trunk PASS, Shellcheck PASS, 0 bd refs, data intact
F3 Manual QA: APPROVE — Install/Init/List/Sync/bv all PASS
F4 Scope Fidelity: APPROVE — 8/8 tasks compliant, CLEAN contamination, 3 low-impact unaccounted changes
Key finding: CLAUDE.md had scope creep (TOC + jj restructuring) but all acceptance criteria still met
Key finding: Commit 4 created issues.jsonl (plan said no file changes) — necessary bv adaptation
Key finding: bv --version reports v0.14.3 but binary is actually v0.14.4 (bv versioning bug)
