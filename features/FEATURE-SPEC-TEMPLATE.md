# Feature: [Feature Name]

**Date:** [YYYY-MM-DD]
**Status:** draft | spec-review | approved | in-progress | verifying | shipped
**Author:** [Name]
**ADR Reference:** [ADR-NNN if this implements an architectural decision, otherwise "None"]

-----

## Problem

[What user problem does this solve? Why now? What evidence exists that this is worth building?]

## User Story

As a [user type], I want [action] so that [outcome].

## Desired Outcome

[Observable behavior when this is working correctly. Write this as if describing what a user would see and experience.]

## Non-Goals

[What this feature explicitly does NOT do. Be specific. This prevents scope creep during implementation.]

- NOT: [thing that seems related but is out of scope]
- NOT: [thing that could be a future enhancement but isn't this ticket]

## Constraints

- **Technical:** [framework limitations, API rate limits, browser support requirements]
- **Timeline:** [deadlines, dependencies on other work]
- **Regulatory:** [compliance requirements, data handling restrictions]
- **Architecture:** [must follow patterns established in ADR-NNN, append-only requirement, etc.]

-----

## API / Data Changes

| Change Type | Target | Details | Migration Required |
|-------------|--------|---------|-------------------|
| New endpoint | `POST /api/[path]` | [Request/response shape] | No |
| New table | `[table_name]` | [Key columns and types] | Yes — forward-only |
| Modified endpoint | `GET /api/[path]` | [What changes in request/response] | No |
| New column | `[table].[column]` | [Type, nullable, default] | Yes — forward-only |

> All changes must be documented in `docs/system/01-data-contracts.md` and `docs/system/02-api-contracts.md` before implementation.

## UI States

| State | Screen | Behavior | Design Notes |
|-------|--------|----------|-------------|
| Loading | [Screen] | [What shows — skeleton, spinner, progressive load] | |
| Success | [Screen] | [What the user sees when everything works] | |
| Error (recoverable) | [Screen] | [Error message + recovery path for the user] | |
| Error (unrecoverable) | [Screen] | [What shows + how user gets help] | |
| Empty state | [Screen] | [What shows when there's no data yet] | |
| Offline / slow connection | [Screen] | [Graceful degradation behavior] | |

## Edge Cases

| # | Scenario | Expected Behavior | Implementation Notes |
|---|----------|-------------------|---------------------|
| 1 | [Edge case description] | [What should happen] | [Any technical considerations] |
| 2 | [Edge case description] | [What should happen] | |
| 3 | [Edge case description] | [What should happen] | |

> Think adversarially: what happens if the user double-taps? What if the API times out? What if the user navigates away mid-flow? What if the data is malformed?

## Analytics

| Event Name | Trigger | Properties | Purpose |
|------------|---------|-----------|---------|
| `[feature]_viewed` | Screen renders | `user_id`, `source` | Track feature adoption |
| `[feature]_completed` | User completes flow | `user_id`, `duration_ms`, `path` | Measure conversion |
| `[feature]_error` | Error state reached | `user_id`, `error_type`, `context` | Debug issues |

-----

## Acceptance Criteria

Every criterion must be independently testable. "Works correctly" is not a criterion.

- [ ] [Specific, observable behavior that can be verified]
- [ ] [Specific, observable behavior that can be verified]
- [ ] [Specific, observable behavior that can be verified]
- [ ] [Error state X shows message Y and offers recovery action Z]
- [ ] [Performance: screen loads in < Nms on [connection type]]
- [ ] [Analytics events fire correctly for all tracked actions]

## Verification Plan

| Check | Method | Pass Criteria |
|-------|--------|--------------|
| Happy path | Manual walkthrough | All acceptance criteria pass |
| Error paths | Force each error state | Correct messages and recovery |
| Performance | Lighthouse or equivalent | Score > [threshold] |
| Accessibility | Screen reader + keyboard nav | All interactive elements reachable |
| Mobile | Test on [devices/viewports] | No layout breaks, touch targets adequate |

## Rollback Plan

[How to revert if this causes problems in production.]

- [ ] Feature flag: [flag name] — can disable without deploy
- [ ] Database: [migration is forward-only / can be reversed by ...]
- [ ] API: [endpoint can be removed by ... / is backward compatible]
- [ ] Rollback owner: [who monitors and decides]

-----

## Build Prompt

> Turn this spec into implementation. Follow existing codebase structure exactly. Do not start coding until the spec is unambiguous. If anything is unclear, ask before writing code.

-----

*Copy this template for each new feature. File naming: `features/[YYYY-MM-DD]-[feature-name].md`*
