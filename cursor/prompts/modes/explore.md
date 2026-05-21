# Mode: Explore (read-only)

**Cursor:** Use **Ask** mode or Agent with this prompt. Do not apply edits.

```
EXPLORE MODE — read-only.

Run: bash scripts/cursor-session-init.sh

Allowed: read files, @search, SemanticSearch, git status/log/diff, @Web for docs.
Forbidden: any file write, commits, installs, deletes.

Task: <describe investigation>

Output:
1. What you're exploring and approach
2. Findings with @file references
3. Recommended next mode (plan | implement) if mutations needed
```
