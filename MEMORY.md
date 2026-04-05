# MEMORY.md — [Project Name] Context & Session Management

> Read when managing context, resuming sessions, or when compaction triggers fire.

-----

## Context Budget

| Parameter | Default | Notes |
|-----------|---------|-------|
| Context window | 200,000 tokens | Extend to 1M only for large analysis tasks |
| System prompt reserve | 6,000 tokens | CLAUDE.md + SAFETY.md — never compacted |
| Module reserve | 2,000 tokens per loaded module | Compacted only via session memory extraction |
| Working context | Remaining tokens after reserves | Where conversation, tool results, and reasoning live |
| Tool result preview limit | 8 KB | Full results saved to `./tmp/tool-results/` |
| Compaction trigger | 70% of working context | Begins cascade at this threshold |
| Hard ceiling | 95% of total window | Forces full compact; 100% forces PTL truncation |

### Token Projection Protocol

Before every API call:
1. Calculate current input tokens (system prompt + conversation + tool results).
2. Estimate output tokens (use 2x the average of the last 5 outputs, or 1,000 tokens if no history).
3. If (current + estimated output) > 90% of remaining budget → trigger compaction before proceeding.
4. If (current + estimated output) > 100% of remaining budget → halt with structured error. Do not fire the API call.

> The 90% trigger gives a 10% margin for estimation error. Never project at 100% — output length is inherently uncertain.

-----

## Compaction Cascade

Five methods, ordered from least to most aggressive. Always start with the lightest method. Escalate only if the lighter method doesn't free enough context.

### §1 — Micro Compact (Lightest)

**Trigger:** Every 5 turns, or when context > 70%.
**What it does:** Clears tool results older than 10 turns.
**What it preserves:** The agent's summary/interpretation of the tool result (in its response). Only the raw tool output is cleared.
**Risk:** Low. The agent already processed these results and incorporated findings.

```
Before: [system] [msg1] [tool-result-1: 3000 tokens] [msg2] [msg3] [tool-result-2: 5000 tokens] [msg4] ...
After:  [system] [msg1] [msg2] [msg3] [tool-result-2: 5000 tokens] [msg4] ...
         (tool-result-1 cleared because it's > 10 turns old)
```

### §2 — Context Collapse (Moderate)

**Trigger:** Context > 70% after micro compact.
**What it does:** Summarizes spans of conversation into compressed representations.
**What it preserves:**
- All system prompts (CLAUDE.md, SAFETY.md content)
- All decision points and their rationale
- All state transitions (workflow state changes)
- The last 5 turns of conversation verbatim
**What it compresses:** Intermediate reasoning, exploratory conversation, superseded approaches.
**Risk:** Moderate. The summary is lossy. A rejected approach might be re-attempted if the rejection reasoning is lost.

**Mitigation:** Before collapsing, extract explicit "do not repeat" items into session memory (§3).

### §3 — Session Memory Extraction

**Trigger:** Context > 85%, or at natural breakpoints (feature complete, branch merged, end of session).
**What it does:** Writes a structured summary file to disk that can be loaded in future sessions.
**Where it writes:** `./tmp/session-memory/[session-id]-[timestamp].md`
**Format:**

```markdown
# Session Memory — [Session ID]
**Date:** [timestamp]
**Task:** [brief description]
**Status:** [workflow state at time of extraction]

## Key Decisions
- [Decision and rationale]
- [Decision and rationale]

## Constraints Discovered
- [Constraint that must be respected in future work]
- [Constraint that must be respected in future work]

## Traps and Anti-Patterns
- [Thing that was tried and failed, with reason]
- [Thing that looks tempting but is wrong, with reason]

## Deferred Work
- [Task that was identified but not completed, with context]

## State Summary
- [Current state of relevant files/systems]
- [Pending changes or open branches]
```

**What it preserves in context:** Only the "Constraints Discovered" and "Traps and Anti-Patterns" sections are kept in the active context. Everything else is offloaded to the file.
**Risk:** Low if extraction is thorough. High if extraction misses a critical constraint.

### §4 — Full Compact (Aggressive)

**Trigger:** Context > 95%.
**What it does:** Summarizes the entire conversation history into a compressed state document.
**Target size:** 2,000-3,000 tokens (roughly 1-2% of the original context).
**What it preserves:**
- System prompts (verbatim, never compressed)
- Current workflow state
- Active constraints and decisions
- The current task specification
- The last 3 turns of conversation
**What it discards:** All intermediate reasoning, exploration, and completed sub-tasks.
**Risk:** High. This is a lossy operation that discards 98%+ of context. Use only when necessary.

**Required action:** Before full compact, always run session memory extraction (§3) to persist important context to disk.

### §5 — PTL Truncation (Last Resort)

**Trigger:** Context at 100% hard ceiling after full compact.
**What it does:** Drops the oldest message groups until context is below 90%.
**What it never drops:**
- System prompts (CLAUDE.md, SAFETY.md)
- The current task specification (first user message in the active task)
- Active workflow state
- Any message containing an explicit constraint or non-negotiable rule
**What it drops first:** Oldest conversational turns, starting from the beginning.
**Risk:** Very high. This is blunt truncation. Important early-conversation context will be lost.

**Required action:** If PTL truncation fires, the agent must immediately inform the user:
> "Context limit reached. I've preserved system instructions and recent work, but older conversation context has been dropped. You may need to re-state earlier constraints if they're still relevant."

-----

## What Is Never Eligible for Compaction

These items are permanently protected across all compaction levels:

| Category | Reason |
|----------|--------|
| System prompts (CLAUDE.md + SAFETY.md content) | Agent identity and safety rules |
| Active safety flags | Must persist until human clears them |
| Current workflow state | Agent must know where it is |
| Permission decisions made this session | Cannot re-prompt for already-decided permissions |
| Explicitly stated user constraints | "Never modify file X" type instructions |
| The active task specification | Agent must know what it's working on |
| Entries from DECISIONS.md loaded this session | Architectural constraints remain binding |

-----

## Session Persistence

### Format: JSONL (Newline-Delimited JSON)

Each session is stored as a JSONL file at `./sessions/[session-id].jsonl`. Each line is a complete, self-contained record.

### Record Schema

```json
{
  "type": "message | tool_call | tool_result | state_transition | compaction | flag | permission | checkpoint",
  "timestamp": "ISO 8601",
  "session_id": "uuid",
  "sequence": 1,
  "data": {
    // Varies by type
  }
}
```

### Record Types

| Type | Data Fields | Purpose |
|------|-----------|---------|
| `message` | `role`, `content`, `token_count` | Conversation turn |
| `tool_call` | `tool`, `inputs`, `tier`, `approved_by` | Tool invocation |
| `tool_result` | `tool`, `output_preview`, `full_result_path`, `token_count` | Tool output (preview only; full result at path) |
| `state_transition` | `from_state`, `to_state`, `reason` | Workflow state change |
| `compaction` | `method`, `tokens_before`, `tokens_after`, `items_removed` | Compaction event |
| `flag` | `category`, `severity`, `context`, `resolution` | Safety flag |
| `permission` | `tool`, `decision`, `decided_by`, `mode` | Permission audit |
| `checkpoint` | `workflow_state`, `loaded_modules`, `active_flags`, `token_usage` | Resumable snapshot |

### Checkpoint Frequency
A checkpoint record is written:
- After every workflow state transition
- Before and after every compaction
- At session end (whether normal or crash)
- Every 10 turns as a safety net

-----

## Session Resume Protocol

When resuming a session after a crash, closure, or pause:

1. **Load the JSONL file** for the session.
2. **Find the last checkpoint record.** This is the recovery point.
3. **Reconstruct state from checkpoint:**
   - Workflow state → set to checkpoint's `workflow_state`
   - Loaded modules → reload from checkpoint's `loaded_modules`
   - Active flags → restore from checkpoint's `active_flags`
   - Token usage → restore from checkpoint's `token_usage`
4. **If the last record before checkpoint was a `tool_call` without a matching `tool_result`:**
   - The tool was mid-execution when the crash occurred.
   - Set workflow state to `partially_complete`.
   - Present to user: "Session resumed. A [tool] operation was in progress when the session ended. Would you like to retry it or skip?"
5. **Load session memory files** from `./tmp/session-memory/` for this session ID. Inject the "Constraints Discovered" and "Traps" sections into context.
6. **Inform the user** of the resume: "Session [ID] resumed from [state]. Last completed action: [description]."

### Fork and Resume

Sessions can be forked for exploration:
```bash
# Fork a session at a specific checkpoint
cp ./sessions/session-abc.jsonl ./sessions/session-abc-fork-1.jsonl
# Truncate to the desired checkpoint
# New work appends to the fork file
```

The original session is untouched. Multiple forks can explore different approaches.

-----

## Memory Decay and Review

Session memory files and decision records accumulate over time. Without maintenance, they become stale.

### Review Cadence
| Content | Review Every | Action |
|---------|-------------|--------|
| Session memory files | 30 days | Archive or delete sessions older than 30 days unless explicitly preserved |
| DECISIONS.md entries | 90 days | Mark entries as `superseded` or `deprecated` if no longer relevant |
| Permission audit logs | 7 days | Rotate logs older than 7 days to archive storage |
| Trap/anti-pattern lists | On every feature ship | Remove traps that have been structurally resolved (not just worked around) |

### Status Lifecycle for Persistent Records
```
proposed → accepted → active → superseded → deprecated → archived
```

Records in `superseded` or `deprecated` status are eligible for compaction and archival. Records in `active` status are never compacted.

-----

*This file governs how context is managed, how sessions persist, and how the agent recovers from interruptions. Load it when context budget alerts fire or when resuming a session.*
