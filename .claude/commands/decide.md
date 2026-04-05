We need to make and record an architectural decision. Follow the ADR format in DECISIONS.md.

Process:
1. **Identify the decision.** What question are we answering? What tradeoff are we resolving?

2. **Check for conflicts.** Read the existing entries in DECISIONS.md. Does any accepted entry constrain this area? If so, acknowledge it — we're either operating within that constraint or explicitly superseding it.

3. **Present options.** For each viable alternative:
   - What is it?
   - What are the pros?
   - What are the cons?
   - What does it optimize for?

4. **Recommend.** State which option you'd choose and why. Be explicit about the tradeoff.

5. **Wait for approval.** Do not write the entry until the user confirms the decision.

6. **Write the entry.** Append to DECISIONS.md using the exact format:
   ```
   ### ADR-[NNN] — [Title]
   **Date:** [today's date]
   **Status:** accepted
   **Context:** [why we're making this decision]
   **Decision:** [what we decided, specific enough to act on]
   **Consequences:** [what changes, positive and negative]
   **Alternatives Considered:** [what else we evaluated and why we rejected it]
   ```

7. **If superseding a previous decision**, update the old entry's status line to `superseded by ADR-[NNN]`. This is the only permitted edit to an existing entry.

Number the ADR sequentially. Check the last entry number before assigning.
