# Agent Operating Manual

This file defines how agents should execute work in this repository.

## Primary Model

- A primary controller agent owns planning, sequencing, validation, and final integration.
- The primary agent should delegate to subagents whenever work can be parallelized.
- Subagents should be scoped to one clear responsibility and return concise artifacts/results.

## Work Modes

Mode is ticket-scoped and should be set per issue.

### Strict Mode (default)

Use this unless the human explicitly requests otherwise.

1. Specs first.
2. Human approves spec/design intent.
3. TDD cycle begins: red -> green -> refactor.
4. Re-check implementation against approved spec and intent.
5. Run full verification and keep tests green.

### Yolo Mode (explicit opt-in)

For straightforward work where speed matters more than incremental ceremony.

1. Keep spec -> tests -> red/green/refactor -> verify.
2. Increase parallelization and swarm subagents.
3. Maintain correctness gates; do not skip verification.

## Mandatory Development Flow (Strict)

1. OpenSpec first: define or update spec artifacts before implementation.
2. Human checkpoint: do not start coding until spec intent is approved.
3. TDD first implementation path:
   - Write failing tests first.
   - Implement minimal code to pass.
   - Refactor while keeping suite green.
4. br planning:
   - Create maximally parallelizable workstreams.
   - Track dependencies explicitly so `br ready` surfaces unblocked tasks.
5. Structure-first scaffolding:
   - Start with function names, variable names, and docstrings/signatures.
   - Run explore/research subagents to validate naming and conventions.
6. Code generation after naming passes review.
7. Final validation:
   - semantic review with `sem diff` over plain `git diff`.
   - full tests and quality gates green.
8. Add or update a `mise` task for context-compressed verification runs when useful.

## Naming and Comments

Names must describe domain behavior, not implementation history.

### Naming rules

- Never use implementation details in names (for example: `ZodValidator`, `MCPWrapper`, `JSONParser`).
- Never use temporal names (for example: `NewAPI`, `LegacyHandler`, `UnifiedTool`).
- Avoid design-pattern words unless they add real clarity.

### Preferred style

- `Tool` over `AbstractToolInterface`
- `RemoteTool` over `MCPToolWrapper`
- `Registry` over `ToolRegistryManager`
- `execute()` over `executeToolWithValidation()`

### Comments

- Keep comments intent-focused.
- Prefer comments for non-obvious constraints and tradeoffs.
- Do not add comments that restate obvious code.

## Testing Policy

- Every change should include comprehensive tests for real logic.
- Target near-100% coverage when practical for touched areas.
- No-exceptions default: unit + integration + end-to-end test coverage expectations apply.
- Do not mock the behavior under test.
- End-to-end tests should use real integrations/data paths where feasible.
- Treat test failures and suspicious logs as first-class defects to resolve.

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

- Purpose: semantic diffs (entity-level change review).
- Use instead of raw line diff when reviewing meaningful code changes:
  - `sem diff`
  - `sem diff --staged`
  - `sem diff --from <revA> --to <revB>`

### ast-grep (`sg`)

- Purpose: AST-aware search/rewrites and structural linting.
- Useful commands:
  - `sg run -p '<pattern>' <path>`
  - `sg run -p '<pattern>' -r '<rewrite>' <path>`
  - `sg scan`

### Linear (`linctl`)

- Purpose: optional human-scale planning context and supplemental directives.
- Policy:
  - Beads (`br`) is the primary execution audit log for agent work.
  - Linear can hold higher-level planning, prioritization, or external directives.
  - At task start, check in with the human on whether/how Linear is used for this repo.
  - If Linear is active, reconcile it with `br` by creating/updating `br` items so execution stays auditable.
- Useful commands:
  - `linctl whoami`
  - `linctl issue list`
  - `linctl issue view <id>`
  - `linctl project list`

### Jujutsu (`jj`) quickref for multi-agent workflows

- `jj st` / `jj log` for status/history.
- `jj new` to create a new change context.
- `jj parallelize` to split stacked changes into siblings for parallel work.
- `jj squash` / `jj rebase` to consolidate and reorder work.
- `jj desc` to keep descriptions accurate for handoff.
- `jj git export` / `jj git push` when syncing with git remotes.

### mise

- Purpose: runtime/tool orchestration and repeatable task execution.
- Use for verification and human-readable test output via tasks:
  - `mise run <task>`
  - `mise tasks ls`
- Prefer adding project tasks over ad-hoc long command strings.

### trunk

- Purpose: lint/format checks (including via hooks).
- Expect automatic checks around commit/push flows.
- Fix obvious issues directly; ask the human when repeated findings seem noisy or policy-level.

## Workspace Hygiene

- Use `scratchpad/` for temporary docs, one-off scripts, experiments, and throwaway artifacts.
- If needed for research/examples, add temporary git submodules only under `scratchpad/`.
- Web research is allowed via available MCP tools; capture useful findings in `scratchpad/` before implementation.
- Use `docs/` for durable human documentation after implementation/testing.
- Base docs on OpenSpec artifacts plus real code behavior.

## Session Completion Protocol

Before handoff/end of session:

1. Create `br` issues for remaining follow-up work.
2. Run tests/lint/verification for changed code.
3. Update issue states in `br`.
4. Sync and push:
   - `git pull --rebase`
   - `br sync --flush-only`
   - `git add .beads/ && git commit -m "beads sync"`
   - `git push`
   - `git status` must be up to date with origin.
5. Provide concise handoff notes with risks and next steps.

Work is not complete until push succeeds.
