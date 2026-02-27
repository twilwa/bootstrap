# Task 1 Validation Findings

## br Install Script Analysis

- Respects custom dir: YES
- Custom dir env var: `BR_INSTALL_DIR` (also supports `DEST`/`--dest`)
- Default install location: `~/.local/bin`
- Platform detection: YES (detected `darwin/linux/windows` + `amd64/arm64/armv7`)
- Other installer env vars observed: `VERSION`, `OWNER`, `REPO`, `CHECKSUM`, `CHECKSUM_URL`, `ARTIFACT_URL`, `HTTP_PROXY`, `HTTPS_PROXY`, `RUSTUP_INIT_SKIP`, `DEBUG`, `CI`, `CODEX_HOME`

## GitHub Release Assets (latest = v0.1.20)

- `br-v0.1.20-darwin_amd64.tar.gz`
- `br-v0.1.20-darwin_arm64.tar.gz`
- `br-v0.1.20-linux_amd64.tar.gz`
- `br-v0.1.20-linux_arm64.tar.gz`
- `br-v0.1.20-windows_amd64.zip`
- plus checksums and SBOM artifacts

## br --help Summary

- Version: `br 0.1.20`
- Has hook/hooks subcommand: NO (`hook` and `hooks` are unrecognized subcommands)

## br sync flags

From `br sync --help`:

- Modes: `--flush-only`, `--import-only`, `--merge`, `--status`
- Safety/behavior: `--force`, `--allow-external-jsonl`, `--manifest`, `--error-policy`, `--orphans`, `--rename-prefix`, `--rebuild`, `--robot`
- Global passthrough flags: `--db`, `--actor`, `--json`, `--no-daemon`, `--no-auto-flush`, `--no-auto-import`, `--allow-stale`, `--lock-timeout`, `--no-db`, `-v/-q`
- Has `--flush-only`: YES
- Has `--from-main` equivalent: NO

## br init (clean directory) - .beads/ layout

Observed files after `br init` in a clean temp dir:

- `.beads/.gitignore`
- `.beads/beads.db`
- `.beads/beads.db-wal`
- `.beads/config.yaml`
- `.beads/issues.jsonl`
- `.beads/metadata.json`

Checks:

- issues.jsonl created: YES (empty file)
- config.yaml created: YES (comment-style config template)
- metadata.json created: YES
- metadata.json backend field: NO explicit `backend` field (contains `database` + `jsonl_export`)
- hooks/ created: NO in clean init

## br init (existing repo with dolt backend)

- Exit code: `2`
- Output: `ALREADY_INITIALIZED` at `./.beads/beads.db`, hint says `Use --force to reinitialize`
- Data files preserved: YES for existing `interactions.jsonl` (byte-for-byte unchanged)
- `issues.jsonl` behavior in this repo state: absent before and remained absent on this non-force re-init attempt

## bv Compatibility

- bv available: YES at `/Users/anon/Projects/bootstrap/.tools/bin/bv`
- Reads br-produced data: PARTIAL YES
  - `br create` succeeded in a clean br workspace and auto-flushed JSONL
  - `bv` launched but exited with `/dev/tty` error in non-interactive context (expected for TUI without TTY)
  - No format/parsing incompatibility observed in this validation run

## INSTALL METHOD DECISION for bootstrap.sh

**Chosen approach**: C (direct tarball)

**Rationale**:

- Avoids installer-script side effects (`PATH` edits, alias edits, optional skills install, optional gum install).
- Keeps installation deterministic and pinned to a known release tag/asset.
- Avoids cargo compile-time cost in bootstrap path while still being cross-platform.
- Matches existing bootstrap style of repo-local managed binaries and explicit linking.

**Exact install code to use in bootstrap.sh**:

```bash
ensure_br_binary() {
    if [[ -x "$BIN_DIR/br" ]]; then
        return
    fi

    local existing
    existing="$(find_system_binary br)"
    if [[ -n "$existing" && -x "$existing" ]]; then
        log "Linking existing br from $existing"
        ln -sf "$existing" "$BIN_DIR/br"
        return
    fi

    local version="v0.1.20"
    local os arch asset url tmpdir

    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        *) die "Unsupported OS for br: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) die "Unsupported architecture for br: $(uname -m)" ;;
    esac

    asset="br-${version}-${os}_${arch}.tar.gz"
    url="https://github.com/Dicklesworthstone/beads_rust/releases/download/${version}/${asset}"

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN

    log "Installing br from release ${version} (${os}_${arch})"
    curl -fsSL "$url" -o "$tmpdir/$asset"
    tar -xzf "$tmpdir/$asset" -C "$tmpdir"

    [[ -x "$tmpdir/br" ]] || die "br binary missing in release artifact"
    install -m 0755 "$tmpdir/br" "$BIN_DIR/br"
}
```

## br init flags

- Flags to use in bootstrap.sh `init_beads()`: `br init`
- For already-initialized repos: do not force-reinit by default
- Optional explicit prefix on first init only: `br init --prefix <repo-name>`

## br sync flags for docs

- Exact command for AGENTS.md/CLAUDE.md: `br sync --flush-only`
- Manual git note: there is no `--from-main` equivalent in `br sync`; keep any git pull/rebase step as a separate git command.
