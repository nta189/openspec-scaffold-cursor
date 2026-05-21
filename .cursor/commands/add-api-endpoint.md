# Add API Endpoint

Read `@IMPLEMENTATION.md` and `@openspec/config.yaml`. Include `@openspec/specs/<domain>/spec.md`.

**Inputs:** domain, method, path, scenario (GIVEN/WHEN/THEN)

**Steps:**
1. Implement route in `src/<domain>/routes.ts` — validation, auth, RBAC, service call, structured errors
2. Implement service in `src/<domain>/service.ts` — parameterized queries, audit log if sensitive
3. Add tests: happy path, 401, 403, 400 validation, injection resistance
4. Update traceability: requirement → scenario → test path

**Verify:** route + service + 5 test categories + traceability entry. Report PASS/FAIL.
