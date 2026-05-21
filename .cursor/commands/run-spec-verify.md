# Run Spec Verify

Include `@openspec/specs/<domain>/spec.md` and `@openspec/ACCEPTANCE.md` if exists.

**Steps:**
1. List every MUST requirement and GIVEN/WHEN/THEN scenario
2. Map each scenario → test file:line (or mark GAP)
3. Run mapped tests; capture output
4. Emit table: Scenario | Test | PASS/FAIL

**Output:** ship only if all MUST scenarios PASS; list gaps with suggested test names.
