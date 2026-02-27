# Bootstrap Team Guide

This repository is a reusable template for human+agent software delivery.

It is designed around:

- spec-first delivery (`OpenSpec`)
- dependency-aware work planning (`br`)
- strong testing discipline (TDD + broad test coverage)
- repo-local tooling (`.mise` + `.tools/bin`)

## What To Expect From Agents

- A primary controller agent should coordinate execution and delegate parallel work to subagents.
- Default mode is **strict** per ticket: spec -> approval -> tests first -> implementation -> verify.
- **yolo** mode is ticket-scoped and opt-in for straightforward work where speed is prioritized.
- Agents should keep temporary artifacts in `scratchpad/` and durable docs in `docs/`.

Detailed agent policy lives in `AGENTS.md`.

## Quick Start (Human)

```bash
./bootstrap.sh
```

Then validate local tools:

```bash
.tools/bin/mise tasks ls
.tools/bin/sem --version
.tools/bin/sg --version
```

Repo-local binaries are linked in:

- `.tools/bin`

Tool/runtime payload is stored in:

- `.mise/`
- `.tools/`

## Daily Commands

```bash
# Full bootstrap (install + init)
mise run bootstrap

# Installs/updates only
mise run install

# Init only (idempotent)
mise run init

# Quality
trunk check --all
trunk fmt

# Work tracking
br ready
br create "<task>"

# Semantic review
sem diff
sem diff --staged
```

## Workflow

1. Create or update spec artifacts in `openspec/` first.
2. Approve intent before coding.
3. Write failing tests first (TDD red/green/refactor).
4. Use `br` dependencies to parallelize safely.
5. Validate with test suite + `sem diff` before merge/push.

## Tool Stack (Researched Docs)

The following links come from official docs/repos for this stack.

- OpenSpec: [openspec.dev](https://openspec.dev/) | [GitHub](https://github.com/Fission-AI/OpenSpec)
- beads (`br`): [GitHub](https://github.com/Dicklesworthstone/beads_rust)
- beads viewer (`bv`): [GitHub](https://github.com/Dicklesworthstone/beads_viewer)
- mise: [Docs](https://mise.jdx.dev/) | [CLI reference](https://mise.jdx.dev/cli/)
- Entire CLI: [Docs](https://docs.entire.io/quickstart) | [GitHub](https://github.com/entireio/cli)
- Trunk CLI: [Docs](https://docs.trunk.io/references/cli) | [Config docs](https://docs.trunk.io/check/configuration)
- Jujutsu (`jj`): [Docs](https://docs.jj-vcs.dev/latest/) | [CLI reference](https://docs.jj-vcs.dev/latest/cli-reference/)
- linctl: [GitHub](https://github.com/dorkitude/linctl)
- sem (semantic diff): [Docs](https://ataraxy-labs.github.io/sem/) | [GitHub](https://github.com/Ataraxy-Labs/sem)
- ast-grep (`sg`): [Docs](https://ast-grep.github.io/) | [CLI reference](https://ast-grep.github.io/reference/cli.html)
- Bun: [Docs](https://bun.sh/docs) | [Reference](https://bun.com/reference)
- uv: [Docs](https://docs.astral.sh/uv/) | [Reference](https://docs.astral.sh/uv/reference/)
- Go: [Docs](https://go.dev/doc/) | [Language spec](https://go.dev/ref/spec)

## Notes

- `trunk` is configured to ignore shell scripts and tool-generated directories in this repo.
- `linctl` installation is automated; auth remains user-specific (`linctl auth`).
- `sem` is installed from source in bootstrap (first run can be slower due Rust compilation).
