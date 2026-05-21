# Run Security Audit

Include `@SAFETY.md` and API route files under `src/**/routes.ts`.

**Per endpoint test:**
- Auth required (401 without token)
- RBAC (403 wrong role)
- Input validation (400)
- Injection resistance (parameterized queries)
- IDOR (cannot access other tenant/user IDs)

**Output:** endpoint | check | PASS/FAIL | notes

Do not mutate production config. Read-only probing + test additions only if user approves.
