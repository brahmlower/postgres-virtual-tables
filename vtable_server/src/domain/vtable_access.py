
from sqlalchemy.exc import InternalError
from vtable_lib import simple as vt
from ..errors import DatabaseError

# Vtable crud

def list_rows(db_session, table_id):
    results = vt.list_rows(db_session, table_id)
    return [dict(i) for i in results]

def create_row(db_session, table_id, create_dict):
    try:
        result = vt.create_row(db_session, table_id, create_dict)
    except InternalError as error:
        raise DatabaseError(error)
    print(result)
    return get_row(db_session, table_id, result)

def get_row(db_session, table_id, row_id):
    result = vt.get_row(db_session, table_id, row_id)
    return dict(result)

def update_row(db_session, table_id, row_id, update_dict):
    return vt.update_row(db_session, table_id, row_id, update_dict)

def delete_row(db_session, table_id, row_id):
    return vt.delete_row(db_session, table_id, row_id)
