# Bootstrap Team Guide

This repository is a reusable template for human + agent software delivery.

## What Humans Should Expect

- Agents default to **Strict Mode**.
- Agents use **OpenSpec** for planning unless you explicitly request **Full Yolo**.
- Agents use **`br`** for task tracking and dependency-aware execution.
- Agents plan first, then parallelize, then fan out bounded tasks to smaller models when that helps.
- Agents follow **TDD** and should report what they actually verified.
- Agents should prefer **`sem diff`** over raw `git diff` for code review.
- Agents should use **GitButler** rather than `jj` in this repo.

## Quick Start

```bash
./bootstrap.sh
mise tasks ls
```

If Entire is not already enabled for the repo, enable it at project start:

```bash
entire enable --project
```

## Tool Shortlist

### Always / default tools

- **OpenSpec** — spec-driven planning and change control. Use by default unless you explicitly request **Full Yolo**.
- **`br`** — task tracking and dependency graph. Use always.
- **`mise`** — toolchain, tasks, and environment manager. Use always.
- **`sg` (ast-grep)** — code search and structural rewrites. Prefer this over grep for code.
- **`sem diff`** — semantic review of code changes. Prefer this over raw `git diff` whenever possible.
- **GitButler** — parallel branch orchestration for this repo.

### Use when appropriate

- **`bv`** — visual/TUI view of the `br` task graph, blockers, and critical path.
- **`linctl`** — higher-level human/team tracking and Linear workflows.
- **`agent-brief` / `robots`** — deeper planning and multi-agent orchestration commands, if your active harness exposes them.
- **`entire`** — agent-session traces and context recovery.

## Daily Commands

```bash
# Toolchain + task list
mise install
mise tasks ls

# Work tracking
br ready
br create "Add feature X"
br show <id>
br update <id> --status in_progress
br dep add <issue> <depends-on>
br close <id>
br sync --flush-only

# Review and quality
sem diff
trunk check --all
trunk fmt
```

## Expected Workflow

1. Update or create OpenSpec artifacts unless the task is explicitly **Full Yolo**.
2. Create/update `br` tasks and dependencies.
3. Plan the work before coding.
4. Parallelize and fan out independent work.
5. Write failing tests first.
6. Implement the minimum code to pass.
7. Refactor while keeping tests green.
8. Review with `sem diff` and run the required checks.

## Notes

- This repo prefers **GitButler** over `jj`.
- `br` is the repo-local execution log; `linctl` is for team/human reporting.
- Bootstrap installs repo tools, but language/runtime choices should be managed through `mise` rather than ad-hoc installers.
- Use `scratchpad/` for temporary artifacts and `docs/` for durable documentation.
