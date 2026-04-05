Knowing everything you know now, scrap the current approach and implement the elegant solution.

Constraints:
- Keep public APIs stable. No breaking changes to any endpoint contract, component prop interface, or database schema that other systems depend on.
- Minimize churn. Every line changed must earn its place. If the existing code is fine, leave it.
- Leave the codebase simpler than before. The diff should reduce total complexity, not redistribute it.
- Follow existing codebase patterns. This is a rebuild, not a rewrite in a new style.

Process:
1. **Before/After design** — Show the current design and proposed design in 8-12 bullets. Make the tradeoffs explicit.
2. **Blast radius** — What breaks if this is wrong? What's the rollback path?
3. **Migration path** — Can this ship incrementally, or is it all-or-nothing?
4. **Get approval** — Do not start coding until the user approves the design.

After approval, implement with:
- Minimal diff (remove more lines than you add)
- All tests passing
- No TODOs, no "we can clean this up later"
- A brief DECISIONS.md entry documenting the rationale

The test for success: would a senior engineer reviewing this PR say "this is cleaner and I understand exactly why every change was made"?
