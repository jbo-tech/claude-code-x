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

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

mkdir -p "$BIN_DIR"
chmod +x "$REPO_DIR/bin/ccx"
ln -sf "$REPO_DIR/bin/ccx" "$BIN_DIR/ccx"

echo "ccx        -> $BIN_DIR/ccx -> $REPO_DIR/bin/ccx"
echo "config dir -> $CONFIG_DIR (700)"
echo
echo "Next:"
echo "  cp $REPO_DIR/providers.env.example $CONFIG_DIR/glm.env"
echo "  \$EDITOR $CONFIG_DIR/glm.env   # set ANTHROPIC_AUTH_TOKEN"
echo "  chmod 600 $CONFIG_DIR/glm.env"
echo "  ccx glm"
