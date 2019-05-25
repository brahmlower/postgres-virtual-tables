
INSERT INTO vtable_table (id, table_name) VALUES (DEFAULT, 'users');

INSERT INTO vtable_column
    (id, table_id, column_name, column_type, column_references, column_position)
VALUES
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'first_name', 'text', NULL, 1),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'last_name', 'text', NULL, 2),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'email', 'text', NULL, 3),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'phone', 'text', NULL, 4),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'likes_apples', 'boolean', NULL, 5),
    (DEFAULT, (SELECT id FROM vtable_table WHERE table_name LIKE 'users'), 'height', 'integer', NULL, 6);
