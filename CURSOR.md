# Cursor IDE — OpenSpec Quick Start

This repo ships a **Cursor-native** layer alongside the legacy Claude Code system (`.claude/`, `CLAUDE.md`).

## First session

```bash
bash scripts/cursor-session-init.sh
# Windows (PowerShell):
# .\scripts\cursor-session-init.ps1
```

## Where rules live

| Asset | Purpose |
|-------|---------|
| `.cursorrules` | Legacy monolithic rules (still supported) |
| `.cursor/rules/*.mdc` | Modular always-on / glob-scoped rules (preferred) |
| `CLAUDE.md`, `AGENT.md`, … | Deep reference — load with `@` on demand |

## Prompts

| Path | Use |
|------|-----|
| `cursor/prompts/inline-ctrl-k.md` | Ctrl+K inline edit templates |
| `cursor/prompts/composer-scaffold.md` | Ctrl+I multi-file scaffold |
| `cursor/prompts/modes/*.md` | Explore / Plan / Implement / Verify |

## Commands (skills)

Converted slash-style workflows: `.cursor/commands/` (see README migration section).

## Assessment

Pre-migration score and gaps: `cursor_migration_assessment.md`.

## Claude vs Cursor

| Claude Code | Cursor |
|-------------|--------|
| `CLAUDE.md` auto-load | `.cursor/rules/` + `@CLAUDE.md` |
| `switch-mode.sh` | Mode prompts + Ask/Plan/Agent |
| `.claude/settings.json` deny ACL | Rules + user approval |
| Claude hooks | Port to `hooks.json` (P2) |

Legacy workflows remain functional; new work should start from `CURSOR.md`.
