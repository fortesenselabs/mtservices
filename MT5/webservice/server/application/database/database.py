from sqlalchemy import create_engine

user = 'mindsdb'
password = ''
host = '127.0.0.1'
port = 47335
database = ''

def get_connection():
    return create_engine(
        url="mysql+pymysql://{0}:{1}@{2}:{3}/{4}".format(user, password, host, port, database)
    )

# if __name__ == '__main__':
#     try:
#         engine = get_connection()
#         engine.connect()
#         print(f"Connection to the {host} for user {user} created successfully.")
#     except Exception as ex:
#         print("Connection could not be made due to the following error: \n", ex)


class DataBaseSQLStore:
    """
        Store historical data, analysis and the current state of the (trading) environment including its history in Redis
    """
    def __init__(self) -> None:
        pass

    async def get_signal(self):
        return