#!/bin/sh
# install.sh — wire up ccx on this machine. Idempotent.
#
# - creates the private config dir (700)
# - symlinks bin/ccx into ~/.local/bin (already on PATH alongside `claude`)
#
# Secrets are NOT created here: drop your <provider>.env files into the config
# dir yourself (see providers.env.example), chmod 600.

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_DIR="${CLAUDE_CODE_X_DIR:-$HOME/.config/claude-code-x}"
BIN_DIR="$HOME/.local/bin"
CENTRAL_STORE_DIR="$HOME/.config/llm-provider-keys"
CENTRAL_STORE="$CENTRAL_STORE_DIR/providers.env"

# --- ccx config dir + symlink ------------------------------------------------
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

mkdir -p "$BIN_DIR"
chmod +x "$REPO_DIR/bin/ccx"
ln -sf "$REPO_DIR/bin/ccx" "$BIN_DIR/ccx"

echo "ccx        -> $BIN_DIR/ccx -> $REPO_DIR/bin/ccx"
echo "config dir -> $CONFIG_DIR (700)"

# --- central key store --------------------------------------------------------
if [ -r "$CENTRAL_STORE" ]; then
	echo "key store  -> $CENTRAL_STORE (exists)"
else
	printf '\nCentral key store not found at %s\n' "$CENTRAL_STORE"
	printf 'Create it now? [Y/n] '
	read -r ans
	case "$ans" in n | N | no) ;; *)
		mkdir -p "$CENTRAL_STORE_DIR"
		chmod 700 "$CENTRAL_STORE_DIR"
		cat > "$CENTRAL_STORE" <<'TMPL'
# Central LLM provider API keys
# Shared across projects: llm-sparring, jobset&match-v2, claude-code-x, etc.
# Permissions: 600 (owner read/write only)
#
# Each project loads this file first, then overrides with its own .env if present.
# Only provider keys here — project-specific config stays in project .env.

# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=
# DEEPSEEK_API_KEY=
# OPENROUTER_API_KEY=
# GOOGLE_API_KEY=
# MISTRAL_API_KEY=
# MOONSHOT_API_KEY=
# ZAI_API_KEY=
TMPL
		chmod 600 "$CENTRAL_STORE"
		echo "key store  -> $CENTRAL_STORE (created, 600)"
		echo "             Edit it to add your API keys."
		;;
	esac
fi

echo
echo "Next:"
echo "  ccx add glm       # add a provider interactively"
echo "  ccx glm            # launch Claude Code on that provider"
