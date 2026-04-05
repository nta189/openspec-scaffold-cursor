# End-to-End Walkthrough: OpenSpec + SCAFFOLD + Claude Code

This document explains how three systems compose to take a project from zero to a production-ready, spec-driven codebase. It is written for developers who have not used any of the three systems before.

-----

## The Three Systems

| System | Role | Where it lives |
|--------|------|----------------|
| **OpenSpec** | Manages specs, change proposals, deltas, and archive. Defines *what* to build. | `npm install -g @fission-ai/openspec@latest` |
| **SCAFFOLD.md** | A universal build prompt that turns specs into a production scaffold. Defines *how* to build it right. | This repo (`SCAFFOLD.md`) |
| **Enhanced Claude Code** | A context engineering architecture for AI coding agents. Provides structured modes, safety enforcement, and repeatable workflows. The *execution engine*. | `github.com/krzemienski/enhanced-claude-code` |

### How they connect

```
You write specs (OpenSpec)
        |
        v
SCAFFOLD.md reads your specs + CLAUDE.md
        |
        v
Claude Code executes the scaffold build
        |
        v
Agent skills + OpenSpec CLI handle ongoing development
```

OpenSpec owns the requirements. SCAFFOLD.md is a one-time build prompt that produces conventions, configs, shared infrastructure, test harness, and agent skills. Claude Code (with the enhanced system) executes the build and every subsequent change, using structured modes (`/explore`, `/plan`, `/implement`, `/verify`) to maintain quality.

-----

## Prerequisites

You need three things installed:

```bash
# 1. Node.js (>= 18)
node --version

# 2. OpenSpec CLI
npm install -g @fission-ai/openspec@latest
openspec --version

# 3. Claude Code (VS Code extension or CLI)
#    Install from: https://claude.ai/code
#    Verify it's available in your editor or terminal
```

You also need a copy of this repo (openspec-scaffold) and optionally the enhanced-claude-code repo:

```bash
git clone https://github.com/krzemienski/openspec-scaffold.git
git clone https://github.com/krzemienski/enhanced-claude-code.git  # optional but recommended
```

-----

## Phase 1: Bootstrap a New Project (5 minutes)

Run the bootstrap script from the openspec-scaffold repo:

```bash
cd openspec-scaffold
./new-project.sh my-app
cd my-app
```

This script does six things:

1. Creates the project directory and initializes git
2. Runs `openspec init` (or creates the directory structure manually if the CLI is not installed)
3. Creates `.claude/commands/` for agent skills
4. Copies `SCAFFOLD.md` into the project as `prompt.md`
5. Creates a template `CLAUDE.md`
6. Creates a `.gitignore`

After running, your project looks like this:

```
my-app/
├── .git/
├── .gitignore
├── .claude/commands/          # agent skills go here later
├── CLAUDE.md                  # template — you fill this in next
├── prompt.md                  # copy of SCAFFOLD.md — the build prompt
└── openspec/
    ├── config.yaml            # spec rules and NFR defaults
    ├── specs/                 # your specs go here
    ├── changes/               # change proposals (created by /opsx:new)
    └── archive/               # archived changes (created by /opsx:archive)
```

-----

## Phase 2: Define Your Project (30 minutes)

Two things to do before the build: define your stack and write your specs.

### 2a. Edit CLAUDE.md

Open `CLAUDE.md` and replace the template comments with your actual stack choices. SCAFFOLD.md reads this file to derive every convention. Be specific:

```markdown
# CLAUDE.md

## Project overview

A multi-tenant SaaS platform for managing restaurant inventory,
ordering, and supplier relationships.

## Architecture

- Language: TypeScript
- Framework: Express
- Database: PostgreSQL
- Test runner: Vitest
- Auth: JWT with refresh tokens
- Deployment: Docker on Railway

## Critical rules

### Data boundary
- No PII in logs
- All financial data encrypted at rest

### Code standards
- Test coverage minimum: 80%
- All endpoints require authentication
- All inputs validated with Zod
```

The more precise you are here, the more consistent the scaffold output will be. Two developers reading the same `CLAUDE.md` should make the same architectural choices.

### 2b. Write Specs

Each capability gets a spec file at `openspec/specs/<capability>/spec.md`. A spec contains:

- **Purpose** -- what this capability does, in plain language
- **Requirements** -- each with GIVEN/WHEN/THEN scenarios
- **Data model** -- entities with typed fields
- **Non-functional requirements** -- latency, throughput, retention
- **Dependencies** -- which other specs this depends on

Create specs with the CLI or manually:

```bash
# Using the OpenSpec CLI
openspec new inventory-management

# Or manually
mkdir -p openspec/specs/inventory-management
touch openspec/specs/inventory-management/spec.md
```

Here is a minimal spec to illustrate the format:

```markdown
# inventory-management Specification

## Purpose

Track current stock levels, receive shipments, and alert
when items fall below reorder thresholds.

## Requirements

### Requirement: Stock level tracking

The system SHALL maintain real-time stock levels for all items.

#### Scenario: Receive a shipment

- GIVEN an item "Olive Oil 1L" with current stock of 20 units
- WHEN a shipment of 50 units is received and recorded
- THEN the stock level updates to 70 units
- AND an audit entry is created with timestamp, user, and quantity

#### Scenario: Stock falls below threshold

- GIVEN an item with reorder threshold of 10 units
- WHEN the stock level drops to 9 or below
- THEN the system creates a low-stock alert
- AND notifies the assigned purchaser

## Data model

- **Item**: id (uuid), name (string), sku (string), unit (string),
  current_stock (integer), reorder_threshold (integer), category_id (uuid)
- **Shipment**: id (uuid), item_id (uuid), quantity (integer),
  received_by (uuid), received_at (timestamptz), supplier_id (uuid)
- **StockAlert**: id (uuid), item_id (uuid), triggered_at (timestamptz),
  resolved_at (timestamptz | null), assigned_to (uuid)

## Non-functional requirements

- Stock level queries: < 100ms p95
- Alert delivery: < 30 seconds from threshold breach

## Dependencies

- Depends on: user-management (for assigned_to references)
- Depended on by: ordering, supplier-management
```

Write one spec per capability. The SCAFFOLD reads all of them.

-----

## Phase 3: Build the Scaffold (60-90 minutes)

This is where Claude Code executes `SCAFFOLD.md`. Open your project in Claude Code (VS Code or CLI), then give it the build prompt.

**Option A -- paste the prompt directly:**

```
Read prompt.md and execute it.
```

**Option B -- if you have the enhanced-claude-code system installed:**

Copy the enhanced-claude-code system files (`AGENT.md`, `SAFETY.md`, `MEMORY.md`, `IMPLEMENTATION.md`, etc.) into your project root first, then tell Claude Code to read `prompt.md`. The enhanced system gives you structured modes and safety gates during the build.

SCAFFOLD.md executes five phases in order. Here is what each one produces:

### Phase 3a: Outcomes -- sharpen your specs

Claude reads every spec in `openspec/specs/` and:

- Adds **MoSCoW priorities** (MUST / SHOULD / COULD) to every requirement
- Adds **non-functional targets** (latency, retention, throughput) where missing
- Tightens every **GIVEN/WHEN/THEN** scenario so each produces exactly one test
- Types all **data model fields** if any are untyped

It also creates two new files:

| File | Purpose |
|------|---------|
| `openspec/ACCEPTANCE.md` | Every capability, its MUST scenarios, and pass/fail criteria. One file answers "is v1 done?" |
| `openspec/SYNTHETIC_DATA.md` | Naming conventions, ID formats, date ranges, and fictional values for all test entities. Every factory and seed script references this. |

### Phase 3b: Constraints -- append conventions to CLAUDE.md

Claude appends six convention blocks to your `CLAUDE.md`:

1. **API shape** -- resource naming, methods, pagination format, error responses, auth headers, response wrappers
2. **Data layer** -- table naming, key strategy, timestamps, soft delete pattern, migration format, index naming
3. **Language rules** -- strictness level, import conventions, data modeling patterns, enum handling
4. **Security** -- banned patterns (eval, string-concatenated queries, hardcoded secrets), input validation, dependency policy
5. **Errors** -- base error shape, categories for DB / validation / auth / external service / unhandled errors
6. **Logging** -- format, required fields, what to always log, what to never log (PII, tokens, passwords)

These conventions are specific enough that two agents working in parallel produce compatible code.

### Phase 3c: Tools -- generate configs and agent skills

Claude creates every config file the project needs:

- `tsconfig.json` (or equivalent) with strictest practical settings
- ESLint / Ruff / equivalent linter config enforcing the language rules
- Prettier / Black / equivalent formatter config
- Vitest / pytest / equivalent test config with coverage thresholds
- `docker-compose.yml` with database and dependencies
- `.env.example` with every variable documented
- CI workflow (GitHub Actions) -- lint, typecheck, test, coverage gate
- Updated `.gitignore`

It also creates five **agent skills** as Claude Code slash commands in `.claude/commands/`:

| Skill file | Slash command | What it does |
|-----------|---------------|--------------|
| `add-domain-module.md` | `/add-domain-module` | Creates a new domain folder with README, routes, service, and test file. Registers in route registry. |
| `add-api-endpoint.md` | `/add-api-endpoint` | Creates route handler, validation schema, and test with auth/RBAC/injection checks. |
| `run-spec-verify.md` | `/run-spec-verify` | Reads a spec, finds its tests via the traceability matrix, runs them, reports PASS/FAIL per MUST scenario. |
| `run-security-audit.md` | `/run-security-audit` | Runs all security test helpers (401, 403, injection, IDOR) against a domain or the full API surface. |
| `add-migration.md` | `/add-migration` | Creates a new sequential migration file with correct naming, timestamp, and up/down structure. |

Each skill file is a prompt that references `CLAUDE.md` conventions and `openspec/config.yaml` rules. When you type the slash command, Claude Code injects the file as instructions.

### Phase 3d: Harness -- shared infrastructure

Claude builds the foundation every domain depends on:

```
src/
├── shared/
│   ├── types.ts            ID types, enums, pagination, response wrappers
│   ├── errors.ts           Base error class + subclass per category
│   ├── config.ts           Environment reader with schema validation
│   ├── db.ts               Connection pool, transaction helper, typed queries
│   ├── logger.ts           Structured logger matching conventions
│   └── middleware/
│       ├── auth.ts          Authentication + role extraction
│       ├── rbac.ts          Role-based access control
│       ├── audit.ts         Audit log middleware
│       ├── error.ts         Error handler (catch, format, log)
│       └── validate.ts      Input validation middleware
├── api/
│   ├── index.ts            Entry point: middleware, routes, health check, shutdown
│   └── routes/
│       └── registry.ts     Mounts domain routers under /api/v1/
├── <domain>/               One folder per spec (empty, ready for implementation)
│   └── README.md           Links to the spec
├── db/
│   ├── migrate.ts          Migration runner (sequential, tracks state)
│   ├── seed.ts             Seed script using SYNTHETIC_DATA.md
│   └── migrations/
│       └── 001_foundation.sql   Users, roles, assignments, audit log
└── test/
    ├── setup.ts            DB cleanup, transaction-per-test, auth helper
    ├── factories/          (populated in phase 3e)
    ├── fixtures/           (populated in phase 3e)
    └── mocks/              (populated in phase 3e)
```

Claude also writes **agent orchestration rules** into `CLAUDE.md`:

- **Dependency map** -- derived from each spec's Dependencies section. An agent must never implement a spec before its dependencies are built.
- **Parallel groups** -- specs with no cross-dependencies can be built simultaneously by separate agents.
- **Scope boundary** -- each agent works within one domain folder. Shared infrastructure is read-only to domain agents.
- **Verify gate** -- `/run-spec-verify` must pass before any spec is marked complete.
- **Conflict resolution** -- parallel agents append-only to shared files (like `types.ts`). A harness agent reconciles after both complete.

### Phase 3e: Evals -- test infrastructure

Claude builds the testing layer:

- **Factories** -- builder-pattern factory per entity, sensible defaults, every field overridable, names from `SYNTHETIC_DATA.md`
- **Fixtures** -- pre-built edge cases (false positives, expired records, access-blocked records)
- **Mocks** -- one mock per external service interface, configurable returns, call recording, no network
- **Test setup** -- DB cleanup between tests, transaction-per-test, auth context helper, HTTP request helper
- **Traceability matrix** -- maps spec capability to scenario to test path. A meta-test verifies every MUST scenario has an entry.
- **Security helpers** -- reusable checks for 401 (auth required), 403 (RBAC enforced), injection resistance, IDOR protection
- **Benchmarks** -- time critical operations against NFR targets, print PASS/FAIL

### Phase 3 verification

The scaffold is not done until Claude confirms:

1. Language compiler/checker runs with zero errors
2. Every file referenced in `CLAUDE.md` exists
3. Every spec has NFRs and MoSCoW priorities
4. Every agent skill is functional and references `CLAUDE.md` conventions
5. Dependency map and parallel groups are consistent with spec dependencies
6. `openspec/config.yaml` has context and rules populated
7. CI workflow is valid YAML

When all checks pass, the scaffold is complete.

-----

## Phase 4: Develop Features (ongoing)

The scaffold is the starting point. From here, you use OpenSpec and the agent skills for every change.

### The development loop

```
1. Create a change proposal     /opsx:new add-batch-screening
2. Fast-forward to tasks        /opsx:ff
3. Implement                    /opsx:apply
4. Verify against spec          /run-spec-verify screening-restricted-parties
5. Security audit               /run-security-audit screening
6. Archive completed work       /opsx:archive
```

### Step by step

**Step 1: Create a change proposal**

```
/opsx:new add-batch-screening
```

OpenSpec creates a proposal file in `openspec/changes/` with scope, out-of-scope, and references to affected specs.

**Step 2: Fast-forward**

```
/opsx:ff
```

OpenSpec generates: proposal (if not already written), design (referencing CLAUDE.md conventions), tasks (each implementable in one session), and spec deltas (changes to existing specs). You review and approve.

**Step 3: Implement**

```
/opsx:apply
```

Claude Code reads the tasks and implements them, following the conventions in `CLAUDE.md` and the patterns established by the scaffold. Because the harness, types, errors, middleware, and test infrastructure already exist, the agent writes domain code only.

**Step 4: Verify**

```
/run-spec-verify screening-restricted-parties
```

The agent reads the spec, finds every MUST scenario in the traceability matrix, runs the matching tests, and reports:

```
Spec: screening-restricted-parties
MUST scenarios: 8 total, 7 passed, 0 failed, 1 missing
Coverage: 84% (threshold: 80%)

PASS  REQ-1 / Scenario 1 — Screen a party against all lists
PASS  REQ-1 / Scenario 2 — Batch screening
PASS  REQ-2 / Scenario 1 — Match despite name variations
PASS  REQ-2 / Scenario 2 — Match on partial identifiers
PASS  REQ-3 / Scenario 1 — No matches found
PASS  REQ-3 / Scenario 2 — Potential match requires review
PASS  REQ-3 / Scenario 3 — Analyst confirms false positive
MISSING  REQ-3 / Scenario 4 — Analyst confirms true match — no test found

Verdict: FAIL
```

Fix the missing test, run again until the verdict is PASS.

**Step 5: Security audit**

```
/run-security-audit screening
```

Runs auth-required (401), RBAC-enforced (403), SQL injection resistance, and IDOR protection tests against all screening endpoints.

**Step 6: Archive**

```
/opsx:archive
```

OpenSpec moves the completed change from `changes/` to `archive/`, preserving the full history of proposal, design, tasks, and deltas.

### Adding new domains

When you need an entirely new capability:

```
# 1. Write the spec
mkdir -p openspec/specs/supplier-management
# Write openspec/specs/supplier-management/spec.md

# 2. Create the domain module
/add-domain-module supplier-management

# 3. Add endpoints one at a time
/add-api-endpoint supplier-management create-supplier
/add-api-endpoint supplier-management list-suppliers

# 4. Add a migration for new tables
/add-migration create-suppliers-table
```

Each skill reads `CLAUDE.md` conventions, so the output is consistent with the rest of the codebase regardless of which session creates it.

-----

## Phase 5: Using Enhanced Claude Code Modes (recommended)

If you installed the enhanced-claude-code system, you have structured modes that prevent the agent from making mistakes during different phases of work.

### Recommended workflow for each feature

```
/explore    Investigate the codebase. Read-only. Cannot write files.
            "Show me how the screening middleware works"

/plan       Produce an implementation plan. Still read-only.
            "Plan how to add continuous re-screening"

/implement  Write code with safety gates. Requires plan first.
            (Agent follows the plan, writes code, runs tests)

/verify     Run verification protocol. Read + test only.
            (Two-level check: correctness + harness integrity)

/grill      Adversarial self-review before PR.
            (Edge cases, rollback safety, observability)
```

Mode enforcement is structural, not instructional. When you type `/explore`, the agent's write tools are removed from its capability set via `.claude/settings.json`. It cannot write files even if you ask it to. This prevents accidents during investigation.

### Multi-agent orchestration

For large projects, the enhanced system supports parallel agents:

- **Fork** -- read-only sub-agents for analysis. Near-zero cost after the first API call (shares the prompt cache).
- **Worktree** -- isolated git branches for parallel writes. Two agents can implement independent specs simultaneously.
- **Teammate** -- separate pane with file-based mailbox for long-running work.

Use `/dispatch` to decompose a task:

```
/dispatch
"Build the screening domain and the ITAR classification domain in parallel"
```

The agent creates a plan with scope boundaries (each agent works in its own domain folder), dependency checks, and a merge strategy.

-----

## Complete Example: ITAR/CFIUS Compliance Platform

The `_extracted/itar-cfius-compliance/` directory in this repo contains a fully scaffolded example with 20 specs across 5 domains.

### Domain map

| Domain | Specs | Owner |
|--------|-------|-------|
| **Security** | infosec-access-control, infosec-cmmc | Tech data security officer |
| **Platform** | platform-workflow-engine, platform-screening-engine, platform-license-tracker, platform-dashboard | GRC platform engineer |
| **Screening** | screening-restricted-parties, screening-deemed-exports, screening-end-use | Supply chain risk manager |
| **Regulatory** | itar-classification, itar-licensing, itar-disclosure, cfius-filing, cfius-mitigation, cfius-tid-analysis, gov-engagement | ITAR counsel, CFIUS counsel |
| **Governance** | compliance-governance, compliance-recordkeeping, audit-internal, training-program | Compliance architect, Audit lead |

### Build order (derived from spec dependencies)

The dependency map determines build order. Each spec lists what it depends on and what depends on it.

```
Layer 1 (no dependencies — build first):
  infosec-access-control

Layer 2 (depends on Layer 1):
  platform-workflow-engine

Layer 3 (depends on Layers 1-2, can be parallelized):
  platform-screening-engine    |  itar-classification
  screening-restricted-parties |  compliance-governance

Layer 4 (depends on Layer 3):
  itar-licensing               |  cfius-filing
  screening-deemed-exports     |  cfius-tid-analysis
  screening-end-use            |  platform-license-tracker

Layer 5 (depends on Layers 1-4):
  itar-disclosure              |  cfius-mitigation
  audit-internal               |  training-program
  compliance-recordkeeping     |  gov-engagement

Layer 6 (depends on everything):
  platform-dashboard
  infosec-cmmc
```

Specs on the same layer with a `|` between them have no cross-dependencies and can be built by separate agents simultaneously.

### Stack choices (from CLAUDE.md)

- **Frontend**: React + TypeScript + Tailwind CSS
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL with row-level security
- **Auth**: SAML 2.0 / OIDC SSO + MFA, RBAC with need-to-know enforcement
- **Screening integrations**: REST adapters for Visual Compliance, Descartes, OFAC SDN
- **Deployment**: AWS GovCloud (us-gov-west-1) + Bedrock

### Data boundary

This example enforces a strict data boundary in `CLAUDE.md`:

- No real ITAR technical data in the repo
- No real USML category assignments
- No real company names in test fixtures
- No real license numbers or case IDs
- All test data is synthetic, defined in `SYNTHETIC_DATA.md`

The platform manages compliance processes. It does not store defense articles or controlled technical data. Real data only exists in the deployed GovCloud environment.

-----

## Troubleshooting

**"OpenSpec CLI is not installed"**

The `new-project.sh` script handles this gracefully. It creates the directory structure manually and prints a reminder to install later. You can run `openspec init` at any time to enable CLI features.

**"Claude Code does not know my stack"**

Check that `CLAUDE.md` is in the project root (not in a subdirectory) and contains concrete stack choices, not placeholder comments.

**"The scaffold produced stubs instead of real code"**

SCAFFOLD.md explicitly says "Create real, working files. Never stubs. Never TODOs. Skip nothing." If Claude produced stubs, paste `prompt.md` again and point to the specific section. The shared infrastructure (types, errors, config, db, logger, middleware) should all be working code.

**"Agent skills are not available as slash commands"**

Verify that skill files exist at `.claude/commands/<skill-name>.md` (not in a subdirectory). Each file must start with a heading and contain the Steps section. Restart Claude Code after adding new skills.

**"Two agents modified the same file"**

The scaffold's conflict resolution rule is append-only for shared files. If two parallel agents both added types to `types.ts`, the harness agent reconciles (deduplicates, reorders) after both complete.

**"Spec verification fails with MISSING scenarios"**

This means a MUST scenario in the spec has no corresponding test in the traceability matrix. Write the test, add it to the matrix, and run `/run-spec-verify` again.

-----

## Quick Reference

### Commands you will use most

| Command | System | Purpose |
|---------|--------|---------|
| `./new-project.sh <name>` | SCAFFOLD | Bootstrap a new project |
| `/opsx:new <capability>` | OpenSpec | Create a change proposal |
| `/opsx:ff` | OpenSpec | Fast-forward: proposal to tasks |
| `/opsx:apply` | OpenSpec | Implement tasks against specs |
| `/add-domain-module <domain>` | SCAFFOLD skill | Create a new domain folder |
| `/add-api-endpoint <domain> <endpoint>` | SCAFFOLD skill | Add an endpoint with tests |
| `/run-spec-verify <spec>` | SCAFFOLD skill | Verify MUST scenarios pass |
| `/run-security-audit <domain>` | SCAFFOLD skill | Run security tests |
| `/add-migration <name>` | SCAFFOLD skill | Create a migration file |
| `/explore` | Enhanced Claude Code | Read-only investigation mode |
| `/plan` | Enhanced Claude Code | Produce implementation plan |
| `/implement` | Enhanced Claude Code | Write code with safety gates |
| `/verify` | Enhanced Claude Code | Run verification protocol |
| `/grill` | Enhanced Claude Code | Adversarial self-review |
| `/dispatch` | Enhanced Claude Code | Decompose into parallel agents |
| `/status` | Enhanced Claude Code | Report system state |

### File map

| File | Created by | Purpose |
|------|-----------|---------|
| `CLAUDE.md` | `new-project.sh` + SCAFFOLD Phase 3b | Stack choices + appended conventions |
| `prompt.md` | `new-project.sh` | Copy of SCAFFOLD.md (the build prompt) |
| `openspec/config.yaml` | `new-project.sh` + SCAFFOLD Phase 3c | Spec rules and NFR defaults |
| `openspec/specs/*/spec.md` | You | One spec per capability |
| `openspec/ACCEPTANCE.md` | SCAFFOLD Phase 3a | All MUST scenarios and pass/fail criteria |
| `openspec/SYNTHETIC_DATA.md` | SCAFFOLD Phase 3a | Test data conventions |
| `openspec/changes/` | `/opsx:new` | Active change proposals |
| `openspec/archive/` | `/opsx:archive` | Completed changes |
| `.claude/commands/*.md` | SCAFFOLD Phase 3c | Agent skills (slash commands) |
| `src/shared/` | SCAFFOLD Phase 3d | Types, errors, config, db, logger, middleware |
| `src/api/` | SCAFFOLD Phase 3d | Entry point and route registry |
| `src/<domain>/` | SCAFFOLD Phase 3d + `/add-domain-module` | One folder per domain |
| `src/db/migrations/` | SCAFFOLD Phase 3d + `/add-migration` | Sequential migrations |
| `src/test/` | SCAFFOLD Phase 3e | Factories, fixtures, mocks, setup |

-----

*This walkthrough covers the full lifecycle. For system architecture details, see `enhanced-claude-code/docs/architecture/context-engineering.md`. For SCAFFOLD internals, read `SCAFFOLD.md` directly -- it is 200 lines and fully self-contained.*
