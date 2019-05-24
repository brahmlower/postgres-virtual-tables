
CREATE EXTENSION tablefunc;

CREATE TABLE IF NOT EXISTS vtable_table(
    id          SERIAL PRIMARY KEY,
    table_name  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vtable_column(
    id                  SERIAL PRIMARY KEY,
    table_id            INTEGER REFERENCES vtable_table(id) NOT NULL,
    column_name         TEXT NOT NULL,
    column_type         TEXT NOT NULL,
    column_references   TEXT,
    column_position     INTEGER NOT NULL,
    CONSTRAINT unq_column_name UNIQUE (table_id, column_name),
    CONSTRAINT unq_column_position UNIQUE (table_id, column_position)
);

CREATE TABLE IF NOT EXISTS vtable_cell(
    id          SERIAL PRIMARY KEY,
    table_id    INTEGER REFERENCES vtable_table(id) NOT NULL,
    row_id      INTEGER NOT NULL,
    column_id   INTEGER REFERENCES vtable_column(id) NOT NULL,
    cell_value  TEXT NOT NULL,
    CONSTRAINT unq_table_cell UNIQUE (table_id, row_id, column_id)
);

CREATE OR REPLACE FUNCTION vtable_insert(
        IN target_table_id INTEGER,
        IN row_values TEXT[]
    ) RETURNS VOID
    AS $$
        DECLARE
            col_id_array INTEGER[];
            row_id INTEGER;
            i TEXT;
        BEGIN
            -- Get the IDs for the columns representing this row
            SELECT array_agg(col_ids.id) INTO col_id_array
            FROM (
                SELECT id
                FROM vtable_column
                WHERE table_id = 100 ORDER BY column_position
            ) col_ids;
            -- Check if the values given are equal to the length of the row.
            IF array_length(col_id_array, 1) != array_length(row_values, 1) THEN
                RAISE EXCEPTION 'Incorrect number of values. Expected %, but got %', array_length(col_id_array, 1), array_length(row_values, 1);
            END IF;
            -- Create a new row entry for the virtual table. The row_id value is
            -- determines based on existing row IDs in the vtable_cells table.
            SELECT COALESCE(MAX(c.row_id), 0)+1 INTO row_id
            FROM vtable_cell AS c
            WHERE table_id = 100;
            -- Begin inserting each cell for the record
            FOR i IN 1 .. array_length(row_values, 1) LOOP
                RAISE NOTICE 'Inserting (%, %, %, %)', target_table_id, row_id, col_id_array[i], row_values[i];
                INSERT INTO vtable_cell
                    (id, table_id, row_id, column_id, cell_value)
                VALUES
                    (DEFAULT, target_table_id, row_id, col_id_array[i], row_values[i]);
            END LOOP;
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
            FOR i IN 1 .. array_length(col_id_array, 1) LOOP
                UPDATE vtable_column SET column_position = i WHERE id = col_id_array[i];
            END LOOP;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_alter_add_column(
        IN target_table_id INTEGER,
        IN new_column_name TEXT,
        IN new_column_type TEXT,
        IN new_column_position INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            col_id_array INTEGER[];
            new_col_id INTEGER;
            new_col_id_array INTEGER[];
            rev_new_col_id_array INTEGER[];
        BEGIN
            -- Select the IDs of the columns in order of their position
            SELECT array_agg(col_ids.id) INTO col_id_array
            FROM (
                SELECT id
                FROM vtable_column
                WHERE table_id = target_table_id
                ORDER BY column_position
            ) col_ids;
            -- Create the record to represent the new column
            INSERT INTO vtable_column
                (id, table_id, column_name, column_type, column_position)
            VALUES
                (DEFAULT, target_table_id, new_column_name, new_column_type, 9000) --TODO: This is stupid and hacky. Find a better way.
            RETURNING id INTO new_col_id;
            -- Calculate the new ordering for the columns
            new_col_id_array := array_cat(
                array_append(col_id_array[:new_column_position], new_col_id),
                col_id_array[new_column_position:]
            );
            -- Now reverse the list becase we're adding a column so we need to
            -- update the position values from the lastmost to the firstmost column
            SELECT array_agg(foo.unnest) INTO rev_new_col_id_array
            FROM (
                SELECT unnest, ordinality
                FROM unnest(new_col_id_array)
                WITH ORDINALITY
                ORDER BY ordinality DESC
            ) foo;
            -- debug
            RAISE NOTICE 'List of column ids is %', rev_new_col_id_array;
            -- Update the position value for each of the tables columns
            FOR i IN 1 .. array_length(rev_new_col_id_array, 1) LOOP
                RAISE NOTICE 'Updating column position for column %, with position %', rev_new_col_id_array[i], i;
                UPDATE vtable_column
                SET column_position = array_position(new_col_id_array, rev_new_col_id_array[i])
                WHERE id = rev_new_col_id_array[i];
            END LOOP;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_func_delete(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            func_name TEXT;
        BEGIN
            SELECT 'vtable_' || vtable_id::TEXT INTO func_name;

            EXECUTE format(
                $delete_func$
                    DROP FUNCTION IF EXISTS pg_temp.%1$s;
                $delete_func$,
                func_name
            );
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vtable_func_creator(
        IN vtable_id INTEGER
    ) RETURNS VOID
    AS $$
        DECLARE
            creator_sql TEXT;
            func_name TEXT;
            func_body_raw TEXT;
            func_body TEXT;
            func_def TEXT;
        BEGIN

            -- Build the return type of the table that will be returned by the
            -- crosstab call. Technically, we kinda already know this in the
            -- function, but at the moment it's easier to rebuild this into a
            -- string and then template it into the dynamic sql.
            -- The 'id' column is added by the crosstab function itself. I could
            -- probably find a way to prevent it from showing through, but it's
            -- an easy unique primary key to use. They just wont be sequential
            -- for a given virtual table. Because of this, I have to manually
            -- specify that this column exists, since it's not represented in the
            -- vtables_column table.
            -- TODO: Investigate copying a table schema as a string
            SELECT
                'id integer, ' || string_agg(
                    column_name || ' ' || column_type,
                    ', '
                    ORDER BY column_position
                )
            INTO func_def
            FROM vtable_column AS c
            WHERE c.table_id = vtable_id;

            SELECT 'vtable_' || vtable_id::TEXT INTO func_name;

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
                CREATE FUNCTION pg_temp.%1$s()
                RETURNS TABLE (%2$s) AS %3$L
                LANGUAGE plpgsql;
            $creator$;

            EXECUTE format(creator_sql, func_name, func_def, func_body);
        END;
$$ LANGUAGE plpgsql;
