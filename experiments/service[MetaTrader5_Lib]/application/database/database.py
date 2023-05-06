import logging
import mysql.connector
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData

logging.basicConfig(level=logging.INFO)

user = 'mindsdb'
password = ''
host = '127.0.0.1'
port = 47335
database = 'mydatabase'

metadata = MetaData()

mytable = Table('mytable', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String),
    Column('age', Integer),
    Column('address', String)
)

def get_connection():
    try:
        conn = mysql.connector.connect(user=user, password=password, host=host, port=port, database=database)
        if conn.is_connected():
            logging.info(f"Connection to {host}:{port} for user {user} created successfully.")
            return conn
    except mysql.connector.Error as e:
        logging.error(f"Error while connecting to the database: {e}")
        raise e

class DataBaseSQLStore:
    """
        Store historical data, analysis and the current state of the (trading) environment including its history in MySQL
    """
    def __init__(self) -> None:
        self.engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")
        metadata.create_all(self.engine)

    async def store_data(self, data):
        conn = self.engine.connect()
        try:
            insert_query = mytable.insert().values(data)
            conn.execute(insert_query)
            logging.info(f"Data inserted successfully into {mytable.name} table")
        except Exception as e:
            logging.error(f"Error while inserting data into the {mytable.name} table: {e}")
            raise e
        finally:
            conn.close()
