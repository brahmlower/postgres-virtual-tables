import json
from functools import wraps
from flask import Flask
from flask import Response
from flask import request
from flask import abort
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import sessionmaker

from .domain import vtable_access as access
from .domain import vtable_manage as manage
from .errors import ServiceException

def response_from_error(error):
    message = error.as_dict()
    content = {'success': False, 'response': message}
    response = Response(json.dumps(content), status=error.status_code, mimetype='application/json')
    return response

def response_with_payload(payload):
    # Custom data types need to have an encoder registered with the custom JSONEncoder
    content = {'success': True, 'response': payload}
    response = Response(json.dumps(content), status=200, mimetype='application/json')
    return response

class VirtualTablesApi(Flask):
    def __init__(self, app_config):
        super().__init__(__name__)
        # Service info
        self.route('/')(self.index)
        self.route('/health')(self.health)
        # Table management
        self.route('/api/manage/tables', methods=['GET'])(self.api_list_tables)
        self.route('/api/manage/tables', methods=['POST'])(self.api_create_table)
        self.route('/api/manage/tables/<table_id>', methods=['GET'])(self.api_get_table)
        self.route('/api/manage/tables/<table_id>', methods=['POST'])(self.api_update_table)
        self.route('/api/manage/tables/<table_id>', methods=['DELETE'])(self.api_delete_table)
        self.route('/api/manage/tables/<table_id>/columns', methods=['GET'])(self.api_get_columns)
        self.route('/api/manage/tables/<table_id>/columns', methods=['POST'])(self.api_create_column)
        self.route('/api/manage/tables/<table_id>/columns/<column_id>', methods=['GET'])(self.api_get_column)
        self.route('/api/manage/tables/<table_id>/columns/<column_id>', methods=['POST'])(self.api_update_column)
        self.route('/api/manage/tables/<table_id>/columns/<column_id>', methods=['DELETE'])(self.api_delete_column)
        # Table access
        self.route('/api/access/<table_id>', methods=['GET'])(self.api_list_rows)
        self.route('/api/access/<table_id>', methods=['POST'])(self.api_create_row)
        self.route('/api/access/<table_id>/<row_id>', methods=['GET'])(self.api_get_row)
        self.route('/api/access/<table_id>/<row_id>', methods=['POST'])(self.api_update_row)
        self.route('/api/access/<table_id>/<row_id>', methods=['DELETE'])(self.api_delete_row)

        # Read the configuration file
        self.app_config = app_config
        self.config['SQLALCHEMY_DATABASE_URI'] = self._get_db_uri()
        self.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
        self.db = SQLAlchemy(self, session_options={"autoflush": False})
        self.Session = sessionmaker()
        self.Session.configure(bind=self.db.engine)

    def _get_db_uri(self):
        return "postgresql://{username}:{password}@{hostname}:{port}/{database}".format(
            username=self.app_config['db']['username'],
            password=self.app_config['db']['password'],
            hostname=self.app_config['db']['hostname'],
            database=self.app_config['db']['database'],
            port=self.app_config['db']['port']
        )

    # Service info -------------------------------------------------------------
    def index(self):
        content = json.dumps({
            'message': 'Version information should go here I think?'
        })
        return Response(content, mimetype='application/json')

    def health(self):
        content = json.dumps({
            'health': 'okay (stubbed)',
            'checks': {
                'db': 'okay (stubbed)'
            }
        })
        return Response(content, mimetype='application/json')

# Table management -------------------------------------------------------------
    def api_list_tables(self):
        session = self.Session()
        try:
            vtable_list = manage.list_vtables(session)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(vtable_list)
        finally:
            return response

    def api_create_table(self):
        create_dict = request.get_json()
        session = self.Session()
        try:
            new_table = manage.create_vtable(session, create_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(new_table)
        finally:
            return response

    def api_get_table(self, table_id):
        session = self.Session()
        try:
            vtable = manage.get_vtable(session, table_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(vtable)
        finally:
            return response

    def api_update_table(self, table_id):
        update_dict = request.get_json()
        session = self.Session()
        try:
            updated_table = manage.update_vtable(session, table_id, update_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(updated_table)
        finally:
            return response

    def api_delete_table(self, table_id):
        session = self.Session()
        try:
            _ = manage.delete_vtable(session, table_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            # Just need some affirmative value. 'True' seems to fit the bill
            response = response_with_payload(True)
        finally:
            return response

    def api_get_columns(self, table_id):
        session = self.Session()
        try:
            columns_list = manage.list_vtable_columns(session, table_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(columns_list)
        finally:
            return response

    def api_create_column(self, table_id):
        create_dict = request.get_json()
        session = self.Session()
        try:
            new_column = manage.create_vtable_column(session, table_id, create_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(new_column)
        finally:
            return response

    def api_get_column(self, table_id, column_id):
        session = self.Session()
        try:
            column = manage.get_vtable_column(session, table_id, column_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(column)
        finally:
            return response

    def api_update_column(self, table_id, column_id):
        update_dict = request.get_json()
        session = self.Session()
        try:
            updated_column = manage.update_vtable_column(session, table_id, column_id, update_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(updated_column)
        finally:
            return response

    def api_delete_column(self, table_id, column_id):
        session = self.Session()
        try:
            manage.delete_vtable_column(session, table_id, column_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            # Just need some affirmative value. 'True' seems to fit the bill
            response = response_with_payload(True)
        finally:
            return response

    # Table access -------------------------------------------------------------

    def api_list_rows(self, table_id):
        session = self.Session()
        try:
            row_list = access.list_rows(session, table_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(row_list)
        finally:
            return response

    def api_create_row(self, table_id):
        create_dict = request.get_json()
        session = self.Session()
        try:
            new_row = access.create_row(session, table_id, create_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(new_row)
        finally:
            return response

    def api_get_row(self, table_id, row_id):
        session = self.Session()
        try:
            row = access.get_row(session, table_id, row_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(row)
        finally:
            return response

    def api_update_row(self, table_id, row_id):
        update_dict = request.get_json()
        session = self.Session()
        try:
            updated_row = access.update_row(session, table_id, row_id, update_dict)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            response = response_with_payload(updated_row)
        finally:
            return response

    def api_delete_row(self, table_id, row_id):
        session = self.Session()
        try:
            access.delete_row(session, table_id, row_id)
        except ServiceException as error:
            response = response_from_error(error)
        else:
            # Just need some affirmative value. 'True' seems to fit the bill
            response = response_with_payload(True)
        finally:
            return response
