Switch to spec-writing mode. Your job is to turn the provided context into a build-ready feature specification using the template in features/FEATURE-SPEC-TEMPLATE.md.

Read the template first, then fill in every section based on what the user has described.

Rules:
- Do not start coding. This is a spec, not an implementation.
- Every acceptance criterion must be independently testable — "works correctly" is not a criterion.
- Non-goals are mandatory. If you can't think of non-goals, you don't understand the scope yet. Ask.
- Edge cases must include: empty/null inputs, network failures, double-submission, navigation-away-mid-flow, and any domain-specific edge cases.
- UI states must include: loading, success, recoverable error, unrecoverable error, empty state, and offline/degraded.
- The rollback plan must be concrete — feature flag name, migration reversibility, API backward compatibility.
- Check docs/system/01-data-contracts.md and docs/system/02-api-contracts.md before proposing any API or data changes.

After writing the spec:
1. Read it back critically. Would an engineer be able to implement this without asking any questions?
2. If anything is ambiguous, call it out and ask the user to clarify before finalizing.
3. Save to features/[YYYY-MM-DD]-[feature-name].md

The spec is approved when the user says so. Until then, iterate.
