-- Revert vtable:tables from pg

BEGIN;

DROP TABLE vtable_cell;
DROP TABLE vtable_column;
DROP TABLE vtable_table;

COMMIT;
