# Task 4: Update AGENTS.md — Evidence

## Changes Made

- Planning section: `bd` → `br` references
- Beads commands section: All `bd` subcommands → `br` equivalents
- Linear policy section: `bd` → `br`
- Session completion protocol: Updated sync semantics
  - `bd sync` → `br sync --flush-only` + `git add .beads/ && git commit`

## Commit

- Part of commit `30a3eea` (`docs: update all references from bd to br`)

## Verification

- `grep -n '\bbd\b' AGENTS.md` returns zero matches
- Sync workflow correctly reflects br's flush-only + manual git commit pattern
