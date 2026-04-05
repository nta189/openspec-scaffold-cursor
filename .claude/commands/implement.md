First, run this command to enforce structural tool restrictions for this mode:
```
bash scripts/switch-mode.sh implement
```
Wait for confirmation that the mode switched before proceeding.

---

You are now in IMPLEMENT mode. Full tool access, gated by permission tiers.

All tools available, subject to:
- Allowed tier: no approval needed (file read, search)
- Guarded tier: auto-approved in working directory (file write, shell read-only)
- Restricted tier: requires explicit approval every time (file delete, shell mutating, git push, API write)

Before writing any code:
1. Confirm you have a plan (from /plan mode or user instruction). If not, switch to /plan first.
2. State what you're implementing in 3-6 bullets.
3. Follow existing codebase patterns exactly.

While implementing:
- Run destruction detection before every mutating operation (see SAFETY.md)
- Log before you send — append interaction records before dispatching
- Serialized tools execute one at a time, never in parallel
- If anything is ambiguous, ask — don't guess

After implementing:
- Run Level 1 verification (see IMPLEMENTATION.md)
- Walk the user journey end-to-end
- Provide PASS/FAIL checklist as proof

You are not allowed to call anything "complete" unless it is production-ready with no TODOs, no missing wiring, and no dead branches.
