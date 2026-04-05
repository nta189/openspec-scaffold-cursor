#!/usr/bin/env bash
# scripts/review-decisions.sh — Scan DECISIONS.md for conflicts, staleness, and review needs
#
# Usage: bash scripts/review-decisions.sh

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECISIONS="$PROJECT_ROOT/DECISIONS.md"

if [ ! -f "$DECISIONS" ]; then
  echo "✗ DECISIONS.md not found"
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  Decision Review"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────
# 1. Extract all ADRs with metadata
# ─────────────────────────────────────────────────────────
python3 - "$DECISIONS" << 'PYTHON'
import re
import sys
from datetime import datetime, timedelta

with open(sys.argv[1]) as f:
    content = f.read()

# Parse ADR entries
pattern = r'### (ADR-\d+)\s*—\s*(.+?)\n\*\*Date:\*\*\s*(.+?)\n\*\*Status:\*\*\s*(.+?)(?:\n|$)'
adrs = re.findall(pattern, content)

if not adrs:
    print("  No ADR entries found.")
    sys.exit(0)

print(f"→ Total entries: {len(adrs)}")
print("")

# Categorize by status
accepted = [(id, title, date, status) for id, title, date, status in adrs if 'accepted' in status.lower() and 'superseded' not in status.lower()]
superseded = [(id, title, date, status) for id, title, date, status in adrs if 'superseded' in status.lower()]
deprecated = [(id, title, date, status) for id, title, date, status in adrs if 'deprecated' in status.lower()]
proposed = [(id, title, date, status) for id, title, date, status in adrs if 'proposed' in status.lower()]

print(f"  Accepted:    {len(accepted)}")
print(f"  Superseded:  {len(superseded)}")
print(f"  Deprecated:  {len(deprecated)}")
print(f"  Proposed:    {len(proposed)}")

# ─────────────────────────────────────────────────────────
# 2. Check for stale accepted decisions (>90 days)
# ─────────────────────────────────────────────────────────
print("")
print("→ Stale Decision Check (accepted > 90 days)")

stale = []
today = datetime.now()
for id, title, date_str, status in accepted:
    try:
        # Try common date formats
        for fmt in ['%Y-%m-%d', '%m/%d/%Y', '%B %d, %Y']:
            try:
                date = datetime.strptime(date_str.strip(), fmt)
                break
            except ValueError:
                continue
        else:
            continue
        
        age = (today - date).days
        if age > 90:
            stale.append((id, title, age))
    except:
        pass

if stale:
    for id, title, age in sorted(stale, key=lambda x: -x[2]):
        print(f"  ⚠ {id} — {title} ({age} days old)")
    print(f"  → {len(stale)} decision(s) need review. Still valid?")
else:
    print("  ✓ No stale decisions")

# ─────────────────────────────────────────────────────────
# 3. Check for potential conflicts among accepted ADRs
# ─────────────────────────────────────────────────────────
print("")
print("→ Conflict Detection (accepted ADRs)")

# Extract decision text for each accepted ADR
decision_pattern = r'### (ADR-\d+)\s*—\s*(.+?)(?=\n### ADR-|\Z)'
blocks = re.findall(decision_pattern, content, re.DOTALL)

accepted_blocks = {}
for id, block in blocks:
    # Check if this block has accepted status
    if re.search(r'\*\*Status:\*\*\s*accepted', block) and not re.search(r'superseded', block):
        # Extract the decision text
        decision_match = re.search(r'\*\*Decision:\*\*\s*(.+?)(?:\n\*\*|\Z)', block, re.DOTALL)
        if decision_match:
            accepted_blocks[id] = {
                'title': block.split('\n')[0].strip('— ').strip(),
                'decision': decision_match.group(1).strip()
            }

# Simple keyword overlap detection for potential conflicts
keywords_by_adr = {}
stop_words = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
              'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
              'should', 'may', 'might', 'shall', 'can', 'to', 'of', 'in', 'for',
              'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
              'before', 'after', 'above', 'below', 'between', 'out', 'off', 'over',
              'under', 'again', 'further', 'then', 'once', 'and', 'but', 'or', 'nor',
              'not', 'no', 'all', 'each', 'every', 'both', 'few', 'more', 'most',
              'other', 'some', 'such', 'only', 'own', 'same', 'so', 'than', 'too',
              'very', 'just', 'because', 'use', 'using', 'used', 'this', 'that',
              'these', 'those', 'it', 'its', 'we', 'our', 'they', 'them', 'their'}

for id, data in accepted_blocks.items():
    words = set(re.findall(r'\b[a-z]{3,}\b', data['decision'].lower()))
    keywords_by_adr[id] = words - stop_words

# Find pairs with high keyword overlap
conflicts_found = False
checked = set()
for id1, kw1 in keywords_by_adr.items():
    for id2, kw2 in keywords_by_adr.items():
        if id1 >= id2 or (id1, id2) in checked:
            continue
        checked.add((id1, id2))
        overlap = kw1 & kw2
        if len(overlap) >= 5:  # Threshold: 5+ shared domain keywords
            print(f"  ⚠ Potential overlap: {id1} ↔ {id2}")
            print(f"    Shared terms: {', '.join(sorted(list(overlap)[:8]))}")
            print(f"    → Review both to confirm they don't contradict")
            conflicts_found = True

if not conflicts_found:
    print("  ✓ No potential conflicts detected")

# ─────────────────────────────────────────────────────────
# 4. Unresolved proposals
# ─────────────────────────────────────────────────────────
if proposed:
    print("")
    print("→ Unresolved Proposals")
    for id, title, date, status in proposed:
        print(f"  • {id} — {title} (proposed {date})")
    print(f"  → {len(proposed)} proposal(s) need a decision")

# ─────────────────────────────────────────────────────────
# 5. Active decisions summary
# ─────────────────────────────────────────────────────────
print("")
print("→ Active Decisions (for quick reference)")
for id, title, date, status in accepted:
    print(f"  {id} — {title}")

print("")
PYTHON

echo "═══════════════════════════════════════════════════════"
