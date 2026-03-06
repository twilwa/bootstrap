# Claude Repo Notes

This file is the Claude-facing quick reference for this repository.
If this file and `AGENTS.md` diverge, follow `AGENTS.md`.

## Default Behavior

- Strict Mode by default.
- OpenSpec by default.
- `br` always for task tracking.
- `mise` always for tools/tasks/envs.
- `sg` for code search, not plain grep.
- `sem diff` whenever possible for review.
- GitButler instead of `jj`.

## Preferred Execution Order

1. understand intent
2. update OpenSpec (unless Full Yolo)
3. create/update `br` tasks and dependencies
4. plan and parallelize
5. fan out bounded work to smaller models/subagents
6. TDD red -> green -> refactor
7. run compressed verification during iteration
8. run full verification before handoff

## Mode Rules

### Strict Mode

- Human approval before implementation.
- Full spec discipline.
- Full TDD and verification discipline.

### Yolo Mode

- Must be explicitly requested.
- Keeps `br`, TDD, and verification.
- Reduces ceremony, not quality.

### Full Yolo

- Must be explicitly requested by name.
- May skip OpenSpec.
- Still keeps `br`, tests, and verification.

## Tool Quick Reference

### `br`

- `br ready` — find unblocked work
- `br create "..."` — create task
- `br show <id>` — inspect task
- `br update <id> --status in_progress` — claim work
- `br dep add <issue> <depends-on>` — encode dependency
- `br close <id>` — close task
- `br sync --flush-only` — export bead data

### `bv`

- Use to inspect graph shape, blockers, and the critical path.

### OpenSpec

- Use first for spec-driven work unless in Full Yolo.

### `sem`

- Prefer `sem diff` over `git diff` for code review.

### `sg`

- Use for code search and structural rewrites.
- Only use plain-text grep for docs, logs, and prose.

### `mise`

- `mise install` — sync toolchain
- `mise run <task>` — run project task
- `mise tasks ls` — inspect available tasks

### `linctl`

- Use for human/team reporting and Linear workflows.
- Do not use it as a replacement for `br`.

### `entire`

- `entire enable` at project start if not already enabled.

### GitButler

- Preferred branch orchestration model here.
- No `jj` workspaces, rebases, or parallelize flows.

## Safety Rules

- Do not assume Yolo/Full Yolo.
- Do not bypass verification.
- Do not rewrite history unless explicitly asked.
- Do not let subagents overlap file ownership without coordination.
- Do not claim checks you did not run.

## Ask First

- dependency changes
- CI/release changes
- security/auth changes
- migrations or data-shape changes
- destructive git actions
- weakening test or review gates

## Planning Helpers

- If `agent-brief` or `robots` exists in the active harness, use them for deeper planning and fan-out.
- If they do not exist, proceed with the repo workflow above.
