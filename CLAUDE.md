# CLAUDE.md — [Project Name]

> Read this first. Every session. Before touching any file.

-----

## Quick-Start Protocol

Every session begins with these four steps:

1. **Run session init.** Execute `bash scripts/session-init.sh` to check branch, safety flags, recent decisions, and session memory. Read the output before proceeding.
2. **Confirm repo location.** You are in `/path/to/your/repo`. Any other path is stale.
3. **Check workflow state.** Read `DECISIONS.md` (last 5 entries) for active constraints or deferred work.
4. **Route to the right module.** Use the decision table in `AGENT.md` to determine which files to load for the current task.

Do not start coding until all four steps are complete.

-----

## Compaction Survival Rules

These rules are here because CLAUDE.md is never compacted. If context runs low and MEMORY.md or IMPLEMENTATION.md get compacted, these rules survive:

- **Compaction order:** micro compact (clear stale tool results) → context collapse (summarize conversation) → session memory extraction (write to disk) → full compact (summarize everything) → PTL truncation (drop oldest, last resort). Always start with the lightest method.
- **Never compact:** system prompts, active safety flags, current workflow state, permission decisions, explicit user constraints, the active task specification, loaded DECISIONS.md entries.
- **Before discarding anything:** extract constraints, traps, and deferred work to `./tmp/session-memory/` so they survive the compaction.
- **If PTL truncation fires:** inform the user what was dropped. They may need to restate earlier constraints.
- **Serialized tools never run in parallel.** File writes, shell mutations, and git operations execute one at a time, even if they affect different files.
- **Mode enforcement:** agent type constraints are structural. Run `bash scripts/switch-mode.sh <mode>` to swap `.claude/settings.json`. Do not rely on instructional compliance alone.

-----

## Cross-Repo System Docs (Single Source of Truth)

All cross-system documentation lives in this repo under `docs/system/`. Before touching anything that crosses repo boundaries, read the relevant file:

| File | Read when… |
|------|-----------|
| `docs/system/00-system-overview.md` | Starting any session — system map, auth model, non-negotiable rules |
| `docs/system/01-data-contracts.md` | Touching the database — all table schemas across both backends |
| `docs/system/02-api-contracts.md` | Adding/changing any API endpoint or webhook |
| `docs/system/03-cross-repo-flows.md` | Touching any flow that spans multiple repos |
| `docs/system/04-env-and-services.md` | Adding env vars or integrating a new service |
| `docs/system/05-[feature].md` | Touching [primary feature] |
| `docs/system/06-[feature].md` | Touching [secondary feature] |
| `docs/system/07-ai-pipeline.md` | Touching AI processing |
| `docs/system/08-scheduling.md` | Touching scheduling and state machines |
| `docs/system/09-[domain-feature].md` | Touching [domain-specific feature] |

Other repos point here as their canonical system reference.

-----

## What [Project Name] Is

[Project Name] is a [brief product description] delivered through [N] surfaces with no native app required:

- **[Surface 1]** — primary interface. [How AI/automation communicates with users.]
- **[Surface 2]** — [Type A]: server-side triggered. [Type B]: client-side browser interaction.
- **[Surface 3]** — [description, e.g., tokenized web links sent via SMS.]

[Surface 1] + [Surface 2] + [Surface 3] = the whole product.

-----

## System Architecture

Three codebases work together:

| Repo | Location | Purpose |
|------|----------|---------|
| `[web-frontend]` | `/path/to/frontend` | React/Vite frontend — tokenized link destinations |
| `[backend-api]` | `/path/to/backend` | Node.js API — [primary engine], auth, [core domains] |
| `[ai-backend]` | `/path/to/ai-backend` | Python/FastAPI — [AI features] |

> The web app is never the initiator. It is always the **destination** of a link sent by the backend.

-----

## Tool Registry

Every capability the agent can invoke is classified here. This registry is the source of truth — if a tool is not listed, it does not exist.

### Tool Classification

| Tool | Type | Tier | Partitioning | Description |
|------|------|------|-------------|-------------|
| File read | Built-in | Allowed | Concurrent | Read file contents. No side effects. |
| File write | Built-in | Guarded | Serialized | Write/create files in working directory. Logged. |
| File delete | Built-in | Restricted | Serialized | Requires explicit approval every time. |
| Shell (read-only) | Built-in | Guarded | Concurrent | `ls`, `cat`, `grep`, `find`, `git status`, `git log`, `git diff` |
| Shell (mutating) | Built-in | Restricted | Serialized | `rm`, `mv`, `git commit`, `git push`, package installs |
| Search (codebase) | Built-in | Allowed | Concurrent | Grep, ripgrep, AST search |
| Search (web) | Built-in | Guarded | Concurrent | External web queries. Logged. |
| API call (read) | Plug-in | Guarded | Concurrent | GET requests to configured endpoints |
| API call (write) | Plug-in | Restricted | Serialized | POST/PUT/DELETE to any endpoint |
| [Custom tool] | Skill | [Tier] | [Partition] | [Description] |

**Tier definitions** (see `SAFETY.md` for enforcement):
- **Allowed:** No approval needed. Always available.
- **Guarded:** First-use approval per session, then auto-approved. Always logged. Revoked on safety flag.
- **Restricted:** Requires explicit approval. Never auto-approved.

**Partitioning rules** (see `IMPLEMENTATION.md` for execution):
- **Concurrent:** Read-only. Safe to run in parallel with other concurrent tools.
- **Serialized:** Mutating. Must run one at a time. Never parallelize.

> When classifying a new tool: if uncertain about tier, choose Restricted. If uncertain about partitioning, choose Serialized.

-----

## Repository Map

```
[project-root]/
├── CLAUDE.md                         ← YOU ARE HERE
├── AGENT.md                          ← Decision brain + workflow state + agent types
├── IMPLEMENTATION.md                 ← Build conventions, execution models, prompts
├── SAFETY.md                         ← Permission tiers, flags, escalation (always loaded)
├── MEMORY.md                         ← Compaction, session persistence, context budget
├── DECISIONS.md                      ← Append-only architectural decision log
│
├── modules/
│   ├── COMMUNICATION.md
│   ├── ONBOARDING.md
│   ├── MATCHING.md
│   ├── REENGAGEMENT.md
│   └── SAFETY.md                     ← Module-level safety (distinct from root SAFETY.md)
│
├── features/
│   └── FEATURE-SPEC-TEMPLATE.md      ← Spec template for new features
│
├── docs/
│   ├── features/                     ← Per-feature documentation
│   ├── architecture/
│   │   ├── stack.md
│   │   ├── data-schemas.md
│   │   └── context-engineering.md
│   └── system/                       ← Cross-repo system docs (source of truth)
│
└── src/
    ├── app/
    │   ├── routes.ts
    │   ├── screens/
    │   └── components/
    └── lib/
        ├── api.ts                    ← API client + TypeScript types
        ├── useAuth.ts                ← Auth state (JWT path — currently unused)
        └── useToken.ts               ← URL token extraction
```

-----

## Project Details

Screen inventory, web app flows, token system, and backend API details are in `PROJECT.md`. Load it when working on screens, routes, auth, or API integration.

-----

## Token Budget and Context Management

| Parameter | Default | Override |
|-----------|---------|----------|
| Context window | 200,000 tokens | Up to 1M (use sparingly) |
| System prompt budget | ≤6,000 tokens | CLAUDE.md + SAFETY.md combined |
| Module budget | ≤2,000 tokens per module | Load only what's needed |
| Tool result preview | 8 KB | Full result saved to disk |
| Compaction trigger | 70% of context window | See `MEMORY.md` for cascade |
| Max conversation turns | Configurable per session | Hard stop at limit |

**Token projection rule:** Before every API call, estimate input + projected output tokens. If the projection exceeds 90% of remaining budget, trigger compaction before proceeding. Never fire an API call that would exceed the budget.

**Large file protocol:** When a tool result exceeds 8 KB, save the full result to `./tmp/tool-results/[timestamp]-[tool].txt` and send only the first 8 KB as preview. Reference the file path for full access.

-----

## Prompt Cache Optimization

The following files form the **stable cache prefix** and must not change mid-session:

```
Stable prefix (cached after first API call):
  1. CLAUDE.md       ← system identity
  2. SAFETY.md       ← permission + safety rules

Variable suffix (changes per task):
  3. AGENT.md        ← loaded for routing decisions
  4. Module files    ← loaded based on routing
  5. Feature specs   ← loaded for specific features
```

Sub-agents spawned via Fork inherit the cached prefix at near-zero marginal cost. This makes parallel read-only analysis effectively free after the first call. See `IMPLEMENTATION.md` for sub-agent dispatch.

-----

## Non-Negotiable Rules

1. **`SAFETY.md` is always in context.** It runs alongside everything. It is not a module you route to.
2. **All data is append-only.** No `UPDATE` or `DELETE` on [core tables: users, matches, interactions].
3. **Surface adapter fires on every outbound message.** No raw content hits [delivery service] without formatting.
4. **Log before you send.** Append interaction record before dispatching. Never the reverse.
5. **One message per turn.** Never send two messages in one handler.
6. **Tokenized links carry intent, not state.** State lives in the DB. Expired session = re-exchange the same `web_token`.
7. **Serialized tools never run in parallel.** File writes, shell mutations, and git operations execute one at a time.
8. **Verify before completing.** No task is "done" until the verification protocol in `IMPLEMENTATION.md` passes.
9. **When in doubt, do less.** Ambiguous routing → safer action. Unsure whether to flag → flag. Unsure whether to advance → don't.

-----

## Module Loading Order

```
1. SAFETY.md          — always, first, never unloads
2. CLAUDE.md          — always (you're reading it)
3. AGENT.md           — loaded for routing/dispatch decisions
4. Primary module     — based on AGENT.md routing
5. PROJECT.md         — when working on screens, routes, auth, API
6. Feature spec       — if working on a specific feature
7. IMPLEMENTATION.md  — when writing or reviewing code
8. MEMORY.md          — when managing context or sessions
9. DECISIONS.md       — when making architectural decisions
```

-----

## Customization Checklist

When adapting this system for a new project, replace these across **all files**:

- [ ] `[Project Name]` — your product name
- [ ] `[yourdomain].com` — your domain
- [ ] `[your-backend]` — your backend service name
- [ ] `[org]/[repo]` — your GitHub org and repo
- [ ] `/path/to/[repo]` — actual local paths for all repos
- [ ] `[Surface 1/2/3]` — your actual delivery surfaces
- [ ] `[feature]` placeholders — in routes, screens, docs, and tool registry
- [ ] `[delivery service]` — Twilio, SendGrid, etc.
- [ ] `[CMS]` — your marketing site platform
- [ ] `[Auth service]` — Supabase, Firebase, Auth0, etc.
- [ ] `[AI model]` — GPT-4o, Claude, etc.
- [ ] Port number in local URL
- [ ] Core tables in append-only rule
- [ ] Screen inventory — add/remove to match actual screens
- [ ] Token types — adjust to your token model
- [ ] Tool registry — add project-specific tools
- [ ] `docs/system/05–09` filenames — rename to match your domains
- [ ] Permission tiers in `SAFETY.md` — adjust to your risk model

*This is the only customization checklist. All files reference this one.*

-----

*This file is the system identity for an AI coding agent operating across a multi-repo architecture. It loads every session and forms the stable cache prefix for prompt optimization.*
