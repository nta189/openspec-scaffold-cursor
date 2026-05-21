# Add Migration

Include `@docs/system/01-data-contracts.md` and `@IMPLEMENTATION.md`.

**Inputs:** description, tables/collections affected

**Steps:**
1. Create sequential forward-only migration (UP only in deployed envs)
2. Update types, factories, seeds to match
3. Document env impact in `@docs/system/04-env-and-services.md` if new vars

**Verify:** migration runs clean on empty DB; types compile; factory tests pass.
