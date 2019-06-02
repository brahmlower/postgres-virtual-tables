
from vtable_lib import simple as vt
from ..errors import MissingRequiredKey
from ..errors import NotImplementedYet

# Table crud

def list_vtables(db_session):
    results = vt.list_vtables(db_session)
    return [dict(i) for i in results]

def create_vtable(db_session, create_dict):
    name = create_dict.get('name', None)
    if name is None:
        raise MissingRequiredKey('name', 'string')
    result = vt.create_vtable(db_session, name)
    return dict(result)

def get_vtable(db_session, table_id):
    result = vt.get_vtable(db_session, table_id)
    return dict(result)

def update_vtable(db_session, table_id, update_dict):
    try:
        result = vt.update_vtable(db_session, table_id, update_dict)
        return dict(result)
    except ValueError as error:
        raise NotImplementedYet

def delete_vtable(db_session, table_id):
    return vt.delete_vtable(db_session, table_id)

# Column crud

def list_vtable_columns(db_session, table_id):
    results = vt.list_vtable_columns(db_session, table_id)
    return [dict(i) for i in results]

def create_vtable_column(db_session, table_id, create_dict):
    name = create_dict.get('name', None)
    if name is None:
        raise MissingRequiredKey('name', 'string')
    type_ = create_dict.get('type', None)
    if type_ is None:
        raise MissingRequiredKey('type', 'string')
    position = create_dict.get('position', None)
    if position is None:
        raise MissingRequiredKey('position', 'int')
    result = vt.create_vtable_column(db_session, table_id, name, type_, position)
    return dict(result)

def get_vtable_column(db_session, table_id, column_id):
    result = vt.get_vtable_column(db_session, table_id, column_id)
    return dict(result)

def update_vtable_column(db_session, table_id, column_id, update_dict):
    try:
        result = vt.update_vtable_column(db_session, table_id, column_id, update_dict)
        return dict(result)
    except ValueError as error:
        raise NotImplementedYet

def delete_vtable_column(db_session, table_id, column_id):
    return vt.delete_vtable_column(db_session, table_id, column_id)
