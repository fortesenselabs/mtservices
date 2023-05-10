import time
import logging
import asyncio
import threading
import pandas as pd
from datetime import datetime, timedelta
from typing import Any, List, Dict
from application.database.database import DataBaseSQLStore
from application.exchange_interfaces.metatrader.types import TimeFrames


class ExchangeInterfaceManager:
    """
        Manage Interfaces
    """
    def __init__(self, logger: logging.Logger, exchange_interfaces: List, database_interface: DataBaseSQLStore, store_data: bool = False):
        self.logger = logger
        self.exchange_interfaces = exchange_interfaces
        self.database_interface = database_interface
        self.store_data = store_data

        if self.store_data:
            self._create_interface_database_tables()

    # Get All Accounts Info
    def get_all_accounts_info(self) -> Dict:
        self.logger.info("ExchangeInterfaceManager.get_all_accounts_info")
        interfaces_info = {}
        for interface in self.exchange_interfaces:
            interfaces_info[interface.name] = interface.get_info()
        return interfaces_info

    def start(self):
        self.logger.info("ExchangeInterfaceManager.start")
        for interface in self.exchange_interfaces:
            t = threading.Thread(target=interface._start)
            t.start()

    def stop(self):
        self.logger.info("ExchangeInterfaceManager.stop")
        for interface in self.exchange_interfaces:
            interface._stop()

    def _create_interface_database_tables(self):
        """
            Create database tables for each interface and symbol
        """
        for interface in self.exchange_interfaces:
            symbols_data = interface.get_symbols()
            for symbol, timeframes in symbols_data.items():
                for timeframe in timeframes:
                    symbol = symbol.lower().replace(" ", "_")
                    table_name = f"{interface.name}_{symbol}_{timeframe}_historic_prices"
                    self.database_interface.create_table(table_name=table_name, schema=interface.table_schema, primary_key="id")

    def get_interfaces_historic_data(self, symbols_data: Dict[str, List[str]] = {"Crash 1000 Index": [TimeFrames.TIMEFRAME_D1]},
                                     start_date: datetime = (datetime.utcnow() - timedelta(days=30)),
                                     end_date: datetime = datetime.utcnow()) -> Dict[str, pd.DataFrame]:
        """
            Get Historic data [All Interfaces]

            Args:
                symbols_data (Dict[str, Any]): Dictionary of symbols and timeframes.
                start_date (datetime): Start date for data retrieval.
                end_date (datetime): End date for data retrieval.

            Returns:
                Dict[str, pd.DataFrame]: Dictionary of interface names and corresponding dataframes.
        """
        self.logger.info("ExchangeInterfaceManager.get_interfaces_historic_data_async")
        data = {}
        for interface in self.exchange_interfaces:
            for symbol, timeframes in symbols_data.items():
                if len(timeframes) != 0:
                    for timeframe in timeframes:
                        historic_data = interface.get_historic_data(symbol=symbol, time_frame=timeframe, start_date=start_date, end_date=end_date)
                        # format symbol (convert to lower case and replace spaces with underscores)
                        symbol = symbol.lower().replace(" ", "_")
                        data[f"{interface.name}_{symbol}_{timeframe}"] = historic_data
                        if self.store_data and not historic_data.empty:
                            table_name = f"{interface.name}_{symbol}_{timeframe}_historic_prices"
                            self.database_interface.store_data(table_name=table_name, data=historic_data)

        return data
    
    def get_interfaces_historic_data_background(self, symbols_data: Dict[str, List[str]] = {"Crash 1000 Index": [TimeFrames.TIMEFRAME_D1]},
                                     start_date: datetime = (datetime.utcnow() - timedelta(days=30)),
                                     end_date: datetime = datetime.utcnow()) -> None:
        """
            Get Historic data [All Interfaces] in the background.

            Args:
                symbols_data (Dict[str, Any]): Dictionary of symbols and timeframes.
                start_date (datetime): Start date for data retrieval.
                end_date (datetime): End date for data retrieval.

            Returns:
                None
        """
        self.logger.info("ExchangeInterfaceManager.get_interfaces_historic_data_background")
        self.get_interfaces_historic_data(symbols_data=symbols_data, start_date=start_date, end_date=end_date)
        # asyncio.run(self.get_interfaces_historic_data_async(symbols_data=symbols_data, start_date=start_date, end_date=end_date))
