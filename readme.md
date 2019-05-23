# Postgres Virtual Tables (testing)

The idea is that users could "create a database table" without actually making a
new table in the database. This will of course not be a perfect abstraction, but
the hope is that it provides some additional flexability in designing and changing
virtual tables.

Terminology is important for clear communication. Frequently used terms and their
exacty meaning are listed here:

table - A normal postgresql table
column - A normal column on a postgres table
vtable - A virtual table conceptually defined by data in postgres tables
vcolumn - A column on the virtual table

## Structure

As of right now, there are four tables, two of which hold the definition for
vtables and their structures, and two of which define data within the vtables.

### vtable_table

This is a pretty straightforward table- it holds a primary key ID and a name for
the vtable. This just serves as the root definition of a the vtables, and could be
expanded to track other info like vtable owner or permissions.

### vtable_column

The vcolumns for a vtable are defined here, and consists of the vtable ID that
the column belongs to, the name of the vcolumn, and the ordering of the vcolumn.
At this time there is a column called 'column_type', which would be used to
define the type of data being stored, however this functionality has not been
implemented yet.

### vtable_row

This table serves to identify a particular row in a vtable. The ID in a row here
is referenced by records in the vtable_cell table to indicate what row the cell
is part of.

### vtable_cell

Like a cell on an excel spreadsheet, records in this table represent a single
column within a row in a vtable.

## Project Setup

Start the test datbase, then load the schema and test data

```
docker-compose up -d
psql -U test -h localhost test -c "\i deploy.sql"
psql -U test -h localhost test -c "\i vtable_building.sql"
```

If you need to reset everything, you can import the revert script (or just
docker-compose down)

```
psql -U test -h localhost test -c "\i revert.sql"
```

The crosstab example I've been using to query the vtable:

```
SELECT * FROM crosstab('
    select
        v.row_id,
        c.column_name,
        v.cell_value
    from vtable_cell v
    left join vtable_column c on v.column_id = c.id
    order by row_id, c.column_position
') AS catalog(
    id integer,
    name text,
    height text,
    city text,
    country text,
    owner_id text,
    is_public text
);
```

## Continued research

Reading from the vtables sucks right now. It can be sorta hacked together using
the `crosstab` function, but you're required to list out all the columns, which
breaks the autonomy here. More reading and testing is needed:

- https://www.postgresql.org/docs/9.5/tablefunc.html#AEN137962
- https://dba.stackexchange.com/questions/158181/pivot-with-2-columns-using-crosstab
- https://stackoverflow.com/questions/12879672/dynamically-generate-columns-for-crosstab-in-postgresql