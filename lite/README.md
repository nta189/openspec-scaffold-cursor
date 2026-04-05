# Enhanced Claude Code — Lite

80% of the value at 20% of the complexity. Three modes, three scripts, two system files.

## What's Included

| File | Purpose |
|------|---------|
| `CLAUDE.md` | System identity + non-negotiable rules (~1,200 tokens) |
| `SAFETY.md` | Permission tiers + destruction detection (~800 tokens) |
| `.claude/settings.json` | Native Claude Code permissions + auto-checkpoint hook |
| `.claude/modes/{explore,implement,verify}.json` | Structural mode enforcement |
| `.claude/commands/{explore,implement,verify}.md` | Three slash commands |
| `scripts/switch-mode.sh` | Swap settings.json per mode |
| `scripts/session-init.sh` | Branch, status, session memory check |
| `scripts/checkpoint.sh` | Write session checkpoints to JSONL |
| `scripts/cleanup.sh` | Log rotation and session archival |

**Total system prompt: ~2,000 tokens** (vs ~4,200 for the full version)

## Setup

```bash
cp -r lite/* /path/to/your/project/
cd /path/to/your/project
chmod +x scripts/*.sh
mkdir -p sessions tmp/session-memory
```

Edit CLAUDE.md — replace `[Project Name]`, `[core tables]`, and the architecture table.

## Usage

Open Claude Code. Three modes:

- `/explore` — read-only investigation
- `/implement` — write code with safety gates  
- `/verify` — test and verify, no writes

That's it. Type `/explore` to start investigating, `/implement` when ready to build, `/verify` when done.

## When to Use Full vs Lite

**Use Lite when:** solo dev, small project, low ceremony, you want mode enforcement without the overhead.

**Use Full when:** team project, regulated domain, multi-repo, you need workflow state tracking, sub-agent dispatch, decision logs, audit trails, and 13 slash commands.

Full version: [github.com/Pupule11/enhanced-claude-code](https://github.com/Pupule11/enhanced-claude-code)
