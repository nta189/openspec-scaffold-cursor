Read CLAUDE.md conventions before executing. Read openspec/config.yaml for spec rules.

## Inputs
- `spec` — spec name (e.g., "screening-restricted-parties") or "all" for full verification

## Steps

1. Read the spec at `openspec/specs/<spec>/spec.md`. Extract every requirement and its GIVEN/WHEN/THEN scenarios. Identify which are MUST priority.

2. Read the traceability map. For each MUST scenario, find the mapped test path.

3. Run the matching tests. Collect PASS/FAIL results per scenario.

4. Check test coverage for the domain folder against the threshold in CLAUDE.md.

5. Report:
   ```
   Spec: <spec-name>
   MUST scenarios: N total, N passed, N failed, N missing
   Coverage: X% (threshold: Y%)

   PASS  REQ-1 / Scenario 1 — <description>
   PASS  REQ-1 / Scenario 2 — <description>
   FAIL  REQ-2 / Scenario 1 — <description> — <failure reason>
   MISSING  REQ-3 / Scenario 1 — <description> — no test found

   Verdict: PASS | FAIL
   ```

6. If any MUST scenario is FAIL or MISSING, verdict is FAIL. Do not mark the spec as complete.

## Verification
- [ ] Every MUST scenario has a mapped test
- [ ] All mapped tests were executed
- [ ] Coverage meets threshold
- [ ] Report format matches template above
