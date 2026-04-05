Read CLAUDE.md conventions before executing.

## Inputs
- `name` — migration name (e.g., "add-screening-results-table")
- `description` — what this migration does

## Steps

1. Determine the next sequential migration number by reading `src/db/migrations/` (or `db/migrations/` per project convention). Use format: `NNN_<name>.sql` (e.g., `002_add_screening_results.sql`).

2. Create the migration file with up and down sections:
   ```sql
   -- Migration: NNN_<name>
   -- Description: <description>
   -- Created: <timestamp>

   -- UP
   <CREATE TABLE / ALTER TABLE / CREATE INDEX statements>

   -- DOWN
   <DROP TABLE / ALTER TABLE / DROP INDEX statements — reverse of UP>
   ```

3. Follow CLAUDE.md data layer conventions:
   - Table naming: snake_case, plural
   - Primary key: `id UUID DEFAULT gen_random_uuid()`
   - Timestamps: `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
   - Soft delete: `deleted_at TIMESTAMPTZ` (if applicable per conventions)
   - Foreign keys: `<entity>_id UUID REFERENCES <table>(id)`
   - Index naming: `idx_<table>_<column>`

4. If the migration adds a new entity, also:
   - Add the entity's ID type to `src/shared/types.ts`
   - Add a factory to `src/test/factories/`
   - Update `src/db/seed.ts` with sample data per SYNTHETIC_DATA.md

## Verification
- [ ] Migration file has correct sequential number
- [ ] UP and DOWN sections are both present and reversible
- [ ] Naming conventions match CLAUDE.md
- [ ] Types, factory, and seed updated if new entity
