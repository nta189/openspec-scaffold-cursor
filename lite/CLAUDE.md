# CLAUDE.md — [Project Name]

> Read this first. Every session.

## Quick Start

1. Run `bash scripts/session-init.sh` to check state.
2. Choose a mode: `/explore` (read-only), `/implement` (full access), `/verify` (test only).

## What [Project Name] Is

[One-sentence description of the project.]

## Architecture

| Repo | Location | Purpose |
|------|----------|---------|
| `[repo-1]` | `/path/to/repo` | [Purpose] |

## Non-Negotiable Rules

1. **All data is append-only.** No UPDATE or DELETE on [core tables].
2. **Log before you send.** Append interaction record before dispatching.
3. **Serialized tools never run in parallel.** File writes, shell mutations, git operations — one at a time.
4. **Verify before completing.** No task is "done" until `/verify` passes.
5. **When in doubt, do less.** Ambiguous → safer action. Unsure → ask.

## Compaction Rules

If context gets full, follow this order: clear stale tool results first → summarize old conversation → write critical context to `./tmp/session-memory/` → then truncate oldest messages as last resort. Never compact: these rules, the current task, or explicit user constraints.

## Mode Enforcement

Modes swap `.claude/settings.json` structurally. Run `bash scripts/switch-mode.sh <mode>` to change. The agent cannot override mode restrictions.

-----

*Customize: replace [Project Name], [core tables], architecture table, and repo paths.*
