# br-bv-migration Decisions

## [2026-02-26] Architecture Decisions

### Install Method for br

- **Status**: RESOLVED — Option C (direct tarball)
- Options: (A) cargo install, (B) curl install script if respects custom dir, (C) direct tarball
- Decision criterion: Does install script respect custom INSTALL_DIR?
- If YES → Option B (curl | INSTALL_DIR="$BIN_DIR" bash)
- If NO → Option A following ensure_sem_binary() pattern

### bv Install

- **Decision**: UNCHANGED — stays as `ensure_go_binary bv github.com/Dicklesworthstone/beads_viewer/cmd/bv`
- Rationale: bv is a Go binary, reads JSONL, fully compatible with br output

### Hook Removal

- **Decision**: Remove .beads/hooks/ entirely (rm -rf)
- Rationale: br has no hook system; all 5 scripts exec dead `bd hook` commands

### .beads/metadata.json

- **Decision**: Update or remove (Task 1 will reveal what br init generates)
- If br init regenerates it: delete the old one, let br init create it
- If br init does NOT create it: update "backend" field from "dolt" to "sqlite"

### Sync Semantics in Docs

- **Decision**: Replace all `bd sync` with `br sync --flush-only` + note that git commit is now manual
- AGENTS.md and CLAUDE.md session close protocol must be updated accordingly

### Scope Guardrails

- No refactoring ensure_go_binary() or creating abstractions
- No restructuring AGENTS.md/CLAUDE.md beyond command substitution
- No touching .trunk/trunk.yaml (its .beads/\*\* ignore still correct)
- No deduplifying AGENTS.md/CLAUDE.md (out of scope)

## [2026-02-26] Final Verification Decisions

### Verdict: APPROVE (all 4 audits)

F1 Plan Compliance: APPROVE
F2 Code Quality: APPROVE
F3 Manual QA: APPROVE
F4 Scope Fidelity: APPROVE (with 3 low-impact scope notes)

### Scope Deviations Accepted

CLAUDE.md TOC + jj restructuring: accepted as non-breaking additive changes
issues.jsonl creation in commit 4: accepted as necessary bv compatibility fix
These do not warrant rejection or rework
