# Cursor Inline Edit (Ctrl+K) — Quick Templates

Copy the block that matches your task. Attach `@Files` for the selection scope.

---

## Fix with minimal diff

```
Apply the smallest correct fix. Match surrounding style. No refactors.
After edit: state what changed and one verification step (test or lint).
@Files: <current file>
```

---

## Add types / tighten types

```
Add or fix TypeScript types without changing runtime behavior.
Types live in the project's api/types module if one exists — do not duplicate.
@Files: <selection>
```

---

## Extract component / function

```
Extract a focused unit with a clear name. Update imports and call sites.
Keep behavior identical. Max 300 lines per component file.
@Files: <selection>
```

---

## Test for selection

```
Write one focused test for the selected behavior.
Cover: happy path + one failure case. Use existing test patterns in @<nearest __tests__ folder>.
```

---

## Explain selection

```
Explain what this code does, invariants, and failure modes. No edits.
Reference related symbols with @ if needed.
```

---

## Safe refactor

```
Refactor for clarity only. Preserve behavior. Run no destructive commands.
List files touched before editing. @SAFETY.md destructive rules apply.
```
