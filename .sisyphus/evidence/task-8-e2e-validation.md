# Task 8: End-to-End Validation — Evidence

## Tool Execution Tests

### br binary

- **Install**: `ensure_br_binary` from bootstrap.sh → installed to `.tools/bin/br` (5.8MB, darwin_arm64)
- **Version**: `br --version` → `br 0.1.20` ✅
- **List**: `br list` → runs clean, no output (no beads yet, expected) ✅
- **Init**: `br init` → `ALREADY_INITIALIZED` error (correct — already initialized) ✅

### bv binary

- **Exists**: `.tools/bin/bv` (49.9MB, pre-existing)
- **Version**: `bv --version` → `bv v0.14.3` ✅

## Grep Sweep

- `grep -rn '\bbd\b' README.md AGENTS.md CLAUDE.md bootstrap.sh .beads/config.yaml .beads/README.md .beads/metadata.json` → **zero matches** ✅

## Data File Preservation

- `.beads/interactions.jsonl` — exists, 0 bytes ✅
- `.beads/beads.db` — exists, 192512 bytes ✅

## Hooks Removal

- `.beads/hooks/` — "No such file or directory" ✅

## Git History

```
30a3eea docs: update all references from bd to br
27c0e9e chore(beads): remove bd hooks, update config for br
a0d2c64 chore(bootstrap): replace bd with br install + init
```

All 3 commits in correct order ✅

## Result: ALL CHECKS PASS
