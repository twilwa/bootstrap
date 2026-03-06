#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
BIN_DIR="$TOOLS_DIR/bin"
MISE_DIR="$ROOT_DIR/.mise"
MISE_BIN="$BIN_DIR/mise"
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
	mkdir -p "$CARGO_DIR/bin"
}

setup_env() {
	export PATH="$BIN_DIR:$PATH"

	export MISE_DATA_DIR="$MISE_DIR/data"
	export MISE_CACHE_DIR="$MISE_DIR/cache"
	export MISE_CONFIG_DIR="$MISE_DIR"
	export MISE_STATE_DIR="$MISE_DIR/state"
	export MISE_TRUSTED_CONFIG_PATHS="$ROOT_DIR${MISE_TRUSTED_CONFIG_PATHS:+:$MISE_TRUSTED_CONFIG_PATHS}"

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

	for tool in mise bun trunk openspec ast-grep sg; do
		link_mise_binary "$tool"
	done
}

ensure_gitbutler_binary() {
	if [[ -x "$BIN_DIR/gitbutler" ]]; then
		return
	fi

	local existing
	existing="$(find_system_binary gitbutler)"
	if [[ -n "$existing" && -x "$existing" ]]; then
		log "Linking existing gitbutler from $existing"
		ln -sf "$existing" "$BIN_DIR/gitbutler"
		return
	fi

	case "$(uname -s)" in
	Darwin)
		for candidate in \
			"/Applications/GitButler.app/Contents/MacOS/gitbutler" \
			"$HOME/Applications/GitButler.app/Contents/MacOS/gitbutler"; do
			if [[ -x "$candidate" ]]; then
				log "Linking existing gitbutler app from $candidate"
				ln -sf "$candidate" "$BIN_DIR/gitbutler"
				return
			fi
		done

		if command -v mdfind >/dev/null 2>&1; then
			local app_path
			app_path="$(mdfind 'kMDItemCFBundleIdentifier == "com.gitbutler.app"' | head -n 1)"
			if [[ -n "$app_path" && -x "$app_path/Contents/MacOS/gitbutler" ]]; then
				log "Linking existing gitbutler app from $app_path"
				ln -sf "$app_path/Contents/MacOS/gitbutler" "$BIN_DIR/gitbutler"
				return
			fi
		fi

		if command -v brew >/dev/null 2>&1; then
			log "Installing GitButler with Homebrew"
			brew list --cask gitbutler >/dev/null 2>&1 || brew install --cask gitbutler
			for candidate in \
				"/Applications/GitButler.app/Contents/MacOS/gitbutler" \
				"$HOME/Applications/GitButler.app/Contents/MacOS/gitbutler"; do
				if [[ -x "$candidate" ]]; then
					ln -sf "$candidate" "$BIN_DIR/gitbutler"
					return
				fi
			done
		fi
		warn "GitButler was not found after Homebrew install; install it manually if needed"
		;;
	*)
		warn "Automatic GitButler install is not configured for $(uname -s); install it manually if needed"
		;;
	esac
}

download_github_release_binary() {
	local name="$1"
	local repo="$2"
	local version="$3"
	local asset="$4"
	local extracted_binary="${5:-$1}"

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

	local tmpdir url
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN
	url="https://github.com/${repo}/releases/download/${version}/${asset}"

	log "Installing $name from ${repo} ${version}"
	curl -fsSL "$url" -o "$tmpdir/$asset"
	tar -xzf "$tmpdir/$asset" -C "$tmpdir"

	[[ -x "$tmpdir/$extracted_binary" ]] || die "Expected $extracted_binary in $asset"
	install -m 0755 "$tmpdir/$extracted_binary" "$BIN_DIR/$name"
}

ensure_bv_binary() {
	local version="v0.14.4"
	local os arch asset

	case "$(uname -s)" in
	Darwin) os="darwin" ;;
	Linux) os="linux" ;;
	*) die "Unsupported OS for bv: $(uname -s)" ;;
	esac

	case "$(uname -m)" in
	x86_64 | amd64) arch="amd64" ;;
	arm64 | aarch64) arch="arm64" ;;
	*) die "Unsupported architecture for bv: $(uname -m)" ;;
	esac

	asset="bv_${version#v}_${os}_${arch}.tar.gz"
	download_github_release_binary bv Dicklesworthstone/beads_viewer "$version" "$asset" bv
}

ensure_entire_binary() {
	local version="v0.4.9"
	local os arch asset

	case "$(uname -s)" in
	Darwin) os="darwin" ;;
	Linux) os="linux" ;;
	*) die "Unsupported OS for entire: $(uname -s)" ;;
	esac

	case "$(uname -m)" in
	x86_64 | amd64) arch="amd64" ;;
	arm64 | aarch64) arch="arm64" ;;
	*) die "Unsupported architecture for entire: $(uname -m)" ;;
	esac

	asset="entire_${os}_${arch}.tar.gz"
	download_github_release_binary entire entireio/cli "$version" "$asset" entire
}

ensure_linctl_binary() {
	if [[ -x "$BIN_DIR/linctl" ]]; then
		return
	fi

	local existing
	existing="$(find_system_binary linctl)"
	if [[ -n "$existing" && -x "$existing" ]]; then
		log "Linking existing linctl from $existing"
		ln -sf "$existing" "$BIN_DIR/linctl"
		return
	fi

	log "Installing linctl with a mise-managed Go toolchain"
	mise_cmd exec -- env -u GOROOT GOBIN="$BIN_DIR" go install github.com/dorkitude/linctl@latest

	if [[ ! -x "$BIN_DIR/linctl" ]]; then
		warn "linctl install did not produce a local binary; install it separately if your workflow needs Linear integration"
	fi
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
	x86_64 | amd64) arch="amd64" ;;
	arm64 | aarch64) arch="arm64" ;;
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
	ensure_gitbutler_binary
	ensure_br_binary
	ensure_bv_binary
	ensure_entire_binary
	ensure_linctl_binary
	ensure_sem_binary

	if [[ -z "$(command -v sg || true)" ]]; then
		die "sg (ast-grep) was not installed by mise"
	fi
	link_mise_binary sg
	link_mise_binary ast-grep
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
	local tools=(mise bun openspec br bv entire trunk linctl sem sg ast-grep)

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
		init_trunk
		post_init_notes
	fi

	verify_installs
	log "Bootstrap complete"
	log "Local binaries: $BIN_DIR"
}

main "$@"
