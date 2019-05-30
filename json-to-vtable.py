import sys
import json

from sqlalchemy import create_engine
from sqlalchemy import func
from sqlalchemy import text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import ProgrammingError
import subprocess

class Vtable(object):
    def __init__(self, vtable_name):
        self.name = vtable_name
        self.table_id = None
        self.columns = []

    def load_table_id(self, db_session):
        query = text('SELECT id FROM vtable_table WHERE table_name LIKE :name')
        result = db_session.execute(query, {'name': self.name})
        self.table_id = result.fetchone()[0]

    def load_columns(self, db_session):
        query = text('SELECT column_name FROM vtable_column WHERE table_id = :table_id ORDER BY column_position')
        result = db_session.execute(query, {'table_id': self.table_id})
        self.columns = [i[0] for i in result.fetchall()]

    def insert(self, db_session, data_row):
        # Insert via sqlalchemy func module
        result = db_session.execute(
            func.vtable_insert(self.table_id, data_row)
        )
        row_id = result.fetchall()[0][0]
        if row_id % 10000 == 0:
            print('Reached row: {}'.format(row_id))

def fetch_data():
    response = subprocess.check_output(['./scratch/get-car-data.sh'], shell=True)
    return json.loads(response)

def load_data(file_path):
    with open(file_path, 'r') as source_file:
        return json.loads(source_file.read())

def get_db_connection():
    # Connect to the database
    db_string = 'postgres://{username}:{password}@{hostname}/{database}'.format(
        username='test',
        password='test',
        hostname='localhost',
        database='test'
    )
    engine = create_engine(db_string)
    Session = sessionmaker(bind=engine)
    new_session = Session()
    return new_session

def main():
    table_name = sys.argv[1]
    itterations = int(sys.argv[2])

    # Connect to the database
    session = get_db_connection()

    for i in range(0, itterations):
        data = fetch_data()

        # Build the vtable instance
        vtable = Vtable(table_name)
        vtable.load_table_id(session)
        vtable.load_columns(session)

        # Convert the json data into rows for the database
        for i in data:
            row = [str(i[k]) for k in vtable.columns]
            # The row has been built, now insert it into the database
            vtable.insert(session, row)
        session.commit()

    session.close()

if __name__ == "__main__":
    main()
