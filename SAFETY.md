# SAFETY.md — [Project Name] Security & Permissions

> Always loaded. First file read after CLAUDE.md. Never unloads. Not a module — runs alongside everything.

-----

## Permission Tier Model

Every tool and operation is assigned a tier. Tier assignment lives in the Tool Registry (`CLAUDE.md`). Enforcement happens here.

### Tier Definitions

| Tier | Approval Required | Logging | Auto-Revoke on Flag | Examples |
|------|------------------|---------|---------------------|----------|
| **Allowed** | Never | Optional | No | File read, codebase search, git status |
| **Guarded** | First use per session, then auto-approved | Always | Yes | File write (working dir), shell read-only, web search |
| **Restricted** | Every single invocation | Always | Yes — and stays revoked until human clears | File delete, shell mutating, git push, API write, anything outside working dir |

### Tier Escalation Rules
- A tool can be escalated to a higher tier (Allowed → Guarded → Restricted) by safety flags, but never de-escalated during a session.
- If a safety flag fires, all Guarded tools are immediately revoked until the flag is cleared.
- Restricted tools are never auto-approved, regardless of settings.json configuration. The bypass permission mode can override this — but bypass mode should only be used in CI/CD pipelines, never in interactive sessions.

-----

## Permission Modes

Three operational modes govern how approvals are handled:

| Mode | Behavior | Use When |
|------|----------|----------|
| **Interactive** (default) | Every Restricted action requires human approval. Guarded actions require first-use approval. | Normal development sessions with a human in the loop. |
| **Allow Edits** | Automatically approves Guarded actions in the working directory. Restricted still requires approval. | Trusted sessions where file writes are expected and routine. |
| **Bypass** | No permission checks. All tiers auto-approved. | CI/CD pipelines only. Never for interactive sessions. Logged as bypass. |

**Mode is set at session start** via `settings.json` or explicit user instruction. It cannot be changed by the agent mid-session. Only a human can change the mode.

### Permission State Persistence
Approved permissions are saved to prevent permission fatigue:

```json
// settings.json (or equivalent)
{
  "permission_mode": "allow_edits",
  "approved_patterns": {
    "file_write": ["src/**", "tests/**", "docs/**"],
    "shell_readonly": ["ls", "cat", "grep", "find", "git status", "git log", "git diff"],
    "shell_mutating": []
  },
  "denied_patterns": {
    "file_write": ["*.env", "*.key", "*.pem", "settings.json"],
    "file_delete": ["*"],
    "shell_mutating": ["rm -rf *", "drop table", "truncate"]
  }
}
```

> Denied patterns always override approved patterns. If a path matches both, it is denied.

-----

## Pre-Classification Logic

Before any tool executes, classify the operation:

```
Is this operation read-only?
  ├─ Yes → Check tier. If Allowed, proceed. If Guarded, check session approval.
  └─ No (mutating) → Run Destruction Detection.
                       ├─ Destructive → Escalate to Restricted regardless of default tier.
                       └─ Non-destructive mutation → Check tier normally.
```

### Destruction Detection

A mutating operation is **destructive** if any of the following are true:

| Check | Destructive If… |
|-------|-----------------|
| **Data loss** | Deletes files, drops tables, truncates data, overwrites without backup |
| **Irreversibility** | `git push --force`, `git rebase` on shared branch, deployed migration rollback |
| **Scope expansion** | Affects files outside the working directory |
| **Credential exposure** | Writes secrets, tokens, or keys to unencrypted files or logs |
| **External side effects** | Sends emails, posts to APIs, triggers webhooks, publishes packages |

If any check is true, the operation is **Restricted regardless of its default tier** and requires explicit human approval even in Allow Edits mode.

-----

## Safety Flag Protocol

A safety flag represents a condition where continued automated execution carries unacceptable risk.

### Flag Triggers
| Category | Trigger | Severity |
|----------|---------|----------|
| **Content** | User message contains harmful/abusive content | P0 |
| **Data integrity** | Agent attempts UPDATE/DELETE on append-only table | P0 |
| **Scope violation** | Agent attempts to modify files outside working directory | P0 |
| **Credential leak** | Agent attempts to log, display, or transmit secrets | P0 |
| **Infinite loop** | Agent has repeated the same tool call 3+ times with identical inputs | P1 |
| **Budget overrun** | Token projection exceeds 95% of remaining budget | P1 |
| **Verification failure** | Level 2 harness verification fails | P1 |
| **Anomalous pattern** | Agent behavior deviates significantly from the plan it proposed | P2 |

### Flag Response Protocol

```
Flag detected
  → Log flag immediately (category, severity, context, timestamp)
    → Set workflow state to `paused`
      → Revoke all Guarded tool permissions
        → Send neutral response to user: "I've paused to review something. [Brief description of flag.]"
          → Wait for human decision:
              ├─ Clear flag → Restore permissions, resume workflow
              ├─ Modify approach → Update plan, resume in `planning` state
              └─ Abort → Set state to `rolled_back` or `idle`
```

**Critical rule:** The agent never auto-resumes after a safety flag. A human must explicitly clear, modify, or abort.

-----

## Append-Only Enforcement

These tables are structurally protected. The agent must never generate SQL or ORM calls that include `UPDATE` or `DELETE` on these tables:

| Table | Allowed Operations | Prohibited Operations |
|-------|-------------------|----------------------|
| `users` | INSERT, SELECT | UPDATE, DELETE |
| `sessions` | INSERT, SELECT | UPDATE, DELETE |
| `interactions` | INSERT, SELECT | UPDATE, DELETE |
| `matches` | INSERT, SELECT | UPDATE, DELETE |
| `flags` | INSERT, SELECT | UPDATE, DELETE |

> Add your actual core tables. The principle: state history is never rewritten.

If the agent generates code containing UPDATE or DELETE on a protected table:
1. Flag immediately (P0, data integrity).
2. Do not execute the code.
3. Present the violation to the human.

-----

## Audit Trail

Every permission decision is logged as a structured record:

```json
{
  "timestamp": "2025-01-15T14:32:01Z",
  "session_id": "abc-123",
  "tool": "shell_mutating",
  "command": "git push origin main",
  "tier": "restricted",
  "classification": "destructive:irreversibility",
  "decision": "approved",
  "decided_by": "human",
  "mode": "interactive",
  "context": "Pushing reviewed PR #47 after passing verification"
}
```

Audit records are appended to `./logs/permission-audit.jsonl`. They are never modified or deleted.

### Audit Queries
The audit trail must support these queries:
- "What Restricted actions were approved in the last session?"
- "How many safety flags have fired this week?"
- "What commands were run in Bypass mode?"

-----

## Permission Handler Contexts

Different execution contexts require different approval flows:

| Handler | Used When | Approval Flow |
|---------|-----------|---------------|
| **Interactive** | Human is actively watching and responding | Prompt human, wait for response |
| **Coordinator** | This agent is being orchestrated by a parent agent | Parent agent approves via mailbox protocol. Human must have pre-approved the parent's authority in settings.json. |
| **Autonomous** | Running in CI/CD or scheduled execution | All actions must be pre-approved in settings.json. Anything not pre-approved fails closed (denied, not prompted). |

> Start with Interactive. Add Coordinator when you implement sub-agent orchestration. Add Autonomous only when you have CI/CD pipelines that invoke the agent.

-----

## Security Checklist (Run on Every Harness Change)

- [ ] Restricted tools still require approval in Interactive mode
- [ ] Safety flag pauses execution and revokes Guarded tools
- [ ] Append-only tables reject UPDATE/DELETE in generated code
- [ ] Files outside working directory trigger scope violation flag
- [ ] Token budget halt fires before 100% consumption
- [ ] Bypass mode is logged distinctly in audit trail
- [ ] Denied patterns override approved patterns
- [ ] Destruction detection catches all five categories
- [ ] Agent cannot change its own permission mode mid-session

-----

*This file is the security layer. It loads first, runs always, and never unloads. It is not a module you route to — it is a persistent background process that intersects every other operation.*
