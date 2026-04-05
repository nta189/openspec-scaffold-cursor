#!/usr/bin/env bash
# scripts/check-secrets.sh — Scan staged files for potential secrets
# Called by: pre-commit hook (fail-closed: blocks commit if secrets found)

set -euo pipefail

echo "→ Scanning for secrets in staged files..."

# Patterns that indicate potential secrets
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                    # AWS Access Key
  'sk-[a-zA-Z0-9_-]{20,}'                 # OpenAI / Stripe secret key
  'ghp_[a-zA-Z0-9]{36}'                 # GitHub personal access token
  'xoxb-[0-9]+-[a-zA-Z0-9]+'           # Slack bot token
  'xoxp-[0-9]+-[a-zA-Z0-9]+'           # Slack user token
  'sk_live_[a-zA-Z0-9]{24,}'           # Stripe live key
  'pk_live_[a-zA-Z0-9]{24,}'           # Stripe publishable live key
  'AIza[0-9A-Za-z_-]{35}'              # Google API key
  'ya29\.[0-9A-Za-z_-]+'               # Google OAuth token
  'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'  # JWT token
  'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY'  # Private keys
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'       # Hardcoded passwords
  'secret\s*[:=]\s*["\x27][^"\x27]{8,}'         # Hardcoded secrets
)

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [ -z "$STAGED_FILES" ]; then
  echo "   ✓ No staged files to check"
  exit 0
fi

FOUND=0

for file in $STAGED_FILES; do
  # Skip binary files and known safe patterns
  if [[ "$file" =~ \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ ]]; then
    continue
  fi

  # Skip lock files
  if [[ "$file" =~ (package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Pipfile\.lock|poetry\.lock)$ ]]; then
    continue
  fi

  if [ -f "$file" ]; then
    for pattern in "${PATTERNS[@]}"; do
      matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        echo ""
        echo "   ✗ POTENTIAL SECRET in $file:"
        echo "$matches" | head -3 | while IFS= read -r line; do
          echo "     $line"
        done
        FOUND=$((FOUND + 1))
      fi
    done
  fi
done

echo ""
if [ "$FOUND" -gt 0 ]; then
  echo "   ✗ Found $FOUND potential secret(s). Commit blocked."
  echo "     Review the files above and remove any real secrets."
  echo "     If these are false positives, use: git commit --no-verify"
  exit 1
else
  echo "   ✓ No secrets detected"
  exit 0
fi
