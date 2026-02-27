#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
BIN_DIR="$TOOLS_DIR/bin"
MISE_DIR="$ROOT_DIR/.mise"
MISE_BIN="$BIN_DIR/mise"
TS_DIR="$TOOLS_DIR/typescript"
CARGO_DIR="$TOOLS_DIR/cargo"

INSTALL_PHASE=1
INIT_PHASE=1
NON_INTERACTIVE=0
OPENSPEC_TOOLS="${OPENSPEC_TOOLS:-}"
ENTIRE_AGENT="${ENTIRE_AGENT:-claude-code}"
ENTIRE_STRATEGY="${ENTIRE_STRATEGY:-manual-commit}"

log() {
	printf '[bootstrap] %s\n' "$*"
}

warn() {
	printf '[bootstrap] WARN: %s\n' "$*" >&2
}

die() {
	printf '[bootstrap] ERROR: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<USAGE
Usage: ./bootstrap.sh [options]

Options:
  --install-only               Install/update tools only (skip repo init)
  --init-only                  Run repo init only (skip installs)
  --non-interactive            Never prompt for user input
  --openspec-tools=<list>      OpenSpec tools list (e.g. codex,claude)
  --entire-agent=<name>        Entire agent name (default: claude-code)
  -h, --help                   Show this help
USAGE
}

parse_args() {
	while (($#)); do
		case "$1" in
		--install-only)
			INSTALL_PHASE=1
			INIT_PHASE=0
			;;
		--init-only)
			INSTALL_PHASE=0
			INIT_PHASE=1
			;;
		--non-interactive)
			NON_INTERACTIVE=1
			;;
		--openspec-tools=*)
			OPENSPEC_TOOLS="${1#*=}"
			;;
		--entire-agent=*)
			ENTIRE_AGENT="${1#*=}"
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			die "Unknown argument: $1"
			;;
		esac
		shift
	done
}

setup_dirs() {
	mkdir -p "$BIN_DIR" "$MISE_DIR" "$MISE_DIR/cache" "$MISE_DIR/state"
	mkdir -p "$TS_DIR" "$TOOLS_DIR/uv/python" "$CARGO_DIR/bin"
}

setup_env() {
	export PATH="$BIN_DIR:$PATH"

	export MISE_DATA_DIR="$MISE_DIR/data"
	export MISE_CACHE_DIR="$MISE_DIR/cache"
	export MISE_CONFIG_DIR="$MISE_DIR"
	export MISE_STATE_DIR="$MISE_DIR/state"
	export MISE_TRUSTED_CONFIG_PATHS="$ROOT_DIR${MISE_TRUSTED_CONFIG_PATHS:+:$MISE_TRUSTED_CONFIG_PATHS}"

	export UV_PYTHON_INSTALL_DIR="$TOOLS_DIR/uv/python"
	export CARGO_INSTALL_ROOT="$CARGO_DIR"
}

mise_cmd() {
	"$MISE_BIN" "$@"
}

find_system_binary() {
	local name="$1"
	local p="${PATH//$BIN_DIR/}"
	p="${p//::/:}"
	p="${p#:}"
	p="${p%:}"
	PATH="$p" command -v "$name" 2>/dev/null || true
}

ensure_local_mise() {
	if [[ -x "$MISE_BIN" ]]; then
		return
	fi

	if command -v mise >/dev/null 2>&1; then
		log "Copying existing mise binary into repo-local bin"
		cp "$(command -v mise)" "$MISE_BIN"
		chmod +x "$MISE_BIN"
		return
	fi

	log "Installing mise into repo-local bin"
	if command -v curl >/dev/null 2>&1; then
		MISE_INSTALL_PATH="$MISE_BIN" MISE_INSTALL_HELP=0 sh -c "$(curl -fsSL https://mise.run)"
	elif command -v wget >/dev/null 2>&1; then
		MISE_INSTALL_PATH="$MISE_BIN" MISE_INSTALL_HELP=0 sh -c "$(wget -qO- https://mise.run)"
	else
		die "Neither curl nor wget is available to install mise"
	fi
}

link_mise_binary() {
	local tool="$1"
	local resolved

	resolved="$(mise_cmd which "$tool" 2>/dev/null || true)"
	if [[ -n "$resolved" && -x "$resolved" ]]; then
		ln -sf "$resolved" "$BIN_DIR/$tool"
	fi
}

ensure_mise_tools() {
	[[ -f "$ROOT_DIR/mise.toml" ]] || die "mise.toml not found in $ROOT_DIR"

	mise_cmd trust -y "$ROOT_DIR/mise.toml" >/dev/null 2>&1 || true
	log "Installing tools from mise.toml"
	mise_cmd install -y

	for tool in mise go bun uv jj trunk openspec ast-grep sg; do
		link_mise_binary "$tool"
	done
}

ensure_go_binary() {
	local name="$1"
	local module="$2"
	local cgo_mode="${3:-1}"

	if [[ -x "$BIN_DIR/$name" ]]; then
		return
	fi

	local existing
	existing="$(find_system_binary "$name")"
	if [[ -n "$existing" && -x "$existing" ]]; then
		log "Linking existing $name from $existing"
		ln -sf "$existing" "$BIN_DIR/$name"
		return
	fi

	log "Installing $name from $module"
	if [[ "$cgo_mode" == "0" ]]; then
		mise_cmd exec -- env -u GOROOT GOBIN="$BIN_DIR" CGO_ENABLED=0 go install "$module@latest"
	else
		mise_cmd exec -- env -u GOROOT GOBIN="$BIN_DIR" go install "$module@latest"
	fi

	[[ -x "$BIN_DIR/$name" ]] || die "Expected $name in $BIN_DIR after install"
}

ensure_sem_binary() {
	if [[ -x "$BIN_DIR/sem" ]]; then
		return
	fi

	local existing
	existing="$(find_system_binary sem)"
	if [[ -n "$existing" && -x "$existing" ]]; then
		log "Linking existing sem from $existing"
		ln -sf "$existing" "$BIN_DIR/sem"
		return
	fi

	log "Installing sem from source (Ataraxy-Labs/sem)"
	if ! command -v cargo >/dev/null 2>&1; then
		die "cargo is not available; rust toolchain install failed"
	fi

	mise_cmd exec -- env CARGO_INSTALL_ROOT="$CARGO_INSTALL_ROOT" \
		cargo install --git https://github.com/Ataraxy-Labs/sem --locked sem-cli --force

	if [[ -x "$CARGO_INSTALL_ROOT/bin/sem" ]]; then
		ln -sf "$CARGO_INSTALL_ROOT/bin/sem" "$BIN_DIR/sem"
	fi
}

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

ensure_extra_tools() {
	ensure_br_binary
	ensure_go_binary bv github.com/Dicklesworthstone/beads_viewer/cmd/bv
	ensure_go_binary entire github.com/entireio/cli/cmd/entire
	ensure_go_binary linctl github.com/dorkitude/linctl
	ensure_sem_binary

	if [[ -z "$(command -v sg || true)" ]]; then
		die "sg (ast-grep) was not installed by mise"
	fi
	link_mise_binary sg
	link_mise_binary ast-grep

	if [[ ! -f "$TS_DIR/package.json" ]]; then
		cat >"$TS_DIR/package.json" <<'JSON'
{
  "name": "bootstrap-typescript",
  "private": true
}
JSON
	fi

	if [[ ! -x "$TS_DIR/node_modules/.bin/tsc" ]]; then
		log "Installing TypeScript toolchain with bun"
		mise_cmd exec -- bun add --cwd "$TS_DIR" typescript@latest tsx@latest @types/node@latest
	fi
	if [[ -x "$TS_DIR/node_modules/.bin/tsc" ]]; then
		ln -sf "$TS_DIR/node_modules/.bin/tsc" "$BIN_DIR/tsc"
	fi
	if [[ -x "$TS_DIR/node_modules/.bin/tsx" ]]; then
		ln -sf "$TS_DIR/node_modules/.bin/tsx" "$BIN_DIR/tsx"
	fi

	if [[ -x "$BIN_DIR/python" ]]; then
		log "Python already installed, skipping"
	else
		local latest_py
		latest_py="$(mise_cmd exec -- env UV_PYTHON_INSTALL_DIR="$UV_PYTHON_INSTALL_DIR" uv python list | awk '/^cpython-[0-9]+\.[0-9]+\.[0-9]+-/ {sub(/^cpython-/, "", $1); split($1, parts, "-"); print parts[1]; exit}')"
		if [[ -z "$latest_py" ]]; then
			latest_py="3"
		fi

		log "Installing CPython $latest_py with uv"
		mise_cmd exec -- env UV_PYTHON_INSTALL_DIR="$UV_PYTHON_INSTALL_DIR" uv python install "$latest_py"

		local py
		py="$(mise_cmd exec -- env UV_PYTHON_INSTALL_DIR="$UV_PYTHON_INSTALL_DIR" uv python find "$latest_py" 2>/dev/null || true)"
		if [[ -n "$py" && -x "$py" ]]; then
			ln -sf "$py" "$BIN_DIR/python"
			ln -sf "$py" "$BIN_DIR/python3"
		fi
	fi
}

resolve_openspec_tools() {
	if [[ -n "$OPENSPEC_TOOLS" ]]; then
		echo "$OPENSPEC_TOOLS"
		return
	fi

	if [[ "$NON_INTERACTIVE" -eq 1 || ! -t 0 ]]; then
		echo "codex"
		return
	fi

	local input
	read -r -p "OpenSpec tools to configure [codex]: " input
	echo "${input:-codex}"
}

init_openspec() {
	if [[ -f "$ROOT_DIR/openspec/config.yaml" ]]; then
		log "OpenSpec already initialized"
		return
	fi

	local tools
	tools="$(resolve_openspec_tools)"
	log "Initializing OpenSpec with tools: $tools"
	mise_cmd exec -- openspec init --tools "$tools" --force "$ROOT_DIR"
}

init_beads() {
	if [[ -f "$ROOT_DIR/.beads/config.yaml" ]]; then
		log "beads already initialized"
		return
	fi

	log "Initializing beads"
	"$BIN_DIR/br" init
}

init_entire() {
	if [[ -f "$ROOT_DIR/.entire/settings.json" ]]; then
		log "Entire already initialized"
		return
	fi

	log "Initializing Entire (agent: $ENTIRE_AGENT, strategy: $ENTIRE_STRATEGY)"
	if ! "$BIN_DIR/entire" enable --agent "$ENTIRE_AGENT" --strategy "$ENTIRE_STRATEGY" --project --force; then
		warn "entire enable with --agent failed; retrying without --agent"
		"$BIN_DIR/entire" enable --strategy "$ENTIRE_STRATEGY" --project --force
	fi
}

init_jj() {
	if [[ -d "$ROOT_DIR/.jj" ]]; then
		log "Jujutsu already initialized"
		return
	fi

	log "Initializing Jujutsu colocated repo"
	mise_cmd exec -- jj git init --colocate "$ROOT_DIR"
}

init_trunk() {
	if [[ -f "$ROOT_DIR/.trunk/trunk.yaml" ]]; then
		log "Trunk already initialized"
		return
	fi

	log "Initializing Trunk"
	mise_cmd exec -- trunk init -y
}

post_init_notes() {
	if [[ -x "$BIN_DIR/linctl" ]]; then
		if ! "$BIN_DIR/linctl" whoami >/dev/null 2>&1; then
			warn "linctl is installed but not authenticated yet. Run: linctl auth"
		fi
	fi
}

verify_installs() {
	local missing=0
	local tools=(mise go bun uv openspec br bv entire jj trunk linctl sem sg ast-grep)

	for tool in "${tools[@]}"; do
		if [[ ! -x "$BIN_DIR/$tool" ]]; then
			warn "$tool is not linked in $BIN_DIR"
			missing=1
		fi
	done

	if [[ "$missing" -eq 1 ]]; then
		warn "Some tools are not local to this repo; fallback to global PATH may still work"
	fi
}

main() {
	parse_args "$@"
	cd "$ROOT_DIR"

	setup_dirs
	setup_env
	ensure_local_mise

	# Always refresh mise-managed tools so init commands can rely on local binaries.
	ensure_mise_tools

	if [[ "$INSTALL_PHASE" -eq 1 ]]; then
		ensure_extra_tools
	fi

	if [[ "$INIT_PHASE" -eq 1 ]]; then
		init_openspec
		init_beads
		init_entire
		init_jj
		init_trunk
		post_init_notes
	fi

	verify_installs
	log "Bootstrap complete"
	log "Local binaries: $BIN_DIR"
}

main "$@"
