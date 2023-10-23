import os
import sys
import json
import time
import socket
import logging
import warnings
from queue import Queue
from threading import Thread
import pandas as pd
from tqdm import tqdm
from pytz import timezone
from tzlocal import get_localzone
from datetime import datetime, timedelta
from influxdb import DataFrameClient
from ejtraderTH import start
from ejtraderDB import DictSQLite

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

SOCK_BUF = 8192  # Adjust the buffer size as needed (4096)


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
            buffer = b""
            while True:
                data = self.sock.recv(SOCK_BUF)
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
            raise Exception(
                "Socket receive error: " + str(err)
            )  # Handle exceptions as needed

    def Command(self, **kwargs) -> dict:
        """Construct a request dictionary from default and send it to the server"""

        # Default dictionary
        request = {
            "action": None,
            "actionType": None,
            "symbol": None,
            "chartTimeFrame": None,
            "fromDate": None,  # None | 1
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
            raise SystemError(f"Metatrader Server is disconnect: {e}")

        utc = datetime.strptime(utc, "%Y-%m-%d %H:%M:%S")

        duration = broker - utc
        duration_in_s = duration.total_seconds()
        hour = divmod(duration_in_s, 60)[0]
        seconds = int(hour) * 60
        return seconds

        # convert datestamp to dia/mes/ano

    def __date_to_timestamp(self, s):
        if s is not None:
            return time.mktime(datetime.strptime(s, "%d/%m/%Y").timetuple())
        return None

    # convert datestamp to dia/mes/ano
    def datetime_to_timestamp(self, s):
        if s is not None:
            return time.mktime(s.timetuple())
        return None

    def ___date_to_timestamp_broker(self):
        brokertime = time.mktime(
            datetime.strptime(
                self.accountInfo()["time"], "%Y.%m.%d %H:%M:%S"
            ).timetuple()
        )
        return brokertime

    def __brokerTimeDelta(self, m):
        delta = timedelta(days=m)
        broker = datetime.strptime(self.accountInfo()["time"], "%Y.%m.%d %H:%M:%S")
        result = broker - delta
        return result

    def __timeframe_to_sec(self, timeframe):
        # Timeframe dictionary
        TIMECANDLE = {
            "M1": 60,
            "M2": 120,
            "M3": 180,
            "M4": 240,
            "M5": 300,
            "M15": 900,
            "M30": 1800,
            "H1": 3600,
            "H4": 14400,
            "D1": 86400,
            "W1": 604800,
            "MN": 2629746,
        }
        return TIMECANDLE[timeframe]

    def __set_utc_or_localtime_tz_df(self, df: pd.DataFrame):
        try:
            df.index = df.index.tz_localize(self.__utc_brocker_offset)
            if self.__tz_local:
                df.index = df.index.tz_convert(self.__my_timezone)
            df.index = df.index.tz_localize(None)
        except:
            pass
        return df

    def _start_thread_price(self):
        t = Thread(target=self._price, daemon=True)
        t.start()
        self.__priceQ = Queue()

    def __historyThread_save(self, data):
        actives = self.__symbol
        chartTimeFrame = self.chartTimeFrame
        fromDate = self.fromDate
        toDate = self.toDate
        main = pd.DataFrame()
        current = pd.DataFrame()
        self._count = 0
        try:
            os.makedirs("DataBase")
        except OSError:
            pass
        # count data
        if not isinstance(fromDate, int):
            start_date = datetime.strptime(fromDate, "%d/%m/%Y")
        else:
            start_date = self.__brokerTimeDelta(fromDate)
        if not toDate:
            end_date = self.__brokerTimeDelta(0)
        else:
            end_date = datetime.strptime(toDate, "%d/%m/%Y")

        delta = timedelta(days=1)
        delta2 = timedelta(days=1)
        diff_days = start_date - end_date
        days_count = diff_days.days
        pbar = tqdm(total=abs(days_count))
        appended_data = []
        active = None
        df = None
        while start_date <= end_date:
            pbar.update(delta.days)
            fromDate = start_date.strftime("%d/%m/%Y")
            toDate = start_date
            toDate += delta2
            toDate = toDate.strftime("%d/%m/%Y")
            attempts = 0
            success = False

            # if chartTimeFrame == "TICK":
            #     chartConvert = 60
            # else:
            #     chartConvert = self.__timeframe_to_sec(chartTimeFrame)
            for active in actives:
                self._count += 1

                # the first symbol on list is the main and the rest will merge
                if active == actives[0]:
                    self.__active_name = active
                    while not success and attempts < 5:
                        try:
                            data = self.__api.Command(
                                action="HISTORY",
                                actionType="DATA",
                                symbol=active,
                                chartTimeFrame=chartTimeFrame,
                                fromDate=self.__date_to_timestamp(fromDate),
                                toDate=self.__date_to_timestamp(toDate),
                            )
                            success = True
                        except Exception as e:
                            logging.info(
                                f"Error while processing {active} from {fromDate}. Error message: {str(e)}"
                            )
                            attempts += 1
                    if attempts == 5 and not success:
                        logging.info(f"Check if {active} is avalible from {fromDate}")
                        pass

                    if data is not None and isinstance(data, dict):
                        try:
                            if data["data"]:
                                main = pd.DataFrame(data["data"])
                                main = main.set_index([0])
                                main.index.name = "date"

                                # TICK DATA
                                if chartTimeFrame == "TICK":
                                    main.columns = ["bid", "ask"]
                                    main.index = pd.to_datetime(main.index, unit="ms")
                                else:
                                    main.index = pd.to_datetime(main.index, unit="s")
                                    if self.real_volume:
                                        del main[5]
                                    else:
                                        del main[6]
                                    main.columns = [
                                        "open",
                                        "high",
                                        "low",
                                        "close",
                                        "volume",
                                        "spread",
                                    ]
                        except Exception as e:
                            logging.info(
                                f"Error while processing Dataframe {active} from {fromDate}. Error message: {str(e)}"
                            )
                            pass
                else:
                    while not success and attempts < 2:
                        try:
                            data = self.__api.Command(
                                action="HISTORY",
                                actionType="DATA",
                                symbol=active,
                                chartTimeFrame=chartTimeFrame,
                                fromDate=self.__date_to_timestamp(fromDate),
                                toDate=self.__date_to_timestamp(toDate),
                            )
                            success = True
                        except Exception as e:
                            logging.info(
                                f"Error while processing {active}. Error message: {str(e)}"
                            )
                            attempts += 1
                    if attempts == 2 and not success:
                        logging.info(f"Check if {active} is avalible from {fromDate}")
                        pass

                    if data is not None and isinstance(data, dict):
                        try:
                            if data["data"]:
                                current = pd.DataFrame(data["data"])
                                current = current.set_index([0])
                                current.index.name = "date"
                                active = active.lower()
                                # TICK DATA
                                if chartTimeFrame == "TICK":
                                    current.index = pd.to_datetime(
                                        current.index, unit="ms"
                                    )
                                    current.columns = [f"{active}_bid", f"{active}_ask"]
                                else:
                                    current.index = pd.to_datetime(
                                        current.index, unit="s"
                                    )
                                    if self.real_volume:
                                        del current[5]
                                    else:
                                        del current[6]

                                    current.columns = [
                                        f"{active}_open",
                                        f"{active}_high",
                                        f"{active}_low",
                                        f"{active}_close",
                                        f"{active}_volume",
                                        f"{active}_spread",
                                    ]

                                # main = pd.merge(main, current, how='inner',
                                #                 left_index=True, right_index=True)
                                main = pd.merge(main, current, on="date")
                        except Exception as e:
                            logging.info(
                                f"Error while merge Dataframe {active}. Error message: {str(e)}"
                            )
                            pass

            try:
                main = main.loc[~main.index.duplicated(keep="first")]
                appended_data.append(main)
            except Exception as e:
                logging.info(
                    f"Error while finishing Dataframe for {active}. Error message: {str(e)}"
                )
                pass
            start_date += delta
        pbar.close()

        if len(appended_data) > 0:
            try:
                df = pd.concat(appended_data)
            except Exception as e:
                logging.info(
                    f"Error while processing {active}. Error message: {str(e)}"
                )
                pass

            if self.__database:
                start(self.__save_to_db, data=[df], repeat=1, max_threads=20)
            else:
                try:
                    self.__set_utc_or_localtime_tz_df(df)
                    self.__historyQ.put(df)

                except Exception as e:
                    logging.info(
                        f"Error while processing {active}. Error message: {str(e)}"
                    )
                    pass

    def __save_to_db(self, df):
        if self.dbtype == "SQLITE":
            q = DictSQLite("history", multithreading=True)
            try:
                self.__set_utc_or_localtime_tz_df(df)

            except Exception as e:
                logging.info(
                    f"Error while processing database. Error message: {str(e)}"
                )
                pass

            q[f"{self._symbol}"] = df
        else:
            try:
                self.__set_utc_or_localtime_tz_df(df)
            except Exception as e:
                logging.info(
                    f"Error while processing utc or localtime tz. Error message: {str(e)}"
                )
                pass
        if self.dbtype == "INFLUXDB":
            self.__client.write_points(df, f"{self._symbol}", protocol=self.protocol)

    def _price(self):
        connect = self.__api.sock
        while True:
            price = connect.recv(SOCK_BUF)
            try:
                price = price["data"]
                price = pd.DataFrame([price])
                price = price.set_index([0])
                price.index.name = "date"
                if self._allchartTimeFrame == "TICK":
                    price.index = pd.to_datetime(price.index, unit="ms")
                    price.columns = ["bid", "ask"]
                    self.__priceQ.put(price)
                elif self.__allchartTimeFrame == "TS":
                    price.index = pd.to_datetime(price.index, unit="ms")
                    price.columns = ["type", "bid", "ask", "last", "volume"]
                    self.__priceQ.put(price)
                else:
                    if self.real_volume:
                        del price[5]
                    else:
                        del price[6]
                    price.index = pd.to_datetime(price.index, unit="s")
                    price.columns = ["open", "high", "low", "close", "volume", "spread"]
                    self.__priceQ.put(price)

            except KeyError:
                pass

    def history(
        self,
        symbol: str,
        chartTimeFrame=None,
        fromDate=None,
        toDate=None,
        database=None,
        use_dataframe=True,
    ):
        self.chartTimeFrame = chartTimeFrame
        self.__database = database
        self.fromDate = fromDate
        self.toDate = toDate
        self.__historyQ = Queue()
        self.dataframe = use_dataframe

        if isinstance(symbol, tuple):
            for symbols in symbol:
                self.__symbol = symbols
                print(symbols)
        elif isinstance(symbol, list):
            self.__symbol = symbol
        else:
            self.__symbol = [symbol]

        if chartTimeFrame:
            if self.__database:
                try:
                    start(self.__historyThread_save, repeat=1, max_threads=20)
                except Exception as e:
                    logging.info(
                        f"Error: unable to start History thread Error message: {str(e)}"
                    )
            else:
                try:
                    start(self.__historyThread_save, repeat=1, max_threads=20)
                except Exception as e:
                    logging.info(
                        f"Error: unable to start History thread Error message: {str(e)}"
                    )

                return self.__historyQ.get()
        else:
            q = DictSQLite("history")
            if isinstance(symbol, list):
                try:
                    if self.dbtype == "SQLITE":
                        df = q[f"{self.__symbol[0]}"]
                    else:
                        df = self.__client.query(f"select * from {self.__symbol[0]}")
                        df = df[self.__symbol[0]]

                        df.index.name = "date"
                except KeyError:
                    df = f" {self.__symbol[0]}  isn't on database"
                    pass
            else:
                try:
                    if self.dbtype == "SQLITE":
                        df = q[f"{self.__symbol}"]
                    else:
                        df = self.__client.query(f"select * from {self.__symbol}")
                        df = df[self.__symbol]

                        df.index.name = "date"
                except KeyError:
                    df = f" {self.__symbol}  isn't on database"
                    pass
            return df
        return

    def calendar(self, symbol=None, fromDate=None, toDate=None, database=None):
        self._symbol = symbol
        self._fromDate = fromDate
        self._toDate = toDate
        self.__calendarQ = Queue()
        self.__database = database
        try:
            start(self._calendar, repeat=1, max_threads=20)
        except Exception as e:
            logging.info(f"Error: {e}")

        return self.__calendarQ.get()

    def _calendar(self, data):
        symbol = self._symbol
        fromDate = self._fromDate
        toDate = self._toDate
        df = pd.DataFrame()
        # count data
        if not isinstance(fromDate, int):
            start_date = datetime.strptime(fromDate, "%d/%m/%Y")
        else:
            start_date = self.__brokerTimeDelta(fromDate)
        if not toDate:
            end_date = self.__brokerTimeDelta(0)
        else:
            end_date = datetime.strptime(toDate, "%d/%m/%Y")

        delta = timedelta(days=1)
        delta2 = timedelta(days=1)
        diff_days = start_date - end_date
        days_count = diff_days.days
        pbar = tqdm(total=abs(days_count))
        appended_data = []
        while start_date <= end_date:
            pbar.update(delta.days)
            fromDate = start_date.strftime("%d/%m/%Y")
            toDate = start_date
            toDate += delta2
            toDate = toDate.strftime("%d/%m/%Y")

            try:
                df = self.__api.Command(
                    action="CALENDAR",
                    actionType="DATA",
                    symbol=symbol,
                    fromDate=self.__date_to_timestamp(fromDate),
                    toDate=self.__date_to_timestamp(toDate),
                )
            except Exception as e:
                logging.info(
                    f"Error while processing {symbol}. Error message: {str(e)}"
                )
                pass

            try:
                df = pd.DataFrame(df["data"])
                df.columns = [
                    "date",
                    "currency",
                    "impact",
                    "event",
                    "country",
                    "actual",
                    "forecast",
                    "previous",
                ]
                df["date"] = pd.to_datetime(df["date"], errors="coerce")
                df = df.dropna(subset=["date"])
                df = df.set_index("date")
                df.index = pd.to_datetime(df.index)
            except Exception as e:
                logging.info(
                    f"Error while processing {symbol} Dataframe. Error message: {str(e)}"
                )
                pass

            appended_data.append(df)
            start_date += delta
        pbar.close()

        df = pd.concat(appended_data)

        if self.__database:
            start(self.__save_to_db, data=[df], repeat=1, max_threads=20)
        else:
            try:
                self.__set_utc_or_localtime_tz_df(df)
                self.__calendarQ.put(df)
            except AttributeError:
                pass

    def balance(self):
        return self.__api.Command(action="BALANCE")

    def accountInfo(self):
        return self.__api.Command(action="ACCOUNT")

    def positions(self):
        return self.__api.Command(action="POSITIONS")

    def orders(self):
        return self.__api.Command(action="ORDERS")

    def _trade(
        self, symbol, actionType, volume, stoploss, takeprofit, price, deviation
    ):
        self.__api.Command(
            action="TRADE",
            actionType=actionType,
            symbol=symbol,
            volume=volume,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
            deviation=deviation,
        )

    def buy(self, symbol, volume, stoploss, takeprofit, deviation=5):
        price = 0
        self._trade(
            symbol, "ORDER_TYPE_BUY", volume, stoploss, takeprofit, price, deviation
        )

    def sell(self, symbol, volume, stoploss, takeprofit, deviation=5):
        price = 0
        self._trade(
            symbol, "ORDER_TYPE_SELL", volume, stoploss, takeprofit, price, deviation
        )

    def buy_limit(self, symbol, volume, stoploss, takeprofit, price=0, deviation=5):
        self._trade(
            symbol,
            "ORDER_TYPE_BUY_LIMIT",
            volume,
            stoploss,
            takeprofit,
            price,
            deviation,
        )

    def sell_limit(self, symbol, volume, stoploss, takeprofit, price=0, deviation=5):
        self._trade(
            symbol,
            "ORDER_TYPE_SELL_LIMIT",
            volume,
            stoploss,
            takeprofit,
            price,
            deviation,
        )

    def buy_stop(self, symbol, volume, stoploss, takeprofit, price=0, deviation=5):
        self._trade(
            symbol,
            "ORDER_TYPE_BUY_STOP",
            volume,
            stoploss,
            takeprofit,
            price,
            deviation,
        )

    def sell_stop(self, symbol, volume, stoploss, takeprofit, price=0, deviation=5):
        self._trade(
            symbol,
            "ORDER_TYPE_SELL_STOP",
            volume,
            stoploss,
            takeprofit,
            price,
            deviation,
        )

    def modify_position(self, id: int, stoploss, takeprofit):
        self.__api.Command(
            action="TRADE",
            actionType="POSITION_MODIFY",
            id=id,
            stoploss=stoploss,
            takeprofit=takeprofit,
        )

    def modify_order(self, id: int, stoploss, takeprofit, price):
        self.__api.Command(
            action="TRADE",
            actionType="ORDER_MODIFY",
            id=id,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
        )

    def cancel_order_by_ticket_id(self, id: int):
        self.__api.Command(action="TRADE", actionType="ORDER_CANCEL", id=id)

    def close_position_by_ticket_id(self, id: int):
        self.__api.Command(action="TRADE", actionType="POSITION_CLOSE_ID", id=id)

    def close_position_by_symbol(self, symbol):
        self.__api.Command(
            action="TRADE", actionType="POSITION_CLOSE_SYMBOL", symbol=symbol
        )

    def close_partial_position(self, id: int, volume: float):
        self.__api.Command(
            action="TRADE", actionType="POSITION_PARTIAL", id=id, volume=volume
        )

    def cancel_all_orders(self):
        orders = self.orders()

        if "orders" in orders:
            for order in orders["orders"]:
                self.cancel_order_by_ticket_id(order["id"])

    def close_all_positions(self):
        positions = self.positions()

        if "positions" in positions:
            for position in positions["positions"]:
                self.close_position_by_ticket_id(position["id"])


if __name__ == "__main__":
    api = Metatrader()

    # Account information
    accountInfo = api.accountInfo()
    print(accountInfo)
    print(api.balance())

    # History from Date to Date
    # symbol = "Step Index"
    # timeframe = "D1"
    # fromDate = "20/02/2021"
    # toDate = "24/02/2022"

    # history = api.history(symbol, timeframe, fromDate, toDate)
    # print(history)

    # History by period unit like 27 candles
    # you can add unlimited actives to list  ["EURUSD","GBPUSD","AUDUSD"]
    # symbol = "Step Index"
    # timeframe = "D1"
    # fromDate = 27

    # history = api.history(symbol, timeframe, fromDate)
    # print(history)

    # TODO: Not Working  (error => strptime() argument 1 must be str, not None)
    # History for lastest period great for predictions
    # you can add unlimited actives to list  ["EURUSD","GBPUSD","AUDUSD"]
    # symbol = "Step Index"
    # timeframe = "D1"

    # history = api.history(symbol, timeframe)
    # print(history)

    # History for multiple symbols merged dataframe
    # you can add unlimited actives to list  ["EURUSD","GBPUSD","AUDUSD"] etc
    # symbol = ["Step Index", "Boom 1000 Index"]
    # timeframe = "D1"
    # fromDate = "20/02/2021"
    # toDate = "24/02/2021"

    # history = api.history(symbol, timeframe, fromDate, toDate)
    # print(history)

    # TODO: there ought to be response in trade request (orders, and positions)
    # You can create market or pending order with the commands.
    # Market Orders
    # symbol, volume, stoploss, takeprofit, deviation
    # api.buy("Step Index", 0.1, None, None, 5) # opens multiple orders
    # api.sell("Step Index", 0.1, None, None, 5)

    # Limit Orders
    # symbol, volume, stoploss, takeprofit, price, deviation
    # api.buy_limit("Step Index", 0.1, 8300.0, 8500.0, 8363.2, 5)
    # api.sellLimit("Step Index", 0.1, 1.20, 1.17, 1.19, 5)

    # Stop Orders
    # symbol, volume, stoploss, takeprofit, price, deviation
    # api.buyStop("Step Index", 0.01, 1.18, 1.20, 1.19, 5)
    # api.sellStop("Step Index", 0.01, 1.19, 1.17, 1.18, 5)

    # Positions & Manipulation
    # positions = api.positions()
    # print(positions)
    # if "positions" in positions:
    #     for position in positions["positions"]:
    #         api.close_position_by_ticket_id(position["id"])

    # close partial
    # id, volume
    # if "positions" in positions:
    #     for position in positions["positions"]:
    #         api.close_partial_position(position["id"], 0.5)

    # Orders & Manipulation
    # orders = api.orders()
    # print(orders)
    # if 'orders' in orders:
    #     for order in orders['orders']:
    #         api.cancel_order_by_ticket_id(order['id'])

    # close by symbol
    # api.close_position_by_symbol("Step Index")

    #  close all positions
    # api.close_all_positions()

    # cancel all orders
    # api.cancel_all_orders()


# errors:
# {"error":true,"lastError":"65537","description":"ERR_DESERIALIZATION","function":"UnWrapRequestObject"}
