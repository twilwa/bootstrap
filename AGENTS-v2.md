# Agent Operating Manual v2

This file defines the required operating model for agents in this repository.

## Core Defaults

- **Default mode is Strict Mode** for every ticket.
- **Yolo Mode is opt-in only** and must be explicitly requested by the human per ticket.
- **Execution order is mandatory**: Plan -> Parallelize -> Fan-out -> TDD -> Verify.
- **GitButler is the default branch orchestration model**; do not use `jj` workflows in this repository.

## Primary Model

- A primary controller agent owns planning, sequencing, validation, and final integration.
- Subagents handle narrow, well-scoped tasks and return concise, verifiable outputs.
- The primary agent is accountable for final quality gates and for rejecting incomplete subagent work.

## Work Modes

Mode is ticket-scoped and set once per issue.

### Strict Mode (default)

Use this unless the human explicitly requests Yolo Mode.

1. OpenSpec first.
2. Human approves spec/design intent.
3. Plan and parallelize workstreams.
4. Fan-out implementation to smaller/cheaper subagents where possible.
5. Run TDD red -> green -> refactor for each workstream.
6. Run compressed verification + full gates before handoff.

### Yolo Mode (explicit opt-in)

Use only when the human explicitly asks for Yolo Mode for that ticket.

1. Keep the same correctness gates as Strict Mode.
2. Increase parallelization and fan-out aggressively.
3. Keep TDD and verification intact.
4. Trade ceremony for speed, not quality.

## Mandatory Development Flow (Strict)

1. **Spec and intent gate**
   - Define or update OpenSpec artifacts before implementation.
   - Do not start implementation until intent is approved.

2. **Planning gate**
   - Produce a concrete execution plan with clear deliverables.
   - Break work into maximally parallelizable streams.
   - Track dependencies in `br` so `br ready` exposes unblocked work.

3. **Fan-out gate**
   - Delegate narrow implementation tasks to smaller models/subagents.
   - Keep each subagent prompt atomic and testable.
   - Do not let subagents own final integration decisions.

4. **TDD gate**
   - Red: write failing tests first.
   - Green: implement minimal code to pass.
   - Refactor: improve design while suite stays green.

5. **Verification gate**
   - Run semantic review (`sem diff`) and test/lint/type/build checks.
   - Use `mise` tasks for context-compressed verification where useful.
   - Keep all quality gates green before handoff.

## Always Do

- Start from explicit plan and dependency-aware parallelization.
- Default to fan-out to smaller subagents for bounded implementation tasks.
- Follow TDD cycle for all behavior changes.
- Keep verification reproducible via `mise` tasks where practical.
- Use `br` as the execution audit trail.
- Validate subagent outputs with direct checks before integration.

## Assume Yes Unless Specified

- Assume Strict Mode unless the human explicitly requests Yolo Mode.
- Assume test updates are required when code behavior changes.
- Assume parallelization is desired when tasks are independent.
- Assume compressed verification should be added/updated when missing.
- Assume GitButler-first branch orchestration for concurrent variants.

## Use Judgment

- Adjust fan-out depth based on task size, coupling, and risk.
- Keep implementation slices small enough for independent validation.
- Prefer simple, maintainable changes over broad refactors.
- Escalate to deeper analysis only when direct resolution fails.
- Use Yolo speedups only inside explicit Yolo tickets.

## Ask First

Ask the human before:

- changing core product behavior beyond approved spec intent
- making destructive or irreversible repository operations
- changing security, compliance, or data retention posture
- skipping or weakening any required quality gate
- introducing backward compatibility layers not requested by spec

## Never Do

- Never bypass tests, lint, typecheck, or build gates.
- Never use `--no-verify` to force commits.
- Never treat Yolo Mode as implicit.
- Never replace failing tests by deleting coverage.
- Never ship unverified subagent output.
- Never use `jj` workspace/parallelize/squash/rebase flows in this repo.

## GitButler-First Multi-Variant Workflow

GitButler is the default model for parallel feature variants in one working tree.

1. Start from base branch (`main`) in the normal repo checkout.
2. Create virtual branches for each variant in GitButler.
3. Assign hunks/files to the correct virtual branch during editing/staging.
4. Commit each variant branch independently.
5. Compare branches in GitButler UI (and regular git diff once commits exist).

Notes:

- GitButler uses one working directory with virtual branches.
- It does not replace git worktrees, but can coexist with them when needed.
- Prefer GitButler virtual branches over `jj` workspace-based orchestration.

## Testing Policy

- Every change should include comprehensive tests for real logic.
- Target near-100% coverage for touched code when practical.
- Unit + integration + end-to-end expectations apply by default.
- Do not mock behavior under test.
- Use real integration paths for end-to-end tests where feasible.
- Treat suspicious logs and flaky behavior as defects to resolve.

## Tooling Quick Reference

### OpenSpec

- Purpose: spec-first planning and change control.
- Typical flow: `/opsx:new` -> `/opsx:ff` or `/opsx:continue` -> `/opsx:apply` -> `/opsx:archive`.

### beads (`br`) and beads viewer (`bv`)

- Purpose: dependency-aware issue graph and execution planning.
- Core commands:
  - `br ready`
  - `br create "..."`
  - `br show <id>`
  - `br update <id> --status in_progress`
  - `br close <id>`
  - `br sync --flush-only` (then `git add .beads/ && git commit` manually)
- `bv` is the visualization/TUI companion for work graph review.

### sem

- Purpose: semantic diffs for entity-level review.
- Use instead of raw line diffs when reviewing behavior-changing edits.

### ast-grep (`sg`)

- Purpose: AST-aware search, rewrites, and structural linting.

### mise

- Purpose: runtime/tool orchestration and repeatable task execution.
- Prefer project tasks for compressed verification flows.

### trunk

- Purpose: lint/format checks and policy enforcement.
- Fix obvious issues directly; escalate policy noise to human review.

## Session Completion Protocol

Before handoff/end of session:

1. Create `br` issues for remaining follow-up work.
2. Run tests/lint/type/build verification for changed code.
3. Update issue states in `br`.
4. Sync and push:
   - `git pull --rebase`
   - `br sync --flush-only`
   - `git add .beads/ && git commit -m "beads sync"`
   - `git push`
   - `git status` must be up to date with origin.
5. Provide concise handoff notes with risks and next steps.

Work is not complete until push succeeds.
