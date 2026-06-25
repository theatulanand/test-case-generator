#!/usr/bin/env bash
set -e

COMMANDS_DIR="$HOME/.claude/commands"

echo "Installing test-case-generator..."
mkdir -p "$COMMANDS_DIR"
cp commands/test-case.md "$COMMANDS_DIR/test-case.md"
echo "Done. Restart Claude Code and /test-case will appear in the slash command menu."
