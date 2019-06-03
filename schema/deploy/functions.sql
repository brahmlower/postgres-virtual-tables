-- Deploy vtable:functions to pg

BEGIN;

CREATE EXTENSION tablefunc;

CREATE OR REPLACE FUNCTION vtable_insert(
        IN target_table_id INTEGER,
        IN row_values TEXT[],
        OUT row_id INTEGER
    ) RETURNS INTEGER
    AS $$
        DECLARE
            col_id_array INTEGER[];
            new_item INTEGER;
            i TEXT;
        BEGIN
            -- Get the IDs for the columns representing this row
            SELECT array_agg(col_ids.id) INTO col_id_array
            FROM (
                SELECT id
                FROM vtable_column
                WHERE table_id = target_table_id ORDER BY column_position
            ) col_ids;
            -- Check if the values given are equal to the length of the row.
            IF array_length(col_id_array, 1) != array_length(row_values, 1) THEN
                RAISE EXCEPTION 'Incorrect number of values. Expected %, but got %', array_length(col_id_array, 1), array_length(row_values, 1);
            END IF;
            -- Create a new row entry for the virtual table. The row_id value is
            -- determines based on existing row IDs in the vtable_cells table.
            SELECT COALESCE(MAX(c.row_id), 0)+1 INTO row_id
            FROM vtable_cell AS c
            WHERE table_id = target_table_id;
            -- Begin inserting each cell for the record
            FOR i IN 1 .. array_length(row_values, 1) LOOP
                RAISE NOTICE 'Inserting (%, %, %, %)', target_table_id, row_id, col_id_array[i], row_values[i];
                INSERT INTO vtable_cell
                    (id, table_id, row_id, column_id, cell_value)
                VALUES
                    (DEFAULT, target_table_id, row_id, col_id_array[i], row_values[i])
                RETURNING id INTO new_item;
                RAISE NOTICE 'New cell row is: %', new_item;
            END LOOP;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_delete(
        IN target_table_id INTEGER
    ) RETURNS VOID
    AS $$
        BEGIN
            PERFORM vtable_view_delete(target_table_id);
            PERFORM vtable_func_delete(target_table_id);
            DELETE FROM vtable_cell WHERE table_id = target_table_id;
            DELETE FROM vtable_column WHERE table_id = target_table_id;
            DELETE FROM vtable_table WHERE id = target_table_id;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_alter_remove_column(
        IN target_table_id INTEGER,
        IN target_column_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            col_id_array INTEGER[];
        BEGIN
            -- Delete all data associated with the vtable for the specified column
            DELETE FROM vtable_cell
            WHERE   table_id = target_table_id
                AND column_id = target_column_id;
            -- Delete the column from the specified table
            DELETE FROM vtable_column
            WHERE   table_id = target_table_id
                AND id = target_column_id;
            -- Select the IDs for the remaining columns in order of their position
            SELECT array_agg(col_ids.id) INTO col_id_array
            FROM (
                SELECT id
                FROM vtable_column
                WHERE table_id = target_table_id
                ORDER BY column_position
            ) col_ids;
            -- Update the column positions for the remaining columns on the table
            -- Range is 1-N because it's used for an array index, which is 1-index
            -- in postgres
            FOR i IN 1 .. array_length(col_id_array, 1) LOOP
                UPDATE vtable_column SET column_position = i WHERE id = col_id_array[i] AND column_position != i;
            END LOOP;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_alter_add_column(
        IN target_table_id INTEGER,
        IN new_column_name TEXT,
        IN new_column_type TEXT,
        IN new_column_position INTEGER
    ) RETURNS SETOF vtable_column
    AS $$
        DECLARE
            col_id_array INTEGER[];
            new_col_id INTEGER;
            new_col_id_array INTEGER[];
        BEGIN
            -- Select the IDs of the columns in order of their position
            SELECT array_agg(col_ids.id) INTO col_id_array
            FROM (
                SELECT id
                FROM vtable_column
                WHERE table_id = target_table_id
                ORDER BY column_position
            ) col_ids;
            -- Create the record to represent the new column. We've set it's
            -- column position to be very large, so that it's likely after all
            -- existing columns. The column position will be updated next.
            INSERT INTO vtable_column
                (id, table_id, column_name, column_type, column_position)
            VALUES
                (DEFAULT, target_table_id, new_column_name, new_column_type, 9000) --TODO: This is stupid and hacky. Find a better way.
            RETURNING id INTO new_col_id;
            -- Calculate the new ordering for the columns
            new_col_id_array := array_cat(
                array_append(col_id_array[:new_column_position-1], new_col_id),
                col_id_array[new_column_position:]
            );
            -- RAISE NOTICE 'Looping on columns: %', new_col_id_array;
            -- Update the position value for each of the tables columns
            -- Range is 1 through N because it's used for an array index, which
            -- is 1-index in postgres
            FOR i IN REVERSE array_length(new_col_id_array, 1) .. 1 LOOP
                -- RAISE NOTICE 'Updating column position for column %, with position %', new_col_id_array[i], i;
                UPDATE vtable_column
                SET column_position = array_position(new_col_id_array, new_col_id_array[i])
                WHERE id = new_col_id_array[i];
            END LOOP;
            -- Now get the new column we added
            RETURN QUERY SELECT * FROM vtable_column WHERE id = new_col_id;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_func_delete(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            func_name TEXT := vtable_get_func_name(vtable_id);
        BEGIN
            EXECUTE format(
                $delete_func$
                    DROP FUNCTION IF EXISTS %1$s;
                $delete_func$,
                func_name
            );
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_get_func_name(
        IN vtable_id INTEGER
    ) RETURNS TEXT
    AS $$
        BEGIN
            RETURN 'vtable_' || vtable_id::TEXT;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_get_view_name(
        IN vtable_id INTEGER,
        OUT view_name TEXT
    ) RETURNS TEXT
    AS $$
        BEGIN
            SELECT table_name INTO view_name
            FROM vtable_table
            WHERE id = vtable_id;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_func_creator(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            creator_sql TEXT;
            func_name TEXT := vtable_get_func_name(vtable_id);
            func_body_raw TEXT;
            func_body TEXT;
            func_def TEXT;
        BEGIN
            -- TODO: Validate that the provided vtable ID actually exists.

            -- Build the return type of the table that will be returned by the
            -- crosstab call. Technically, we kinda already know this in the
            -- function, but at the moment it's easier to rebuild this into a
            -- string and then template it into the dynamic sql.
            -- The 'id' column is added by the crosstab function itself. I could
            -- probably find a way to prevent it from showing through, but it's
            -- an easy unique primary key to use. They just wont be sequential
            -- for a given virtual table. Because of this, I have to manually
            -- specify that this column exists, since it's not represented in the
            -- vtable_column table.
            -- TODO: Investigate copying a table schema as a string
            SELECT
                'id integer, ' || string_agg(
                    c.column_name || ' ' || c.column_type,
                    ', '
                    ORDER BY c.column_position
                )
            INTO func_def
            FROM vtable_column AS c
            WHERE c.table_id = vtable_id;

            func_body_raw := $func_body$
                BEGIN
                    RETURN QUERY
                    SELECT *
                    FROM crosstab($query$
                        SELECT
                            v.row_id,
                            c.column_name,
                            v.cell_value
                        FROM vtable_cell AS v
                        LEFT JOIN vtable_column AS c ON v.column_id = c.id
                        WHERE c.table_id = %2$s
                        ORDER BY v.row_id, c.column_position
                    $query$, $col_query$
                        SELECT column_name
                        FROM vtable_column
                        WHERE table_id = %2$s
                        ORDER BY column_position;
                    $col_query$) AS catalog(%1$s);
                END;
            $func_body$;

            func_body := format(func_body_raw, func_def, vtable_id);

            creator_sql := $creator$
                CREATE FUNCTION %1$s()
                RETURNS TABLE (%2$s) AS %3$L
                LANGUAGE plpgsql;
            $creator$;

            EXECUTE format(creator_sql, func_name, func_def, func_body);
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_view_delete(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            view_name TEXT := vtable_get_view_name(vtable_id);
        BEGIN
            EXECUTE format(
                $delete_func$
                    DROP VIEW IF EXISTS %1$s;
                $delete_func$,
                view_name
            );
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_view_creator(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            func_name TEXT := vtable_get_func_name(vtable_id);
            view_name TEXT := vtable_get_view_name(vtable_id);
        BEGIN
            EXECUTE format(
                $create_view$
                    CREATE VIEW %1$s AS SELECT * FROM %2$s()
                $create_view$,
                view_name,
                func_name
            );
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_access_rebuild(
        IN target_table_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            column_count INTEGER;
        BEGIN
            PERFORM vtable_view_delete(target_table_id);
            PERFORM vtable_func_delete(target_table_id);
            -- If there are no more columns left, we don't need an an access
            -- function or view, since the table cannot hold data
            SELECT count(*) INTO column_count FROM vtable_column WHERE table_id = target_table_id;
            IF column_count > 0 THEN
                PERFORM vtable_func_creator(target_table_id);
                PERFORM vtable_view_creator(target_table_id);
            END IF;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_trigger_on_insert(
    ) RETURNS TRIGGER
    AS $$
        DECLARE
            table_id INTEGER;
        BEGIN
            SELECT DISTINCT(inserted.table_id) INTO table_id
            FROM inserted
            LIMIT 1;
            RAISE NOTICE 'Insert trigger, table_id: %', table_id;
            PERFORM vtable_access_rebuild(table_id);
            RETURN NEW;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_trigger_on_update(
    ) RETURNS TRIGGER
    AS $$
        DECLARE
            table_id INTEGER;
        BEGIN
            SELECT DISTINCT(updated.table_id) INTO table_id
            FROM updated
            LIMIT 1;
            IF table_id IS NULL THEN
                -- This happens when we run an update statement on the table but
                -- none of the records meet the conditional. Therefore reaching
                -- this state isn't considered and error, and hardly warrants a
                -- warning. Setting to notice for now.
                RAISE NOTICE 'Failed to get table_id from updated record';
            ELSE
                RAISE NOTICE 'Update trigger, table_id: %', table_id;
                PERFORM vtable_access_rebuild(table_id);
            END IF;
            RETURN NEW;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_trigger_on_delete(
    ) RETURNS TRIGGER
    AS $$
        DECLARE
            table_id INTEGER;
        BEGIN
            SELECT DISTINCT(removed.table_id) INTO table_id
            FROM removed
            LIMIT 1;
            RAISE NOTICE 'Delete trigger, table_id: %', table_id;
            PERFORM vtable_access_rebuild(table_id);
            RETURN OLD;
        END;
$$ LANGUAGE plpgsql;

COMMIT;
