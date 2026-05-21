# Mode: Verify

**Cursor:** Agent focused on validation; avoid feature edits.

```
VERIFY MODE — read + test only.

Context: @IMPLEMENTATION.md @openspec/specs/<domain>/spec.md

Task: Verify <feature or PR scope>

Steps:
1. Map each MUST scenario → test file:line or gap
2. Run targeted test commands (document exact commands)
3. Run lint/typecheck on affected packages
4. Security spot-check per @skills/run-security-audit.md if API touched

Output table:
| Scenario | Test | Result |
|----------|------|--------|

End with: PASS (ship) | FAIL (list blockers with file paths)
```
