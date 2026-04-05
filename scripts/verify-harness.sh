#!/usr/bin/env bash
# scripts/verify-harness.sh — Level 2 harness integrity verification
# Run after any change to CLAUDE.md, AGENT.md, SAFETY.md, settings, or hooks
#
# This verifies that safety guardrails are intact, not that features work.
# For feature verification (Level 1), use the verification protocol in IMPLEMENTATION.md.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "═══════════════════════════════════════════════════════"
echo "  Level 2 — Harness Integrity Verification"
echo "═══════════════════════════════════════════════════════"
echo ""

PASS=0
FAIL=0
WARN=0

check_pass() { echo "  ✓ PASS: $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  ✗ FAIL: $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  ⚠ WARN: $1"; WARN=$((WARN + 1)); }

# ─────────────────────────────────────────────────────────
# 1. Required files exist
# ─────────────────────────────────────────────────────────
echo "→ Check 1: Required system files"

for file in CLAUDE.md AGENT.md IMPLEMENTATION.md SAFETY.md MEMORY.md DECISIONS.md project.settings.json .claude/settings.json; do
  if [ -f "$PROJECT_ROOT/$file" ]; then
    check_pass "$file exists"
  else
    check_fail "$file is MISSING"
  fi
done

# ─────────────────────────────────────────────────────────
# 2. Append-only tables are documented
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 2: Append-only enforcement"

if grep -q "No.*UPDATE.*DELETE" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null; then
  check_pass "Append-only rule present in CLAUDE.md"
else
  check_fail "Append-only rule MISSING from CLAUDE.md"
fi

if grep -q "Append-Only Enforcement" "$PROJECT_ROOT/SAFETY.md" 2>/dev/null; then
  check_pass "Append-only enforcement section present in SAFETY.md"
else
  check_fail "Append-only enforcement section MISSING from SAFETY.md"
fi

# Check codebase for UPDATE/DELETE on protected tables
if [ -d "$PROJECT_ROOT/src" ]; then
  violations=$(grep -rn "UPDATE\s\+users\|DELETE\s\+FROM\s\+users\|UPDATE\s\+sessions\|DELETE\s\+FROM\s\+sessions\|UPDATE\s\+interactions\|DELETE\s\+FROM\s\+interactions\|UPDATE\s\+matches\|DELETE\s\+FROM\s\+matches\|UPDATE\s\+flags\|DELETE\s\+FROM\s\+flags" "$PROJECT_ROOT/src" 2>/dev/null || true)
  if [ -n "$violations" ]; then
    check_fail "Found UPDATE/DELETE on protected tables in source code"
    echo "    $violations" | head -5
  else
    check_pass "No UPDATE/DELETE on protected tables in source code"
  fi
else
  check_warn "No src/ directory found — skipping codebase scan"
fi

# ─────────────────────────────────────────────────────────
# 3. Permission deny list is populated
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 3: Permission deny list"

if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
  deny_count=$(python3 -c "
import json
with open('$PROJECT_ROOT/.claude/settings.json') as f:
    data = json.load(f)
deny = data.get('permissions', {}).get('deny', [])
print(len(deny))
" 2>/dev/null || echo "0")

  if [ "$deny_count" -gt 0 ]; then
    check_pass "Deny list has $deny_count entries in .claude/settings.json"
  else
    check_fail "Deny list is EMPTY in .claude/settings.json"
  fi
else
  check_fail ".claude/settings.json not found"
fi

# ─────────────────────────────────────────────────────────
# 4. Safety flag protocol is documented
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 4: Safety flag protocol"

if grep -q "never auto-resume\|Never auto-resume" "$PROJECT_ROOT/SAFETY.md" 2>/dev/null; then
  check_pass "No-auto-resume rule present in SAFETY.md"
else
  check_fail "No-auto-resume rule MISSING from SAFETY.md"
fi

if grep -q "Destruction Detection" "$PROJECT_ROOT/SAFETY.md" 2>/dev/null; then
  check_pass "Destruction detection section present in SAFETY.md"
else
  check_fail "Destruction detection section MISSING from SAFETY.md"
fi

# ─────────────────────────────────────────────────────────
# 5. Workflow state machine includes failure states
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 5: Workflow state machine"

for state in "failed" "partially_complete" "rolling_back" "verification_failed"; do
  if grep -q "$state" "$PROJECT_ROOT/AGENT.md" 2>/dev/null; then
    check_pass "State '$state' defined in AGENT.md"
  else
    check_fail "State '$state' MISSING from AGENT.md"
  fi
done

# ─────────────────────────────────────────────────────────
# 6. Token budget limits are defined
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 6: Token budget enforcement"

if grep -q "90%" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null && grep -q "token" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null; then
  check_pass "Token projection rule present in CLAUDE.md"
else
  check_fail "Token projection rule MISSING from CLAUDE.md"
fi

if grep -q "compaction" "$PROJECT_ROOT/MEMORY.md" 2>/dev/null; then
  check_pass "Compaction cascade defined in MEMORY.md"
else
  check_fail "Compaction cascade MISSING from MEMORY.md"
fi

# ─────────────────────────────────────────────────────────
# 7. Git hooks are installed
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 7: Git hooks"

hooks_path=$(git config core.hooksPath 2>/dev/null || echo "")
if [ "$hooks_path" = ".githooks" ]; then
  check_pass "Git hooks path set to .githooks/"
else
  check_warn "Git hooks path is '$hooks_path' (expected .githooks/)"
fi

if [ -f "$PROJECT_ROOT/.githooks/pre-commit" ] && [ -x "$PROJECT_ROOT/.githooks/pre-commit" ]; then
  check_pass "Pre-commit hook exists and is executable"
else
  check_warn "Pre-commit hook missing or not executable"
fi

# ─────────────────────────────────────────────────────────
# 8. Agent type constraints are defined
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 8: Agent type system"

for type in "explore" "plan" "implement" "verify" "guide"; do
  if grep -q "$type" "$PROJECT_ROOT/AGENT.md" 2>/dev/null; then
    check_pass "Agent type '$type' defined in AGENT.md"
  else
    check_fail "Agent type '$type' MISSING from AGENT.md"
  fi
done

# ─────────────────────────────────────────────────────────
# 9. Serialization rule is documented
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Check 9: Tool serialization"

if grep -q "Serialized.*never run in parallel\|never run simultaneously\|Serialized tools never run in parallel" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null; then
  check_pass "Serialization rule present in CLAUDE.md"
else
  check_fail "Serialization rule MISSING from CLAUDE.md"
fi

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "═══════════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  ✗ HARNESS INTEGRITY COMPROMISED"
  echo "    Fix all failures before continuing development."
  echo "    Do not merge changes until this passes clean."
  exit 1
else
  echo ""
  echo "  ✓ HARNESS INTACT"
  exit 0
fi
