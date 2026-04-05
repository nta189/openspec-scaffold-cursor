#!/usr/bin/env bash
set -euo pipefail

# new-project.sh — Bootstrap a new project with OpenSpec + SCAFFOLD + enhanced-claude-code builder
# Usage: ./new-project.sh <project-name> [directory]

PROJECT_NAME="${1:?Usage: ./new-project.sh <project-name> [directory]}"
PROJECT_DIR="${2:-./$PROJECT_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════"
echo "  Creating project: $PROJECT_NAME"
echo "  Directory: $PROJECT_DIR"
echo "═══════════════════════════════════════════════"

# 1. Create and enter project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 2. Initialize git
if [ ! -d .git ]; then
  git init
  echo "✓ Git initialized"
fi

# 3. Initialize OpenSpec
if command -v openspec &> /dev/null; then
  openspec init
  echo "✓ OpenSpec initialized"
  openspec config profile 2>/dev/null || true
  openspec update 2>/dev/null || true
  echo "✓ OpenSpec expanded workflow enabled"
else
  echo "⚠ OpenSpec CLI not installed. Creating directory structure manually."
  echo "  Install later: npm install -g @fission-ai/openspec@latest"
  mkdir -p openspec/specs openspec/changes openspec/archive
  cat > openspec/config.yaml << 'YAML'
schema: spec-driven
context: |
  <define your stack in CLAUDE.md — the scaffold reads it>
nfr_defaults:
  api_response_p95_ms: 200
  api_response_p99_ms: 500
  retention_days: 2555
  test_coverage_min_pct: 80
rules:
  specs:
    - Every requirement has a MoSCoW priority (MUST / SHOULD / COULD)
    - Every requirement has non-functional targets
    - Every scenario uses GIVEN/WHEN/THEN format
    - Every data model has typed fields
  proposal:
    - Include scope and out-of-scope
    - Reference affected specs by path
  design:
    - Reference conventions from CLAUDE.md
    - Identify affected shared modules
  tasks:
    - Each task is implementable in one session
    - Each task references the scenario it satisfies
YAML
  echo "✓ OpenSpec directory structure created manually"
  echo "  Run 'openspec init' later to enable CLI features"
fi

# 4. Create supporting directories
mkdir -p .claude/commands
echo "✓ Agent skill directory created"

# Copy skills as Claude Code commands
if [ -d "$SCRIPT_DIR/skills" ]; then
  cp "$SCRIPT_DIR/skills/"*.md "$PROJECT_DIR/.claude/commands/" 2>/dev/null || true
  echo "  ✓ Agent skills copied to .claude/commands/"
fi

# 5. Copy SCAFFOLD as the builder prompt
cp "$SCRIPT_DIR/SCAFFOLD.md" ./prompt.md
echo "✓ SCAFFOLD.md copied as prompt.md"

# 6. Create minimal CLAUDE.md if none exists
if [ ! -f CLAUDE.md ]; then
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

## Project overview

<!-- Describe your project in 2-3 sentences -->

## Architecture

<!-- Define your stack choices. The SCAFFOLD reads these. -->
<!-- Examples: -->
<!-- - Language: TypeScript / Python / Go / Rust -->
<!-- - Framework: Express / FastAPI / Gin / Axum -->
<!-- - Database: PostgreSQL / SurrealDB -->
<!-- - Test runner: Vitest / pytest / go test -->

## Critical rules

### Data boundary

<!-- Define what data is NOT allowed in this repo -->

### Code standards

<!-- Define coverage thresholds, auth requirements, logging rules -->
EOF
  echo "✓ CLAUDE.md template created — fill this in before building"
fi

# 7. Create minimal .gitignore if none exists
if [ ! -f .gitignore ]; then
  cat > .gitignore << 'EOF'
node_modules/
dist/
.env
*.log
coverage/
.DS_Store
__pycache__/
*.pyc
.venv/
EOF
  echo "✓ .gitignore created"
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "  Project ready: $PROJECT_DIR"
echo "═══════════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Edit CLAUDE.md — define your stack and rules"
echo "  3. Write specs in openspec/specs/"
echo "  4. Open in Claude Code (VS Code or CLI)"
echo "  5. Paste prompt.md or run: cat prompt.md"
echo ""
echo "  For enhanced-claude-code builder integration:"
echo "  https://github.com/krzemienski/enhanced-claude-code"
echo ""
