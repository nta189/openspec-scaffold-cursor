#!/usr/bin/env bash
# scripts/cleanup.sh — Rotate logs, archive old sessions, clear stale tmp files
# Run weekly or when disk usage is high.
#
# Usage: bash scripts/cleanup.sh [--dry-run]

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${1:-}"

echo "═══════════════════════════════════════════════════════"
echo "  System Cleanup"
if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "  MODE: DRY RUN (no files will be deleted)"
fi
echo "═══════════════════════════════════════════════════════"
echo ""

ARCHIVED=0
DELETED=0

do_remove() {
  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "    [dry-run] would remove: $1"
  else
    rm -f "$1"
    DELETED=$((DELETED + 1))
  fi
}

do_archive() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "    [dry-run] would archive: $src → $dest"
  else
    mv "$src" "$dest"
    ARCHIVED=$((ARCHIVED + 1))
  fi
}

# ─────────────────────────────────────────────────────────
# 1. Archive sessions older than 30 days
# ─────────────────────────────────────────────────────────
echo "→ Sessions older than 30 days..."

SESSION_DIR="$PROJECT_ROOT/sessions"
ARCHIVE_DIR="$PROJECT_ROOT/sessions/archive"

if [ -d "$SESSION_DIR" ]; then
  stale_sessions=$(find "$SESSION_DIR" -maxdepth 1 -name "*.jsonl" -mtime +30 2>/dev/null)
  if [ -n "$stale_sessions" ]; then
    echo "$stale_sessions" | while IFS= read -r f; do
      do_archive "$f" "$ARCHIVE_DIR/$(basename "$f")"
    done
  else
    echo "  ✓ No stale sessions"
  fi
else
  echo "  ✓ No sessions directory"
fi

# ─────────────────────────────────────────────────────────
# 2. Rotate permission audit logs older than 30 days
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Permission audit log rotation..."

AUDIT_LOG="$PROJECT_ROOT/logs/permission-audit.jsonl"
if [ -f "$AUDIT_LOG" ]; then
  line_count=$(wc -l < "$AUDIT_LOG" | tr -d ' ')
  if [ "$line_count" -gt 1000 ]; then
    # Keep last 500 entries, archive the rest
    ARCHIVE_FILE="$PROJECT_ROOT/logs/archive/permission-audit-$(date +%Y%m%d).jsonl"
    if [ "$DRY_RUN" = "--dry-run" ]; then
      echo "    [dry-run] would archive $(($line_count - 500)) entries to $ARCHIVE_FILE"
    else
      mkdir -p "$PROJECT_ROOT/logs/archive"
      head -n $(($line_count - 500)) "$AUDIT_LOG" > "$ARCHIVE_FILE"
      tail -n 500 "$AUDIT_LOG" > "$AUDIT_LOG.tmp"
      mv "$AUDIT_LOG.tmp" "$AUDIT_LOG"
      echo "  ✓ Archived $(($line_count - 500)) entries, kept 500"
    fi
  else
    echo "  ✓ $line_count entries (under 1000 threshold)"
  fi
else
  echo "  ✓ No audit log to rotate"
fi

# ─────────────────────────────────────────────────────────
# 3. Rotate safety flag logs older than 30 days
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Safety flag log rotation..."

FLAG_LOG="$PROJECT_ROOT/logs/safety-flags.jsonl"
if [ -f "$FLAG_LOG" ]; then
  # Only archive resolved flags. Active flags stay.
  resolved=$(grep -cE '"resolution": *("cleared"|"resolved")' "$FLAG_LOG" 2>/dev/null || echo "0")
  if [ "$resolved" -gt 50 ]; then
    echo "  $resolved resolved flags eligible for archival"
    if [ "$DRY_RUN" != "--dry-run" ]; then
      mkdir -p "$PROJECT_ROOT/logs/archive"
      grep -E '"resolution": *("cleared"|"resolved")' "$FLAG_LOG" > "$PROJECT_ROOT/logs/archive/flags-$(date +%Y%m%d).jsonl"
      grep -vE '"resolution": *("cleared"|"resolved")' "$FLAG_LOG" > "$FLAG_LOG.tmp" || true
      mv "$FLAG_LOG.tmp" "$FLAG_LOG"
      echo "  ✓ Archived $resolved resolved flags"
    fi
  else
    echo "  ✓ $resolved resolved flags (under 50 threshold)"
  fi
else
  echo "  ✓ No flag log"
fi

# ─────────────────────────────────────────────────────────
# 4. Clear stale tool results (older than 7 days)
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Stale tool results..."

TOOL_RESULTS="$PROJECT_ROOT/tmp/tool-results"
if [ -d "$TOOL_RESULTS" ]; then
  stale_results=$(find "$TOOL_RESULTS" -type f -mtime +7 2>/dev/null)
  if [ -n "$stale_results" ]; then
    count=$(echo "$stale_results" | wc -l | tr -d ' ')
    echo "$stale_results" | while IFS= read -r f; do
      do_remove "$f"
    done
    echo "  Processed $count stale tool result(s)"
  else
    echo "  ✓ No stale tool results"
  fi
else
  echo "  ✓ No tool results directory"
fi

# ─────────────────────────────────────────────────────────
# 5. Clear old session memory (older than 30 days, unless preserved)
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Old session memory files..."

MEMORY_DIR="$PROJECT_ROOT/tmp/session-memory"
if [ -d "$MEMORY_DIR" ]; then
  old_memory=$(find "$MEMORY_DIR" -name "*.md" -mtime +30 2>/dev/null)
  if [ -n "$old_memory" ]; then
    count=$(echo "$old_memory" | wc -l | tr -d ' ')
    echo "$old_memory" | while IFS= read -r f; do
      # Check if marked as preserved
      if grep -q "PRESERVE: true" "$f" 2>/dev/null; then
        echo "    Skipping (preserved): $(basename "$f")"
      else
        do_remove "$f"
      fi
    done
    echo "  Processed $count old session memory file(s)"
  else
    echo "  ✓ No old session memory"
  fi
else
  echo "  ✓ No session memory directory"
fi

# ─────────────────────────────────────────────────────────
# 6. Clear empty mailbox files
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Stale mailbox files..."

MAILBOX_DIR="$PROJECT_ROOT/tmp/mailbox"
if [ -d "$MAILBOX_DIR" ]; then
  stale_mailbox=$(find "$MAILBOX_DIR" -name "*.jsonl" -mtime +3 2>/dev/null)
  if [ -n "$stale_mailbox" ]; then
    echo "$stale_mailbox" | while IFS= read -r f; do
      do_remove "$f"
    done
  else
    echo "  ✓ No stale mailbox files"
  fi
else
  echo "  ✓ No mailbox directory"
fi

# ─────────────────────────────────────────────────────────
# 7. Report disk usage
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Disk usage..."
echo "  sessions/:     $(du -sh "$PROJECT_ROOT/sessions" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "  logs/:         $(du -sh "$PROJECT_ROOT/logs" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "  tmp/:          $(du -sh "$PROJECT_ROOT/tmp" 2>/dev/null | cut -f1 || echo 'N/A')"

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "  Dry run complete. No files were modified."
else
  echo "  Cleanup complete. Archived: $ARCHIVED, Deleted: $DELETED"
fi
echo "═══════════════════════════════════════════════════════"
