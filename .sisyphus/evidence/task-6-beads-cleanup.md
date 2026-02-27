# Task 6: Clean up .beads/ directory — Evidence

## Changes Made

### Removed

- `.beads/hooks/` directory — 5 hook scripts deleted:
  - `pre-commit`, `pre-push`, `post-merge`, `post-checkout`, `prepare-commit-msg`
  - All were `bd` shims that `exec bd hook ...`
- `.beads/.local_version` — contained `0.52.0`, was NOT git-tracked

### Updated

- `.beads/config.yaml` — all `bd` refs → `br`, `Dolt` → `SQLite`
- `.beads/README.md` — fully rewritten for `br` with Dicklesworthstone links, sync workflow section
- `.beads/metadata.json` — `"backend":"dolt"` → `"backend":"sqlite"`, added `"tool":"br"`

### Preserved (guardrail)

- `.beads/interactions.jsonl` — empty, 0 bytes
- `.beads/beads.db` — SQLite DB created by `br init`
- `.beads/beads.db-wal` — SQLite WAL file

## Commit

- `27c0e9e` (`chore(beads): remove bd hooks, update config for br`)

## Verification

- `ls .beads/hooks/` → "No such file or directory"
- `grep -n '\bbd\b' .beads/config.yaml .beads/README.md .beads/metadata.json` → zero matches
- `ls .beads/interactions.jsonl .beads/beads.db` → both exist
