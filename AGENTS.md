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
- for javascript projects, use typescript and bun. for go projects, go should be managed by mise. for python projects, we use uv, and mypy for stronger typing, we like types. all of this should be managed via mise en place.

## Conditional reminders

These blocks add task-specific emphasis. They do not replace the foundational
rules above.

<important if="you are starting a task, planning work, or updating specs">
- Strict Mode is the default.
- OpenSpec comes before implementation unless the human explicitly says `Full Yolo`.
- Turn approved work into `br` tasks with explicit dependency edges before coding.
- The primary controller owns sequencing, validation, and final integration.
</important>

<important if="you are writing or modifying code">
- Start from clear names, boundaries, and docstrings that match repo conventions.
- Use TDD red -> green -> refactor for each behavior slice.
- Prefer multiple narrow subagents over one broad worker when ownership can stay separate.
- Keep changes minimal, reversible, and within the approved scope.
</important>

<important if="you are writing or modifying tests">
- Test real behavior, not mocked versions of the behavior under test.
- Unit, integration, and end-to-end coverage are the default expectation for touched behavior.
- Treat suspicious logs, flaky results, or noisy output as defects to resolve.
- If you think a test layer should be skipped, stop and get explicit human approval.
</important>

<important if="you are reviewing changes, verifying work, or preparing handoff">
- Prefer `sem diff` for code review.
- Run compressed verification during iteration and full verification before handoff.
- Report exactly what ran, what passed, and what remains unverified.
- Create follow-up `br` tasks before ending the session if anything remains.
</important>

<important if="you are touching version control, branch orchestration, or commit preparation">
- Use GitButler (`but`) instead of `git` or `jj` workflows in this repo.
- Do not bypass hooks or verification.
- Expect routine state churn under hidden tool directories such as `.beads/`, `.entire/`, `.trunk/`, `.mise/`, and `.tools/`; treat it as operational noise unless it is destructive, leaves the repo boundary, or conflicts with the current task.
- Escalate before destructive history edits or branch surgery.
</important>

## Primary Model

- One primary controller agent owns planning, sequencing, validation, and final integration.
- Subagents are expected whenever work can be parallelized safely.
- use multiple subagents whenever writing code, the code should always be structured in a maximally parallel dependency graph.
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
   - Delegate bounded tasks to smaller models/subagents always.
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
- Run `entire enable`, `openspec init`, `br init` when starting a new project unless they are already enabled.
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
- Never use `jj` or `git` workflows in this repository, use only the `but` cli or ask the human to use GitButler for branch management.
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
- Prefer GitButler over `jj` for concurrent variants in this repository. The `but` CLI is your version control entrypoint; the human also has a UI available.
- In this repo, the trunk branch is always `gitbutler/workspace`, virtual branches will commonly be named t-branch-N. Agents should work on gitbutler/workspace, the virtual branches will be largely managed by the human unless instructed to cherrypick or perform another git op.

### mcphub.nvim (Neovim MCP Client)

- Use for integrating MCP servers into Neovim editing workflows.
- Plugin: [ravitemer/mcphub.nvim](https://github.com/ravitemer/mcphub.nvim) — native Lua MCP client and proxy/aggregator.
- Runs a local hub process (`mcp-hub`) that manages server lifecycle, multiplexing all configured MCP servers behind a single SSE/HTTP endpoint (`localhost:37373/mcp`).
- Supports STDIO, SSE, and Streamable-HTTP transports.

#### Installation (lazy.nvim)

```lua
{
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = "npm install -g mcp-hub@latest",
    config = function()
        require("mcphub").setup({
            port = 37373,
            config = vim.fn.expand("~/.config/mcphub/servers.json"),
        })
    end,
}
```

#### Server Registration

Three methods for registering MCP servers, checked in this order:

1. **Global config**: `~/.config/mcphub/servers.json` — standard MCP JSON format, shared across projects.
2. **Project-local config**: `.mcphub/servers.json`, `.vscode/mcp.json`, or `.cursor/mcp.json` — scoped to the repo.
3. **Native Lua servers**: Define MCP servers directly in Lua within the `setup()` call — no external process needed.

#### Native Lua Servers

Native Lua servers run inside the Neovim process and have direct access to the Neovim API. Use these for editor-aware tooling (buffer inspection, LSP queries, terminal management).

```lua
require("mcphub").setup({
    native_servers = {
        my_server = {
            name = "my_server",
            capabilities = {
                tools = {
                    {
                        name = "get_buffer_count",
                        description = "Get number of open buffers",
                        handler = function(req, res)
                            local count = #vim.api.nvim_list_bufs()
                            return res:text("Open buffers: " .. count):send()
                        end,
                    },
                },
            },
        },
    },
})
```

Two native servers ship built-in:
- **Neovim Server**: File operations, terminal control, LSP integration.
- **MCPHub Server**: Plugin and server management from within the editor.

#### Commands and API

- `:MCPHub` — Opens the management UI (view servers, toggle, inspect tools/resources).
- `require("mcphub").get_hub_instance()` — Programmatic access to the hub.
- `.add_tool(server, tool_spec)` — Register tools at runtime.
- `.on(event, callback)` — Subscribe to hub lifecycle events.

#### Agent Integration

- Agents running inside Neovim (via chat plugins or inline completion) can call MCP tools through mcphub without spawning separate server processes.
- For agent workflows that need both Neovim context and external MCP servers, mcphub acts as the single aggregation point — configure external servers in `servers.json` and editor-aware servers as native Lua servers.

## Testing and Verification

- Unit + integration + end-to-end coverage is the default expectation for touched behavior.
- Do not mock the behavior under test.
- Use real integration paths whenever practical.
- Treat flaky tests, suspicious logs, and unexplained failures as defects to resolve.

### Minimum compressed verification

During iteration, the compressed check should include the smallest meaningful subset of:

- targeted tests for touched behavior
- `sem diff` review
- lint/type/build task(s) for the touched surface
- creating a mise task for additional human verification or to compress multiple suite outputs with sense-making names for the verification.

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

## Typical Workflow Orchestration order

- human may provide additional steering or prompting, this should be reflected as an openspec changeset
- once proprosal is approved and tasks.md are generated for ALL changesets in the wave, codify tasks into br workstreams, maximally paralell, with correct dependencies for blocking tasks.
- as the primary model, create failing tests, function and variable names, and docstrings for each file to be created in the workstreams. make sure this matches conventions with the codebase for naming and code style, such as using an apimanager wrapper for ease of use in api versioning, hoisting enums or using or creating classes for reusable patterns. match convention with the codebase and follow code best practices a la Peter Norvig.
- next, deploy parallel subagents with smaller models (typically 2-5, at least 1 per workstream) to work through the TDD workflow for each available bead (red > green > refactor if needed until full greens)
- compressed verification by the main model (create a mise task to verify test output against spec, use sem diff to investigate discrepancies)
- goto 1 by creating a series of changesets for the next stage, may wish to consult with the human
- version control will be handled by gitbutler, you can use the `but` cli ( `but branch new`, for as many versions as are appropriate. be sure to name them appropriately so it's easy to tell what the parallel agent is working on.) to create virtual branches for subagents if there's a tricky ticket that is worth comparing the results of multiple subagents on.
