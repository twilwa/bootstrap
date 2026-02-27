# Migrate beads tooling from `bd` to `br` + `bv`

## TL;DR

> **Quick Summary**: Replace the `bd` (steveyegge/beads Go binary) with `br` (Dicklesworthstone/beads_rust) in bootstrap.sh and all first-party docs/configs. Keep `bv` (beads_viewer) installed and verify it reads `br`-produced data.
>
> **Deliverables**:
>
> - `bootstrap.sh` installs `br` (Rust binary) + `bv` (Go binary) instead of `bd` + `bv`
> - All docs (README.md, AGENTS.md, CLAUDE.md) reference `br` commands
> - `.beads/hooks/` removed (br is non-invasive, no hook system)
> - `.beads/config.yaml`, `.beads/README.md`, `.beads/metadata.json` updated for `br`
> - End-to-end validation: `bootstrap.sh` installs both tools, `br init` works, `bv` reads the data
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves
> **Critical Path**: Task 1 (validation) → Task 2 (bootstrap.sh) → Tasks 3-6 (parallel docs/config) → Task 7 (E2E) → Final Verification

---

## Context

### Original Request

Migrate the `bootstrap` repo from `bd` (steveyegge/beads) to `br` (Dicklesworthstone/beads_rust) and ensure `bv` (Dicklesworthstone/beads_viewer) remains installed and compatible. We are working ON the bootstrap repo itself.

### Interview Summary

**Key Discussions**:

- `br` is a Rust binary distributed as pre-built tarballs or via `cargo install`; `bd` was Go (`go install`)
- `bv` is a Go binary that reads `.beads/` JSONL files — stays compatible with `br`
- Key behavioral change: `bd sync` auto-committed to git; `br sync --flush-only` exports JSONL only, git add/commit is manual
- Hook scripts in `.beads/hooks/` are `bd` shims that `exec bd hook ...` — will break when `bd` removed
- SQLite DB incompatibility: `br` cannot read `bd`'s `beads.db`; must delete and rebuild from JSONL
- No test infrastructure in this repo (it's a shell bootstrap script)
- The existing `ensure_sem_binary()` function (lines 180-204 of bootstrap.sh) is a good model for installing a Rust/cargo binary

**Research Findings**:

- `beads_rust` repo has an official `bd-to-br-migration` SKILL.md with exact transform patterns
- `br` latest release v0.1.20, `bv` latest release v0.14.4
- `br` install script: `curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh | bash`
- `bv` install options: brew tap, go install, curl script, direct binary download
- `br` creates empty `issues.jsonl` on init specifically for `bv` compatibility
- `.beads/hooks/` scripts all `exec bd hook ...` or `exec bd hooks run ...` — dead code post-migration
- `.beads/metadata.json` says `"backend": "dolt"` — stale after migration, `br` uses SQLite
- `.beads/.local_version` says `0.52.0` — stale `bd` version, needs removal/update

### Metis Review

**Identified Gaps** (addressed):

- `.beads/metadata.json` with `"backend": "dolt"` is stale — included in cleanup task
- `.beads/.local_version` with bd version `0.52.0` is stale — included in cleanup task
- `interactions.jsonl` preservation — guardrail added to preserve data files
- `br` install script may not respect custom `INSTALL_DIR` — validation task added
- `br init` behavior with existing `.beads/` (dolt backend) — validation task added
- Parallel `bd`/`br` during transition — atomicity requirement added to bootstrap.sh task
- AGENTS.md and CLAUDE.md near-identical content — flagged but out of scope for this migration
- Downstream repos with old hooks — documented in commit message, not in scope to fix

---

## Work Objectives

### Core Objective

Replace `bd` with `br` in the bootstrap repo's install pipeline, update all documentation and configuration, and verify end-to-end compatibility with `bv`.

### Concrete Deliverables

- `bootstrap.sh`: `ensure_br_binary()` function replacing `bd` install; `init_beads()` calls `br init`; verify list uses `br`
- `README.md`: All `bd` command refs → `br`; tool stack links updated
- `AGENTS.md`: All `bd` command refs → `br`; sync semantics updated
- `CLAUDE.md`: All `bd` command refs → `br`; session close protocol updated
- `.beads/hooks/`: 5 hook scripts removed
- `.beads/config.yaml`: Comments updated for `br`
- `.beads/README.md`: Rewritten minimally for `br`
- `.beads/metadata.json`: Updated or removed
- `.beads/.local_version`: Removed

### Definition of Done

- [ ] `./bootstrap.sh --install-only --non-interactive` exits 0 and installs both `br` and `bv`
- [ ] `br init` succeeds in the repo
- [ ] `br list` shows existing issues (if any)
- [ ] `bv` can read `br`-produced `.beads/` data without errors
- [ ] `grep -r '\bbd\b' bootstrap.sh README.md AGENTS.md CLAUDE.md .beads/config.yaml .beads/README.md` returns 0 matches (excluding migration docs)
- [ ] No `.beads/hooks/` directory exists

### Must Have

- `br` binary installed and executable at `.tools/bin/br`
- `bv` binary installed and executable at `.tools/bin/bv`
- `br init` works idempotently
- `bv` reads `br`-produced data
- All first-party docs reference `br` commands
- Sync semantics documented correctly (`br sync --flush-only` + manual git)

### Must NOT Have (Guardrails)

- **Must NOT delete `.beads/issues.jsonl` or `interactions.jsonl`** — these are data, not config
- **Must NOT refactor `ensure_go_binary()` or create generic abstractions** — inline `br` install logic
- **Must NOT rewrite workflow docs beyond `bd`→`br` substitution + sync semantics** — no feature additions
- **Must NOT add `br`-specific features not validated in smoke tests**
- **Must NOT leave hooks silently broken** — remove them explicitly with a tracked commit
- **Must NOT create duplicate AGENTS.md/CLAUDE.md content** — only substitute commands, don't restructure
- **Must NOT change `.trunk/trunk.yaml`** — its `.beads/**` ignore is still correct

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision

- **Infrastructure exists**: NO (shell bootstrap script, no test framework)
- **Automated tests**: None — verification via executable acceptance criteria and QA scenarios
- **Framework**: N/A

### QA Policy

Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **CLI tools**: Use Bash — run commands, assert exit codes + output
- **File changes**: Use Bash (grep/diff) — verify content substitution completeness
- **E2E**: Use Bash — run full bootstrap, verify tool installation and interop

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — validation, BLOCKING):
└── Task 1: Validate br install method + br init behavior [deep]

Wave 2 (After Wave 1 — bootstrap.sh changes, BLOCKING):
└── Task 2: Update bootstrap.sh (install, init, verify) [deep]

Wave 3 (After Wave 2 — parallel docs + config, MAX PARALLEL):
├── Task 3: Update README.md [quick]
├── Task 4: Update AGENTS.md [quick]
├── Task 5: Update CLAUDE.md [quick]
├── Task 6: Clean up .beads/ (hooks, config, metadata) [unspecified-high]
└── Task 7: Update docs/planning/br-bv-migration-handoff.md [quick]

Wave 4 (After Wave 3 — end-to-end verification):
└── Task 8: End-to-end validation [deep]

Wave FINAL (After ALL tasks — independent review, 4 parallel):
├── Task F1: Plan compliance audit [oracle]
├── Task F2: Code quality review [unspecified-high]
├── Task F3: Real manual QA [unspecified-high]
└── Task F4: Scope fidelity check [deep]

Critical Path: Task 1 → Task 2 → Tasks 3-7 (parallel) → Task 8 → F1-F4 (parallel)
Parallel Speedup: ~40% faster than sequential
Max Concurrent: 5 (Wave 3)
```

### Dependency Matrix

| Task  | Depends On    | Blocks        | Wave  |
| ----- | ------------- | ------------- | ----- |
| 1     | —             | 2             | 1     |
| 2     | 1             | 3, 4, 5, 6, 7 | 2     |
| 3     | 2             | 8             | 3     |
| 4     | 2             | 8             | 3     |
| 5     | 2             | 8             | 3     |
| 6     | 2             | 8             | 3     |
| 7     | 2             | 8             | 3     |
| 8     | 3, 4, 5, 6, 7 | F1-F4         | 4     |
| F1-F4 | 8             | —             | FINAL |

### Agent Dispatch Summary

- **Wave 1**: 1 task — T1 → `deep`
- **Wave 2**: 1 task — T2 → `deep`
- **Wave 3**: 5 tasks — T3-T5,T7 → `quick`, T6 → `unspecified-high`
- **Wave 4**: 1 task — T8 → `deep`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [ ] 1. Validate `br` install method and `br init` behavior

  **What to do**:
  - Fetch the `br` install script source from `https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh` and read it to determine:
    - Does it respect a custom install directory (env var like `INSTALL_DIR` or `BIN_DIR`)?
    - Where does it install by default (`~/.local/bin`? `~/.cargo/bin`?)?
    - Does it detect platform (darwin/linux, amd64/arm64) correctly?
  - Test `br` binary behavior in a temporary directory:
    - Create a temp dir, run `br init` in it — confirm it creates `.beads/` with `issues.jsonl`
    - Check what other files `br init` creates (config.yaml? metadata.json? hooks?)
    - Run `br --help` to confirm available subcommands (especially: does `br` have a `hook` subcommand?)
    - Run `br init` in THIS repo's root (which has existing `.beads/` with dolt backend) — confirm it doesn't clobber `issues.jsonl` or `interactions.jsonl`
  - Test `bv` compatibility:
    - After `br init`, run `bv` in the same directory — confirm it reads `br`-produced data
  - Document findings in `.sisyphus/evidence/task-1-validation-findings.md`
  - Based on findings, determine the exact install method for bootstrap.sh:
    - If install script respects custom dir: use `curl | INSTALL_DIR=... bash`
    - If not: use `cargo install beads_rust` (following `ensure_sem_binary()` pattern) or direct tarball download + extract

  **Must NOT do**:
  - Do NOT modify any repo files — this is read-only validation
  - Do NOT install `br` into `.tools/bin/` yet — that's Task 2

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires reading external source code, running multiple test scenarios, synthesizing findings into a decision
  - **Skills**: []
    - No specialized skills needed — standard bash + web fetch
  - **Skills Evaluated but Omitted**:
    - `cargo-rust`: Not needed — we're evaluating install methods, not writing Rust code

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (sole task)
  - **Blocks**: Task 2 (bootstrap.sh changes depend on validated install method)
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References** (existing code to follow):
  - `bootstrap.sh:180-204` — `ensure_sem_binary()` function: model for cargo-based Rust binary install with `find_system_binary` fallback and `ln -sf` linking to `$BIN_DIR`
  - `bootstrap.sh:156-178` — `ensure_go_binary()` function: current `bd`/`bv` install pattern being replaced
  - `bootstrap.sh:206-208` — `ensure_extra_tools()`: where `bd` and `bv` are currently installed

  **External References**:
  - `br` install script: `https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh` — Read this to understand install behavior
  - `br` GitHub releases API: `https://api.github.com/repos/Dicklesworthstone/beads_rust/releases/latest` — Check available binaries per platform
  - `br` migration skill: `https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/skills/bd-to-br-migration/SKILL.md` — Official command mapping
  - `bv` GitHub: `https://github.com/Dicklesworthstone/beads_viewer` — Verify bv install methods

  **WHY Each Reference Matters**:
  - `ensure_sem_binary()` is the EXACT pattern to follow if we use `cargo install` — it handles system binary detection, cargo install with custom root, and symlinking
  - The install script source tells us if we can use it directly or need to do manual tarball extraction
  - The migration SKILL.md confirms exact command equivalences

  **Acceptance Criteria**:
  - [ ] Install script source fetched and analyzed — findings documented
  - [ ] `br init` tested in clean temp dir — `.beads/` layout documented
  - [ ] `br --help` output captured — subcommand list documented
  - [ ] `br init` tested with existing `.beads/` dir — data file preservation confirmed
  - [ ] `bv` tested reading `br`-produced data — compatibility confirmed
  - [ ] Install method decision documented with rationale

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: br init creates expected .beads/ layout in clean directory
    Tool: Bash
    Preconditions: Empty temp directory, br binary available
    Steps:
      1. mkdir -p /tmp/br-test-$ && cd /tmp/br-test-$
      2. br init
      3. ls -la .beads/
      4. cat .beads/issues.jsonl (should exist, possibly empty)
      5. Check for: config.yaml, metadata.json, hooks/, README.md
    Expected Result: .beads/ created with at minimum issues.jsonl; layout documented
    Failure Indicators: br init exits non-zero; .beads/ not created; issues.jsonl missing
    Evidence: .sisyphus/evidence/task-1-clean-init.txt

  Scenario: br init preserves existing data files in repo with .beads/ (dolt backend)
    Tool: Bash
    Preconditions: This repo's root directory with existing .beads/issues.jsonl and interactions.jsonl
    Steps:
      1. cp .beads/issues.jsonl /tmp/issues-backup-$
      2. cp .beads/interactions.jsonl /tmp/interactions-backup-$ (if exists)
      3. br init (in repo root)
      4. diff .beads/issues.jsonl /tmp/issues-backup-$
      5. diff .beads/interactions.jsonl /tmp/interactions-backup-$ (if existed)
    Expected Result: Data files identical before/after init (diff exits 0)
    Failure Indicators: diff shows changes; files deleted; br init errors on dolt backend
    Evidence: .sisyphus/evidence/task-1-existing-repo-init.txt

  Scenario: br has no hook subcommand (confirming hooks should be removed)
    Tool: Bash
    Preconditions: br binary available
    Steps:
      1. br --help 2>&1
      2. br hook --help 2>&1 (expect failure)
      3. br hooks --help 2>&1 (expect failure)
    Expected Result: No `hook` or `hooks` subcommand exists
    Failure Indicators: br has a hook subcommand (would change migration strategy)
    Evidence: .sisyphus/evidence/task-1-br-help.txt

  Scenario: bv reads br-produced data
    Tool: Bash
    Preconditions: br init has been run, bv binary available
    Steps:
      1. Run bv --help 2>&1 to confirm available commands
      2. Run bv in a directory with br-produced .beads/
      3. Check exit code and output for "file not found" errors
    Expected Result: bv exits 0, no file-not-found errors
    Failure Indicators: bv can't find issues.jsonl; bv errors on br's layout
    Evidence: .sisyphus/evidence/task-1-bv-compat.txt
  ```

  **Evidence to Capture:**
  - [ ] task-1-validation-findings.md — Full analysis document
  - [ ] task-1-clean-init.txt — br init output in clean dir
  - [ ] task-1-existing-repo-init.txt — br init output in existing repo
  - [ ] task-1-br-help.txt — br --help output
  - [ ] task-1-bv-compat.txt — bv compatibility test output
  - [ ] task-1-install-script-analysis.txt — Install script source + analysis

  **Commit**: NO (read-only validation, no file changes to commit)

- [ ] 2. Update `bootstrap.sh` — install `br`, update init, update verify

  **What to do**:
  - **Replace `bd` install** (line 207): Remove `ensure_go_binary bd github.com/steveyegge/beads/cmd/bd 0`. Add `br` installation using the method determined in Task 1. Two likely approaches:
    - **Option A (cargo install)**: Create `ensure_br_binary()` modeled on `ensure_sem_binary()` (lines 180-204): check for existing binary via `find_system_binary`, fall back to `cargo install beads_rust --locked`, symlink from `$CARGO_INSTALL_ROOT/bin/br` to `$BIN_DIR/br`
    - **Option B (curl install script)**: If Task 1 confirms the install script respects a custom dir, use: `curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh | INSTALL_DIR="$BIN_DIR" bash`
    - **Option C (direct tarball)**: Download platform-specific tarball from GitHub releases, extract `br` binary to `$BIN_DIR/br`
  - **Keep `bv` install** (line 208): `ensure_go_binary bv github.com/Dicklesworthstone/beads_viewer/cmd/bv` — this stays as-is since bv is a Go binary
  - **Update `init_beads()`** (lines 288-296): Change `"$BIN_DIR/bd" init -q` to `"$BIN_DIR/br" init`. Note: `br init` may not have a `-q` flag — use whatever Task 1 discovered
  - **Update `verify_installs()`** (line 341): Change `bd` to `br` in the tools array
  - **Ensure atomicity**: The install of `br` must complete before `bd` reference is removed from verify list. Since we're editing the same file, this is naturally atomic.

  **Must NOT do**:
  - Do NOT refactor `ensure_go_binary()` into something more generic
  - Do NOT change `bv` install method (it stays as `ensure_go_binary`)
  - Do NOT change any other tool installs in `ensure_extra_tools()`
  - Do NOT touch anything outside `ensure_extra_tools()`, `init_beads()`, and `verify_installs()`

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Shell script surgery on the critical bootstrap pipeline — needs careful reasoning about install paths, error handling, and atomicity
  - **Skills**: []
    - No specialized skills needed — standard bash editing
  - **Skills Evaluated but Omitted**:
    - `cargo-rust`: Not writing Rust, just installing a Rust binary

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sole task, depends on Task 1)
  - **Blocks**: Tasks 3, 4, 5, 6, 7 (all downstream changes depend on bootstrap.sh being correct)
  - **Blocked By**: Task 1 (need validated install method)

  **References**:

  **Pattern References** (existing code to follow):
  - `bootstrap.sh:180-204` — `ensure_sem_binary()`: EXACT pattern to follow for `ensure_br_binary()` if using cargo install. Shows: `find_system_binary` check → `ln -sf` existing → `cargo install --git ... --locked` → `ln -sf` from cargo root to `$BIN_DIR`
  - `bootstrap.sh:156-178` — `ensure_go_binary()`: Current pattern being replaced for `bd` (keep for `bv`)
  - `bootstrap.sh:206-208` — `ensure_extra_tools()`: Lines to modify — replace `bd` install, keep `bv` install
  - `bootstrap.sh:288-296` — `init_beads()`: Change `bd init -q` to `br init`
  - `bootstrap.sh:339-353` — `verify_installs()`: Change `bd` to `br` in tools array (line 341)

  **API/Type References**:
  - Task 1 evidence: `.sisyphus/evidence/task-1-validation-findings.md` — Contains the validated install method to use

  **External References**:
  - `br` install script: `https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh`
  - `br` GitHub releases: `https://api.github.com/repos/Dicklesworthstone/beads_rust/releases/latest`

  **WHY Each Reference Matters**:
  - `ensure_sem_binary()` is the template — copy its structure for `ensure_br_binary()` if cargo is the chosen method
  - Task 1 findings determine which of Options A/B/C to implement — must read before starting
  - The `init_beads()` function just needs the command swap, but check Task 1 for `br init` flags

  **Acceptance Criteria**:
  - [ ] `bash -n bootstrap.sh` exits 0 (syntax valid)
  - [ ] `bd` does not appear anywhere in `bootstrap.sh` (verified by grep)
  - [ ] `br` install function exists and follows repo patterns
  - [ ] `bv` install line unchanged
  - [ ] `init_beads()` calls `br init` (not `bd init`)
  - [ ] `verify_installs()` tools array lists `br` (not `bd`)

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: bootstrap.sh has valid bash syntax after changes
    Tool: Bash
    Preconditions: bootstrap.sh modified with br changes
    Steps:
      1. bash -n bootstrap.sh
    Expected Result: Exit code 0, no output (no syntax errors)
    Failure Indicators: Any syntax error output; non-zero exit code
    Evidence: .sisyphus/evidence/task-2-syntax-check.txt

  Scenario: No bd references remain in bootstrap.sh
    Tool: Bash
    Preconditions: bootstrap.sh modified
    Steps:
      1. grep -n '\bbd\b' bootstrap.sh
    Expected Result: No matches (exit code 1 from grep = no matches)
    Failure Indicators: Any line matching 'bd' as a whole word
    Evidence: .sisyphus/evidence/task-2-bd-grep.txt

  Scenario: br installs successfully via bootstrap.sh
    Tool: Bash
    Preconditions: Clean .tools/bin/ (br removed if present)
    Steps:
      1. rm -f .tools/bin/br
      2. Source the relevant functions from bootstrap.sh or run the install section
      3. test -x .tools/bin/br
      4. .tools/bin/br --version
    Expected Result: br binary exists, is executable, prints version >= 0.1.20
    Failure Indicators: Binary not found; not executable; version command fails
    Evidence: .sisyphus/evidence/task-2-br-install.txt

  Scenario: bv install unchanged and still works
    Tool: Bash
    Preconditions: bootstrap.sh modified
    Steps:
      1. grep 'ensure_go_binary bv' bootstrap.sh
      2. test -x .tools/bin/bv
      3. .tools/bin/bv --version
    Expected Result: bv install line present and unchanged; binary works
    Failure Indicators: bv install line missing or changed; binary broken
    Evidence: .sisyphus/evidence/task-2-bv-unchanged.txt

  Scenario: init_beads() calls br not bd
    Tool: Bash
    Preconditions: bootstrap.sh modified
    Steps:
      1. grep -A5 'init_beads()' bootstrap.sh
      2. Verify the function body contains 'br init' not 'bd init'
    Expected Result: Function calls "$BIN_DIR/br" init
    Failure Indicators: Still references bd; br init command malformed
    Evidence: .sisyphus/evidence/task-2-init-beads.txt
  ```

  **Evidence to Capture:**
  - [ ] task-2-syntax-check.txt
  - [ ] task-2-bd-grep.txt
  - [ ] task-2-br-install.txt
  - [ ] task-2-bv-unchanged.txt
  - [ ] task-2-init-beads.txt

  **Commit**: YES
  - Message: `chore(bootstrap): replace bd with br install + init`
  - Files: `bootstrap.sh`
  - Pre-commit: `bash -n bootstrap.sh && ! grep -q '\bbd\b' bootstrap.sh`

- [ ] 3. Update `README.md` — replace `bd` references with `br`

  **What to do**:
  - Line 8: Change `dependency-aware work planning (`bd`)` → `dependency-aware work planning (`br`)`
  - Lines 61-62: Change `bd ready` and `bd create "<task>"` → `br ready` and `br create "<task>"`
  - Line 74: Change `beads (`bd`):` link text and URL → `beads (`br`):` with link to `https://github.com/Dicklesworthstone/beads_rust`
  - Line 82: Change `Use `bd` dependencies` → `Use `br` dependencies`
  - Line 83: Note about sync semantics if mentioned
  - Verify: the `bv` reference on line 75 stays unchanged
  - Update the beads docs link (line 74) from steveyegge/beads to Dicklesworthstone/beads_rust

  **Must NOT do**:
  - Do NOT rewrite sections beyond `bd`→`br` substitution
  - Do NOT change `bv` references
  - Do NOT add new sections about `br`-specific features

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical text substitution in a single markdown file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 4, 5, 6, 7)
  - **Blocks**: Task 8
  - **Blocked By**: Task 2

  **References**:
  - `README.md:1-100` — Full file; lines 8, 61-62, 74, 82-83 contain `bd` references
  - `https://github.com/Dicklesworthstone/beads_rust` — New repo URL for tool stack section

  **Acceptance Criteria**:
  - [ ] `grep -n '\bbd\b' README.md | grep -v 'br-bv-migration' | wc -l` returns 0
  - [ ] `bv` reference on line 75 is unchanged
  - [ ] beads tool stack link points to Dicklesworthstone/beads_rust

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: No bd references remain in README.md
    Tool: Bash
    Preconditions: README.md edited
    Steps:
      1. grep -cn '\bbd\b' README.md
    Expected Result: 0 matches
    Failure Indicators: Any non-zero count
    Evidence: .sisyphus/evidence/task-3-readme-grep.txt

  Scenario: bv reference preserved
    Tool: Bash
    Preconditions: README.md edited
    Steps:
      1. grep -n 'bv' README.md
    Expected Result: bv references still present (beads_viewer line)
    Failure Indicators: bv references accidentally removed
    Evidence: .sisyphus/evidence/task-3-bv-preserved.txt
  ```

  **Commit**: YES (groups with Tasks 4, 5, 7)
  - Message: `docs: update all references from bd to br`
  - Files: `README.md`

- [ ] 4. Update `AGENTS.md` — replace `bd` references with `br`, update sync semantics

  **What to do**:
  - Lines 41-43: Change `bd` command refs in beads section → `br`
  - Lines 92-101: Update `bd` commands in Core commands section → `br` equivalents:
    - `bd ready` → `br ready`
    - `bd create "..."` → `br create "..."`
    - `bd show <id>` → `br show <id>`
    - `bd update <id> --status in_progress` → `br update <id> --status in_progress`
    - `bd close <id>` → `br close <id>`
    - `bd sync` → `br sync --flush-only` (NOTE: add comment that git add/commit is now manual)
  - Lines 124-127: Update Usage section references
  - Lines 169-174: Update Session Completion Protocol:
    - Change `bd sync` → `br sync --flush-only` then `git add .beads/ && git commit`
    - Change `bd` in status update commands → `br`

  **Must NOT do**:
  - Do NOT restructure the document
  - Do NOT add new sections for `br`-specific features
  - Do NOT deduplicate with CLAUDE.md (out of scope)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical text substitution in a single markdown file with one semantic change (sync semantics)
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 3, 5, 6, 7)
  - **Blocks**: Task 8
  - **Blocked By**: Task 2

  **References**:
  - `AGENTS.md:41-43` — beads section header
  - `AGENTS.md:92-102` — Core commands block
  - `AGENTS.md:124-127` — Usage references
  - `AGENTS.md:169-174` — Session completion protocol
  - `https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/skills/bd-to-br-migration/SKILL.md` — Official command mapping

  **Acceptance Criteria**:
  - [ ] `grep -cn '\bbd\b' AGENTS.md` returns 0
  - [ ] Sync semantics updated to mention `br sync --flush-only` + manual git
  - [ ] All `br` commands are valid per the migration SKILL.md

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: No bd references remain in AGENTS.md
    Tool: Bash
    Preconditions: AGENTS.md edited
    Steps:
      1. grep -cn '\bbd\b' AGENTS.md
    Expected Result: 0 matches
    Failure Indicators: Any non-zero count
    Evidence: .sisyphus/evidence/task-4-agents-grep.txt

  Scenario: Sync semantics correctly updated
    Tool: Bash
    Preconditions: AGENTS.md edited
    Steps:
      1. grep -n 'sync' AGENTS.md
      2. Verify mentions of "flush-only" or manual git commit
    Expected Result: Sync references mention br sync --flush-only and manual git
    Failure Indicators: Still says "bd sync" or lacks manual git note
    Evidence: .sisyphus/evidence/task-4-sync-semantics.txt
  ```

  **Commit**: YES (groups with Tasks 3, 5, 7)
  - Message: `docs: update all references from bd to br`
  - Files: `AGENTS.md`

- [ ] 5. Update `CLAUDE.md` — replace `bd` references with `br`, update session protocol

  **What to do**:
  - Lines 41-43: Change `bd` command refs → `br`
  - Lines 92-101: Update `bd` commands → `br` equivalents (same mapping as Task 4)
  - Lines 155-160: Update Session Close Protocol:
    - Change `bd sync --from-main` → `br sync --flush-only` (NOTE: semantics change — `--from-main` was bd-specific for pulling beads updates; `br` may have different sync flags — use whatever Task 1 discovered)
    - Update git add/commit instructions to include `.beads/` explicitly
  - Update any other `bd` references found by grep

  **Must NOT do**:
  - Do NOT restructure the document
  - Do NOT deduplicate with AGENTS.md
  - Do NOT change non-beads sections

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical text substitution in a single markdown file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 3, 4, 6, 7)
  - **Blocks**: Task 8
  - **Blocked By**: Task 2

  **References**:
  - `CLAUDE.md:41-43` — beads command section
  - `CLAUDE.md:92-101` — Core commands
  - `CLAUDE.md:155-160` — Session close protocol
  - Task 1 evidence: `.sisyphus/evidence/task-1-validation-findings.md` — For `br sync` flag behavior

  **Acceptance Criteria**:
  - [ ] `grep -cn '\bbd\b' CLAUDE.md` returns 0
  - [ ] Session close protocol references `br sync` with correct flags
  - [ ] Git workflow updated to reflect manual .beads/ commit

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: No bd references remain in CLAUDE.md
    Tool: Bash
    Preconditions: CLAUDE.md edited
    Steps:
      1. grep -cn '\bbd\b' CLAUDE.md
    Expected Result: 0 matches
    Failure Indicators: Any non-zero count
    Evidence: .sisyphus/evidence/task-5-claude-grep.txt

  Scenario: Session close protocol updated correctly
    Tool: Bash
    Preconditions: CLAUDE.md edited
    Steps:
      1. grep -A10 'SESSION CLOSE PROTOCOL' CLAUDE.md
      2. Verify br sync command with correct flags
    Expected Result: Protocol references br sync, not bd sync
    Failure Indicators: Still references bd sync; flags incorrect
    Evidence: .sisyphus/evidence/task-5-session-protocol.txt
  ```

  **Commit**: YES (groups with Tasks 3, 4, 7)
  - Message: `docs: update all references from bd to br`
  - Files: `CLAUDE.md`

- [ ] 6. Clean up `.beads/` directory — remove hooks, update config, remove stale files

  **What to do**:
  - **Remove hooks directory**: `rm -rf .beads/hooks/` — all 5 scripts are dead `bd` shims:
    - `.beads/hooks/pre-commit`
    - `.beads/hooks/pre-push`
    - `.beads/hooks/post-merge`
    - `.beads/hooks/post-checkout`
    - `.beads/hooks/prepare-commit-msg`
  - **Update `.beads/config.yaml`**: Replace `bd`-specific comments with `br` equivalents. Keep actual config values that are still relevant. Remove bd-specific settings that `br` doesn't use (if identifiable).
  - **Update `.beads/README.md`**: Minimal rewrite — replace `bd` command references with `br`, update links. Don't create a comprehensive `br` guide — just make it accurate.
  - **Update or remove `.beads/metadata.json`**: Currently says `"backend": "dolt"`. Either update to reflect `br`'s backend or remove if `br init` will regenerate it.
  - **Remove `.beads/.local_version`**: Contains stale `bd` version `0.52.0`. `br` will manage its own version tracking.
  - **Preserve data files**: `issues.jsonl` and `interactions.jsonl` must NOT be touched.

  **Must NOT do**:
  - **Must NOT delete `issues.jsonl` or `interactions.jsonl`** — these are data
  - Must NOT rewrite `.beads/README.md` into a comprehensive `br` guide
  - Must NOT modify `.beads/.gitignore` (it still works)
  - Must NOT touch the `dolt/` subdirectory (it's gitignored and will be cleaned separately if needed)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Multiple file operations with data preservation constraint — needs care
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 3, 4, 5, 7)
  - **Blocks**: Task 8
  - **Blocked By**: Task 2

  **References**:
  - `.beads/hooks/pre-commit` — Example hook shim (all 5 follow same pattern: `exec bd hook <name>`)
  - `.beads/config.yaml:1-52` — Full config file with bd-specific comments
  - `.beads/README.md:1-50` — bd-centric user guide
  - `.beads/metadata.json` — Contains `"backend": "dolt"` (stale)
  - `.beads/.local_version` — Contains `0.52.0` (stale bd version)
  - Task 1 evidence: `.sisyphus/evidence/task-1-validation-findings.md` — For what `br init` generates

  **Acceptance Criteria**:
  - [ ] `.beads/hooks/` directory does not exist
  - [ ] `.beads/.local_version` does not exist
  - [ ] `.beads/config.yaml` contains no `bd` references
  - [ ] `.beads/README.md` contains no `bd` references
  - [ ] `.beads/metadata.json` updated or removed
  - [ ] `.beads/issues.jsonl` exists and is unchanged
  - [ ] `.beads/interactions.jsonl` exists and is unchanged (if it existed before)

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Hooks directory completely removed
    Tool: Bash
    Preconditions: Cleanup performed
    Steps:
      1. ls .beads/hooks/ 2>&1
    Expected Result: "No such file or directory" error
    Failure Indicators: Any files listed; directory still exists
    Evidence: .sisyphus/evidence/task-6-hooks-removed.txt

  Scenario: Data files preserved after cleanup
    Tool: Bash
    Preconditions: Cleanup performed
    Steps:
      1. test -f .beads/issues.jsonl && echo "EXISTS" || echo "MISSING"
      2. wc -l .beads/issues.jsonl
    Expected Result: "EXISTS" and non-empty line count
    Failure Indicators: "MISSING" or zero lines
    Evidence: .sisyphus/evidence/task-6-data-preserved.txt

  Scenario: No bd references in .beads/ config files
    Tool: Bash
    Preconditions: Config files updated
    Steps:
      1. grep -r '\bbd\b' .beads/config.yaml .beads/README.md 2>/dev/null | wc -l
    Expected Result: 0 matches
    Failure Indicators: Any non-zero count
    Evidence: .sisyphus/evidence/task-6-beads-grep.txt
  ```

  **Commit**: YES
  - Message: `chore(beads): remove bd hooks, update config for br`
  - Files: `.beads/hooks/*, .beads/config.yaml, .beads/README.md, .beads/metadata.json, .beads/.local_version`
  - Pre-commit: `! ls .beads/hooks/ 2>/dev/null && test -f .beads/issues.jsonl`

- [ ] 7. Update `docs/planning/br-bv-migration-handoff.md` — mark as completed

  **What to do**:
  - Add a "Migration Status" section at the top marking this as COMPLETED
  - Update any `bd` command references in the doc to `br` for accuracy
  - Add a note about the actual install method chosen (from Task 1 findings)
  - This is a planning artifact, not a living doc — just make it accurate

  **Must NOT do**:
  - Do NOT rewrite the entire document
  - Do NOT delete the document (it's useful as a migration record)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Minor update to a planning document
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 3, 4, 5, 6)
  - **Blocks**: Task 8
  - **Blocked By**: Task 2

  **References**:
  - `docs/planning/br-bv-migration-handoff.md` — The handoff doc created during research phase
  - Task 1 evidence: `.sisyphus/evidence/task-1-validation-findings.md` — Actual install method chosen

  **Acceptance Criteria**:
  - [ ] Document has a "Migration Status: COMPLETED" header
  - [ ] Command references are accurate for `br`

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Handoff doc marked as completed
    Tool: Bash
    Preconditions: Document updated
    Steps:
      1. grep -i 'completed' docs/planning/br-bv-migration-handoff.md
    Expected Result: Contains "COMPLETED" status indicator
    Failure Indicators: No completion status found
    Evidence: .sisyphus/evidence/task-7-handoff-status.txt
  ```

  **Commit**: YES (groups with Tasks 3, 4, 5)
  - Message: `docs: update all references from bd to br`
  - Files: `docs/planning/br-bv-migration-handoff.md`

- [ ] 8. End-to-end validation — full bootstrap + tool interop verification

  **What to do**:
  - Run the FULL bootstrap from a clean-ish state:
    1. `./bootstrap.sh --install-only --non-interactive` — verify it completes
    2. `.tools/bin/br --version` — verify br installed, version >= 0.1.20
    3. `.tools/bin/bv --version` — verify bv installed, version >= 0.14.4
    4. `.tools/bin/br init` — verify idempotent init works
    5. `.tools/bin/br list` — verify can list issues
    6. `.tools/bin/br sync --flush-only` — verify sync exports JSONL
    7. Run `bv` and verify it reads the data
  - Run the final grep sweep:
    - `grep -r '\bbd\b' bootstrap.sh README.md AGENTS.md CLAUDE.md .beads/config.yaml .beads/README.md` — must return 0 matches
  - Verify data preservation:
    - `.beads/issues.jsonl` exists and is non-empty
    - `.beads/interactions.jsonl` exists (if it did before)
  - Verify hooks removed:
    - `ls .beads/hooks/` should fail (directory gone)
  - Save ALL output to `.sisyphus/evidence/task-8-e2e/`

  **Must NOT do**:
  - Do NOT modify any files — this is read-only verification
  - Do NOT skip any verification step

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Comprehensive verification requiring multiple sequential checks with pass/fail judgment
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sole task)
  - **Blocks**: Final Verification Wave (F1-F4)
  - **Blocked By**: Tasks 3, 4, 5, 6, 7

  **References**:
  - All previous task evidence files in `.sisyphus/evidence/`
  - Plan's Success Criteria section (this document)
  - Plan's Definition of Done (this document)

  **Acceptance Criteria**:
  - [ ] `./bootstrap.sh --install-only --non-interactive` exits 0
  - [ ] `br --version` prints version >= 0.1.20
  - [ ] `bv --version` prints version >= 0.14.4
  - [ ] `br init` exits 0
  - [ ] `br list` exits 0
  - [ ] `br sync --flush-only` exits 0
  - [ ] Final grep sweep returns 0 `bd` matches across all first-party files
  - [ ] `.beads/issues.jsonl` exists
  - [ ] `.beads/hooks/` does not exist

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Full bootstrap completes successfully
    Tool: Bash
    Preconditions: All previous tasks completed
    Steps:
      1. ./bootstrap.sh --install-only --non-interactive
      2. echo "EXIT: $?"
    Expected Result: Exit code 0
    Failure Indicators: Non-zero exit code; error output
    Evidence: .sisyphus/evidence/task-8-e2e/bootstrap-run.txt

  Scenario: Both br and bv are installed and functional
    Tool: Bash
    Preconditions: Bootstrap completed
    Steps:
      1. .tools/bin/br --version
      2. .tools/bin/bv --version
      3. .tools/bin/br init
      4. .tools/bin/br list
    Expected Result: All commands exit 0 with expected output
    Failure Indicators: Any command fails; version too old
    Evidence: .sisyphus/evidence/task-8-e2e/tool-check.txt

  Scenario: Zero bd references in first-party files
    Tool: Bash
    Preconditions: All doc updates completed
    Steps:
      1. grep -r '\bbd\b' bootstrap.sh README.md AGENTS.md CLAUDE.md .beads/config.yaml .beads/README.md 2>/dev/null | grep -v 'br-bv-migration'
    Expected Result: No output (no matches)
    Failure Indicators: Any matching lines
    Evidence: .sisyphus/evidence/task-8-e2e/final-grep.txt

  Scenario: Data files intact and hooks removed
    Tool: Bash
    Preconditions: All tasks completed
    Steps:
      1. test -f .beads/issues.jsonl && echo "DATA OK" || echo "DATA MISSING"
      2. ls .beads/hooks/ 2>&1 && echo "HOOKS STILL EXIST" || echo "HOOKS REMOVED"
    Expected Result: "DATA OK" and "HOOKS REMOVED"
    Failure Indicators: "DATA MISSING" or "HOOKS STILL EXIST"
    Evidence: .sisyphus/evidence/task-8-e2e/data-hooks-check.txt
  ```

  **Commit**: NO (verification only, no file changes)

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **Plan Compliance Audit** — `oracle`
      Read the plan end-to-end. For each "Must Have": verify implementation exists (run `br --version`, `bv --version`, `br init`, `br list`). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
      Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
      Run `trunk check --all` on changed files. Review all changed files for: dead code, broken references, inconsistent command names, leftover `bd` references. Check shell scripts with `shellcheck` if available. Verify no data files were accidentally deleted.
      Output: `Trunk [PASS/FAIL] | bd References [0/N] | Data Files [intact/missing] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
      Start from clean state. Run `./bootstrap.sh --install-only --non-interactive`. Verify `br --version`, `bv --version`. Run `br init`, `br list`, `br sync --flush-only`. Run `bv` and verify it reads data. Save all output to `.sisyphus/evidence/final-qa/`.
      Output: `Install [PASS/FAIL] | Init [PASS/FAIL] | List [PASS/FAIL] | Sync [PASS/FAIL] | bv [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
      For each task: read "What to do", read actual diff (`git diff`). Verify 1:1 — everything in spec was done, nothing beyond spec was done. Check "Must NOT do" compliance. Detect cross-task contamination. Flag unaccounted changes.
      Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Commit | Message                                               | Files                                                                                               | Pre-commit check                                                    |
| ------ | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1      | `chore(bootstrap): replace bd with br install + init` | `bootstrap.sh`                                                                                      | `bash -n bootstrap.sh`                                              |
| 2      | `chore(beads): remove bd hooks, update config for br` | `.beads/hooks/*, .beads/config.yaml, .beads/README.md, .beads/metadata.json, .beads/.local_version` | `ls .beads/hooks/ 2>/dev/null` returns empty                        |
| 3      | `docs: update all references from bd to br`           | `README.md, AGENTS.md, CLAUDE.md, docs/planning/br-bv-migration-handoff.md`                         | `grep -r '\bbd\b' README.md AGENTS.md CLAUDE.md \| wc -l` returns 0 |
| 4      | `chore(bootstrap): validate br+bv end-to-end`         | — (verification only, no file changes)                                                              | Full bootstrap + tool check                                         |

---

## Success Criteria

### Verification Commands

```bash
# br installed and working
.tools/bin/br --version          # Expected: version >= 0.1.20
.tools/bin/br init               # Expected: exit 0
.tools/bin/br list               # Expected: exit 0

# bv installed and reads br data
.tools/bin/bv --version          # Expected: version >= 0.14.4

# No bd references in first-party files
grep -r '\bbd\b' bootstrap.sh README.md AGENTS.md CLAUDE.md .beads/config.yaml .beads/README.md 2>/dev/null | grep -v 'br-bv-migration' | wc -l
# Expected: 0

# Hooks removed
ls .beads/hooks/ 2>/dev/null | wc -l
# Expected: 0

# Full bootstrap works
./bootstrap.sh --install-only --non-interactive
# Expected: exit 0
```

### Final Checklist

- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] `.beads/issues.jsonl` and `interactions.jsonl` preserved
- [ ] All first-party docs reference `br` not `bd`
- [ ] bootstrap.sh syntax valid (`bash -n bootstrap.sh`)
- [ ] End-to-end bootstrap succeeds
