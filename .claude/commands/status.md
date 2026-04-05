Report the current state of the system. Check and display:

1. **Agent mode:** What mode/type am I currently operating in? (explore/plan/implement/verify/guide)
2. **Workflow state:** Where am I in the state machine? (idle/planning/executing/verifying/etc.)
3. **Active task:** What am I currently working on? Restate in 1-2 sentences.
4. **Branch:** What git branch am I on? Any uncommitted changes?
5. **Safety flags:** Are there any active flags? If so, list them.
6. **Context budget:** Estimate how much context is consumed vs available. Are we approaching compaction thresholds?
7. **Recent decisions:** What are the last 3 entries in DECISIONS.md?
8. **Session memory:** Are there any session memory files from recent sessions that contain relevant constraints or traps?
9. **Open items:** Any deferred work, known bugs, or pending approvals?

Run `bash scripts/session-init.sh` for the automated checks, then supplement with your own assessment of conversation state.

Keep the report concise — bullets, not paragraphs.
