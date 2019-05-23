
-- Build the definition for the virtual table
INSERT INTO vtable_table
    (id, table_name)
VALUES
    (100, 'buildings');

INSERT INTO vtable_column
    (id,    table_id,   column_name,    column_type,    column_position)
VALUES
    (2019,  100,        'id',           'text',         0),
    (2020,  100,        'name',         'text',         1),
    (2021,  100,        'height',       'integer',      2),
    (2022,  100,        'city',         'text',         3),
    (2023,  100,        'country',      'text',         4),
    (2024,  100,        'owner_id',     'reference',    5),
    (2025,  100,        'is_public',    'boolean',      6);

-- Define an entry in our virtual table
INSERT INTO vtable_row
    (id, table_id)
VALUES
    (50, 100);

INSERT INTO vtable_cell
    (id,        table_id,   row_id,     column_id,  cell_value)
VALUES
    (DEFAULT,   100,        50,         2020,       'Burj Khalifa'),
    (DEFAULT,   100,        50,         2021,       '828'),
    (DEFAULT,   100,        50,         2022,       'Dubai'),
    (DEFAULT,   100,        50,         2023,       'United Arab Emirates'),
    (DEFAULT,   100,        50,         2024,       '0'),
    (DEFAULT,   100,        50,         2025,       'TRUE'),
    (DEFAULT,   100,        50,         2019,       '9000');
