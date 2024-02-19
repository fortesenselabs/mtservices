import socket
import json
from typing import List
from constants import SOCKET_BUFFER_SIZE


class MTFunctions:
    """
    MTFunctions: Functions to connect to a MT4 or MT5 EA Server.

        Args:
            host: Server IP address, like -> '127.0.0.1', '192.168.5.1'
            port: port number
            instrument_lookup: dict with general instrument names and broker instrument names
    """

    def __init__(
        self,
        host: str = None,
        port: int = None,
        debug: bool = False,
        instrument_lookup: list = [],
        authorization_code: str = "None",
    ):
        self.HOST = host or "127.0.0.1"
        self.PORT = port or 1122  # Port
        self.debug = debug
        self.instrument_conversion_list: list = instrument_lookup
        self.authorization_code: str = authorization_code
        self.connected: bool = False
        self.socket_error_message: str = ""
        self.timeout_value: int = 120
        self.sock: socket.socket

    @property
    def is_connected(self) -> bool:
        """Returns connection status.
        Returns:
            bool: True or False
        """
        return self.connected

    def _set_timeout(self, timeout_in_seconds: int = 120) -> None:
        """
        Set time out value for socket communication with MT4 or MT5 EA/Bot.

        Args:
            timeout_in_seconds: the time out value
        Returns:
            None
        """
        self.timeout_value = timeout_in_seconds
        self.sock.settimeout(
            self.timeout_value
        )  # improve the timeout value (causes socket to end without completing task)
        self.sock.setblocking(1)
        return

    def _disconnect(self) -> bool:
        """
        Closes the socket connection to a MT4 or MT5 EA bot.

        Args:
            None
        Returns:
            bool: True or False
        """
        self.sock.close()
        return True

    def _connect(self) -> bool:
        """
        Connects to a MT4 or MT5 EA/Bot.

        Args:
            None
        Returns:
            bool: True or False
        """
        # Create a socket object
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # Set timeout
        self._set_timeout()

        # if len(self.instrument_conversion_list) == 0:
        #     print("Broker Instrument list not available or empty")
        #     self.socket_error_message = "Broker Instrument list not available"
        #     return False

        # Connect to the server
        try:
            self.sock.connect((self.HOST, self.PORT))
            return True
        except socket.error as msg:
            print(
                "Couldnt connect with the socket-server: %self.sock\n terminating program"
                % msg
            )
            self.connected = False
            self.socket_error_message = "Could not connect to server."
            self.sock.close()
            return False
        except KeyboardInterrupt:
            self.sock.close()
            return False

    def _send_request(self, data: str) -> None:
        """Send request to the server via socket"""
        try:
            # Serialize the data to JSON and send it
            # json_data = json.dumps(data)
            self.sock.sendall(data.encode())  # Encode and send as bytes
        except AssertionError as err:
            raise err from Exception  # Handle exceptions as needed

    def _get_reply(self):
        """Get reply from the server via the socket with timeout"""
        try:
            # Read data from the socket until a valid JSON object is received
            buffer = b""
            while True:
                data = self.sock.recv(SOCKET_BUFFER_SIZE)
                if not data:
                    raise Exception("No data received from the server")

                buffer += data

                try:
                    msg, idx = json.JSONDecoder().raw_decode(buffer.decode())
                    buffer = buffer[idx:]
                    # msg = buffer.decode()
                    return msg  # Return the parsed string message
                except ValueError:
                    pass
        except Exception as err:
            raise Exception(
                "Socket receive error: " + str(err)
            )  # Handle exceptions as needed

    def send_command(self, command: str) -> dict:
        """Construct a request and send it to the server"""

        # Default dictionary
        request = command + "|" + self.authorization_code + "\r\n"

        # Send the dictionary to the server
        self._send_request(request)

        # Return the server reply
        return self._get_reply()
