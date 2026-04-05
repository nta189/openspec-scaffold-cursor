# SCAFFOLD

Read every file in this project. Derive the stack, framework, database, language, and test runner from CLAUDE.md, package.json, and existing configs. Where choices are not yet made, prefer open-source tools, PostgreSQL or SurrealDB for storage, and the most widely adopted framework for the detected language.

Create real, working files. Never stubs. Never TODOs. Skip nothing.

---

## 1. Outcomes

For every spec in `openspec/specs/*/spec.md`:

- Every requirement gets a MoSCoW priority (MUST / SHOULD / COULD).
- Every requirement has non-functional targets (latency, retention, throughput, concurrency) derived from its nature. If a spec has none, add them.
- Every GIVEN/WHEN/THEN scenario is precise enough to produce one test with zero interpretation. If ambiguous, rewrite it.
- Every data model has typed fields. If fields are untyped, type them.

Create `openspec/ACCEPTANCE.md` — list every capability, its MUST scenarios, and pass/fail criteria. One file answers "is v1.0 done?"

Create `openspec/SYNTHETIC_DATA.md` — naming conventions, ID formats, date ranges, and realistic fictional values for all test entities. Every factory and seed script in this project references this file.

---

## 2. Constraints

Append to CLAUDE.md (never delete existing content) every convention the agent needs. Cover all six, using patterns matching the project's stack:

- **API shape** — resource naming, methods, pagination format, error response structure, auth mechanism, response wrappers
- **Data layer** — table/collection naming, key strategy, timestamp conventions, soft delete pattern, migration/schema format, index naming
- **Language** — strictness level, type safety rules, import conventions, data modeling pattern, enum handling
- **Security** — banned patterns (eval, dynamic execution, string-concatenated queries, hardcoded secrets), input validation strategy, dependency policy
- **Errors** — base error shape, handling patterns for DB / external service / validation / auth / unhandled errors — consistent across all domains
- **Logging** — format, required fields, what to always log, what to never log

Each convention is specific enough that two developers following it independently produce compatible code.

---

## 3. Tools

For every tool the project uses, create its config file if missing:

- Language config — strictest practical settings, path aliases
- Linter — enforces section 2 language rules
- Formatter — one style, no debates
- Test runner — coverage thresholds from CLAUDE.md, setup file, aliases
- Container/services — database + dependencies, health checks, dev ports
- Environment template — every variable, described, with safe defaults
- CI workflow — lint, typecheck, test, coverage gate on push and PR
- `.gitignore` — standard ignores for the stack

Create reusable agent skills for the project's AI tool:

- **add-domain-module** — creates a new domain folder, README linking to spec, route stub, test file, registers in route registry. Agent reads this skill instead of inventing the pattern each time.
- **add-api-endpoint** — creates route handler, input validation schema, test with auth/RBAC/injection checks, updates route registry. Follows all section 2 conventions automatically.
- **run-spec-verify** — reads a spec, finds its traceability entries, runs the matching tests, checks coverage against MUST scenarios, reports PASS/FAIL per scenario.
- **run-security-audit** — runs all security test helpers (401, 403, injection, IDOR) against a specified domain or the entire API surface.
- **add-migration** — creates a new sequential migration file with the correct naming convention, timestamp, and up/down structure.

Each skill references CLAUDE.md conventions and openspec/config.yaml rules so the agent's output is consistent regardless of which session creates it.

Each skill is a Claude Code slash command at `.claude/commands/<skill-name>.md`. Format:

```markdown
# Skill: <name>

Read CLAUDE.md conventions before executing. Read openspec/config.yaml for spec rules.

## Inputs
- `<param>` — description

## Steps
1. [Concrete step referencing a convention from CLAUDE.md]
2. [File creation with exact path pattern]
3. [Registration in route registry / test suite / etc.]

## Verification
- [ ] [Testable check]
```

The skill file IS the prompt. When the user types `/<skill-name>`, Claude Code injects the file contents as instructions.

Create or update `openspec/config.yaml`:

```yaml
schema: spec-driven
context: |
  Stack: <detected from CLAUDE.md>
  Framework: <detected from CLAUDE.md>
  Database: <detected from CLAUDE.md>
  Test runner: <detected from CLAUDE.md>
  Auth: <detected from CLAUDE.md>
nfr_defaults:
  api_response_p95_ms: 200
  api_response_p99_ms: 500
  query_timeout_ms: 5000
  retention_days: 2555          # 7 years default for regulated industries
  concurrent_users: 100
  test_coverage_min_pct: 80
rules:
  specs:
    - Every requirement has a MoSCoW priority (MUST / SHOULD / COULD)
    - Every requirement has non-functional targets
    - Every scenario uses GIVEN/WHEN/THEN format
    - Every data model has typed fields
  proposal:
    - Include scope and out-of-scope
    - Reference affected specs by path
  design:
    - Reference conventions from CLAUDE.md
    - Identify affected shared modules
  tasks:
    - Each task is implementable in one session
    - Each task references the scenario it satisfies
```

---

## 4. Harness

Build the shared infrastructure every domain builds on:

- **Types** — ID types for every entity across all specs, common enums, pagination types, response wrappers
- **Errors** — base error class, one subclass per error category, each with status code
- **Config** — reads environment, validates with schema, fails fast if missing
- **Database** — connection pool, transaction helper, typed query wrapper
- **Logger** — structured output matching section 2 logging conventions
- **Middleware/hooks** — auth, role-based access, audit log, error handler, input validation — matching the project's framework
- **Entry point** — wires middleware, mounts routes, health check, graceful shutdown
- **Route registry** — mounts domain routers under versioned paths
- **Domain folders** — one per domain, README linking to specs, no implementation code
- **Initial migration/schema** — foundational tables (users, roles, assignments, audit log) with all conventions applied
- **Migration runner** — sequential, tracks state
- **Seed script** — test data per SYNTHETIC_DATA.md: one user per role, fictional entities, sample records

Define agent orchestration in `CLAUDE.md`:

- **Dependency map** — which specs depend on which. Derived from the "Dependencies" section in each spec. An agent must never implement a spec before its dependencies are built.
- **Parallel groups** — specs with no cross-dependencies can be built simultaneously by separate agents. List which specs can be parallelized.
- **Agent scope boundary** — each agent works within one domain folder. Shared infrastructure (types, errors, middleware) is read-only to domain agents. Only the harness agent modifies shared code.
- **Verify gate** — after any agent completes a spec implementation, run the `run-spec-verify` skill before marking the task complete. No merge without passing verification.
- **Conflict resolution** — if two parallel agents need to modify the same shared file (e.g., adding a type to types.ts), they append only. The harness agent reconciles after both complete.

### Target structure

Generate this directory layout, adapting paths to the project's detected stack:

```
src/
├── shared/
│   ├── types.ts           ← ID types, enums, pagination, response wrappers
│   ├── errors.ts          ← Base error + subclasses with status codes
│   ├── config.ts          ← Environment reader with schema validation
│   ├── db.ts              ← Connection pool, transaction helper, typed query wrapper
│   ├── logger.ts          ← Structured logger matching section 2 conventions
│   └── middleware/
│       ├── auth.ts        ← Authentication + role extraction
│       ├── rbac.ts        ← Role-based access control
│       ├── audit.ts       ← Audit log middleware
│       ├── error.ts       ← Error handler (catches, formats, logs)
│       └── validate.ts    ← Input validation middleware
├── api/
│   ├── index.ts           ← Entry point: wire middleware, mount routes, health check, graceful shutdown
│   └── routes/
│       └── registry.ts    ← Route registry: mounts domain routers under /api/v1/
├── <domain>/              ← One folder per domain from specs
│   ├── README.md          ← Links to relevant specs
│   ├── routes.ts          ← Domain route handlers
│   ├── service.ts         ← Business logic
│   └── __tests__/
│       └── <domain>.test.ts
├── db/
│   ├── migrate.ts         ← Migration runner (sequential, tracks state)
│   ├── seed.ts            ← Seed script per SYNTHETIC_DATA.md
│   └── migrations/
│       └── 001_foundation.sql  ← Users, roles, assignments, audit log
└── test/
    ├── setup.ts           ← DB cleanup, transaction-per-test, auth helper, HTTP helper
    ├── factories/         ← Builder-pattern factory per entity
    ├── fixtures/          ← Pre-built edge cases
    └── mocks/             ← Mock per external service
```

Adapt file extensions and directory conventions to the detected language (e.g., `.py` + `app/` for Python, `.go` + `internal/` for Go). The structure above is the TypeScript/Node.js default.

---

## 5. Evals

Build the testing infrastructure:

- **Factories** — builder-pattern factory per entity, sensible defaults, every field overridable, names from SYNTHETIC_DATA.md
- **Fixtures** — pre-built edge cases: a match trigger, a false positive, an expiring record, a past-deadline record, an access-blocked record
- **Mocks** — mock per external service interface: configurable returns, call recording, no network
- **Test setup** — DB cleanup between tests, transaction-per-test, auth context helper, HTTP request helper
- **Traceability** — map: spec capability → scenario → test path. Meta-test verifying every MUST scenario has an entry.
- **Security helpers** — reusable: auth required (401), RBAC enforced (403), injection resistance, IDOR protection
- **Benchmarks** — time critical operations against NFR targets, print PASS/FAIL

---

## Verify

1. Language compiler/checker: zero errors.
2. Every file referenced in CLAUDE.md exists.
3. Every spec has NFRs and priorities.
4. Every skill is functional and references CLAUDE.md conventions.
5. Dependency map and parallel groups are consistent with spec dependencies.
6. `openspec/config.yaml` has context and rules populated.
7. CI workflow is valid.

```
SCAFFOLD COMPLETE — ready for /opsx:apply
```
