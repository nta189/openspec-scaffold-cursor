#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── Session Init ──"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
echo "Uncommitted: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files"

# Check sessions
if [ -d "$PROJECT_ROOT/sessions" ]; then
  count=$(find "$PROJECT_ROOT/sessions" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  echo "Sessions: $count"
fi

# Check for session memory
if [ -d "$PROJECT_ROOT/tmp/session-memory" ]; then
  mem=$(find "$PROJECT_ROOT/tmp/session-memory" -name "*.md" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
  [ "$mem" -gt 0 ] && echo "Recent memory files: $mem"
fi

echo "── Ready ──"
