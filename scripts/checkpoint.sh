#!/usr/bin/env bash
# scripts/checkpoint.sh — Write a checkpoint record to the session JSONL
# Called by: hook system (session-end), manually, or every N turns
#
# Usage:
#   bash scripts/checkpoint.sh [session-id] [workflow-state] [notes]
#
# If no session-id is provided, generates one from timestamp.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_DIR="$PROJECT_ROOT/sessions"
mkdir -p "$SESSION_DIR"

# Arguments
SESSION_ID="${1:-$(date +%Y%m%d-%H%M%S)}"
WORKFLOW_STATE="${2:-idle}"
NOTES="${3:-automatic checkpoint}"

SESSION_FILE="$SESSION_DIR/$SESSION_ID.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Determine sequence number
if [ -f "$SESSION_FILE" ]; then
  SEQUENCE=$(wc -l < "$SESSION_FILE" | tr -d ' ')
  SEQUENCE=$((SEQUENCE + 1))
else
  SEQUENCE=1
fi

# Collect state (guard for non-git environments)
if git rev-parse --is-inside-work-tree 2>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
else
  BRANCH="no-git"
  UNCOMMITTED=0
fi

# Count active flags (handle both compact and spaced JSON formats)
FLAG_LOG="$PROJECT_ROOT/logs/safety-flags.jsonl"
if [ -f "$FLAG_LOG" ] && [ -s "$FLAG_LOG" ]; then
  ACTIVE_FLAGS=$(python3 -c "
import json
count = 0
with open('$FLAG_LOG') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            if d.get('resolution') is None or d.get('resolution') == 'pending':
                count += 1
        except: pass
print(count)
" 2>/dev/null || echo "0")
else
  ACTIVE_FLAGS=0
fi

# Loaded modules (check which .md files were recently accessed)
LOADED_MODULES="[]"
if command -v python3 &>/dev/null; then
  LOADED_MODULES=$(python3 -c "
import json, os, time
modules = []
for f in ['CLAUDE.md', 'AGENT.md', 'IMPLEMENTATION.md', 'SAFETY.md', 'MEMORY.md']:
    path = os.path.join('$PROJECT_ROOT', f)
    if os.path.exists(path):
        # Check if accessed in last hour
        if time.time() - os.path.getatime(path) < 3600:
            modules.append(f)
print(json.dumps(modules))
" 2>/dev/null || echo "[]")
fi

# Build checkpoint record
CHECKPOINT=$(cat <<EOF
{"type":"checkpoint","timestamp":"$TIMESTAMP","session_id":"$SESSION_ID","sequence":$SEQUENCE,"data":{"workflow_state":"$WORKFLOW_STATE","branch":"$BRANCH","uncommitted_changes":$UNCOMMITTED,"active_flags":$ACTIVE_FLAGS,"loaded_modules":$LOADED_MODULES,"notes":"$NOTES"}}
EOF
)

# Append to session file
echo "$CHECKPOINT" >> "$SESSION_FILE"

echo "✓ Checkpoint written to $SESSION_FILE (seq: $SEQUENCE, state: $WORKFLOW_STATE)"
