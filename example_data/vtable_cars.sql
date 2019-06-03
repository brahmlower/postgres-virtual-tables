
INSERT INTO vtable_table (id, table_name) VALUES (DEFAULT, 'cars');

INSERT INTO vtable_column
    (id, table_id, column_name, column_type, column_references, column_position)
VALUES
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'cars'), 'make', 'text', NULL, 1),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'cars'), 'model', 'text', NULL, 2),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'cars'), 'year', 'integer', NULL, 3),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'cars'), 'owner', 'integer', 'users.row_id', 4),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'cars'), 'insured', 'boolean', NULL, 5);
