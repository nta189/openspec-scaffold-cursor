# Mode: Plan

**Cursor:** Use **Plan** mode or read-only Agent with this prompt.

```
PLAN MODE — no implementation.

Context: @AGENT.md @DECISIONS.md @<relevant spec or module>

Task: <describe goal>

Deliver:
1. Current state (3–5 bullets)
2. Proposed approach (numbered steps)
3. Files/globs to touch
4. Risks + rollback
5. Verification criteria (from spec MUST scenarios)
6. Explicit question if approval needed before implement

Do not write code. End with: "Reply approve to proceed in Implement mode."
```
