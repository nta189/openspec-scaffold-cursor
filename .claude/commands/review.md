You have one job: Review your work end-to-end and ensure it ACTUALLY fixes the exact problem identified, for real users, in production.

You are not allowed to call anything "complete" unless it meets this baseline:
1. It fixes the problem identified (not adjacent improvements).
2. It is production ready (no errors, no TODOs, no "later" steps, no missing wiring).
3. It works out of the box, end-to-end, from the user's perspective, with a unicorn-level UX: smooth, beautiful, and reliable.
4. Logging is optional and must not distract from the actual fix.

Constraints:
- Follow the existing codebase structure exactly (schemas, tables, event naming, shapes, patterns).
- Do not leave any TODOs or "paths" that do not immediately work.
- Do not over-engineer. Do not ship a quick hack. Pick the most sensible solution with minimal risk and minimal diff.

Step 1: Restate the target (no scope creep)
- In 3-6 bullets, restate the exact area of improvement or problem you are fixing.
- List what "fixed" means in observable terms (user-visible behavior + metrics).

Step 2: Walk the user journey end-to-end
Simulate the full user flow step-by-step as a user would experience it. For each step, verify:
- UI state is correct
- Network calls succeed
- Errors are handled with good UX
- Loading states are smooth
- Nothing dead-ends
Call out any edge cases that a reviewer or real user would hit.

Step 3: Code correctness and production polish
Verify all of this:
- No crashes, no nil hazards, no invalid state assumptions
- No unhandled promise rejections / async race conditions
- All backend validations align with frontend constraints
- Timeouts, retries, and error surfaces are sane
- No unused code, no dead branches, no placeholder logic
- Visual polish: spacing, copy, transitions, responsiveness

Step 4: Proof
- List the exact commands/tests you ran
- List the exact screens/flows you manually tested
- Provide a short PASS/FAIL checklist at the end

Output format (required):
1. "What I checked" (bullets)
2. "What I fixed" (bullets, with file paths)
3. "End-to-end verification results" (PASS/FAIL checklist)
4. "Remaining risks" (only if truly unavoidable; otherwise, state "none")

Rules:
- You are not allowed to say "complete" if any step above is missing.
- If you discover the fix does not truly resolve the original problem, stop and correct it immediately.
- Keep the solution minimal, aligned to existing patterns, and production ready.
- Assume an independent reviewer will audit this work and flag any gaps.
