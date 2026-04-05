Read CLAUDE.md conventions before executing.

## Inputs
- `target` — domain name or "all" for full API surface

## Steps

1. Identify all route handlers in the target domain(s).

2. For each endpoint, run these checks:

   **Authentication (401)**
   - Send request without auth token → expect 401
   - Send request with expired/invalid token → expect 401

   **Authorization (403)**
   - For each RBAC-protected endpoint, send request with a valid token for a role that lacks permission → expect 403
   - Test horizontal access: user A accessing user B's resources → expect 403

   **Input validation**
   - Send malformed JSON → expect 400
   - Send oversized payloads → expect 400 or 413
   - Send unexpected fields → expect 400 or fields ignored

   **Injection resistance**
   - SQL injection: send `'; DROP TABLE users; --` in string fields → expect parameterized handling
   - XSS: send `<script>alert(1)</script>` in string fields → expect escaped output
   - Path traversal: send `../../etc/passwd` in path params → expect 400

   **IDOR (Insecure Direct Object Reference)**
   - Request resource by ID belonging to different tenant/user → expect 403 or 404

3. Report per endpoint:
   ```
   POST /api/v1/screening/search
     ✓ 401 without auth
     ✓ 403 insufficient role
     ✓ 400 malformed input
     ✓ Injection resistant
     ✗ IDOR — returns 200 for cross-tenant resource
   ```

4. Summary: total endpoints checked, total checks passed, total failed.

## Verification
- [ ] Every route handler was tested
- [ ] All 5 check categories applied to each endpoint
- [ ] Failures include specific reproduction steps
