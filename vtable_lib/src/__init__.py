

# def get_vtable(db_session, table_id):
#     query = text('SELECT * FROM vtable_table WHERE table_id LIKE :table_id')
#     result = db_session.execute(query, {'table_id': table_id})
#     return result.fetchone()

# def get_vtable_columns(db_session, table_id):
#     query = text('SELECT column_name FROM vtable_column WHERE table_id = :table_id ORDER BY column_position')
#     result = db_session.execute(query, {'table_id': self.table_id})
#     return result.fetchall()

# class Column(object):
#     def __init__(self, table_id, name, _type, ref, pos):
#         self._table_id = table_id
#         self._column_name = name
#         self._column_type = _type
#         self._column_references = ref
#         self._column_position = pos
#         self.db_session = None

#     @property
#     def table_id(self):
#         return self._table_id

#     @property
#     def name(self):
#         return self._column_name

#     @name.setter
#     def name(self, value):
#         # TODO: input validation
#         self._update('name', value)
#         self._column_name = value

#     @property
#     def type_(self):
#         return self._column_type
    
#     @type_.setter
#     def type_(self, value):
#         # TODO: input validation
#         self._update('column_type', value)
#         self._column_type = value

#     @property
#     def references(self):
#         return self._column_references
    
#     @references.setter
#     def references(self, value):
#         # TODO: input validation
#         self._update('column_references', value)
#         self._column_references = value
    
#     @property
#     def position(self):
#         return self._column_position
    
#     @position.setter
#     def position(self, value):
#         # TODO: input validation
#         self._update_('column_position', value)
#         self._column_position = value

#     def _update(self, key, value):
#         if key in ['id', 'table_id']:
#             raise ValueError("Can't update that key")
#         query = text('UPDATE vtable_column SET :key = :value WHERE table_id = :table_id AND column_id = :column_id')
#         params = {
#             'key': key,
#             'value': value,
#             'table_id': self.table_id,
#             'column_id': self.column_id
#         }
#         result = self.db_session.execute(query, params)

# class VtableColumns(object):
#     def __init__(self, table_id, columns):
#         self.table_id = table_id
#         self.columns = columns

#     def add(self, name, _type, references=None, position=None):
#         new_column = Column(self.table_id, name, _type, references, position)
    
#     def remove(self):
#         pass

# class Vtable(object):
#     def __init__(self, table_id, name):
#         self.table_id = table_id
#         self.name = name
#         self.columns = []

#     @classmethod
#     def from_db(cls, db_session, vtable_id):
#         result = get_vtable(db_session, vtable_id)
#         inst = cls(result.table_id, result.name)
#         inst.load_columns(db_session)
#         return inst

#     def load_columns(self, db_session):
#         self.columns = get_vtable_columns(db_session, self.table_id)

#     def insert_row(self, db_session, data_row):
#         # Insert via sqlalchemy func module
#         result = db_session.execute(
#             func.vtable_insert(self.table_id, data_row)
#         )
#         row_id = result.fetchall()[0][0]
#         if row_id % 10000 == 0:
#             print('Reached row: {}'.format(row_id))

#     def add_column()
#         pass

#     def remove_column()
#         pass

# if __name__ == "__main__":
#     db_session = Session()
#     table = Vtable.from_db(db_session, 1)
#     table.columns.add("age", 'int')
#     table.columns["age"].position = 2
