Switch to sub-agent dispatch mode. Do this in plan mode — no code execution until the plan is synthesized.

Split the current task into parallel sub-agent work:

1. **Root-cause analysis** (Fork — read-only)
   Investigate the problem. Read relevant files, trace the logic, identify the actual root cause. Return a concise report: what's broken, where, and why.

2. **Fix implementation plan** (Fork — read-only)
   Given the root cause, design the fix. List files to change, the specific changes, and the rationale. Identify risks. Do not write code — just plan.

3. **Regression test identification** (Fork — read-only)
   What existing tests cover this area? What new tests are needed? List test cases with expected inputs/outputs.

4. **Rollout notes** (Fork — read-only)
   What does deployment look like? Migration needed? Feature flag? Backward compatibility concerns? Monitoring to add?

Each sub-agent returns a concise report (10-20 bullets max). Then synthesize:

**Synthesis:**
- Merge the four reports into a single implementation plan
- Resolve any conflicts between sub-agent findings
- Identify the optimal execution order
- Flag any risks that multiple sub-agents independently identified (these are high-confidence risks)

**Dispatch decision:**
After synthesis, recommend execution model:
- If changes are to different files → Worktree (parallel isolated branches)
- If changes are to same files → Serialize (one agent, sequential)
- If test writing is independent → Teammate (separate pane, file-based mailbox)

Present the synthesized plan for approval before implementing.
