# AGENT.md — [Project Name] Decision Brain

> Read after CLAUDE.md. Routing, state, dispatch.

-----

## The 7 Rules

**Rule 1: Surface first, content second.**
Determine the delivery surface before composing any message. [Surface A], [Surface B], and web have different constraints. Correct content on the wrong surface is a failed action.

**Rule 2: One message per turn. Always.**
One outbound message per inbound event. Never batch. Never follow up before receiving a reply.

**Rule 3: Safety before flow logic.**
Every inbound message is scanned by `SAFETY.md` before any flow logic runs. A flag pauses everything.

**Rule 4: Log before you send.**
Interaction record is appended before the [delivery service] call is made. Never the reverse.

**Rule 5: Tokenized links carry intent, not state.**
Links tell the web app what to show and who is viewing. State lives in the database. Expired session = re-exchange the same `web_token` (tokens don't expire — sessions do).

**Rule 6: Append only.**
No `UPDATE` or `DELETE` on [core tables: users, sessions, interactions, matches, flags]. Ever.

**Rule 7: When in doubt, do less.**
Ambiguous routing → safer action. Unsure whether to flag → flag. Unsure whether to advance a flow → don't.

-----

## Workflow State Machine

Every task moves through explicit states. No implicit transitions.

```
                    ┌──────────────────────────────────┐
                    │                                  │
                    ▼                                  │
idle ──→ planning ──→ awaiting_approval ──→ executing ──→ verifying ──→ complete
                    │         │                │              │
                    │         │                │              │
                    ▼         ▼                ▼              ▼
                  failed   rejected     partially_complete  verification_failed
                    │                        │                    │
                    ▼                        ▼                    ▼
              rolling_back          awaiting_decision       re_executing
                    │                        │                    │
                    ▼                        ▼                    │
              rolled_back              (human decides)           │
                                                                 │
                                      ┌──────────────────────────┘
                                      ▼
                                  verifying (re-enters)
```

### State Definitions

| State | Meaning | Allowed Transitions |
|-------|---------|-------------------|
| `idle` | No active work. Waiting for input. | → `planning` |
| `planning` | Analyzing task, reading context, forming approach. No mutations. | → `awaiting_approval`, → `failed` |
| `awaiting_approval` | Plan formed. Waiting for human sign-off on mutating actions. | → `executing`, → `rejected` |
| `executing` | Actively running tools (writes, shell, API calls). | → `verifying`, → `partially_complete`, → `failed` |
| `verifying` | Checking work against acceptance criteria. Read-only. | → `complete`, → `verification_failed` |
| `complete` | Work passes verification. Task done. | → `idle` |
| `failed` | Unrecoverable error during planning or execution. | → `rolling_back`, → `idle` (with error report) |
| `partially_complete` | Some steps succeeded, others failed. System is in mixed state. | → `awaiting_decision` |
| `awaiting_decision` | Ambiguous failure. Needs human judgment on how to proceed. | → `executing` (retry), → `rolling_back`, → `idle` (abandon) |
| `rolling_back` | Reverting mutations from failed execution. | → `rolled_back` |
| `rolled_back` | Rollback complete. System restored to pre-execution state. | → `idle` |
| `verification_failed` | Work completed but doesn't pass checks. | → `re_executing` (fix), → `awaiting_decision` |
| `rejected` | Human rejected the plan. | → `planning` (revise), → `idle` (abandon) |

**Crash recovery:** If the system crashes in any state, resume protocol (see `MEMORY.md`) restores to the last checkpointed state. Execution-state crashes resume at `partially_complete` to force verification before proceeding.

-----

## Agent Type System

Not every task requires the same agent profile. Constrained types prevent capability leakage.

| Type | System Role | Allowed Tools | Prohibited Tools | Use When |
|------|------------|---------------|-----------------|----------|
| `explore` | Read-only analysis and investigation | File read, search, web fetch | File write, shell mutate, git push | Understanding code, researching, reading docs |
| `plan` | Strategy and approach formation | File read, search | File write, shell execute, git anything | Forming implementation plans, writing specs |
| `implement` | Code writing and mutation | All tools per permission tier | None (tier-gated) | Writing code, editing files, running tests |
| `verify` | Validation and testing | File read, shell (read-only), test runners | File write, git push | Running tests, reviewing output, checking criteria |
| `guide` | Explanation and teaching | File read, search | All mutating tools | Explaining concepts, documenting decisions |

**Type enforcement is structural.** An `explore` agent physically cannot write files — the tool is not in its pool, not merely discouraged. See `IMPLEMENTATION.md` (Dynamic Tool Pool Assembly) for how pools are constructed per type.

**Default type is `explore`.** Escalate to `plan` or `implement` only when the task requires it. This prevents accidental mutations during investigation.

-----

## Decision Table

| Trigger | Module | Step 1 | Step 2 | Step 3 | Output |
|---------|--------|--------|--------|--------|--------|
| User sends first message (inbound [Surface A]) | `ONBOARDING.md` | `POST /api/[webhook]` receives message | Agent determines: `action_now`, `schedule`, or `respond_only` | Deliver reply OR initiate outbound action | Message sent + history updated |
| Immediate action requested during onboarding | `ONBOARDING.md` | `initiateOutbound[Action]()` calls service API | Service places [channel] to user | Dynamic variables passed to agent | Action active |
| Scheduled callback time reached | `ONBOARDING.md` | Cron calls `execute[Callbacks]()` | Distributed lock acquired | `initiateOutbound[Action]()` fired | Action placed or retry scheduled |
| Tokenized link opened | `COMMUNICATION.md` | `useToken.ts` extracts token from URL | `POST /api/web/user/:token/session` | Route to correct screen per `routes.ts` | Web view shown |
| Session expired | `COMMUNICATION.md` | `useAuth.ts` detects 401 | Re-exchange using same `web_token` | New session stored in `sessionStorage` | Session refreshed |
| Browser-based interaction flow | `COMMUNICATION.md` | User opens `/[feature]/:token` | Consent modal → interaction initialized | Service interaction in browser | Interaction active |
| Both users mutual action | `MATCHING.md` | `action()` called for second user | Result instance auto-created | Notifications sent to both | Instance created, next flow begins |
| Scheduling action | `MATCHING.md` | `POST /[domain]/[instances]/:id/action` | State updated in instance | Notification sent if needed | UI state advances |
| Primary event ends — follow-up | `REENGAGEMENT.md` | Cron `processAllEscalations()` | T+0h: prompt message sent | T+Nh nudge, T+Nh discussion, T+Nd auto-close | Message sent (not high-cost channel) |
| Unconfirmed action N hours+ | `REENGAGEMENT.md` | `processAll[Action]Nudges()` | Check nudge timestamp is null | Send nudge to relevant users | Message sent |
| Safety flag triggered | `SAFETY.md` | Log flag immediately | Pause active session | Send neutral response | Human review queued |
| User sends STOP / opt-out | `COMMUNICATION.md` | Delivery service handles automatically | No application-layer action | No confirmation message | User opted out |
| **Agent crashes mid-execution** | `MEMORY.md` | Load session JSONL to last checkpoint | Restore workflow state to `partially_complete` | Present state to user for decision | Session resumed |
| **Context budget at 70%** | `MEMORY.md` | Trigger micro compact (clear stale tool results) | If still >70%, trigger context collapse | Log compaction event | Context freed |
| **Context budget at 90%** | `MEMORY.md` | Trigger full compact (summarize all history) | Extract session memory to file | Resume with compressed context | Session preserved |

-----

## Sub-Agent Dispatch Protocol

When a task benefits from parallel work, use sub-agents. Three models available:

### Fork (Cache-Optimized Parallelism)
- **Use when:** Task is read-only (analysis, research, review).
- **How:** Sub-agent inherits parent's cached prefix. Runs against same files.
- **Cost:** Near-zero marginal — shared prompt cache means only the unique instruction is billed.
- **Merge:** Each fork returns a concise report. Parent synthesizes.
- **Risk:** None — read-only operations cannot conflict.

### Worktree (Isolated Write Parallelism)
- **Use when:** Multiple independent code changes needed simultaneously.
- **How:** Each sub-agent gets an isolated git branch. Works independently.
- **Cost:** Full context per agent (no cache sharing across branches).
- **Merge:** Standard git merge. Conflicts resolved by parent or human.
- **Risk:** Merge conflicts on shared files. Use only when changes are to different files.

### Teammate (Long-Running Independent Work)
- **Use when:** Task is independent and long-running (e.g., building a test suite while implementing a feature).
- **How:** Runs in separate pane (tmux/iTerm). Communicates via file-based mailbox (`./tmp/mailbox/[agent-id].jsonl`).
- **Cost:** Full independent context. No cache sharing.
- **Merge:** Mailbox files are append-only. Parent reads completed messages.
- **Risk:** Stale context — teammate doesn't see parent's changes in real time.

### Dispatch Decision Tree

```
Is the task read-only?
  ├─ Yes → Fork (inherit cache, run parallel, synthesize reports)
  └─ No → Does it write to the same files as another active task?
           ├─ Yes → Serialize (do not parallelize)
           └─ No → Is it long-running and independent?
                    ├─ Yes → Teammate (separate pane, mailbox)
                    └─ No → Worktree (isolated branch, merge on complete)
```

### Standard Sub-Agent Decomposition

For complex tasks, the default decomposition is:

```
Parent spawns:
  Fork 1: Root-cause analysis (read-only)
  Fork 2: Regression test identification (read-only)
  Fork 3: Impact assessment (read-only)

Parent synthesizes fork reports, then:
  Implement agent: Fix implementation (serialized writes)

After implementation:
  Fork 4: Verification (read-only test execution)
  Fork 5: Rollout notes (read-only documentation)
```

> Always run in plan mode first. Sub-agents return concise reports. Parent synthesizes and implements.

-----

## Priority Levels

| Level | Timing | Examples |
|-------|--------|----------|
| **P0** | Immediately | Safety flags, failed message delivery, opt-out handling, data corruption |
| **P1** | This session | Core action notifications, onboarding triggers, post-feature follow-up |
| **P2** | Today | Re-engagement nudges, stale entity follow-ups, non-critical bugs |
| **P3** | Backlog | Analytics, config updates, flow improvements, refactoring |

-----

## Compaction Trigger Logic

Context management is not optional. These triggers fire automatically:

| Trigger | Threshold | Action | Reference |
|---------|-----------|--------|-----------|
| Stale tool results | Every 5 turns | Micro compact: clear tool results older than 10 turns | `MEMORY.md` §1 |
| Context usage >70% | 70% of window | Context collapse: summarize conversation spans | `MEMORY.md` §2 |
| Context usage >85% | 85% of window | Session memory: extract key context to file | `MEMORY.md` §3 |
| Context usage >95% | 95% of window | Full compact: summarize entire history | `MEMORY.md` §4 |
| Hard limit reached | 100% of window | PTL truncation: drop oldest message groups (last resort) | `MEMORY.md` §5 |

> Compaction runs between turns, never mid-tool-execution. See `MEMORY.md` for what is never eligible for compaction.

-----

## Module Load Order

```
1. SAFETY.md          — always, first
2. Primary module     — based on routing decision
3. Data files         — only what the module references
4. surface-adapter    — on every outbound action
5. Log interaction    — before sending
```

-----

*This file is the decision brain. It routes triggers to modules, manages workflow state, dispatches sub-agents, and enforces priority ordering. Load it when making routing or architectural decisions.*
