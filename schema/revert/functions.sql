-- Revert vtable:functions from pg

BEGIN;

DROP FUNCTION vtable_insert;
DROP FUNCTION vtable_delete;
DROP FUNCTION vtable_alter_remove_column;
DROP FUNCTION vtable_alter_add_column;
DROP FUNCTION vtable_func_delete;
DROP FUNCTION vtable_get_func_name;
DROP FUNCTION vtable_get_view_name;
DROP FUNCTION vtable_func_creator;
DROP FUNCTION vtable_view_delete;
DROP FUNCTION vtable_view_creator;
DROP FUNCTION vtable_access_rebuild;
DROP FUNCTION vtable_trigger_on_insert;
DROP FUNCTION vtable_trigger_on_update;
DROP FUNCTION vtable_trigger_on_delete;
DROP EXTENSION tablefunc;

COMMIT;
