# Composer / Agent (Ctrl+I) — Full Scaffold from Specs

Use for greenfield or large multi-file builds. Include: `@SCAFFOLD.md`, `@openspec/specs/`, `@CLAUDE.md` or `@.cursorrules`.

---

## System prompt (paste at start of Composer)

```
You are building from OpenSpec. Read @SCAFFOLD.md fully first.

Workflow:
1. planning — inventory specs under openspec/specs/*/spec.md; no writes yet
2. awaiting_approval — post file tree + milestone plan; wait for user OK
3. executing — create real files (no stubs/TODOs); minimal diff per domain
4. verifying — map each MUST scenario to a test; report PASS/FAIL

Include in context:
@openspec/
@DECISIONS.md
@IMPLEMENTATION.md
@docs/system/ (only files relevant to this feature)

Rules:
- Serialized writes: complete one domain layer before starting unrelated domains
- After each domain: run tests for that package
- Append new conventions to project docs only when SCAFFOLD §2 requires it

Deliverables:
- openspec/ACCEPTANCE.md
- openspec/SYNTHETIC_DATA.md
- Implementation + tests per spec
- Final verification table: scenario → test path → PASS/FAIL
```

---

## Incremental feature (existing codebase)

```
Feature: <name>
Spec: @openspec/specs/<domain>/spec.md

Plan (3–6 bullets) → implement → verify.

Touch only:
- src/<domain>/**
- related tests
- docs if API contract changes (@docs/system/02-api-contracts.md)

Do not mark done until IMPLEMENTATION.md Level 1 + scenario tests pass.
```

---

## Multi-repo change

```
Cross-repo task. Read before coding:
@docs/system/03-cross-repo-flows.md
@docs/system/00-system-overview.md

List repos/paths affected. One repo per execution batch unless user approves parallel agents.
```
