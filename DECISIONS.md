# DECISIONS.md — [Project Name] Architectural Decision Log

> Append-only. Never edit existing entries. Load when making architectural decisions or checking for active constraints.

-----

## Format

Every entry follows this structure. Copy the template, fill it in, append it to the bottom.

```markdown
### ADR-[NNN] — [Title]
**Date:** [YYYY-MM-DD]
**Status:** proposed | accepted | superseded by ADR-[NNN] | deprecated
**Context:** [Why this decision is being made. What problem or tradeoff prompted it.]
**Decision:** [What was decided. Be specific enough that a future reader knows exactly what to do.]
**Consequences:** [What changes because of this decision. Include both positive and negative.]
**Alternatives Considered:** [What other options were evaluated and why they were rejected.]
```

-----

## Rules

1. **Append only.** Never edit or delete an existing entry. If a decision is reversed, add a new entry with status `superseded by ADR-[NNN]` referencing the new decision.
2. **One decision per entry.** If a single conversation produces three decisions, write three entries.
3. **Status is the source of truth.** Before implementing anything, check for `accepted` entries that constrain the relevant area. If a relevant entry exists, follow it unless you create a new superseding entry.
4. **Conflict resolution.** If two `accepted` entries conflict, the newer one wins. But both should be updated: the older entry's status becomes `superseded by ADR-[NNN]`.
5. **Review trigger.** Every 90 days, scan for entries older than 90 days that are still `accepted`. Ask: is this still the right decision? If yes, no action. If no, create a superseding entry.

-----

## Active Decisions

*Entries below are ordered chronologically. Newest at the bottom.*

### ADR-001 — [Example: Token-based auth over JWT]
**Date:** [YYYY-MM-DD]
**Status:** accepted
**Context:** The web app needs to authenticate users arriving via tokenized links. JWT adds complexity (refresh flow, session management) without benefit since all state lives server-side.
**Decision:** Use `web_token` (UUID) passed via `x-web-token` header on every request. No JWT. No session exchange. Token is permanent per user.
**Consequences:** Simpler auth flow. No token expiry handling. Trade-off: tokens are bearer tokens with no expiry — compromise of a token = permanent access until rotated server-side.
**Alternatives Considered:** JWT with refresh tokens (rejected: unnecessary complexity for this use case). Session cookies (rejected: doesn't work well with cross-device tokenized links).

### ADR-002 — [Example: Append-only core tables]
**Date:** [YYYY-MM-DD]
**Status:** accepted
**Context:** Data integrity and auditability require that user state history is never rewritten.
**Decision:** Tables `users`, `sessions`, `interactions`, `matches`, and `flags` are append-only. No UPDATE or DELETE operations. State changes are represented as new INSERT records with a status field.
**Consequences:** Complete audit trail of all state changes. Increased storage usage. Queries for "current state" require ordering by timestamp and taking the latest record (or a materialized view).
**Alternatives Considered:** Soft delete with `deleted_at` column (rejected: still allows UPDATE on other fields). Event sourcing (rejected: overkill for current scale, but may revisit).

-----

*Add new entries below this line. Never edit above.*
