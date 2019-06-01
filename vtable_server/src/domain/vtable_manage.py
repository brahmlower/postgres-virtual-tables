
from vtable_lib import simple as vt

# Table crud

def list_vtables(db_session):
    return vt.list_vtables(db_session)

def create_vtable(db_session, create_dict):
    return vt.create_vtable(db_session, create_dict)

def get_vtable(db_session, table_id):
    return vt.get_vtable(db_session, table_id)

def update_vtable(db_session, table_id, update_dict):
    return vt.update_vtable(db_session, table_id, update_dict)

def delete_vtable(db_session, table_id):
    return vt.delete_vtable(db_session, table_id)

# Column crud

def list_vtable_columns(db_session, table_id):
    return vt.list_vtable_columns(db_session, table_id)

def create_vtable_column(db_session, table_id, create_dict):
    return vt.create_vtable_column(db_session, table_id, create_dict)

def get_vtable_column(db_session, table_id, column_id):
    return vt.get_vtable_column(db_session, table_id, column_id)

def update_vtable_column(db_session, table_id, column_id, update_dict):
    return vt.update_vtable_column(db_session, table_id, column_id, update_dict)

def delete_vtable_column(db_session, table_id, column_id):
    return vt.delete_vtable_column(db_session, table_id, column_id)
