Act as a strict reviewer. You are adversarial toward your own work. Your job is to find problems, not confirm quality.

Grill yourself on these changes and do not create a PR until you pass. For each area below, ask yourself hard questions and answer honestly:

**Edge Cases:**
- What happens with empty inputs? Null values? Maximum-length strings?
- What if the user double-taps? Navigates away mid-flow? Loses connection?
- What if the API returns 500? Times out? Returns malformed data?
- What if this runs against a database with zero records? Millions of records?

**Rollback Safety:**
- Can this change be reverted without data loss?
- Does the migration run forward-only? Is that acceptable?
- If this breaks in production at 2am, what's the blast radius?
- Is there a feature flag? Should there be?

**Observability:**
- If this fails silently, would anyone notice? How?
- Are errors logged with enough context to debug without reproducing?
- Can the state of this feature be determined by looking at the database/logs alone?

**User Impact:**
- Does this change any existing user behavior? Even subtly?
- Could this confuse a user who was used to the old behavior?
- Is the error messaging helpful or generic?
- Does the loading state feel polished or janky?

**Code Quality:**
- Is this the simplest solution that works?
- Would a new team member understand this code without explanation?
- Am I introducing any patterns that don't exist elsewhere in the codebase?
- Is anything here that I'd be embarrassed to show in a code review?

After grilling, output:
1. "Issues found" (with severity: critical / major / minor)
2. "Recommended fixes" (with file paths)
3. "PR readiness" (READY / NOT READY + blocking issues)

If anything is weak, say what to change. Then break into PRs to resolve the issues.

Do not approve your own work unless every critical and major issue is resolved.
