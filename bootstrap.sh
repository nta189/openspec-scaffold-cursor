#!/usr/bin/env bash
# bootstrap.sh — Initialize the enhanced Claude Code system
# Run once when setting up a new project, or after cloning.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "  Enhanced Claude Code System — Bootstrap"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────
# 1. Create directory structure
# ─────────────────────────────────────────────────────────
echo "→ Creating directory structure..."

directories=(
  "tmp/tool-results"
  "tmp/session-memory"
  "tmp/mailbox"
  "tmp/forks"
  "tmp/worktrees"
  "sessions"
  "logs"
  "features"
  "modules"
  "docs/system"
  "docs/features"
  "docs/architecture"
  "scripts"
  ".claude/commands"
  ".githooks"
)

for dir in "${directories[@]}"; do
  mkdir -p "$PROJECT_ROOT/$dir"
  echo "   ✓ $dir"
done

# ─────────────────────────────────────────────────────────
# 2. Create .gitkeep files for empty directories
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Adding .gitkeep files..."

gitkeep_dirs=(
  "tmp/tool-results"
  "tmp/session-memory"
  "tmp/mailbox"
  "tmp/forks"
  "sessions"
  "logs"
)

for dir in "${gitkeep_dirs[@]}"; do
  touch "$PROJECT_ROOT/$dir/.gitkeep"
done
echo "   ✓ .gitkeep files added"

# ─────────────────────────────────────────────────────────
# 3. Add tmp and session dirs to .gitignore
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Updating .gitignore..."

gitignore_entries=(
  "# Enhanced Claude Code System — runtime directories"
  "tmp/tool-results/*"
  "tmp/session-memory/*"
  "tmp/mailbox/*"
  "tmp/forks/*"
  "tmp/worktrees/*"
  "sessions/*"
  "logs/*"
  "!**/.gitkeep"
)

gitignore_file="$PROJECT_ROOT/.gitignore"
touch "$gitignore_file"

for entry in "${gitignore_entries[@]}"; do
  if ! grep -qF "$entry" "$gitignore_file" 2>/dev/null; then
    echo "$entry" >> "$gitignore_file"
  fi
done
echo "   ✓ .gitignore updated"

# ─────────────────────────────────────────────────────────
# 4. Install git hooks
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Installing git hooks..."

if [ -d "$PROJECT_ROOT/.git" ]; then
  git config core.hooksPath .githooks
  echo "   ✓ Git hooks path set to .githooks/"
else
  echo "   ⚠ Not a git repository. Skipping hook installation."
  echo "     Run 'git init' first, then re-run bootstrap.sh"
fi

# ─────────────────────────────────────────────────────────
# 5. Validate required files exist
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Validating system files..."

required_files=(
  "CLAUDE.md"
  "AGENT.md"
  "IMPLEMENTATION.md"
  "SAFETY.md"
  "MEMORY.md"
  "DECISIONS.md"
  "project.settings.json"
  ".claude/settings.json"
  "features/FEATURE-SPEC-TEMPLATE.md"
)

missing=0
for file in "${required_files[@]}"; do
  if [ -f "$PROJECT_ROOT/$file" ]; then
    echo "   ✓ $file"
  else
    echo "   ✗ $file — MISSING"
    missing=$((missing + 1))
  fi
done

# ─────────────────────────────────────────────────────────
# 6. Validate customization placeholders
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Checking for uncustomized placeholders..."

placeholder_count=0
for file in CLAUDE.md AGENT.md IMPLEMENTATION.md SAFETY.md MEMORY.md; do
  if [ -f "$PROJECT_ROOT/$file" ]; then
    count=$(grep -c '\[Project Name\]\|\[yourdomain\]\|\[your-backend\]\|\[org\]/\[repo\]\|/path/to/' "$PROJECT_ROOT/$file" 2>/dev/null || true)
    if [ "$count" -gt 0 ]; then
      echo "   ⚠ $file has $count uncustomized placeholder(s)"
      placeholder_count=$((placeholder_count + count))
    fi
  fi
done

if [ "$placeholder_count" -eq 0 ]; then
  echo "   ✓ All placeholders customized"
else
  echo ""
  echo "   → Run through the Customization Checklist in CLAUDE.md"
fi

# ─────────────────────────────────────────────────────────
# 7. Make scripts executable
# ─────────────────────────────────────────────────────────
echo ""
echo "→ Setting script permissions..."

for script in scripts/*.sh .githooks/*; do
  if [ -f "$script" ]; then
    chmod +x "$script"
    echo "   ✓ $script"
  fi
done

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
if [ "$missing" -eq 0 ]; then
  echo "  ✓ Bootstrap complete. System ready."
else
  echo "  ⚠ Bootstrap complete with $missing missing file(s)."
  echo "    Copy missing files from the template package."
fi
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Replace all [placeholders] using the checklist in CLAUDE.md"
echo "  2. Review permission patterns in project.settings.json"
echo "  3. Customize .claude/settings.json deny list for your project"
echo "  4. Start a Claude Code session — it will read CLAUDE.md automatically"
echo ""
