#!/usr/bin/env bash
# scripts/log-permission.sh — Log a permission decision to the audit trail
# Usage: bash scripts/log-permission.sh <tool> <command> <tier> <decision> <decided_by> [context]
#
# Example:
#   bash scripts/log-permission.sh "shell_mutating" "git push origin main" "restricted" "approved" "human" "Pushing reviewed PR #47"
#   bash scripts/log-permission.sh "file_delete" "rm src/old-module.ts" "restricted" "denied" "human" "Decided to keep for reference"

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
AUDIT_LOG="$LOG_DIR/permission-audit.jsonl"

mkdir -p "$LOG_DIR"

TOOL="${1:?Usage: log-permission.sh <tool> <command> <tier> <decision> <decided_by> [context]}"
COMMAND="${2:?Missing: command}"
TIER="${3:?Missing: tier (allowed|guarded|restricted)}"
DECISION="${4:?Missing: decision (approved|denied|auto_approved)}"
DECIDED_BY="${5:?Missing: decided_by (human|coordinator|autonomous|settings)}"
CONTEXT="${6:-}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${SESSION_ID:-manual}"

# Read permission mode from settings
MODE=$(python3 -c "
import json, os
settings_path = os.path.join('$PROJECT_ROOT', 'project.settings.json')
if os.path.exists(settings_path):
    with open(settings_path) as f:
        print(json.load(f).get('permission_mode', 'interactive'))
else:
    print('interactive')
" 2>/dev/null || echo "unknown")

# Detect if this was a destructive operation
CLASSIFICATION="standard"
case "$COMMAND" in
  *"rm "*|*"delete"*|*"DROP"*|*"TRUNCATE"*)
    CLASSIFICATION="destructive:data_loss"
    ;;
  *"--force"*|*"rebase"*)
    CLASSIFICATION="destructive:irreversibility"
    ;;
esac

# Build JSON safely using Python to handle special characters
python3 -c "
import json, sys
record = {
    'timestamp': '$TIMESTAMP',
    'session_id': '$SESSION_ID',
    'tool': sys.argv[1],
    'command': sys.argv[2],
    'tier': sys.argv[3],
    'classification': sys.argv[4],
    'decision': sys.argv[5],
    'decided_by': sys.argv[6],
    'mode': sys.argv[7],
    'context': sys.argv[8]
}
print(json.dumps(record))
" "$TOOL" "$COMMAND" "$TIER" "$CLASSIFICATION" "$DECISION" "$DECIDED_BY" "$MODE" "$CONTEXT" >> "$AUDIT_LOG"

echo "✓ Permission logged: $TOOL ($DECISION by $DECIDED_BY)"
