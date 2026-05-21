#!/usr/bin/env bash
# scripts/cursor-session-init.sh — Cursor session startup (wraps session-init + mode hint)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── Cursor Session Init ─────────────────────────"
echo "IDE: Cursor | Rules: .cursor/rules/ + .cursorrules"
echo ""

# Delegate to canonical init
if [ -f "$PROJECT_ROOT/scripts/session-init.sh" ]; then
  bash "$PROJECT_ROOT/scripts/session-init.sh"
else
  echo "⚠ scripts/session-init.sh not found"
fi

echo ""
echo "Context hints:"
echo "  @DECISIONS.md  — recent ADRs"
echo "  @AGENT.md      — routing"
echo "  @SAFETY.md     — permissions"
echo "  @IMPLEMENTATION.md — when coding"
echo ""
echo "Modes: cursor/prompts/modes/{explore,plan,implement,verify}.md"
echo "──────────────────────────────────────────────"
