#!/usr/bin/env bash
set -e

PLUGIN_DIR="$HOME/.claude/plugins/test-case-generator"

echo "Installing test-case-generator plugin..."
mkdir -p "$PLUGIN_DIR/skills"
cp plugin.json "$PLUGIN_DIR/plugin.json"
cp skills/test-case.md "$PLUGIN_DIR/skills/test-case.md"
echo "Done. Restart Claude Code and run /test-case to use the plugin."
