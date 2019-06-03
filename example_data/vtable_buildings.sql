
INSERT INTO vtable_table (id, table_name) VALUES (DEFAULT, 'buildings');

INSERT INTO vtable_column
    (id,    table_id,   column_name,    column_type,    column_references,  column_position)
VALUES
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'name',         'text',         NULL,               1),
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'height',       'integer',      NULL,               2),
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'city',         'text',         NULL,               3),
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'country',      'text',         NULL,               4),
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'owner_id',     'integer',      'accounts.id',      5),
    (DEFAULT,   (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),    'is_public',    'boolean',      NULL,               6);

-- Insert some test data
SELECT vtable_insert(
    (SELECT id FROM vtable_table WHERE table_name LIKE 'buildings'),
    ARRAY['Burj Khalifa', '828', 'Dubai', 'United Arab Emirates', '0', 'TRUE']
);
