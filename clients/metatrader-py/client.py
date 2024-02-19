import sys
import time
import logging
import pandas as pd
from datetime import datetime
from constants import TIME_FRAMES, ACTION_TYPE
from functions import MTFunctions
from typing import Dict

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


class MetaTrader:
    def __init__(
        self,
        host=None,
        real_volume=None,
        debug=False,
        authorization_code: str = "None",
        instrument_lookup: list = [],
    ):
        if debug:
            logging.basicConfig(**LOGGER)

        self._api = MTFunctions(
            host,
            debug=debug,
            authorization_code=authorization_code,
            instrument_lookup=instrument_lookup,
        )

        self.real_volume = real_volume or False

    def _date_to_timestamp(self, date, _format: str = "%d/%m/%Y"):
        if date is not None:
            return time.mktime(datetime.strptime(date, _format).timetuple())

        return None

    def _convert_date_to_utc(
        self, date: str, _format: str = "%d-%m-%Y %H:%M:%S"
    ) -> str:
        # date = datetime.strptime(date, _format)
        date = datetime.strptime(date, _format)
        # date = get_localzone().localize(date)
        # date = date.astimezone(timezone("UTC"))
        return date

    def _convert_results_to_df(
        self,
        results: Dict,
        time_frame: str = "TICK",
        action_type: str = ACTION_TYPE.PRICE,
    ) -> pd.DataFrame:
        df = pd.DataFrame()

        if action_type == ACTION_TYPE.PRICE:
            initial_columns = []
            if time_frame != "TICK":
                if len(results["rates"]) == 0:
                    return df

                initial_columns = ["rates"]
                df = pd.DataFrame(results["rates"], columns=initial_columns)

                # Splitting the column 'ticks' into three separate columns
                df[
                    [
                        "datetime",
                        "open",
                        "high",
                        "low",
                        "close",
                        "tick_volume",
                        "real_volume",
                        "spread",
                    ]
                ] = df["rates"].str.split(r"\|\|", expand=True)

            else:
                if len(results["ticks"]) == 0:
                    return df

                initial_columns = ["ticks"]
                df = pd.DataFrame(results["ticks"], columns=initial_columns)

                # Splitting the column 'ticks' into three separate columns
                df[["timestamp", "bid", "ask"]] = df["ticks"].str.split(
                    r"\|\|", expand=True
                )

            # Dropping the original column 'initial_columns'
            df.drop(columns=initial_columns, axis=1, inplace=True)

        elif action_type == ACTION_TYPE.TRADES:
            if len(results["trades"]) == 0:
                return df

            initial_columns = ["trades"]
            df = pd.DataFrame(results["trades"], columns=initial_columns)

            # Splitting the column 'trades' into three separate columns
            df[
                [
                    "ticket",
                    "timestamp",
                    "price",
                    "volume",
                    "symbol",
                    "type",
                    "entry",
                    "profit",
                ]
            ] = df["trades"].str.split(r"\|\|", expand=True)

            # Dropping the original column 'initial_columns'
            df.drop(columns=initial_columns, axis=1, inplace=True)
        else:
            # df["timestamp"] = pd.to_datetime(df["timestamp"], unit="s")
            pass

        return df

    def _trade(
        self,
        symbol: str = "EURUSD",
        actionType: str = "ORDER_TYPE_BUY",
        volume: float = 0.1,
        stoploss: float = 1.224,
        takeprofit: float = 1.244,
        price: float = 1.234,
        deviation: float = 5.0,
        comment: str = "Trade",
        id: str = "",
    ):
        actions = [
            "ORDER_TYPE_BUY",
            "ORDER_TYPE_SELL",
            "ORDER_TYPE_BUY_LIMIT",
            "ORDER_TYPE_SELL_LIMIT",
            "ORDER_TYPE_BUY_STOP",
            "ORDER_TYPE_SELL_STOP",
        ]
        if len(str(id)) == 0 and actionType not in actions:
            id = str(int(time.time()))

        expiration = 0  # int(time.time()) + 60 * 60 * 24  # 1 day
        command = f"TRADE|id={id}|actionType={actionType}|symbol={symbol}|volume={volume}|price={price}|stoploss={stoploss}|takeprofit={takeprofit}|expiration={expiration}|deviation={deviation}|comment={comment}"
        return self._api.send_command(command)

    def connect(self):
        self._api._connect()

    def disconnect(self):
        self._api._disconnect()

    def get_orders(self) -> dict:
        return self._api.send_command("ORDERS")

    def balance(self) -> dict:
        return self._api.send_command("BALANCE")

    def accountInfo(self) -> dict:
        return self._api.send_command("ACCOUNT")

    def get_positions(self) -> dict:
        return self._api.send_command("POSITIONS")

    def get_current_price(self, symbol: str = "EURUSD") -> dict:
        # {"event":"tick","data":{"symbol":"EURUSD","timeframe":"TICK","tick":["1708034393909",1.07689,1.07691]}}
        # time, bid, ask
        return self._api.send_command(f"TICK|symbol={symbol}")

    def get_historical_data(
        self,
        symbol: str = "EURUSD",
        time_frame: str = TIME_FRAMES.CURRENT,
        action_type: str = ACTION_TYPE.PRICE,
        from_date: str = "13-02-2024 00:00:00",
        to_date: str = "13-02-2024 12:00:00",
    ) -> pd.DataFrame:
        # from_date = "13-02-2024 00:00:00"
        # to_date = "13-02-2024 12:00:00"  # "13-02-2024 12:00:00"
        # NOTE: 1 day 14 hrs of data takes >7 mins to download (this is quite slow for a single day of data)
        # look for a way to download data faster

        from_date = self._convert_date_to_utc(from_date)
        to_date = self._convert_date_to_utc(to_date)

        print(from_date, to_date)

        results = self._api.send_command(
            f"HISTORY|symbol={symbol}|timeFrame={time_frame}|actionType={action_type}|from={from_date}|to={to_date}"
        )

        return self._convert_results_to_df(results, time_frame, action_type)

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

    def cancel_order_by_ticket_id(self, id: int):
        symbol = ""
        volume = 0
        price = 0
        stoploss = 0
        takeprofit = 0
        expiration = 0
        deviation = 0
        comment = "cancel order"

        return self._trade(
            symbol=symbol,
            actionType="ORDER_CANCEL",
            volume=volume,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
            comment=comment,
            id=id,
        )

    def close_position_by_ticket_id(self, id: int):
        symbol = ""
        volume = 0
        price = 0
        stoploss = 0
        takeprofit = 0
        expiration = 0
        deviation = 0
        comment = "close position"

        return self._trade(
            symbol=symbol,
            actionType="POSITION_CLOSE_ID",
            volume=volume,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
            comment=comment,
            id=id,
        )

    def close_position_by_symbol(self, symbol):
        id = ""
        volume = 0
        price = 0
        stoploss = 0
        takeprofit = 0
        expiration = 0
        deviation = 0
        comment = "close position"

        return self._trade(
            symbol=symbol,
            actionType="POSITION_CLOSE_SYMBOL",
            volume=volume,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
            comment=comment,
            id=id,
        )

    def close_partial_position(self, positionId: int, volume: float):
        symbol = ""
        price = 0
        stoploss = 0
        takeprofit = 0
        expiration = 0
        deviation = 0
        comment = "close position"

        return self._trade(
            symbol=symbol,
            actionType="POSITION_PARTIAL",
            volume=volume,
            stoploss=stoploss,
            takeprofit=takeprofit,
            price=price,
            comment=comment,
            id=positionId,
        )

    def cancel_all_orders(self):
        orders = self.get_orders()

        if "orders" in orders:
            while len(orders["orders"]) > 0:
                for order in orders["orders"]:
                    self.cancel_order_by_ticket_id(order["id"])
                    print(f"Canceling order {order['id']}")

    def close_all_positions(self):
        positions = self.get_positions()
        #    while len(positions["positions"]) > 0:
        if "positions" in positions:
            for i, position in enumerate(positions["positions"]):
                ticket_id = position["id"]
                self.close_position_by_ticket_id(ticket_id)
                print(f"Closing position {i+1} of {len(positions['positions'])}")
