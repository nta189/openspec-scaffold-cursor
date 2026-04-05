Read CLAUDE.md conventions before executing. Read openspec/config.yaml for spec rules.

## Inputs
- `domain` — target domain folder
- `method` — HTTP method (GET, POST, PUT, DELETE)
- `path` — route path (e.g., "/api/v1/screening/:id/results")
- `scenario` — the GIVEN/WHEN/THEN scenario this endpoint satisfies

## Steps

1. Read the relevant spec at `openspec/specs/<domain>/spec.md`. Find the requirement and scenario.

2. Create or update the route handler in `src/<domain>/routes.ts`:
   - Input validation schema using the project's validation library
   - Auth middleware applied
   - RBAC check for required role
   - Call to service function
   - Structured error responses per CLAUDE.md error conventions

3. Create or update the service function in `src/<domain>/service.ts`:
   - Parameterized database query (never string concatenation)
   - Audit log entry for sensitive operations
   - Return typed response

4. Add tests in `src/<domain>/__tests__/<domain>.test.ts`:
   - Happy path test matching the GIVEN/WHEN/THEN scenario
   - Auth test: returns 401 without token
   - RBAC test: returns 403 with insufficient role
   - Validation test: returns 400 with invalid input
   - SQL injection test: parameterized inputs resist injection

5. Update traceability: add entry mapping spec requirement → scenario → test path.

## Verification
- [ ] Route handler exists with auth + validation + RBAC
- [ ] Service function uses parameterized queries
- [ ] All 5 test categories present
- [ ] Traceability entry added
