#!/usr/bin/env bash
# scripts/stats.sh — System observability dashboard
# Parses JSONL logs and session files to answer: is the system working? where's the friction?
#
# Usage: bash scripts/stats.sh [--period 7|30|90] [--json]

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERIOD="${2:-30}"
JSON_OUTPUT="${1:-}"

echo "═══════════════════════════════════════════════════════"
echo "  System Stats — Last $PERIOD Days"
echo "═══════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────
# Sessions
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Sessions"

SESSION_DIR="$PROJECT_ROOT/sessions"
if [ -d "$SESSION_DIR" ]; then
  total_sessions=$(find "$SESSION_DIR" -name "*.jsonl" -mtime -"$PERIOD" 2>/dev/null | wc -l | tr -d ' ')
  total_records=0
  total_checkpoints=0
  
  for f in $(find "$SESSION_DIR" -name "*.jsonl" -mtime -"$PERIOD" 2>/dev/null); do
    records=$(wc -l < "$f" | tr -d ' ')
    checkpoints=$(grep -c '"type":"checkpoint"' "$f" 2>/dev/null || echo 0)
    total_records=$((total_records + records))
    total_checkpoints=$((total_checkpoints + checkpoints))
  done
  
  if [ "$total_sessions" -gt 0 ]; then
    avg_records=$((total_records / total_sessions))
  else
    avg_records=0
  fi
  
  echo "  Total sessions:      $total_sessions"
  echo "  Total records:       $total_records"
  echo "  Avg records/session: $avg_records"
  echo "  Total checkpoints:   $total_checkpoints"
else
  echo "  No sessions directory"
fi

# ─────────────────────────────────────────────────────────
# Safety Flags
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Safety Flags"

FLAG_LOG="$PROJECT_ROOT/logs/safety-flags.jsonl"
if [ -f "$FLAG_LOG" ]; then
  total_flags=$(wc -l < "$FLAG_LOG" | tr -d ' ')
  active_flags=$(grep -cE '"resolution": *(null|"pending")' "$FLAG_LOG" 2>/dev/null || echo 0)
  cleared_flags=$(grep -cE '"resolution": *"cleared"' "$FLAG_LOG" 2>/dev/null || echo 0)
  
  echo "  Total flags (all time): $total_flags"
  echo "  Currently active:       $active_flags"
  echo "  Cleared:                $cleared_flags"
  
  # Flags by category
  echo "  By category:"
  python3 -c "
import json, collections
cats = collections.Counter()
with open('$FLAG_LOG') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            cats[d.get('category', 'unknown')] += 1
        except: pass
for cat, count in cats.most_common(10):
    print(f'    {cat}: {count}')
" 2>/dev/null || echo "    (python3 required for category breakdown)"

  # Flags by severity
  echo "  By severity:"
  for sev in P0 P1 P2; do
    count=$(grep -c "\"severity\":\"$sev\"" "$FLAG_LOG" 2>/dev/null || echo 0)
    echo "    $sev: $count"
  done
else
  echo "  No safety flag log"
fi

# ─────────────────────────────────────────────────────────
# Permission Decisions
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Permission Decisions"

PERM_LOG="$PROJECT_ROOT/logs/permission-audit.jsonl"
if [ -f "$PERM_LOG" ]; then
  total_perms=$(wc -l < "$PERM_LOG" | tr -d ' ')
  approved=$(grep -c '"decision":"approved"' "$PERM_LOG" 2>/dev/null || echo 0)
  denied=$(grep -c '"decision":"denied"' "$PERM_LOG" 2>/dev/null || echo 0)
  auto_approved=$(grep -c '"decision":"auto_approved"' "$PERM_LOG" 2>/dev/null || echo 0)
  destructive=$(grep -c '"destructive:' "$PERM_LOG" 2>/dev/null || echo 0)
  
  echo "  Total decisions:   $total_perms"
  echo "  Approved:          $approved"
  echo "  Auto-approved:     $auto_approved"
  echo "  Denied:            $denied"
  echo "  Destructive ops:   $destructive"
  
  if [ "$total_perms" -gt 0 ]; then
    deny_rate=$(python3 -c "print(f'{($denied / $total_perms * 100):.1f}%')" 2>/dev/null || echo "N/A")
    echo "  Deny rate:         $deny_rate"
  fi
  
  # Most common tools
  echo "  Most requested tools:"
  python3 -c "
import json, collections
tools = collections.Counter()
with open('$PERM_LOG') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            tools[d.get('tool', 'unknown')] += 1
        except: pass
for tool, count in tools.most_common(5):
    print(f'    {tool}: {count}')
" 2>/dev/null || echo "    (python3 required for tool breakdown)"

else
  echo "  No permission audit log"
fi

# ─────────────────────────────────────────────────────────
# Architectural Decisions
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Architectural Decisions"

DECISIONS="$PROJECT_ROOT/DECISIONS.md"
if [ -f "$DECISIONS" ]; then
  total_adrs=$(grep -c "^### ADR-" "$DECISIONS" 2>/dev/null || echo 0)
  accepted=$(grep -c "accepted" "$DECISIONS" 2>/dev/null || echo 0)
  superseded=$(grep -c "superseded" "$DECISIONS" 2>/dev/null || echo 0)
  deprecated=$(grep -c "deprecated" "$DECISIONS" 2>/dev/null || echo 0)
  
  echo "  Total ADRs:    $total_adrs"
  echo "  Accepted:      $accepted"
  echo "  Superseded:    $superseded"
  echo "  Deprecated:    $deprecated"
  
  # Check for stale decisions (accepted, older than 90 days)
  # This is a rough check based on date strings in the file
  echo "  Review needed: check for accepted ADRs older than 90 days"
else
  echo "  No DECISIONS.md found"
fi

# ─────────────────────────────────────────────────────────
# Session Memory
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Session Memory"

MEMORY_DIR="$PROJECT_ROOT/tmp/session-memory"
if [ -d "$MEMORY_DIR" ]; then
  total_memory=$(find "$MEMORY_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  recent_memory=$(find "$MEMORY_DIR" -name "*.md" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
  stale_memory=$(find "$MEMORY_DIR" -name "*.md" -mtime +30 2>/dev/null | wc -l | tr -d ' ')
  
  echo "  Total files:      $total_memory"
  echo "  Last 7 days:      $recent_memory"
  echo "  Stale (>30 days): $stale_memory"
else
  echo "  No session memory directory"
fi

# ─────────────────────────────────────────────────────────
# Disk Usage
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Disk Usage"

echo "  sessions/:     $(du -sh "$PROJECT_ROOT/sessions" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "  logs/:         $(du -sh "$PROJECT_ROOT/logs" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "  tmp/:          $(du -sh "$PROJECT_ROOT/tmp" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "  Total system:  $(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1 || echo 'N/A')"

# ─────────────────────────────────────────────────────────
# Health Score
# ─────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────"
echo "→ Health Assessment"

issues=0

if [ "$active_flags" -gt 0 ] 2>/dev/null; then
  echo "  ⚠ $active_flags active safety flag(s) — resolve before continuing"
  issues=$((issues + 1))
fi

if [ "$stale_memory" -gt 5 ] 2>/dev/null; then
  echo "  ⚠ $stale_memory stale session memory files — run cleanup.sh"
  issues=$((issues + 1))
fi

stale_sessions=$(find "$SESSION_DIR" -name "*.jsonl" -mtime +30 2>/dev/null | wc -l | tr -d ' ')
if [ "$stale_sessions" -gt 10 ] 2>/dev/null; then
  echo "  ⚠ $stale_sessions sessions older than 30 days — run cleanup.sh"
  issues=$((issues + 1))
fi

if [ "$issues" -eq 0 ]; then
  echo "  ✓ System healthy"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
