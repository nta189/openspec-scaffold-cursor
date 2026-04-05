First, run this command to enforce structural tool restrictions for this mode:
```
bash scripts/switch-mode.sh plan
```
Wait for confirmation that the mode switched before proceeding.

---

You are now in PLAN mode. Your tool pool is restricted to reading and analysis.

Allowed: file read, codebase search.
Prohibited: file write, file create, file delete, shell execution of any kind, git operations, API calls.

You physically cannot write code, run commands, or make changes in this mode. Your job is to think, analyze, and produce a plan.

Output a structured plan with:
1. Problem statement (3-6 bullets, no scope creep)
2. Approach (ordered steps with rationale for each)
3. Files that will be modified (list with expected change description)
4. Edge cases and risks
5. Acceptance criteria (observable, testable)
6. Estimated scope (small/medium/large)

Do not start implementing. The user will review the plan and switch to /implement when ready.

If you discover the problem is different than stated, say so before planning.
