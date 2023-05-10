import logging
from typing import List, Tuple
import mysql.connector
import pandas as pd
from sqlalchemy import create_engine, Table, Column, MetaData, PrimaryKeyConstraint

class DataBaseSQLStore:
    """
        Store historical data, analysis and the current state of the (trading) environment including its history in MySQL 
    """
    def __init__(self, logger: logging.Logger, user: str = "", password: str = "", host: str = "", port: int = 3306, database: str = "", engine_parser_name: str = "") -> None:
        self.logger = logger
        self.user = user
        self.password = password
        self.host = host
        self.port = port
        self.engine_parser_name = engine_parser_name # mindsdb
        
        self.engine = self._set_db_engine(engine_parser_name)
        self._create_database(database) # create database if not exists
        self.metadata = MetaData(bind=self.engine, schema=database)
        
    def _set_db_engine(self, engine_name: str = "", database_name: str = ""):
        """
            Set DB Engine
        """
        if engine_name != "mindsdb":
            if len(database_name) != 0:
                engine = create_engine(f"mysql+mysqlconnector://{self.user}:{self.password}@{self.host}:{self.port}/{database_name}")
            else:
                engine = create_engine(f"mysql+mysqlconnector://{self.user}:{self.password}@{self.host}:{self.port}/")
        else:
            if len(database_name) != 0:
                engine = create_engine(f"mysql+pymysql://{self.user}:{self.password}@{self.host}:{self.port}/{database_name}")
            else:
                engine = create_engine(f"mysql+pymysql://{self.user}:{self.password}@{self.host}:{self.port}/")
                
        return engine

    def _create_database(self, database_name: str):
        """
            Create database if it does not exist and connect to it 
        """
        database_exists = self.engine.execute(f"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '{database_name}'").fetchone() is not None

        if database_exists:
            self.logger.info(f"Database '{database_name}' exists")
            self.engine = self._set_db_engine(self.engine_parser_name, database_name)
        else:
            self.logger.info(f"Database '{database_name}' does not exist > Creating database....")
            self.engine.execute(f"CREATE DATABASE {database_name}")
            self.engine = self._set_db_engine(self.engine_parser_name, database_name)
        return

    def create_table(self, table_name: str, schema: List[Tuple[str, type]], primary_key: str):
        """
            Create a table with a given name and schema
            :param table_name: name of the table to create
            :param schema: a list of tuples containing column names and types
            :param primary_key: the name of the primary key column
        """
        self.logger.info(f"DatabaseSQLStore.create_table => {table_name}")
        table_columns = [Column(name, type_) for name, type_ in schema]
        table_columns.append(PrimaryKeyConstraint(primary_key))
        table = Table(table_name, self.metadata, *table_columns)
        table.create(self.engine, checkfirst=True)
        self.logger.info(f"Table {table_name} created successfully")
        return 

    def store_data(self, table_name: str, data: pd.DataFrame):
        """
        Store data
            - params: table_name [str], data [pandas.DataFrame]

            https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_sql.html
        """
        self.logger.info(f"DatabaseSQLStore.store_data => {table_name}")
        try:
            # Store the data
            response = data.to_sql(table_name, con=self.engine, if_exists='append', index=False)
            self.logger.info(f"Data inserted successfully into {table_name} table")
            return response
        except Exception as e:
            self.logger.error(f"Error while inserting data into the {table_name} table: {e}")
            return None


    def get_table_data(self, table_name: str, columns: str = "*", query: str = None):
        """
        Get table data -> retrieve a sql database table data
            - params: table_name [str], columns [str], query [str]

        https://pandas.pydata.org/docs/reference/api/pandas.read_sql.html
        """
        self.logger.info(f"DatabaseSQLStore.get_table_data => {table_name}")
        try:
            if query is None:
                query = f"SELECT {columns} FROM {table_name}"
            else:
                query = query.replace("<table_name>", table_name).replace("<columns>", columns)

            # get the data from table_name
            data = pd.read_sql(query, con=self.engine)
            self.logger.info(f"Data retrieved successfully from {table_name} table")
            return data
        except Exception as e:
            self.logger.error(f"Error while retrieving data from the {table_name} table: {e}")
            return None

