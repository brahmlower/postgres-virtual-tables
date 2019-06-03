-- Deploy vtable:tables to pg

BEGIN;

CREATE TABLE IF NOT EXISTS vtable_table(
    id          SERIAL PRIMARY KEY,
    table_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS vtable_column(
    id                  SERIAL PRIMARY KEY,
    table_id            INTEGER REFERENCES vtable_table(id) NOT NULL,
    column_name         TEXT NOT NULL,
    column_type         TEXT NOT NULL,
    column_references   TEXT,
    column_position     INTEGER NOT NULL,
    CONSTRAINT unq_column_name UNIQUE (table_id, column_name),
    CONSTRAINT unq_column_position UNIQUE (table_id, column_position),
    CONSTRAINT non_zero_position CHECK(column_position > 0)
);

CREATE TABLE IF NOT EXISTS vtable_cell(
    id          SERIAL PRIMARY KEY,
    table_id    INTEGER REFERENCES vtable_table(id) NOT NULL,
    row_id      INTEGER NOT NULL,
    column_id   INTEGER REFERENCES vtable_column(id) NOT NULL,
    cell_value  TEXT,
    CONSTRAINT unq_table_cell UNIQUE (table_id, row_id, column_id)
);

COMMIT;
