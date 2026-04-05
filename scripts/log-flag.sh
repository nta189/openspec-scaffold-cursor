#!/usr/bin/env bash
# scripts/log-flag.sh — Log a safety flag event
# Usage: bash scripts/log-flag.sh <category> <severity> <context> [resolution]
#
# Example:
#   bash scripts/log-flag.sh "scope_violation" "P0" "Agent attempted to modify /etc/hosts"
#   bash scripts/log-flag.sh "infinite_loop" "P1" "Same grep command 3 times" "cleared"

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
FLAG_LOG="$LOG_DIR/safety-flags.jsonl"

mkdir -p "$LOG_DIR"

CATEGORY="${1:?Usage: log-flag.sh <category> <severity> <context> [resolution]}"
SEVERITY="${2:?Usage: log-flag.sh <category> <severity> <context> [resolution]}"
CONTEXT="${3:?Usage: log-flag.sh <category> <severity> <context> [resolution]}"
RESOLUTION="${4:-null}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${SESSION_ID:-manual}"

# Build JSON safely using Python to handle special characters
python3 -c "
import json, sys
record = {
    'timestamp': sys.argv[1],
    'session_id': sys.argv[2],
    'category': sys.argv[3],
    'severity': sys.argv[4],
    'context': sys.argv[5],
    'resolution': None if sys.argv[6] == 'null' else sys.argv[6]
}
print(json.dumps(record))
" "$TIMESTAMP" "$SESSION_ID" "$CATEGORY" "$SEVERITY" "$CONTEXT" "${RESOLUTION:-null}" >> "$FLAG_LOG"

echo "✓ Safety flag logged: $CATEGORY ($SEVERITY)"

if [ "$RESOLUTION" = "null" ]; then
  echo "  ⚠ Flag is ACTIVE. Guarded tools are revoked."
  echo "  To clear: bash scripts/log-flag.sh \"$CATEGORY\" \"$SEVERITY\" \"$CONTEXT\" \"cleared\""
fi
