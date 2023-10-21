import sys
import json
import socket
import logging
import warnings
from datetime import datetime
from pytz import timezone
from tzlocal import get_localzone
from influxdb import DataFrameClient


LOGGER = {
    "datefmt": "%Y-%m-%d %H:%M:%S",
    "format": (
        "[%(asctime)s.%(msecs)03d]"
        "[%(process)s]"
        "[%(funcName)s:%(lineno)d]"
        "[%(levelname)s]"
        ": %(message)s"
    ),
    "level": logging.INFO,
    "stream": sys.stdout,
}


class Functions:
    def __init__(self, host=None):
        self.HOST = host or "127.0.0.1"
        self.PORT = 9000  # Port

        # Create a socket object
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # Connect to the server
        try:
            self.sock.connect((self.HOST, self.PORT))
        except KeyboardInterrupt:
            self.sock.close()

    def _send_request(self, data: dict) -> None:
        """Send request to the server via socket"""
        try:
            # Serialize the data to JSON and send it
            json_data = json.dumps(data)
            self.sock.sendall(json_data.encode())  # Encode and send as bytes
        except AssertionError as err:
            raise Exception(err)  # Handle exceptions as needed

    def _get_reply(self):
        """Get reply from the server via the socket with timeout"""
        try:
            # Read data from the socket until a valid JSON object is received
            buffer = b''
            while True:
                data = self.sock.recv(4096)  # Adjust the buffer size as needed
                if not data:
                    raise Exception("No data received from the server")
                buffer += data
                try:
                    msg, idx = json.JSONDecoder().raw_decode(buffer.decode())
                    buffer = buffer[idx:]
                    return msg  # Return the parsed JSON object
                except ValueError:
                    pass
        except Exception as err:
            raise Exception("Socket receive error: " + str(err))  # Handle exceptions as needed
    
    def Command(self, **kwargs) -> dict:
        """Construct a request dictionary from default and send it to the server"""

        # Default dictionary
        request = {
            "action": None,
            "actionType": None,
            "symbol": None,
            "chartTF": None,
            "fromDate": None,
            "toDate": None,
            "id": None,
            "magic": None,
            "volume": None,
            "price": None,
            "stoploss": None,
            "takeprofit": None,
            "expiration": None,
            "deviation": None,
            "comment": None,
            "chartId": None,
            "indicatorChartId": None,
            "chartIndicatorSubWindow": None,
            "style": None,
        }

        # Update dictionary values if they exist in kwargs
        for key, value in kwargs.items():
            if key in request:
                request[key] = value
            else:
                raise KeyError("Unknown key in **kwargs ERROR")

        # Send the dictionary to the server
        self._send_request(request)

        # Return the server reply
        return self._get_reply()



class Metatrader:
    """
        MetaTrader API Interface
    """
    def __init__(
        self,
        host=None,
        real_volume=None,
        tz_local=None,
        dbtype=None,
        dbhost=None,
        dbport=None,
        dbpass=None,
        dbuser=None,
        dbname=None,
        debug=False,
    ):
        if debug:
            logging.basicConfig(**LOGGER)

        self.__api = Functions(host)
        self.real_volume = real_volume or False
        self.__tz_local = tz_local
        self.__utc_timezone = timezone("UTC")
        self.__my_timezone = get_localzone()
        self.__utc_brocker_offset = self.___utc_brocker_offset()
        # db settings
        self.dbtype = dbtype or "SQLITE"  # SQLITE OR INFLUXDB
        if self.dbtype == "INFLUXDB":
            warnings.warn(
                "INFLUXDB will be removed in future versions.", DeprecationWarning
            )
            # if dbtype is influxdb
            self.dbhost = dbhost or "localhost"
            self.dbport = dbport or "8086"
            self.dbuser = dbuser or "root"
            self.dbpass = dbpass or "root"
            self.dbname = dbname or "wisefinanceMT"
            self.protocol = "line"
            self.__client = DataFrameClient(
                self.dbhost, self.dbport, self.dbuser, self.dbpass, self.dbname
            )
            self.__client.create_database(self.dbname)

    def ___utc_brocker_offset(self):
        utc = datetime.now(self.__utc_timezone).strftime("%Y-%m-%d %H:%M:%S")
        try:
            broker = self.accountInfo()
            broker = datetime.strptime(broker["time"], "%Y.%m.%d %H:%M:%S")
        except KeyError as e:
            raise "Metatrader Server is disconnect" from e
        
        utc = datetime.strptime(utc, "%Y-%m-%d %H:%M:%S")

        duration = broker - utc
        duration_in_s = duration.total_seconds()
        hour = divmod(duration_in_s, 60)[0]
        seconds = int(hour) * 60
        return seconds
    
    def accountInfo(self):
        return self.__api.Command(action="ACCOUNT")
    

if __name__ == '__main__':
    api = Metatrader()
    accountInfo = api.accountInfo()
    print(accountInfo)
    print(accountInfo['balance'])