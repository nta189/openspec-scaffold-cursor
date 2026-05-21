# Cursor Prompts

Copy one block. Attach relevant `@` paths.

---

## Ctrl+K — fix selection

```
Minimal fix only. Match local style. No drive-by refactors.
After: one line what changed + how to verify.
```

---

## Ctrl+K — explain selection

```
Explain behavior, invariants, and failure modes. No edits.
```

---

## Composer — feature from spec

```
@openspec/specs/<domain>/spec.md @IMPLEMENTATION.md

Plan (bullets) → implement → verify.
Real code only. Map each MUST scenario → test → PASS/FAIL.
```

---

## Composer — full scaffold

```
@SCAFFOLD.md @openspec/

Plan and wait for approval. Then implement per SCAFFOLD.
End with scenario → test → PASS/FAIL table.
```

---

## Composer — security pass (API change)

```
@SAFETY.md

For each changed endpoint: auth, RBAC, validation, injection, IDOR.
Table: endpoint | check | PASS/FAIL
```
