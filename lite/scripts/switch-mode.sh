#!/usr/bin/env bash
# scripts/switch-mode.sh — Swap .claude/settings.json based on agent type
# This makes agent type constraints STRUCTURAL, not just instructional.
#
# Usage: bash scripts/switch-mode.sh <explore|implement|verify>
#
# How it works:
#   Each mode has a pre-built settings file in .claude/modes/
#   This script swaps .claude/settings.json to the mode-specific version
#   Claude Code reads settings.json on every tool invocation — so the swap is immediate

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODES_DIR="$PROJECT_ROOT/.claude/modes"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

MODE="${1:?Usage: switch-mode.sh <explore|implement|verify>}"

if [ ! -f "$MODES_DIR/${MODE}.json" ]; then
  echo "✗ Unknown mode: $MODE"
  echo "  Available: explore, implement, verify"
  exit 1
fi

# Backup current settings
cp "$SETTINGS" "$SETTINGS.backup" 2>/dev/null || true

# Merge mode permissions into settings.json, preserving hooks and other keys
if ! python3 -c "
import json, sys

with open('$SETTINGS') as f:
    current = json.load(f)

with open('$MODES_DIR/${MODE}.json') as f:
    mode = json.load(f)

# Replace only permissions and customInstructions from the mode file
current['permissions'] = mode['permissions']
if 'customInstructions' in mode:
    current['customInstructions'] = mode['customInstructions']

# Preserve hooks, \$schema, env, and everything else from current settings

with open('$SETTINGS', 'w') as f:
    json.dump(current, f, indent=2)
    f.write('\n')
" 2>/dev/null; then
  echo "✗ Mode switch failed (python3 required for merge)"
  cp "$SETTINGS.backup" "$SETTINGS" 2>/dev/null || true
  exit 1
fi

echo "✓ Switched to $MODE mode"
echo "  Settings: .claude/settings.json updated"
echo "  To restore: cp .claude/settings.json.backup .claude/settings.json"

# Log the mode switch
if [ -f "$PROJECT_ROOT/scripts/log-permission.sh" ]; then
  bash "$PROJECT_ROOT/scripts/log-permission.sh" "mode_switch" "switch to $MODE" "allowed" "auto_approved" "human" "Mode switch via switch-mode.sh"
fi
