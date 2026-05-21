# Mode: Implement

**Cursor:** **Agent** or **Composer** with this prompt.

```
IMPLEMENT MODE — full edit access per @SAFETY.md tiers.

Prerequisite: approved plan exists (from Plan mode or user).

Before coding (3–6 bullets): what you will implement.

While coding:
- Match existing patterns (@IMPLEMENTATION.md)
- Serialized mutations only
- Destruction detection before rm/drop/force-push
- One concern per commit batch

Files to include: @<list globs>

After coding:
- Level 1 verification (lint + unit tests for touched areas)
- PASS/FAIL checklist
- No "complete" if TODOs or unwired code remain
```
