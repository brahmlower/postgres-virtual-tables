
from sqlalchemy import text

# Vtable crud

def list_vtables(db_session):
    return []

def create_vtable(db_session, create_dict):
    return {}

def get_vtable(db_session, table_id):
    return {}
    # query = text('SELECT * FROM vtable_table WHERE table_id LIKE :table_id')
    # result = db_session.execute(query, {'table_id': table_id})
    # return result.fetchone()

def update_vtable(db_session, table_id, update_dict):
    return {}

def delete_vtable(db_session, table_id):
    return None

# Column crud

def list_vtable_columns(db_session, table_id):
    # query = text('SELECT * FROM vtable_column WHERE table_id = :table_id ORDER BY column_position')
    # result = db_session.execute(query, {'table_id': self.table_id})
    # return result.fetchall()
    return []

def create_vtable_column(db_session, table_id, create_dict):
    return {}

def get_vtable_column(db_session, table_id, column_id):
    # query = text('SELECT * FROM vtable_column WHERE table_id = :table_id, column_id = :column_id')
    # result = db_session.execute(query, {'table_id': self.table_id, 'column_id': self.column_id})
    # return result.fetchall()
    return {}

def update_vtable_column(db_session, table_id, column_id, update_dict):
    return {}

def delete_vtable_column(db_session, table_id, column_id):
    return None

# Access

def list_rows(db_session, table_id):
    return []

def create_row(db_session, table_id, create_dict):
    return {}

def get_row(db_session, table_id, row_id):
    return {}

def update_row(db_session, table_id, row_id, update_dict):
    return {}

def delete_row(db_session, table_id, row_id):
    return None
