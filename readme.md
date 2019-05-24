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
PGPASSWORD=test psql -U test -h localhost test -c "\i deploy.sql"
PGPASSWORD=test psql -U test -h localhost test -c "\i vtable_building.sql"
```

If you need to reset everything, you can import the revert script (or just
docker-compose down)

```
PGPASSWORD=test psql -U test -h localhost test -c "\i revert.sql"
```

## Basic usage

This section will lightly detail how to use the tables and functions provided.
Until the project reaches a mature state, this will be a mix of loose notes and
reference for myself. Boring or inconsequential command output has been ommited.

### Create vtable access function!

We can create a function (only a temporary functions) configured to show data
from a specific vtable.

```
test=# select vtable_func_creator(100);
test=# select * from pg_temp.vtable_100();
 id |     name     | height | city  |       country        | owner_id | is_public 
----+--------------+--------+-------+----------------------+----------+-----------
 50 | Burj Khalifa |    828 | Dubai | United Arab Emirates |        0 | t
(1 row)
```

### Views on vtable access functions!

Create a view on top of the temporary vtable access function.

```
test=# create view buildings as select * from pg_temp.vtable_100();
test=# select * from buildings;
 id |     name     | height | city  |       country        | owner_id | is_public 
----+--------------+--------+-------+----------------------+----------+-----------
 50 | Burj Khalifa |    828 | Dubai | United Arab Emirates |        0 | t
(1 row)
```

### Vtables preserve specified types!

Prove to ourselves that the virtual table is preserving the specified column
types specified in vtable_column.

```
test=# select column_name, column_type from vtable_column where column_name = ANY(ARRAY['city', 'owner_id', 'is_public']);
 column_name | column_type 
-------------+-------------
 city        | text
 owner_id    | integer
 is_public   | boolean
(3 rows)

test=# select pg_typeof(city), pg_typeof(owner_id), pg_typeof(is_public) from buildings;
 pg_typeof | pg_typeof | pg_typeof 
-----------+-----------+-----------
 text      | integer   | boolean
(1 row)

```

### Thoughs on future work

#### Better record insertion

It'd be nice to have a cleaner way of inserting data into a vtable. Current method
kinda sucks. Possibly make another temporary function crafted for the particular
virtual table. Would prevent errors like below:

```
test=# select * from vtable_insert(100, ARRAY['Home', '15', 'Puyallup', 'United States of America', '0', 'false']);
test=# select * from buildings;
 id |     name     | height |   city   |         country          | owner_id | is_public 
----+--------------+--------+----------+--------------------------+----------+-----------
 50 | Burj Khalifa |    828 | Dubai    | United Arab Emirates     |        0 | t
 51 | Home         |     15 | Puyallup | United States of America |        0 | f
(2 rows)
test=# select * from vtable_insert(100, ARRAY['Home', '15', 'Puyallup', 'United States of America', '0', 'poop']);
test=# select * from buildings;
ERROR:  invalid input syntax for type boolean: "poop"
CONTEXT:  PL/pgSQL function pg_temp_3.vtable_100() line 3 at RETURN QUERY
```

#### Row locks, transactions, and alters oh my!

Additionally, it's possible for the vtable to be altered while another session is
open, at which point the existing temporary access functions will be broken. For
example, in Session 1 we have our view for the vtable 'buildings' set up and we
can query from it just fine:

```
-- Session 1
test=# select * from buildings;
 id |     name     | height | city  |       country        | owner_id | is_public 
----+--------------+--------+-------+----------------------+----------+-----------
 50 | Burj Khalifa |    828 | Dubai | United Arab Emirates |        0 | t
(1 row)

```

But then in Session 2, representing a different user, we decide we're going to
change the shape of the vtable, and remove the 'city' column.

```
-- Session 2
test=# select * from vtable_column where table_id = 100 and column_name = 'city';
 id  | table_id | column_name | column_type | column_references | column_position 
-----+----------+-------------+-------------+-------------------+-----------------
2022 |      100 | city        | text        |                   |               3
(1 row)
test=# select vtable_alter_remove_column(100, 2022);
 vtable_alter_remove_column 
----------------------------
 
(1 row)
```

Now the vtable has one less column then the temporary access function in Session 1
is expecting, so when the user attempts to query their view again, it fails:

```
-- Session 1
test=# select * from buildings;
ERROR:  invalid return type
DETAIL:  Query-specified return tuple has 7 columns but crosstab returns 6.
CONTEXT:  PL/pgSQL function pg_temp_3.vtable_100() line 3 at RETURN QUERY
```

This can be somewhat prevented by using row-level locks and transactions. For
this example we'll reset the database to its original state. Session 1 create
the temporary access function and view again, but will also read the vtable
columns with a 'for shared', which will prevent the resulting rows from being
modified for the duration of the transaction.

```
-- Session 1
test=# begin;
test=# select * from vtable_column where table_id = 100 for share;
...
(6 rows)
test=# select * from buildings;
 id |     name     | height | city  |       country        | owner_id | is_public 
----+--------------+--------+-------+----------------------+----------+-----------
 50 | Burj Khalifa |    828 | Dubai | United Arab Emirates |        0 | t
(1 row)
```

Session 1 now has a row-level lock on the columns that define the virtual table.
If Session 2 comes along now and tries to modify the table, their change will be
blocked until the Session 1 transaction is closed.

```
-- Session 2
test=# select vtable_alter_remove_column(100, 2022);
```

This just blocks. I'm not sure if what the default timeout value is, but this is
most certainly not what you want if you're letting users modify the virtual
tables (I mean, what else are you doing if not that?), so we should set the
`statement_timeout` setting when opening the database session. Here we'll set it
to 10 seconds, just as an example.

```
-- Session 2
SET statement_timeout = 10000;
```

As soon as the transaction on Session 1 is closed, the alter statement
completes. This isn't ideal behavior though! We don't want to be locking longer
than we need to, and we should be able to read from the table without making any
manual changes when the vtable changes unexpectedly.

Couple options:
1) try to find a way to detect when the table changes, then rebuild our temporary
    access function and acompanying view
2) Don't use temporary functions/view. Use real ones that persist across sessions,
    and then recreate them based on triggers set up on the vtable_column table.

## Continued research

Reading from the vtables sucks right now. It can be sorta hacked together using
the `crosstab` function, but you're required to list out all the columns, which
breaks the autonomy here. More reading and testing is needed:

- https://www.postgresql.org/docs/9.5/tablefunc.html#AEN137962
- https://dba.stackexchange.com/questions/158181/pivot-with-2-columns-using-crosstab
- https://stackoverflow.com/questions/12879672/dynamically-generate-columns-for-crosstab-in-postgresql