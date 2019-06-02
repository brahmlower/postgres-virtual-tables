
from sqlalchemy import text

# Vtable crud ------------------------------------------------------------------

def list_vtables(db_session):
    query = text('SELECT * FROM vtable_table')
    result = db_session.execute(query)
    return result.fetchall()

def create_vtable(db_session, name):
    query = text('INSERT INTO vtable_table (id, name) VALUES (DEFAULT, :name) RETURNING *')
    result = db_session.execute(query, {'name': name})
    return result.fetchone()

def get_vtable(db_session, table_id):
    query = text('SELECT * FROM vtable_table WHERE id = :table_id')
    result = db_session.execute(query, {'table_id': table_id})
    return result.fetchone()

def update_vtable(db_session, table_id, update_dict):
    raise Exception

def delete_vtable(db_session, table_id):
    raise Exception

# Column crud ------------------------------------------------------------------

def list_vtable_columns(db_session, table_id):
    query = text('SELECT * FROM vtable_column WHERE table_id = :table_id ORDER BY column_position')
    result = db_session.execute(query, {'table_id': table_id})
    return result.fetchall()

def create_vtable_column(db_session, table_id, name, type_, position):
    query = text('SELECT * FROM vtable_alter_add_column(:table_id, :name, :type_, :position)')
    params = {
        'table_id': table_id,
        'name': name,
        'type_': type_,
        'position': position
    }
    return db_session.execute(query, params).fetchone()

def get_vtable_column(db_session, table_id, column_id):
    query = text('SELECT * FROM vtable_column WHERE table_id = :table_id AND id = :column_id')
    result = db_session.execute(query, {'table_id': table_id, 'column_id': column_id})
    return result.fetchone()

def update_vtable_column(db_session, table_id, column_id, update_dict):
    raise Exception

def delete_vtable_column(db_session, table_id, column_id):
    query = text('SELECT * FROM vtable_alter_remove_column(:table_id, :column_id)')
    db_session.execute(query, {'table_id': table_id, 'column_id': column_id})
    return None

# Access crud ------------------------------------------------------------------

def list_rows(db_session, table_id):
    """ Call the access function for the virtual table

    This is some tight coupling without any solid assurance that the created
    name is acurate to what's in the databse. We could totally facilitate
    better methods of connecting the table_id to the access function, but this
    is good enough for the moment.
    """
    query = text('SELECT * FROM vtable_{}()'.format(table_id))
    return db_session.execute(query).fetchall()

def create_row(db_session, table_id, create_dict):
    # TODO: THIS DOES NOT WORK.
    # We need to take the dictionary values in the order that the columns are arranged
    values = list(create_dict.values())
    query = text('SELECT * FROM vtable_insert(:table_id, :values)')
    params = {
         'table_id': table_id,
         'values': values
    }
    return db_session.execute(query, params).fetchone()[0]

def get_row(db_session, table_id, row_id):
    query = text('SELECT * FROM vtable_{}() WHERE id = :row_id'.format(table_id))
    return db_session.execute(query, {'row_id': row_id}).fetchone()

def update_row(db_session, table_id, row_id, update_dict):
    raise Exception

def delete_row(db_session, table_id, row_id):
    query = text('DELETE FROM vtable_cell WHERE table_id = :table_id AND row_id = :row_id')
    db_session.execute(query, {'table_id': table_id, 'row_id': row_id})
    return None
