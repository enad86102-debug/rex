-- DANGER: destructive candidate-only evaluation rollback. Never execute on production.
-- Use only on the dedicated isolated rex_ci database when deliberately resetting test data.
BEGIN;
DROP SCHEMA IF EXISTS rex_candidate CASCADE;
COMMIT;
