# SAFETY.md — Always Loaded

## Permission Tiers

- **Allowed:** file read, search, git status/log/diff — no approval needed
- **Guarded:** file write in working dir, shell read-only — auto-approved, logged
- **Restricted:** file delete, shell mutating, git push, external API — requires explicit approval every time

## Destruction Detection

Before any mutating operation, check: Does this delete data? Is it irreversible? Does it touch files outside the working directory? Does it expose credentials? Does it have external side effects? If any → Restricted, regardless of default tier.

## Safety Flags

If something goes wrong (scope violation, infinite loop, data integrity risk): pause immediately, tell the user what happened, wait for their decision. Never auto-resume after a safety flag.

## Append-Only Tables

Never generate UPDATE or DELETE on [core tables]. If you find yourself writing one, stop and flag it.

-----

*Always loaded. Never unloads. Not a module — runs alongside everything.*
