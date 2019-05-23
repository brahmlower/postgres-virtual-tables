
CREATE EXTENSION tablefunc;

CREATE TABLE IF NOT EXISTS vtable_table(
    id          SERIAL PRIMARY KEY,
    table_name  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vtable_column(
    id              SERIAL PRIMARY KEY,
    table_id        INTEGER REFERENCES vtable_table(id) NOT NULL,
    column_name     TEXT NOT NULL,
    column_type     TEXT NOT NULL,
    column_position INTEGER NOT NULL,
    CONSTRAINT unq_column_name UNIQUE (table_id, column_name),
    CONSTRAINT unq_column_position UNIQUE (table_id, column_position)
);

CREATE TABLE IF NOT EXISTS vtable_row(
    id          SERIAL PRIMARY KEY,
    table_id    INTEGER REFERENCES vtable_table(id) NOT NULL,
    CONSTRAINT unq_overlapping_row UNIQUE (id, table_id)
);

CREATE TABLE IF NOT EXISTS vtable_cell(
    id          SERIAL PRIMARY KEY,
    table_id    INTEGER REFERENCES vtable_table(id) NOT NULL,
    row_id      INTEGER REFERENCES vtable_row(id) NOT NULL,
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
            -- Create a new row entry for the virtual table
            INSERT INTO vtable_row (table_id) VALUES (target_table_id) RETURNING id INTO row_id;
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


-- SELECT * FROM crosstab('
--     select
--         v.row_id,
--         c.column_name,
--         v.cell_value
--     from vtable_cell v
--     left join vtable_column c on v.column_id = c.id
--     order by row_id, c.column_position
-- ') AS catalog(
--     id integer,
--     vid text,
--     name text,
--     height text,
--     city text,
--     country text,
--     owner_id text,
--     is_public text
-- );