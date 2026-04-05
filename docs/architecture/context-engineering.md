# Context Engineering — How This System Works

> This document explains the architecture of the enhanced Claude Code system for humans who need to understand, maintain, or extend it.

-----

## Core Principle

AI coding agents fail for one reason more than any other: they hallucinate architecture. They invent endpoints that don't exist, reference files that aren't there, use auth mechanisms that aren't active, and generate code that's structurally inconsistent with the codebase.

This system prevents that by giving the agent a deterministic mental model — a complete, accurate representation of the system it's operating in — and then constraining its behavior through explicit state machines, permission tiers, and verification protocols.

The agent reads the system files before it touches any code. It knows what exists, what's allowed, and what state it's in. When it doesn't know something, it has a structured way to say "I don't know" instead of making something up.

-----

## File Architecture

The system is layered by responsibility:

```
Identity Layer (always loaded):
  CLAUDE.md    — What the system is. Ground truth.
  SAFETY.md    — What's not allowed. Enforcement.

Decision Layer (loaded for routing):
  AGENT.md     — How to decide what to do.

Execution Layer (loaded for building):
  IMPLEMENTATION.md — How to build correctly.

Memory Layer (loaded for context management):
  MEMORY.md    — How to manage context lifecycle.

Record Layer (append-only):
  DECISIONS.md — What was decided and why.
```

### Why This Layering Matters

**Token economy.** Each file costs tokens to load. CLAUDE.md and SAFETY.md are always loaded (~4,000 tokens combined). Everything else loads on demand. A session that's just exploring code loads CLAUDE.md + SAFETY.md + AGENT.md ≈ 6,000 tokens of instructions, leaving ~194,000 tokens for actual work.

**Cache optimization.** CLAUDE.md + SAFETY.md form a stable prefix that gets cached by the API. Sub-agents spawned via Fork share this cache. The stable prefix never changes mid-session, so cache hit rate approaches 100% for parallel work.

**Single responsibility.** When the agent needs to make a routing decision, it reads AGENT.md. When it needs to write code, it reads IMPLEMENTATION.md. When context is full, it reads MEMORY.md. No file serves two masters.

-----

## How the Agent Operates

### Session Start
1. CLAUDE.md loads automatically (Claude Code native behavior).
2. SAFETY.md loads alongside it (explicitly instructed in CLAUDE.md).
3. The Quick-Start Protocol runs: confirm repo → check DECISIONS.md → route to module.
4. session-init.sh fires (if hooks are configured): reports branch, flags, decisions, memory.

### Task Execution
1. User describes a task.
2. Agent consults AGENT.md's decision table to route the task to a module.
3. Workflow state transitions from `idle` to `planning`.
4. Agent reads relevant module files and feature specs.
5. Agent forms a plan and presents it (if the task involves mutations).
6. On approval, state transitions to `executing`.
7. For each tool invocation:
   - Pre-classification: read-only or mutating?
   - If mutating: destruction detection (5 categories).
   - Tier check: Allowed → proceed. Guarded → log and proceed. Restricted → ask human.
   - Partitioning check: Concurrent → can run parallel. Serialized → must wait.
8. After execution, state transitions to `verifying`.
9. Two-level verification runs.
10. On pass, state transitions to `complete`.

### Failure Handling
- Tool call fails → state goes to `failed` → rollback if mutations occurred.
- Work doesn't pass verification → state goes to `verification_failed` → fix and re-verify.
- Crash mid-execution → session resumes from last checkpoint → state is `partially_complete`.
- Context runs out → compaction cascade fires → micro → collapse → session memory → full → truncate.

### Session End
- checkpoint.sh fires (if hooks configured): writes final state to session JSONL.
- Session can be resumed later with resume-session.sh.

-----

## Enforcement Model

The system has three enforcement levels:

### Structural Enforcement (Hardest)
- `.claude/settings.json` deny list blocks dangerous commands at the Claude Code level.
- `.githooks/pre-commit` blocks secrets and protected files from being committed.
- Agent type system removes tools from the pool — an explore agent can't write because the tool isn't there.

### Protocol Enforcement (Medium)
- Workflow state machine requires explicit transitions — the agent can't skip from `planning` to `complete`.
- Tool partitioning prevents parallel execution of serialized tools.
- Compaction cascade follows a defined order with specific thresholds.
- Safety flags revoke Guarded tool permissions until a human clears them.

### Instructional Enforcement (Softest)
- Non-negotiable rules in CLAUDE.md (append-only, log before send, one message per turn).
- Verification protocol in IMPLEMENTATION.md.
- The agent follows these because it's instructed to, not because it's mechanically prevented.

**The system is designed so that the most dangerous actions have the hardest enforcement.** File deletion is structurally blocked. Code style is instructionally guided. The gap between "structurally prevented" and "instructionally discouraged" is where you need to focus maintenance attention.

-----

## Extending the System

### Adding a New Tool
1. Add to the Tool Registry in CLAUDE.md (name, type, tier, partitioning, description).
2. If Restricted, add to the deny list in `.claude/settings.json`.
3. Add to the appropriate agent type pools in `project.settings.json`.
4. Log a DECISIONS.md entry if the tool changes the system's capability surface.

### Adding a New Module
1. Create `modules/[MODULE-NAME].md`.
2. Add a routing row to AGENT.md's decision table.
3. List the module in CLAUDE.md's module loading order.
4. Estimate token cost and add to context budget in MEMORY.md if it's large.

### Adding a New Slash Command
1. Create `.claude/commands/[command-name].md`.
2. Define the agent type constraints (what tools are allowed/prohibited).
3. Add to the README.md command table.

### Changing Permission Tiers
1. Update the Tool Registry in CLAUDE.md.
2. Update `.claude/settings.json` deny/allow lists.
3. Update `project.settings.json` agent type pools.
4. Run `bash scripts/verify-harness.sh` to confirm integrity.
5. Log a DECISIONS.md entry.

-----

## Known Limitations

1. **Instructional enforcement is soft.** The agent follows non-negotiable rules because it's told to, not because it's mechanically prevented. A sufficiently long or complex conversation can cause the agent to lose track of instructions. Compaction makes this worse by discarding context. The mitigation is that the highest-risk rules are in CLAUDE.md and SAFETY.md, which are never compacted.

2. **Token projection is imprecise.** Output token estimation is inherently uncertain. The 90% trigger provides a 10% margin, but edge cases exist where the actual output exceeds the estimate. The consequence is occasionally triggering compaction slightly later than ideal.

3. **Compaction is lossy.** Every compaction method except micro compact discards information that might be relevant later. Session memory extraction mitigates this by persisting important context to disk, but the extraction itself is an LLM judgment call that can miss things.

4. **Sub-agent context transfer is incomplete.** Fork agents inherit the cached prefix but don't inherit the full conversation history. They know the system architecture but not the specific discussion that led to the task. The parent's fork instruction must contain enough context for the fork to operate independently.

5. **Hook execution is not guaranteed.** Claude Code doesn't natively support the hook system defined in `project.settings.json`. Hooks are currently run manually or via git hooks. Full hook automation would require a custom harness wrapper.

-----

*This document is for humans who maintain the system. The agent reads CLAUDE.md, not this file.*
