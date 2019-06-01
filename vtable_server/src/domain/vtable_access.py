
from vtable_lib import simple as vt

# Vtable crud

def list_rows(db_session, table_id):
    return vt.list_rows(db_session, table_id)

def create_row(db_session, table_id, create_dict):
    return vt.create_row(db_session, table_id, create_dict)

def get_row(db_session, table_id, row_id):
    return vt.get_row(db_session, table_id, row_id)

def update_row(db_session, table_id, row_id, update_dict):
    return vt.update_row(db_session, table_id, row_id, update_dict)

def delete_row(db_session, table_id, row_id):
    return vt.delete_row(db_session, table_id, row_id)
