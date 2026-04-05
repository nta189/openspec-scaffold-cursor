Read CLAUDE.md conventions before executing. Read openspec/config.yaml for spec rules.

## Inputs
- `domain` — the domain name (e.g., "payments", "screening", "auth")

## Steps

1. Read the spec at `openspec/specs/<domain>/spec.md`. Extract: purpose, data model entities, dependencies.

2. Create domain folder and files:
   - `src/<domain>/README.md` — links to `openspec/specs/<domain>/spec.md`, lists entities, notes dependencies
   - `src/<domain>/routes.ts` — route handler stubs for each requirement in the spec. Import validation schemas. Mount under `/api/v1/<domain>/`.
   - `src/<domain>/service.ts` — business logic functions matching each route. Import shared types and DB helper.
   - `src/<domain>/__tests__/<domain>.test.ts` — test file importing factories and test setup. One `describe` block per requirement.

3. Register routes in `src/api/routes/registry.ts` — import and mount the domain router.

4. Adapt file extensions and patterns to the project's detected language from CLAUDE.md.

## Verification
- [ ] Domain folder exists with all 4 files
- [ ] Routes registered in registry
- [ ] Test file imports test setup and factories
- [ ] README links to correct spec path
