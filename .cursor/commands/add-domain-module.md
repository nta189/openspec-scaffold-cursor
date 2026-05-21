# Add Domain Module

Include `@openspec/specs/<domain>/spec.md` and `@SCAFFOLD.md` conventions.

**Inputs:** domain name, spec path

**Steps:**
1. Create domain folder structure matching existing domains
2. Add routes, service, types, `__tests__` from spec MUST scenarios
3. Wire into app router / DI per project patterns
4. Seed/factory updates per `@openspec/SYNTHETIC_DATA.md` if present

**Verify:** all MUST scenarios mapped to tests; lint + test pass for domain package.
