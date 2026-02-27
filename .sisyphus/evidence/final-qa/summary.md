# F3 Manual QA Summary

## Results

- Install: PASS (br 0.1.20 at .tools/bin/br [5.8MB], bv v0.14.3-reported/v0.14.4-actual at .tools/bin/bv [50MB])
- Init: PASS (ALREADY_INITIALIZED exit 2 — correct idempotent behavior for existing repo)
- List: PASS (exit 0, empty list — no issues created yet)
- Sync: PASS (exit 0, "Nothing to export (no dirty issues)" — correct for empty repo)
- bv: PASS (binary exists, v0.14.4 confirmed via `strings .tools/bin/bv | grep v0.14.4`)
- Data Files: PASS (issues.jsonl 0 bytes, interactions.jsonl 0 bytes, hooks directory removed)
- Grep Sweep: PASS (0 `bd` references found in bootstrap.sh, README.md, AGENTS.md, CLAUDE.md, .beads/config.yaml, .beads/README.md, .beads/metadata.json)

## Evidence Files

- `tool-versions.txt` — binary existence, sizes, version strings
- `br-init.txt` — ALREADY_INITIALIZED JSON response, exit 2
- `br-list.txt` — empty list, exit 0
- `br-sync.txt` — flush-only "Nothing to export", exit 0
- `data-files.txt` — JSONL files exist, hooks removed
- `grep-sweep.txt` — no stale `bd` references (grep exit 1 = no matches)

## Notes

- bv --version reports v0.14.3 due to hardcoded string bug; `strings` confirms v0.14.4 source
- br init exit code 2 is documented ALREADY_INITIALIZED behavior, not an error
- All JSONL files are 0 bytes (created empty as pre-flight fix) — valid for bv consumption

## VERDICT: APPROVE

Install PASS | Init PASS | List PASS | Sync PASS | bv PASS | Data PASS | Grep PASS | VERDICT: APPROVE
