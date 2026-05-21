# AGENTS.md — Cursor / OpenSpec Entry Point

> Cursor loads this file for agent context. Deep docs load via `@` on demand.

## Start here

1. `bash scripts/cursor-session-init.sh`
2. `@DECISIONS.md` — last 5 ADRs
3. `@AGENT.md` — routing and workflow states

## Rule layers

- Always on: `.cursor/rules/openspec-core.mdc`, `safety.mdc`
- When coding: `implementation.mdc` (auto via globs)
- Full policy: `@SAFETY.md`, `@IMPLEMENTATION.md`, `@CLAUDE.md` (legacy identity)

## Modes

See `cursor/prompts/modes/` and `CURSOR.md`.

## Assessment

Migration score: `cursor_migration_assessment.md` (73/100 baseline).
