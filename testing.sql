CREATE OR REPLACE FUNCTION testing_failing_function(
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

CREATE OR REPLACE FUNCTION testing_simple_insert(
        IN row_values TEXT[],
        OUT row_id INTEGER
    ) RETURNS INTEGER
    AS $$
        BEGIN
            INSERT INTO vtable_cell
                (id, table_id, row_id, column_id, cell_value)
            VALUES
                (DEFAULT, row_values[1]::INTEGER, row_values[2]::INTEGER, row_values[3]::INTEGER, row_values[4])
                -- (DEFAULT, target_table_id, row_id, col_id_array[i], row_values[i])
            RETURNING id INTO row_id;
        END;
$$ LANGUAGE plpgsql;