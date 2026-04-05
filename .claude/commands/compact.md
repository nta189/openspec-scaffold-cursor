Trigger context compaction now. Follow the cascade defined in MEMORY.md:

1. **Micro compact first** — Clear tool results older than 10 turns. Keep your interpretation of those results, discard the raw output.

2. **If still too large, context collapse** — Summarize intermediate conversation spans. Preserve: all decision points, all state transitions, last 5 turns verbatim, and any explicit user constraints.

3. **Before discarding anything important, extract session memory** — Write a session memory file to ./tmp/session-memory/ with:
   - Key decisions and rationale
   - Constraints discovered
   - Traps and anti-patterns (things tried that failed)
   - Deferred work
   - Current state summary

4. **After compaction, report:**
   - What was compacted (method used)
   - Estimated tokens freed
   - What was preserved
   - What was written to session memory (if applicable)

Never compact: system prompts, active safety flags, current workflow state, permission decisions, explicit user constraints, the active task specification, or loaded DECISIONS.md entries.

If this is an emergency compaction (context is critically full), inform me: "Context is critically full. I've preserved system instructions and recent work, but older context has been dropped. Re-state any earlier constraints that are still relevant."
