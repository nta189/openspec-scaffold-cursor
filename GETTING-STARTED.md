# Getting Started

This guide walks you through your first session with the Enhanced Claude Code System. No prior experience with context engineering required.

-----

## What This System Does

When you use Claude Code without this system, the agent guesses your architecture, invents endpoints that don't exist, and writes code that's structurally inconsistent with your codebase. This system prevents that by giving the agent a complete mental model of your project before it writes a line of code.

It also adds safety constraints (so the agent can't delete your database), workflow tracking (so it knows where it is in a task), context management (so it doesn't lose important information in long sessions), and repeatable workflows (so you stop retyping the same prompts).

-----

## Setup (5 minutes)

```bash
# 1. Copy the system files into your project root
#    (or clone the repo and copy the files)

# 2. Run bootstrap — creates directories, installs git hooks, validates setup
chmod +x bootstrap.sh
./bootstrap.sh

# 3. The bootstrap script will flag uncustomized placeholders.
#    Open CLAUDE.md and replace all [bracketed placeholders]
#    with your actual project details. The checklist is at the bottom.

# 4. That's it. Start Claude Code in your project directory.
#    It reads CLAUDE.md automatically.
```

-----

## Your First Session

Open Claude Code in your project directory. The agent reads CLAUDE.md automatically and knows your architecture.

### Step 1: Check system status

Type:
```
/status
```

The agent will report: current branch, safety flags, recent decisions, context budget, and session memory. This is how you confirm the system is loaded and working.

### Step 2: Explore your codebase (read-only)

Type:
```
/explore
```

The agent switches to **explore mode**. It can read files, search code, and trace logic — but it **cannot write, create, or delete files**. This isn't a suggestion; the tool is structurally removed from its capabilities via the settings file.

Try asking it something about your code:
- "Trace the auth flow from login to the first authenticated API call"
- "What files would be affected if I changed the user schema?"
- "Find all places where we handle API errors"

Notice the agent navigates your codebase accurately — it knows the repo structure, the file paths, and the patterns because CLAUDE.md told it.

### Step 3: Plan a change

Type:
```
/plan
```

The agent switches to **plan mode**. Still read-only, but now focused on producing a structured implementation plan.

Try:
- "Plan how to add email notifications when a user's match is confirmed"

The agent will produce: problem statement, ordered steps, files to modify, edge cases, and acceptance criteria. It does this without touching any code.

### Step 4: Implement

When you're happy with the plan, type:
```
/implement
```

The agent switches to **implement mode**. Full tool access, but gated by permission tiers:
- Writing files in `src/` → auto-approved
- Running shell commands → depends on the command
- Deleting files → requires your explicit approval every time
- Anything touching core database tables → structurally blocked

The agent will work through the plan, write code, and then tell you it needs to verify.

### Step 5: Verify

Type:
```
/verify
```

The agent switches to **verify mode** (read-only plus test execution). It runs the two-level verification protocol:
- **Level 1:** Does the code actually fix the problem? Walk the user journey, check correctness, provide proof.
- **Level 2:** Are the safety guardrails still intact? (Only runs if system files were changed.)

You'll get a PASS/FAIL checklist. If anything fails, the agent tells you what needs fixing.

### Step 6: Review before merging

Type:
```
/grill
```

The agent becomes an adversarial reviewer of its own work. It checks edge cases, rollback safety, observability, and user impact. It gives you a PR readiness verdict: READY or NOT READY with specific issues.

-----

## The Slash Commands at a Glance

| Command | What it does | When to use it |
|---------|-------------|---------------|
| `/explore` | Read-only investigation | Understanding code before changing it |
| `/plan` | Produce an implementation plan | Before writing any code |
| `/implement` | Write code with safety gates | When you have a plan and are ready to build |
| `/verify` | Run verification protocol | After implementation, before merge |
| `/review` | End-to-end production review | Daily, on any active work |
| `/grill` | Adversarial self-review | Before creating a PR |
| `/dispatch` | Decompose into parallel sub-agents | Complex tasks that benefit from parallelism |
| `/elegant` | Controlled rebuild | When complexity has accumulated beyond incremental fixes |
| `/spec` | Generate a feature spec | Starting a new feature |
| `/decide` | Log an architectural decision | When making a choice that affects the system |
| `/compact` | Trigger context compaction | When the agent is getting slow or losing context |
| `/status` | Report system state | Start of session, or when you need orientation |

-----

## Common Workflows

### "I need to fix a bug"
```
/explore → understand the bug
/dispatch → decompose into root cause + fix + tests + rollout
/implement → write the fix
/verify → confirm it works
/grill → review before PR
```

### "I need to build a new feature"
```
/spec → write the feature spec
/plan → create implementation plan
/implement → build it
/verify → run verification
/review → end-to-end production review
/grill → final review before PR
```

### "The code is getting messy"
```
/explore → understand current state
/elegant → design the cleaner version
/implement → rebuild
/verify → confirm nothing broke
```

### "I'm starting my day"
```
/status → check system state
/review → review yesterday's active work
```

-----

## What the Files Do

You don't need to read all the system files to use this. But if you're curious:

| File | One-line purpose |
|------|-----------------|
| `CLAUDE.md` | Tells the agent what your system looks like |
| `AGENT.md` | Tells the agent how to make decisions |
| `IMPLEMENTATION.md` | Tells the agent how to write code correctly |
| `SAFETY.md` | Tells the agent what it's not allowed to do |
| `MEMORY.md` | Tells the agent how to manage its own memory |
| `DECISIONS.md` | Records architectural decisions so they persist across sessions |

The agent reads `CLAUDE.md` and `SAFETY.md` every session. The others load on demand based on what you're doing.

-----

## How Modes Actually Work

When you type `/explore`, two things happen:

1. A prompt is injected telling the agent it's in explore mode and listing what's allowed/prohibited.
2. The script `scripts/switch-mode.sh explore` runs, which **swaps `.claude/settings.json`** to a version where write tools are denied at the system level.

This means the agent can't write files even if it tries — the tool is blocked by Claude Code's native permission system, not just by instructions the agent might forget in a long session.

To manually switch modes without the slash command:
```bash
bash scripts/switch-mode.sh explore   # read-only
bash scripts/switch-mode.sh plan      # read + analyze only
bash scripts/switch-mode.sh implement # full access with safety gates
bash scripts/switch-mode.sh verify    # read + test only
bash scripts/switch-mode.sh guide     # read-only, explanation focused
```

-----

## Troubleshooting

**"The agent doesn't seem to know my architecture"**
→ Check that CLAUDE.md is in your project root and has no uncustomized `[placeholders]`.

**"The agent is writing files in explore mode"**
→ Run `bash scripts/switch-mode.sh explore` manually. The settings.json might not have been swapped.

**"Context seems degraded in a long session"**
→ Type `/compact` to trigger the compaction cascade. Or type `/status` to check context budget.

**"I want to see what the agent has been doing"**
→ Run `bash scripts/stats.sh` for a full observability dashboard.

**"I changed a system file and want to verify nothing broke"**
→ Run `bash scripts/verify-harness.sh` for Level 2 harness integrity checks.
→ Run `bash scripts/test-system.sh` for behavioral tests.

-----

*This guide covers the basics. For system architecture details, see `docs/architecture/context-engineering.md`. For the complete command and script reference, see `README.md`.*
