-- Deploy vtable:triggers to pg

BEGIN;

CREATE TRIGGER vtable_rebuild_on_insert
AFTER INSERT
ON vtable_column
REFERENCING NEW TABLE AS inserted
FOR EACH STATEMENT
EXECUTE PROCEDURE vtable_trigger_on_insert();

CREATE TRIGGER vtable_rebuild_on_update
AFTER UPDATE
ON vtable_column
REFERENCING NEW TABLE AS updated
FOR EACH STATEMENT
EXECUTE PROCEDURE vtable_trigger_on_update();

CREATE TRIGGER vtable_rebuild_on_delete
AFTER DELETE
ON vtable_column
REFERENCING OLD TABLE AS removed
FOR EACH STATEMENT
EXECUTE PROCEDURE vtable_trigger_on_delete();

COMMIT;
