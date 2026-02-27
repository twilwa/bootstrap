# Agent Operating Manual

<!--toc:start-->

- [Agent Operating Manual](#agent-operating-manual)
  - [Primary Model](#primary-model)
  - [Work Modes](#work-modes)
    - [Strict Mode (default)](#strict-mode-default)
    - [Yolo Mode (explicit opt-in)](#yolo-mode-explicit-opt-in)
  - [Mandatory Development Flow (Strict)](#mandatory-development-flow-strict)
  - [Naming and Comments](#naming-and-comments)
    - [Naming rules](#naming-rules)
    - [Preferred style](#preferred-style)
    - [Comments](#comments)
  - [Testing Policy](#testing-policy)
  - [Tooling Quick Reference](#tooling-quick-reference)
    - [OpenSpec](#openspec)
    - [beads (`br`) and beads viewer (`bv`)](#beads-br-and-beads-viewer-bv)
    - [sem](#sem)
    - [ast-grep (`sg`)](#ast-grep-sg)
    - [When deploying subagents that modify the codebase](#when-deploying-subagents-that-modify-the-codebase)
    - [When subagents have completed their work (primary/orchestrator)](#when-subagents-have-completed-their-work-primaryorchestrator)
    - [mise](#mise)
    - [trunk](#trunk)
  - [Workspace Hygiene](#workspace-hygiene)
  - [Session Completion Protocol](#session-completion-protocol)
  <!--toc:end-->

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

### When deploying subagents that modify the codebase

    •	 jj workspace add <dir>  to create an isolated working copy per subagent.
    •	 jj st  /  jj log  to inspect workspace status and history before editing.
    •	 jj new  to create a dedicated change context on the assigned base revision.
    •	`jj desc  to keep change descriptions clear and up to date for later review.
    •	Avoid  jj parallelize  /  jj squash  /  jj rebase  unless explicitly instructed.
    •	Avoid direct  git  commands; syncing is handled by the primary/orchestrator agent.

### When subagents have completed their work (primary/orchestrator)

    •	 jj st  /  jj log  to review subagent workspaces, diffs, and test status.
    •	 jj parallelize <revset>  to fan out stacked exploratory changes into sibling branches when a solution needs restructuring or comparison.
    •	 jj squash  to consolidate selected revisions into a single linear feature change.
    •	 jj rebase  to move finalized changes onto  trunk()  /  main  or other target bases.
    •	 jj desc  to normalize commit messages and annotate which subagent produced which change.
    •	 jj git export  /  jj git push  to sync the curated, final history to Git remotes.

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
