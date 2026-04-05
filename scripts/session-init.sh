#!/usr/bin/env bash
# scripts/session-init.sh — Run at session start to load context and validate state
# Called by: hook system (session-start) or manually

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── Session Init ──────────────────────────────"

# 1. Report current branch and status
echo ""
if git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
  echo "Status: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') uncommitted changes"
else
  echo "Git: not a git repository"
fi

# 2. Check for active safety flags
FLAG_LOG="$PROJECT_ROOT/logs/safety-flags.jsonl"
if [ -f "$FLAG_LOG" ]; then
  active_flags=$(grep -E '"resolution": *(null|"pending")' "$FLAG_LOG" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$active_flags" -gt 0 ]; then
    echo ""
    echo "⚠ ACTIVE SAFETY FLAGS: $active_flags"
    echo "  Review logs/safety-flags.jsonl before proceeding."
    echo "  Guarded tools are revoked until flags are cleared."
  fi
else
  active_flags=0
fi

# 3. Show last 5 decisions
DECISIONS="$PROJECT_ROOT/DECISIONS.md"
if [ -f "$DECISIONS" ]; then
  decision_count=$(grep -c "^### ADR-" "$DECISIONS" 2>/dev/null || true)
  if [ "$decision_count" -gt 0 ]; then
    echo ""
    echo "Recent decisions ($decision_count total):"
    grep "^### ADR-\|^.Status:." "$DECISIONS" | tail -10 | while IFS= read -r line; do
      echo "  $line"
    done
  fi
fi

# 4. Check for pending session memory
MEMORY_DIR="$PROJECT_ROOT/tmp/session-memory"
if [ -d "$MEMORY_DIR" ]; then
  memory_files=$(find "$MEMORY_DIR" -name "*.md" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
  if [ "$memory_files" -gt 0 ]; then
    echo ""
    echo "Session memory: $memory_files file(s) from the last 7 days"
    find "$MEMORY_DIR" -name "*.md" -mtime -7 -exec basename {} \; 2>/dev/null | while IFS= read -r f; do
      echo "  → $f"
    done
  fi
fi

# 5. Check for stale sessions (older than 30 days)
SESSION_DIR="$PROJECT_ROOT/sessions"
if [ -d "$SESSION_DIR" ]; then
  stale=$(find "$SESSION_DIR" -name "*.jsonl" -mtime +30 2>/dev/null | wc -l | tr -d ' ')
  if [ "$stale" -gt 0 ]; then
    echo ""
    echo "⚠ $stale session file(s) older than 30 days. Consider archiving."
  fi
fi

# 6. Disk check on tmp directories
tmp_size=$(du -sh "$PROJECT_ROOT/tmp" 2>/dev/null | cut -f1 || true)
echo ""
echo "Tmp directory size: $tmp_size"

echo ""
echo "── Session Ready ─────────────────────────────"
if [ "$active_flags" -gt 0 ]; then
  echo "  Mode: RESTRICTED (active safety flags)"
else
  echo "  Mode: $(python3 -c "import json; print(json.load(open('$PROJECT_ROOT/project.settings.json'))['permission_mode'])" 2>/dev/null || echo 'unknown')"
fi
echo "───────────────────────────────────────────────"
