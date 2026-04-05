#!/usr/bin/env bash
# scripts/resume-session.sh — Resume a previous session from its last checkpoint
# Usage: bash scripts/resume-session.sh <session-id>
#        bash scripts/resume-session.sh --latest
#        bash scripts/resume-session.sh --list

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_DIR="$PROJECT_ROOT/sessions"
MEMORY_DIR="$PROJECT_ROOT/tmp/session-memory"

if [ ! -d "$SESSION_DIR" ]; then
  echo "✗ No sessions directory found. Nothing to resume."
  exit 1
fi

# ─────────────────────────────────────────────────────────
# Handle --list flag
# ─────────────────────────────────────────────────────────
if [ "${1:-}" = "--list" ]; then
  echo "── Available Sessions ─────────────────────────"
  echo ""
  for session_file in "$SESSION_DIR"/*.jsonl; do
    if [ -f "$session_file" ]; then
      session_id=$(basename "$session_file" .jsonl)
      line_count=$(wc -l < "$session_file" | tr -d ' ')
      last_modified=$(date -r "$session_file" "+%Y-%m-%d %H:%M" 2>/dev/null || stat -c "%y" "$session_file" 2>/dev/null | cut -d. -f1)

      # Get last checkpoint state
      last_state=$(grep '"type":"checkpoint"' "$session_file" 2>/dev/null | tail -1 | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get('data', {}).get('workflow_state', 'unknown'))
except: print('unknown')
" 2>/dev/null || echo "unknown")

      echo "  $session_id  |  $line_count records  |  state: $last_state  |  $last_modified"
    fi
  done
  echo ""
  exit 0
fi

# ─────────────────────────────────────────────────────────
# Determine session to resume
# ─────────────────────────────────────────────────────────
if [ "${1:-}" = "--latest" ]; then
  SESSION_FILE=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)
  if [ -z "$SESSION_FILE" ]; then
    echo "✗ No session files found."
    exit 1
  fi
  SESSION_ID=$(basename "$SESSION_FILE" .jsonl)
else
  SESSION_ID="${1:?Usage: resume-session.sh <session-id> | --latest | --list}"
  SESSION_FILE="$SESSION_DIR/$SESSION_ID.jsonl"
fi

if [ ! -f "$SESSION_FILE" ]; then
  echo "✗ Session file not found: $SESSION_FILE"
  echo "  Run with --list to see available sessions."
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  Session Resume — $SESSION_ID"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────
# 1. Find last checkpoint
# ─────────────────────────────────────────────────────────
echo "→ Finding last checkpoint..."

CHECKPOINT=$(grep '"type":"checkpoint"' "$SESSION_FILE" 2>/dev/null | tail -1)

if [ -z "$CHECKPOINT" ]; then
  echo "  ⚠ No checkpoint found in session. Cannot determine state."
  echo "  Session has $(wc -l < "$SESSION_FILE" | tr -d ' ') records."
  echo "  Starting fresh may be safer."
  exit 1
fi

# Parse checkpoint
CHECKPOINT_DATA=$(echo "$CHECKPOINT" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
d = data.get('data', {})
print(f\"Workflow state: {d.get('workflow_state', 'unknown')}\")
print(f\"Branch: {d.get('branch', 'unknown')}\")
print(f\"Uncommitted changes: {d.get('uncommitted_changes', 0)}\")
print(f\"Active flags: {d.get('active_flags', 0)}\")
print(f\"Loaded modules: {', '.join(d.get('loaded_modules', []))}\")
print(f\"Notes: {d.get('notes', 'none')}\")
print(f\"Timestamp: {data.get('timestamp', 'unknown')}\")
print(f\"Sequence: {data.get('sequence', 0)}\")
" 2>/dev/null)

echo "$CHECKPOINT_DATA" | while IFS= read -r line; do
  echo "  $line"
done

# ─────────────────────────────────────────────────────────
# 2. Check for interrupted tool execution
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Checking for interrupted operations..."

LAST_TOOL_CALL=$(grep '"type":"tool_call"' "$SESSION_FILE" 2>/dev/null | tail -1)
LAST_TOOL_RESULT=$(grep '"type":"tool_result"' "$SESSION_FILE" 2>/dev/null | tail -1)

if [ -n "$LAST_TOOL_CALL" ]; then
  CALL_SEQ=$(echo "$LAST_TOOL_CALL" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('sequence',0))" 2>/dev/null || echo "0")
  RESULT_SEQ=$(echo "$LAST_TOOL_RESULT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('sequence',0))" 2>/dev/null || echo "0")

  if [ "$CALL_SEQ" -gt "$RESULT_SEQ" ]; then
    INTERRUPTED_TOOL=$(echo "$LAST_TOOL_CALL" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('data',{}).get('tool','unknown'))" 2>/dev/null || echo "unknown")
    echo "  ⚠ INTERRUPTED: A '$INTERRUPTED_TOOL' operation was in progress when the session ended."
    echo "  Workflow state should be treated as 'partially_complete'."
    echo "  Decision needed: retry the operation, skip it, or roll back."
  else
    echo "  ✓ No interrupted operations."
  fi
else
  echo "  ✓ No tool calls in session."
fi

# ─────────────────────────────────────────────────────────
# 3. Load session memory files
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Checking for session memory files..."

if [ -d "$MEMORY_DIR" ]; then
  MEMORY_FILES=$(find "$MEMORY_DIR" -name "${SESSION_ID}*" 2>/dev/null)
  if [ -n "$MEMORY_FILES" ]; then
    echo "$MEMORY_FILES" | while IFS= read -r mf; do
      echo "  → $(basename "$mf")"
      # Show constraints and traps sections
      if grep -q "## Constraints Discovered" "$mf" 2>/dev/null; then
        echo "    Constraints:"
        sed -n '/## Constraints Discovered/,/## /p' "$mf" | grep "^-" | head -5 | while IFS= read -r line; do
          echo "      $line"
        done
      fi
      if grep -q "## Traps" "$mf" 2>/dev/null; then
        echo "    Traps:"
        sed -n '/## Traps/,/## /p' "$mf" | grep "^-" | head -5 | while IFS= read -r line; do
          echo "      $line"
        done
      fi
    done
  else
    echo "  No session memory files for this session."
  fi
else
  echo "  No session memory directory."
fi

# ─────────────────────────────────────────────────────────
# 4. Count active safety flags
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Checking safety flags..."

FLAG_LOG="$PROJECT_ROOT/logs/safety-flags.jsonl"
if [ -f "$FLAG_LOG" ]; then
  ACTIVE=$(grep -E '"resolution": *(null|"pending")' "$FLAG_LOG" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ACTIVE" -gt 0 ]; then
    echo "  ⚠ $ACTIVE active safety flag(s). Guarded tools are revoked."
  else
    echo "  ✓ No active safety flags."
  fi
else
  echo "  ✓ No flag log found."
fi

# ─────────────────────────────────────────────────────────
# 5. Summary
# ─────────────────────────────────────────────────────────
TOTAL_RECORDS=$(wc -l < "$SESSION_FILE" | tr -d ' ')
CHECKPOINT_SEQ=$(echo "$CHECKPOINT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('sequence',0))" 2>/dev/null || echo "0")
RECORDS_AFTER=$((TOTAL_RECORDS - CHECKPOINT_SEQ))

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Resume Summary"
echo "  Total records: $TOTAL_RECORDS"
echo "  Checkpoint at: sequence $CHECKPOINT_SEQ"
echo "  Records after checkpoint: $RECORDS_AFTER"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "To resume in Claude Code, provide this context:"
echo "  \"Resume session $SESSION_ID. Last state: [workflow state from above]."
echo "   [Include any constraints and traps from session memory].\""
echo ""
