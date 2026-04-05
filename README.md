# OpenSpec Scaffold

A production-grade operating system for AI coding agents. Combines three systems:

- **Enhanced Claude Code** — modes, safety enforcement, session management, verification protocols
- **SCAFFOLD.md** — universal build prompt that turns specs into production scaffolds
- **Agent Skills** — reusable slash commands for domain modules, API endpoints, migrations, verification, security audits

One repo. Any project. Any stack. Every time.

-----

## Quick Start

### New project

```bash
./new-project.sh my-app
cd my-app
# Edit CLAUDE.md — define your stack
# Write specs in openspec/specs/
# Open in Claude Code, paste prompt.md
```

### Existing project

```bash
# Copy the system into your project root
cp CLAUDE.md SAFETY.md AGENT.md IMPLEMENTATION.md MEMORY.md DECISIONS.md /path/to/project/
cp -r .claude scripts .githooks /path/to/project/
cp SCAFFOLD.md /path/to/project/prompt.md
cp skills/*.md /path/to/project/.claude/commands/
chmod +x /path/to/project/scripts/*.sh
./bootstrap.sh
```

-----

## What's Inside

### System Files

| File | Purpose | Loaded When |
|------|---------|------------|
| `CLAUDE.md` | System identity, architecture, tool registry, token budget | Every session |
| `SAFETY.md` | Permission tiers, destruction detection, safety flags, audit trails | Every session |
| `AGENT.md` | Decision routing, workflow state machine, agent types, sub-agent dispatch | Routing decisions |
| `IMPLEMENTATION.md` | Code conventions, tool partitioning, hooks, verification protocol | Writing code |
| `MEMORY.md` | Compaction cascade, session persistence, context budget, resume protocol | Managing context |
| `DECISIONS.md` | Append-only architectural decision log | Architectural decisions |
| `SCAFFOLD.md` | Universal build prompt — 5 dimensions: outcomes, constraints, tools, harness, evals | Scaffolding a project |

### Agent Skills

| Skill | What It Does |
|-------|-------------|
| `/add-domain-module` | Creates domain folder, routes, service, tests from a spec |
| `/add-api-endpoint` | Creates route handler + validation + 5 test categories + traceability |
| `/run-spec-verify` | Maps MUST scenarios to tests, runs them, reports PASS/FAIL per scenario |
| `/run-security-audit` | Tests every endpoint: auth, RBAC, validation, injection, IDOR |
| `/add-migration` | Creates sequential migration with UP/DOWN, updates types + factories + seeds |

### Mode Enforcement

| Command | Mode | Tool Access |
|---------|------|------------|
| `/explore` | Read-only | Cannot write files — structurally enforced |
| `/plan` | Read-only | Cannot execute shell or tests |
| `/implement` | Full access | Gated by permission tiers + deny list |
| `/verify` | Read + test | Cannot write files, only run tests |
| `/guide` | Read-only | Explanation and teaching only |

Plus: `/review`, `/grill`, `/dispatch`, `/elegant`, `/spec`, `/decide`, `/compact`, `/status`

### Operational Scripts

| Script | Purpose |
|--------|---------|
| `scripts/session-init.sh` | Session startup: branch, flags, decisions, memory |
| `scripts/checkpoint.sh` | Write session checkpoint to JSONL |
| `scripts/switch-mode.sh` | Swap settings.json per agent type |
| `scripts/verify-harness.sh` | Level 2 harness integrity verification |
| `scripts/check-secrets.sh` | Pre-commit secret scanning |
| `scripts/cleanup.sh` | Log rotation and session archival |
| `scripts/resume-session.sh` | Resume from checkpoint |
| `scripts/stats.sh` | Observability dashboard |

-----

## The SCAFFOLD

SCAFFOLD.md is a universal, stack-agnostic build prompt. It reads your CLAUDE.md and specs, then builds everything:

| Dimension | What It Creates |
|-----------|----------------|
| **Outcomes** | MoSCoW priorities, NFRs, acceptance criteria, synthetic data spec |
| **Constraints** | API shape, data layer, language rules, security, errors, logging conventions |
| **Tools** | Config files, linter, formatter, test runner, containers, CI, agent skills |
| **Harness** | Shared types, errors, middleware, entry point, migrations, seed data, orchestration |
| **Evals** | Test factories, fixtures, mocks, traceability matrix, security tests, benchmarks |

### How It Works

```
You write specs (OpenSpec)
  → SCAFFOLD.md tells Claude Code how to build everything around them
    → Enhanced Claude Code enforces safety while building
      → Agent skills provide reusable patterns for ongoing development
```

-----

## Lite Variant

80% of the value at 20% of the complexity. In `lite/`:

- 3 modes (explore, implement, verify)
- 4 scripts (session-init, checkpoint, cleanup, switch-mode)
- ~2,000 token system prompt

Use lite for solo projects. Use full for teams, regulated domains, or multi-repo architectures.

-----

## Typical Workflows

**Scaffold a new project:**
```
./new-project.sh my-app → edit CLAUDE.md → write specs → paste prompt.md into Claude Code
```

**Build a feature (after scaffold):**
```
/opsx:new add-payments → /opsx:ff → /opsx:apply → /run-spec-verify → /run-security-audit → /opsx:archive
```

**Bug fix:**
```
/explore → /dispatch → /implement → /verify → /grill
```

**Daily maintenance:**
```
/status → /review → /grill
```

-----

## Integration with OpenSpec

This repo complements [OpenSpec](https://openspec.dev). Install it:

```bash
npm install -g @fission-ai/openspec@latest
```

OpenSpec manages specs, proposals, and deltas. This repo provides the build system and agent operating system.

See [WALKTHROUGH.md](WALKTHROUGH.md) for the complete end-to-end guide.

-----

## License

MIT
