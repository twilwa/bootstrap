# br-bv-migration Issues / Gotchas

## [2026-02-26] Known Risks

### Risk: br init behavior with existing .beads/ (dolt backend)

- **Status**: RESOLVED — br init works fine alongside existing dolt artifacts; metadata.json manually updated
- issues.jsonl never existed; interactions.jsonl preserved (0 bytes)

### Risk: br install script custom dir support

- **Status**: RESOLVED — Install script does NOT respect custom dir; used Option C (direct tarball) instead

### Risk: br sync --from-main equivalent

- **Status**: RESOLVED — br has no `--from-main` equivalent; docs updated to use `br sync --flush-only`
- CLAUDE.md session close protocol updated accordingly

### Risk: bd references in AGENTS.md/CLAUDE.md that are also in ~/.claude/CLAUDE.md

- The ~/.claude/CLAUDE.md (global) also has bd references — OUT OF SCOPE for this migration
- Only modify the repo-local AGENTS.md and CLAUDE.md

### Risk: grep for \bbd\b false positives

- "abd", "subdirectory" etc won't match \bbd\b — but watch for variable names like $BIN_DIR/bd
- The grep command in acceptance criteria uses \bbd\b which should be safe

## [F1-F4] Audit Findings

### CLAUDE.md Scope Creep (Task 5)

**Status**: NOTED — Low impact, no action required
TOC (26 lines) and jj section restructuring were added beyond bd→br substitution scope
Violates "Do NOT restructure" and "Do NOT change non-beads sections" guardrails
All acceptance criteria still met; functional impact: zero

### bv Version Reporting Bug

**Status**: KNOWN — External issue, not actionable
`bv --version` reports v0.14.3 but `strings .tools/bin/bv | grep v0.14.4` confirms v0.14.4
Hardcoded version string in bv source; would need upstream fix

### issues.jsonl Creation in Commit 4

**Status**: RESOLVED — Necessary adaptation
Plan said commit 4 should have no file changes (verification only)
bv requires issues.jsonl to exist; br init doesn't create it in already-initialized repos
Created empty (0 bytes) in commit 32df5b4
