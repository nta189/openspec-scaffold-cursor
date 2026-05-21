# Cursor Migration Quality Assessment

**Repository:** OpenSpec Scaffold (`openspec-scaffold-cursor`)  
**Assessment date:** 2026-05-20  
**Assessor scope:** Full Claude-native asset inventory (system docs, `.claude/` commands & modes, `skills/`, `scripts/`, `lite/` variant, architecture docs)

---

## Executive Summary

| Metric | Score |
|--------|-------|
| **Total** | **73 / 100** |
| Context Efficiency & Token Savings | 16 / 25 |
| Multi-file & Composer Readiness | 17 / 25 |
| Automation & Terminal Synergy | 18 / 25 |
| Actionability & Precision | 22 / 25 |

This repository is a **high-quality, production-oriented AI agent operating system** with exceptional safety, workflow, and verification design. It is **not yet optimized for Cursor IDE**—it targets Claude Code's `CLAUDE.md` auto-load, `.claude/settings.json` permission matrices, and `switch-mode.sh` structural enforcement.

---

## Score Breakdown

### 1. Context Efficiency & Token Savings — **16 / 25**

**Strengths**
- Layered documentation (`CLAUDE.md` → `AGENT.md` → `IMPLEMENTATION.md` → modules) reduces unnecessary loading.
- Explicit "load when" tables and module loading order.
- Prompt cache prefix concept (stable vs variable suffix) shows deliberate token economics.
- Skills are short, step-based checklists (~40 lines) instead of monolithic prompts.

**Deductions (−9)**
| Gap | Impact |
|-----|--------|
| No `@file` / `@folder` / `@Git` / `@Web` usage patterns | Cursor's primary context injection is unused; agents rely on "read file X" prose |
| `CLAUDE.md` + `SAFETY.md` treated as always-loaded (~4k+ tokens) | No equivalent to Cursor's `alwaysApply` rules split into small `.mdc` slices |
| Claude-specific token math (200k window, PTL truncation, API projection) | Irrelevant in Cursor; adds noise without actionable hooks |
| Placeholder-heavy templates (`[Project Name]`, `[Surface 1]`) | Wastes tokens until customized; no "minimal core" variant for Cursor |
| No `AGENTS.md` or `.cursor/rules/` modularization | Single large identity file vs Cursor's composable rule files |

**Path to 25/25:** Split identity into `.cursor/rules/*.mdc` with `alwaysApply: true` only for safety + session protocol; reference `DECISIONS.md`, `docs/system/*` via `@` mentions; delete Claude-only token cascade from always-on rules.

---

### 2. Multi-file & Composer Readiness — **17 / 25**

**Strengths**
- `IMPLEMENTATION.md` defines concurrent vs serialized tool partitioning—maps well to Composer parallel reads + sequential writes.
- Skills (`add-api-endpoint`, `add-domain-module`, etc.) are multi-file mutation playbooks.
- Workflow state machine in `AGENT.md` aligns with Plan → Execute → Verify agent loops.
- `SCAFFOLD.md` is a strong Composer-scale "build entire project from specs" prompt.
- Cross-repo `docs/system/` contract tables support large refactors.

**Deductions (−8)**
| Gap | Impact |
|-----|--------|
| Mode enforcement via `bash scripts/switch-mode.sh` + `.claude/settings.json` | Cursor has no native equivalent; modes are instructional only unless replicated with rules + user discipline |
| Sub-agent dispatch / Fork cache inheritance | Cursor uses Task subagents differently; docs don't map to `@agent` or Composer multi-agent |
| `.claude/commands/*.md` slash commands | Not portable to Cursor Commands (`.cursor/commands` or custom prompts) without conversion |
| No Composer-specific "touch these paths" scoping | Skills don't list target globs for `@` inclusion |
| `lite/` duplicate tree | Maintenance burden; no Cursor-specific slim variant |

**Path to 25/25:** Add `.cursor/commands/` mirrors of slash commands; Composer prompts with explicit file globs; Plan mode as Cursor Plan + read-only rule; map agent types to Cursor Agent vs Ask vs Debug modes.

---

### 3. Automation & Terminal Synergy — **18 / 25**

**Strengths**
- Rich `scripts/` suite: `session-init.sh`, `checkpoint.sh`, `check-secrets.sh`, `verify-harness.sh`, safety logging.
- `.claude/settings.json` hooks: PostToolUse (Prettier), Stop (auto-checkpoint).
- `.githooks/pre-commit` integration.
- `bootstrap.sh` creates full directory scaffolding.
- Fail-open hook policy documented in `IMPLEMENTATION.md`.

**Deductions (−7)**
| Gap | Impact |
|-----|--------|
| Hooks use Claude Code API (`$CLAUDE_FILE_PATH`, schemastore settings) | Won't run in Cursor without migration to `hooks.json` (Cursor hooks skill) |
| Bash-first on Windows dev environments | No `cursor-session-init.ps1`; session-init assumes Unix |
| No integration with Cursor's built-in linter diagnostics loop | Verification is doc-driven, not "read lints → fix → re-run" |
| `switch-mode.sh` requires Python3 for JSON merge | Extra friction vs rule-based mode switching |
| No CI snippet for Cursor Agent SDK / cloud agents | Future automation path undocumented |

**Path to 25/25:** Port hooks to Cursor `hooks.json`; add `scripts/cursor-session-init.sh` + PowerShell twin; wire Stop → checkpoint; document terminal-first debug loop in rules.

---

### 4. Actionability & Precision — **22 / 25**

**Strengths**
- Skills use numbered steps, verification checklists, and explicit inputs.
- Commands (`/implement`, `/explore`) open with **executable** mode switch commands.
- `SAFETY.md` destruction detection tables are operational, not aspirational.
- Non-negotiable rules are numbered and testable.
- Low corporate fluff; high directive density in commands and skills.

**Deductions (−3)**
| Gap | Impact |
|-----|--------|
| Domain-specific decision table rows (Twilio, web_token, etc.) | Noise for generic scaffold consumers until templated away |
| Some duplication across `CLAUDE.md`, `AGENT.md`, `SAFETY.md` (append-only, log-before-send) | Minor token waste |
| `GETTING-STARTED.md` / README still Claude Code-centric | Onboarding friction for Cursor users |

**Path to 25/25:** Cursor-specific quick-start; deduplicate always-on rules into one `.mdc`; keep domain tables in optional `modules/` rules with globs.

---

## Asset Inventory (Input Analyzed)

| Category | Paths | Lines (approx.) | Cursor readiness |
|----------|-------|-----------------|------------------|
| System identity | `CLAUDE.md` | 254 | Needs rename → `AGENTS.md` + rules |
| Safety | `SAFETY.md` | 200+ | Convert to `safety.mdc` |
| Decision brain | `AGENT.md` | 218+ | Convert to `agent-workflow.mdc` |
| Build manual | `IMPLEMENTATION.md` | 350+ | Convert to `implementation.mdc` (globs) |
| Memory | `MEMORY.md` | 240+ | Cursor-adapted subset only |
| Commands | `.claude/commands/*.md` (14) | ~15–40 each | → `.cursor/commands/` or `cursor/prompts/` |
| Modes | `.claude/modes/*.json` (5) | N/A | → Rules + user prompts (no JSON swap) |
| Skills | `skills/*.md` (5) | ~35–40 each | → Cursor commands / Composer prompts |
| Scripts | `scripts/*.sh` (12+) | Operational | Add Cursor entrypoints |
| Docs | `docs/architecture/context-engineering.md` | 150+ | Update for Cursor mental model |

---

## Gap Analysis: Claude → Cursor Architectural Drift

| Claude Pattern | Status in Cursor | Migration Action |
|----------------|------------------|------------------|
| `CLAUDE.md` auto-loaded every session | `AGENTS.md` + `.cursor/rules/` + optional `.cursorrules` | Split layers; use `@` for on-demand docs |
| `.claude/settings.json` permission deny lists | No file-level tool ACL | Enforce via rules + Ask mode + user approval habits |
| `switch-mode.sh` structural modes | Instructional only | Replace with mode-specific Composer/Chat prompts + `alwaysApply` toggles |
| Slash commands in `.claude/commands/` | Cursor Commands (beta) or saved prompts | Copy converted templates to `.cursor/commands/` |
| Claude Code hooks (`PreToolUse`, `Stop`) | Cursor `hooks.json` | Port checkpoint + format-on-save |
| Fork / sub-agent cache prefix | Task tool + separate chats | Document parallel explore vs single Composer |
| Token projection / compaction cascade | Cursor-managed context | Keep only "write decisions to `DECISIONS.md`" survival rules |
| Tool registry in prose | Cursor built-in tools (SemanticSearch, Shell, etc.) | Map tiers to "ask before destructive shell" rule |

---

## Priority Migration Roadmap

1. **P0 (done in this migration):** `cursor_migration_assessment.md`, `.cursorrules`, `.cursor/rules/`, `cursor/prompts/`, `scripts/cursor-session-init.sh`
2. **P1:** Rename onboarding docs; add `CURSOR.md` quick-start; convert all 14 commands + 5 skills to `.cursor/commands/`
3. **P2:** Port hooks to `hooks.json`; PowerShell session-init; `bootstrap-cursor.sh`
4. **P3:** Cursor Agent SDK CI recipes; `@Web` research protocol for explore mode

---

## Target State (100/100)

- **Context:** &lt;2k tokens always-on via 3–4 `.mdc` rules; everything else `@`-referenced on demand.
- **Composer:** Every skill lists `Files to include` globs; state machine referenced in Composer system prompt.
- **Automation:** Session init runs from terminal rule; hooks checkpoint on agent stop; secrets scan on commit.
- **Actionability:** Zero Claude-specific APIs in active paths; dual README (Claude legacy + Cursor primary).

---

*This assessment is the canonical pre-migration score. Re-score after P1–P3 complete.*

---

## Post-Prune (Cursor-only layer, 2026-05-20)

**Filtration applied:** removed Claude mode switching, session-init wrappers, duplicate `.mdc` always-on rules, workflow state machine prose, serialized-tool partitioning, tier tables duplicated across files, and six scattered prompt files.

| Asset | Before prune | After prune |
|-------|----------------|-------------|
| Always-on rules | `.cursorrules` + 3× `.mdc` (~3k tokens) | `.cursorrules` (~400 tokens) + `coding.mdc` (glob only) |
| Prompts | 6 files | 1 file (`cursor/prompts.md`) |
| Commands | verbose | ~6 lines each |
| Cursor scripts | `cursor-session-init.*` | removed (use `@DECISIONS.md` + terminal natively) |

**Estimated Cursor config score after prune:** ~88/100 (remaining gap: legacy `CLAUDE.md` still in repo for reference; optional `hooks.json` not ported).
