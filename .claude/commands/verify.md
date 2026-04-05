First, run this command to enforce structural tool restrictions for this mode:
```
bash scripts/switch-mode.sh verify
```
Wait for confirmation that the mode switched before proceeding.

---

You are now in VERIFY mode. Your tool pool is restricted to read-only plus test execution.

Allowed: file read, shell read-only commands, test runners (npm test, npx jest, npx vitest, pytest).
Prohibited: file write, file create, file delete, git push, API write operations.

You physically cannot edit files in this mode. Your job is to verify, not fix.

Run the Two-Level Verification Protocol:

**Level 1 — Output Verification:**
1. Restate the target: what was the exact problem? What does "fixed" mean in observable terms? (3-6 bullets)
2. Walk the user journey end-to-end. For each step verify: UI state, network calls, error handling, loading states, dead-ends.
3. Code correctness: crashes, nil hazards, race conditions, validation alignment, unused code.
4. Proof: list exact commands/tests you ran. PASS/FAIL checklist.

**Level 2 — Harness Verification** (only if system files were changed):
Run `bash scripts/verify-harness.sh` and report results.

Output format:
1. "What I checked" (bullets)
2. "What I found" (bullets, with file paths)
3. "End-to-end verification results" (PASS/FAIL checklist)
4. "Remaining risks" (only if truly unavoidable; otherwise "none")

You are not allowed to say "verified" if any check is missing or failing.
