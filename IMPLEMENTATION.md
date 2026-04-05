# IMPLEMENTATION.md — [Project Name] Build Manual

> Read when writing, reviewing, or shipping code. Not loaded every session — loaded when building.

-----

## Code Conventions

### General
- Follow the existing codebase structure exactly: schemas, tables, event naming, shapes, patterns.
- No TODOs in shipped code. If it's not ready, don't merge it.
- No placeholder logic, dead branches, or unused imports.
- Minimal diff. Pick the most sensible solution with minimal risk and minimal change surface.
- Do not over-engineer. Do not ship a quick hack. Find the middle.

### TypeScript / React
- All API types live in `src/lib/api.ts`. No inline type definitions in components.
- Components handle one concern. If a component file exceeds 300 lines, decompose it.
- State management uses the pattern already established in the codebase. Do not introduce new state libraries without an approved `DECISIONS.md` entry.
- Error boundaries exist. Use them. Every screen-level component catches and surfaces errors.

### Backend (Node.js / Python)
- All database operations go through the established ORM/query builder. No raw SQL unless the ORM cannot express the query.
- Migrations are forward-only. Never edit a deployed migration.
- Environment variables are documented in `docs/system/04-env-and-services.md` before use.
- API endpoints follow existing naming conventions. Check `docs/system/02-api-contracts.md` before adding.

-----

## Tool Partitioning

Tools are classified as **Concurrent** (read-only, parallelizable) or **Serialized** (mutating, sequential). This classification is enforced at the execution layer, not advisory.

### Concurrent Tools (Safe to Parallelize)
- File read / view
- Codebase search (grep, ripgrep, AST)
- Web search / fetch
- API GET requests
- Test execution (read-only — test runners that don't mutate state)
- Static analysis / linting (read-only mode)
- Git status, log, diff

### Serialized Tools (Must Execute One at a Time)
- File write / create / delete
- Shell commands that mutate state
- Git add, commit, push, merge, rebase, checkout
- API POST / PUT / DELETE requests
- Database operations (all types)
- Package installation (npm, pip, etc.)

### Partitioning Rules
1. When a concurrent and serialized tool need to run in sequence, the serialized tool always waits for any pending concurrent tools to complete first.
2. Multiple serialized tools never run simultaneously, even if they affect different files.
3. A tool that is read-only in one context but has side effects in another (e.g., a test runner that seeds a database) is classified as Serialized.
4. New tools default to Serialized until proven safe for concurrent execution.

-----

## Dynamic Tool Pool Assembly

Each agent type (defined in `AGENT.md`) receives a filtered subset of the tool registry. The pool is assembled at session start based on:

1. **Agent type** — determines base tool set (explore: read-only; implement: full)
2. **Permission tier** — filters out Restricted tools unless pre-approved in settings
3. **Active safety flags** — revokes Guarded tools if a flag is active
4. **Deny list** — project-specific tool exclusions (e.g., "never use [deprecated-tool]")

```
Full Registry (CLAUDE.md)
  → Filter by agent type
    → Filter by permission tier
      → Filter by safety flags
        → Filter by deny list
          = Session Tool Pool
```

If the agent needs a tool not in its current pool, it must:
1. State which tool it needs and why.
2. Request escalation to a higher-capability agent type.
3. Wait for human approval before the tool is added to the pool.

Never silently work around a missing tool.

-----

## Hook System

Hooks attach custom logic to agent lifecycle events without modifying core behavior.

### Event Points
| Event | Fires When | Common Uses |
|-------|-----------|-------------|
| `session-start` | New session begins or resumes | Load project context, check git status, validate environment |
| `pre-tool` | Before any tool executes | Validate inputs, check permissions, log intent |
| `post-tool` | After any tool completes | Format output, update state, trigger follow-up |
| `pre-commit` | Before git commit | Run linter, check for secrets, validate commit message |
| `session-end` | Session concludes or is paused | Extract session memory, write compaction summary, update DECISIONS.md |
| `compaction-trigger` | Context budget threshold crossed | Custom compaction logic, priority-based retention |

### Hook Types
| Type | Execution | Example |
|------|-----------|---------|
| Command | Runs a shell command | `pre-commit: npx lint-staged` |
| Function | Runs inline logic | `post-tool: updateTokenCount(result)` |
| Prompt | Injects text into next context | `session-start: "Current branch: $(git branch --show-current)"` |
| HTTP | Fires a webhook | `session-end: POST /api/agent/session-log` |

### Error Policy
- Hook failure **logs a warning** but **does not block** tool execution.
- Hooks are fail-open: the agent continues even if a hook errors.
- Exception: `pre-commit` hooks are fail-closed. A linting failure blocks the commit.

### Hook Registration
Hooks are defined in `settings.json` (or equivalent project config):
```json
{
  "hooks": {
    "pre-commit": [
      { "type": "command", "run": "npx lint-staged" },
      { "type": "command", "run": "npx secretlint" }
    ],
    "session-start": [
      { "type": "prompt", "inject": "Active branch: $(git branch --show-current)" }
    ]
  }
}
```

-----

## Two-Level Verification Protocol

No task is complete until both levels pass.

### Level 1: Output Verification (Does the work meet the spec?)

Run after every implementation task:

1. **Restate the target.** 3-6 bullets: what was the exact problem? What does "fixed" mean in observable terms?
2. **Walk the user journey.** Simulate the full flow step-by-step. For each step, verify:
   - UI state is correct
   - Network calls succeed
   - Errors are handled with good UX
   - Loading states are smooth
   - Nothing dead-ends
3. **Code correctness.** Verify:
   - No crashes, nil hazards, or invalid state assumptions
   - No unhandled promise rejections or async race conditions
   - Backend validations align with frontend constraints
   - Timeouts, retries, and error surfaces are sane
   - No unused code, dead branches, or placeholder logic
4. **Proof.** List the exact commands/tests you ran and their results. Provide a PASS/FAIL checklist.

### Level 2: Harness Verification (Are the guardrails intact?)

Run after any change to the agent system itself (CLAUDE.md, AGENT.md, SAFETY.md, hooks, permissions):

1. **Permission gates.** Do Restricted tools still require approval?
2. **Safety flags.** Does a triggered flag still pause execution?
3. **Token limits.** Does the system still halt at budget threshold?
4. **Append-only.** Are core tables still protected from UPDATE/DELETE?
5. **Serialization.** Are mutating tools still prevented from parallel execution?

> If Level 1 fails, fix the output. If Level 2 fails, stop everything and escalate.

-----

## Sub-Agent Execution Models

Detailed implementation for the dispatch protocol defined in `AGENT.md`.

### Fork Execution
```bash
# Parent creates a fork instruction file
echo '{"type": "fork", "task": "analyze root cause of issue #123", "tools": ["read-only"], "return": "concise report"}' > ./tmp/forks/fork-1.json

# Fork agent reads parent context (cached) + fork instruction
# Fork agent writes report to ./tmp/forks/fork-1-report.md
# Parent reads all fork reports and synthesizes
```

### Worktree Execution
```bash
# Create isolated worktree per agent
git worktree add ./tmp/worktrees/agent-1 -b agent-1/feature-name

# Agent works in isolated directory
# On completion, merge back
git checkout main
git merge agent-1/feature-name
git worktree remove ./tmp/worktrees/agent-1
```

### Teammate Execution
```bash
# Teammate runs in separate pane
# Communication via mailbox
echo '{"from": "parent", "task": "build test suite for auth module", "status": "assigned"}' >> ./tmp/mailbox/teammate-1.jsonl

# Teammate appends progress updates
echo '{"from": "teammate-1", "status": "in-progress", "note": "15 tests written, 3 remaining"}' >> ./tmp/mailbox/teammate-1.jsonl

# Parent polls mailbox for completion
tail -1 ./tmp/mailbox/teammate-1.jsonl
```

-----

## Streaming and Interruption

### Typed Event Stream
The agent emits structured events during execution:

| Event Type | Meaning | Action |
|-----------|---------|--------|
| `message_start` | Response generation begins | Display to user |
| `tool_match` | Agent is about to invoke a tool | Check permissions, log intent |
| `tool_result` | Tool execution completed | Display result or preview |
| `compaction_trigger` | Context threshold crossed | Run compaction cascade |
| `workflow_transition` | State machine transition | Log state change |
| `error` | Recoverable error occurred | Display and continue |
| `fatal` | Unrecoverable error | Save state, display reason, halt |

### Interruption Protocol
When a user interrupts mid-generation:
1. Immediately stop token generation.
2. If mid-tool-execution:
   - Read-only tool: discard result. No cleanup needed.
   - File write: check if write completed. If partial, delete the partial file and log the rollback.
   - Shell command: send SIGINT. Wait for graceful termination. If hung, SIGKILL after 5s.
   - Git operation: check repo state. If mid-commit, `git reset HEAD`. Log the rollback.
3. Set workflow state to `partially_complete` or `idle` depending on what completed before interruption.
4. Report to user what was completed and what was interrupted.

-----

## Feature Spec Template

Located at `features/FEATURE-SPEC-TEMPLATE.md`. Use this prompt to generate a build-ready spec:

> Turn this into a build-ready spec and then implement it. Include: user story, non-goals, API/data changes, UI states, edge cases, analytics, and acceptance criteria. Don't start coding until the spec is unambiguous.

```markdown
# Feature: [Feature Name]
**Date:** [YYYY-MM-DD]
**Status:** draft | approved | in-progress | shipped
**Author:** [Name]

## Problem
[What user problem does this solve? Why now?]

## User Story
As a [user type], I want [action] so that [outcome].

## Desired Outcome
[Observable behavior when this is working correctly.]

## Non-Goals
[What this feature explicitly does NOT do. Be specific.]

## Constraints
[Technical, timeline, dependency, or regulatory constraints.]

## API / Data Changes
| Change | Type | Details |
|--------|------|---------|
| [endpoint/table] | Add/Modify | [Specifics] |

## UI States
| State | Screen | Behavior |
|-------|--------|----------|
| Loading | [Screen] | [What shows] |
| Success | [Screen] | [What shows] |
| Error | [Screen] | [What shows and recovery path] |
| Empty | [Screen] | [What shows when no data] |

## Edge Cases
1. [Edge case and how it's handled]
2. [Edge case and how it's handled]

## Analytics
| Event | Trigger | Properties |
|-------|---------|-----------|
| [event_name] | [when it fires] | [key-value pairs] |

## Acceptance Criteria
- [ ] [Observable, testable criterion]
- [ ] [Observable, testable criterion]
- [ ] [Observable, testable criterion]

## Rollback Plan
[How to revert if this causes problems in production.]
```

-----

## Battle-Tested Prompts

### Sub-Agent Decomposition
Use when you want parallelism without blowing up your main context:

> Use subagents. Split into: (1) root-cause analysis, (2) fix implementation plan, (3) regression tests, (4) rollout notes. Each subagent returns a concise report, then you synthesize and implement. Do this in plan mode.

### End-to-End Production Review
Use at least once a day on any active implementation:

> You have one job: Review your work end-to-end and ensure it ACTUALLY fixes the exact problem identified, for real users, in production. You are not allowed to call anything "complete" unless:
> 1. It fixes the problem identified (not adjacent improvements).
> 2. It is production ready (no errors, no TODOs, no "later" steps, no missing wiring).
> 3. It works out of the box, end-to-end, from the user's perspective, with a unicorn-level UX.
> 4. Logging is optional and must not distract from the actual fix.
>
> Step 1: Restate the target (3-6 bullets, no scope creep).
> Step 2: Walk the user journey end-to-end (verify UI, network, errors, loading, dead-ends).
> Step 3: Code correctness and production polish (crashes, race conditions, validations, unused code).
> Step 4: Proof (exact commands/tests run, PASS/FAIL checklist).
> Output: "What I checked" → "What I fixed" → "End-to-end verification results" → "Remaining risks."

### Self-Grill (Strict Reviewer Mode)
Use at least once a day:

> [Role: Act as a strict reviewer.] Grill yourself on these changes and do not create a PR until you pass. Ask yourself questions about edge cases, rollback safety, observability, and user impact. If anything is weak, tell me what to change. Then break into PRs to resolve the issues.

### Elegant Rebuild
Use when complexity has accumulated beyond the value of incremental fixes:

> Knowing everything you know now, scrap this and implement the elegant solution. Constraints: keep public APIs stable, minimize churn, and leave the codebase simpler than before. Show me the before/after design in 8-12 bullets.

### Adversarial QA Anchor
Add to any review or implementation prompt for higher-quality output:

> Assume an independent reviewer will audit this work. They have full codebase access and will flag: silent failures, untested paths, scope creep, unnecessary complexity, and any claim of "complete" that isn't verifiable.

-----

*This file is the build manual. Load it when writing code, reviewing implementations, or shipping features. It governs how tools execute, how work is verified, and how features are specified.*
