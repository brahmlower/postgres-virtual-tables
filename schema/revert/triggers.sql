-- Revert vtable:triggers from pg

BEGIN;

DROP TRIGGER IF EXISTS vtable_rebuild_on_insert ON vtable_column;
DROP TRIGGER IF EXISTS vtable_rebuild_on_update ON vtable_column;
DROP TRIGGER IF EXISTS vtable_rebuild_on_delete ON vtable_column;

COMMIT;
