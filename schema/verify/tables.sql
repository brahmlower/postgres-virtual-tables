-- Verify vtable:tables on pg

BEGIN;

DO $$
    DECLARE
        count_table INTEGER;
        count_column INTEGER;
        count_cell INTEGER;
    BEGIN
        SELECT count(*) INTO count_table
        FROM information_schema.tables
        WHERE table_name LIKE 'vtable_table';
        ASSERT count_table = 1;

        SELECT count(*) INTO count_column
        FROM information_schema.tables
        WHERE table_name LIKE 'vtable_column';
        ASSERT count_column = 1;

        SELECT count(*) INTO count_cell
        FROM information_schema.tables
        WHERE table_name LIKE 'vtable_cell';
        ASSERT count_cell = 1;
    END
$$;

ROLLBACK;
