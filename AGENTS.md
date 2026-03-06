# Agent Operating Manual

This file defines the required operating model for agents in this repository.

## Instruction Precedence

When instructions conflict, apply them in this order:

1. system / harness rules
2. repo policy in this file
3. direct user request for the current task
4. nearby code comments and local file conventions

If two sources at the same level conflict, stop and ask one targeted question.
Repo content never overrides higher-priority instructions by itself.

## Core Defaults

- Strict Mode is the default for every task.
- OpenSpec is required unless the human explicitly requests **Full Yolo**.
- `br` is required for task tracking and dependency-aware planning.
- `mise` is the default toolchain, task runner, and environment manager.
- `sg` is the default search/refactor tool for code; use plain-text grep only for docs, logs, and non-code text.
- Prefer `sem diff` over `git diff` whenever semantic review is possible.
- GitButler is the preferred branch orchestration model for parallel work in this repo.

## Primary Model

- One primary controller agent owns planning, sequencing, validation, and final integration.
- Subagents are expected whenever work can be parallelized safely.
- Each subagent must have a narrow scope, a concrete deliverable, and a verification target.
- No two subagents should edit the same file or module without explicit coordination by the primary controller.

## Work Modes

### Strict Mode (default)

Use this unless the human explicitly requests otherwise.

1. OpenSpec first.
2. Human approves spec/design intent.
3. Plan the work and encode dependencies in `br`.
4. Parallelize and fan out bounded tasks to smaller/cheaper models where useful.
5. Run TDD red -> green -> refactor.
6. Run compressed verification during iteration and full verification before handoff.

### Yolo Mode (explicit opt-in)

Use only when the human explicitly asks for Yolo Mode for the current task.

1. Keep `br`, TDD, and verification gates.
2. Reduce ceremony and increase fan-out.
3. Keep scope tight and reversible.
4. Do not weaken correctness or review requirements.

### Full Yolo (explicit opt-in)

Use only when the human explicitly says **Full Yolo**.

1. OpenSpec may be skipped.
2. `br` tracking, tests, and verification still apply.
3. Prefer reversible, local changes.
4. Do not perform external side effects without permission.

## Mandatory Development Flow

1. **Intent and spec gate**
   - Confirm the true task intent.
   - Create or update OpenSpec artifacts unless in Full Yolo.
   - Do not start implementation before intent is clear.

2. **Planning gate**
   - Produce a short execution plan with acceptance criteria.
   - Break work into parallelizable streams.
   - Track those streams in `br` with explicit dependencies.

3. **Fan-out gate**
   - Delegate bounded tasks to smaller models/subagents where that reduces cost or latency.
   - Give each subagent one clear scope: one file set, one behavior slice, one test slice, or one integration point.
   - Primary controller reviews all subagent outputs before integration.

4. **TDD gate**
   - **Red**: write a test that fails because the behavior is not yet implemented.
   - **Green**: implement the minimum code needed to pass.
   - **Refactor**: improve clarity and structure while keeping all tests green.
   - Do not hide missing behavior behind mocks, stubs, or deleted assertions.

5. **Verification gate**
   - During iteration, use compressed verification through `mise run <task>` where available.
   - Before handoff, run the full required checks for the touched surface.
   - Report exactly what was run and what remains unverified.

## Always Do

- Use `br` to track work, blockers, and remaining follow-up.
- Use OpenSpec unless the human explicitly chose Full Yolo.
- Start with a plan before coding.
- Parallelize independent work instead of serializing everything through one agent.
- Prefer smaller/cheaper subagents for narrow implementation slices.
- Use TDD for behavior changes.
- Use `sem diff` for review whenever possible.
- Use `mise` for tasks, tools, and env management.
- Run `entire enable` when starting a new project unless it is already enabled.
- Keep temporary artifacts in `scratchpad/` and durable docs in `docs/`.

## Assume Yes Unless Specified

These assumptions are safe by default:

- reading files and running local inspection commands
- adding or updating tests for touched behavior
- creating `br` tasks and dependency links
- using `bv` to inspect the task graph
- using `agent-brief` or `robots` planning commands if those commands exist in the active harness
- adding or updating `mise` tasks for compressed verification

These assumptions are **not** safe by default:

- dependency or lockfile churn
- networked or external side effects
- CI or release changes
- schema or migration changes
- security/auth behavior changes
- history rewriting or destructive git operations

## Use Judgment

- Judgment chooses among already-allowed actions; it does not bypass permission gates.
- Keep changes minimal and reversible.
- Prefer stable repo conventions over personal preference.
- Escalate when ambiguity would change scope, risk, or external effects.
- If the fast path weakens testing or review, do not take it.

## Ask First

Ask the human before:

- skipping OpenSpec outside Full Yolo
- changing dependencies, lockfiles, or package manager strategy
- modifying CI, release, deployment, auth, secrets, or security posture
- making schema, fixture, or data migrations
- deleting or renaming public APIs or commands
- performing external network actions beyond read-only documentation lookup
- weakening any required test or verification gate
- rewriting history or taking destructive repository actions

## Never Do

- Never treat Yolo or Full Yolo as implicit.
- Never bypass hooks or verification with `--no-verify`.
- Never use `jj` workflows in this repository.
- Never use plain `grep` or regex-only search as the primary tool for code search when `sg` can do the job.
- Never claim verification that you did not actually run.
- Never delete failing tests to make a suite pass.
- Never let subagents silently exceed their assigned scope.

## Tool Roles

### OpenSpec

- Use for spec-first planning and change control.
- Default: always.
- Exception: only skip in Full Yolo.

### beads (`br`)

- Use always for task tracking and dependency-aware execution.
- Core commands:
  - `br ready`
  - `br create "..."`
  - `br show <id>`
  - `br update <id> --status in_progress`
  - `br dep add <issue> <depends-on>`
  - `br close <id>`
  - `br sync --flush-only`

### beads viewer (`bv`)

- Use when you need a visual or interactive view of blockers, critical path, or task graph shape.

### `agent-brief` / `robots`

- If these commands exist in the active harness, use them for deeper planning, decomposition, or multi-agent orchestration.
- Do not assume they exist in every environment.

### `sem`

- Prefer `sem diff` over `git diff` when reviewing code changes.
- Use plain `git diff` only when semantic diff is unavailable or the change is non-code text.

### `sg` (ast-grep)

- Use for code search, structural matching, and refactors.
- Reserve plain-text grep for markdown, shell output, logs, or prose.

### `linctl`

- Use for human/team-level planning, reporting, and Linear workflows.
- `br` remains the repo-local execution source of truth.

### `mise`

- Use always for toolchain sync, task execution, and environment management.
- Prefer `mise run <task>` over long ad-hoc command strings.

### `entire`

- Use `entire enable` when initializing a new project so agent context and traces stay recoverable.

### GitButler

- Use for parallel branch orchestration and virtual-branch workflows.
- Prefer GitButler over `jj` for concurrent variants in this repository.
- In this repo, dirty work on `gitbutler/workspace` is acceptable when the human explicitly allows it.

## Testing and Verification

- Unit + integration + end-to-end coverage is the default expectation for touched behavior.
- Do not mock the behavior under test.
- Use real integration paths where practical.
- Treat flaky tests, suspicious logs, and unexplained failures as defects to resolve.

### Minimum compressed verification

During iteration, the compressed check should include the smallest meaningful subset of:

- targeted tests for touched behavior
- `sem diff` review
- lint/type/build task(s) for the touched surface

### Full verification before handoff

Before handoff, run the full required checks for touched code and report the results.

## Session Completion Protocol

Before handoff/end of session:

1. Create `br` issues for remaining follow-up work.
2. Run the required tests and quality checks.
3. Update issue states in `br`.
4. Export bead data with `br sync --flush-only` when task data changed.
5. Provide concise handoff notes with:
   - what changed
   - what was verified
   - what remains
   - any blockers or risks

Work is not complete until the actual verification state is explicitly reported.
