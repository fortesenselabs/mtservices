import logging
import asyncio
import threading
import pandas as pd
from datetime import datetime, timedelta
from typing import Any, List, Dict
from application.exchange_interfaces.metatrader._types import TimeFrames

class ExchangeInterfaceManager:
    """
        Manage Interfaces
    """
    def __init__(self, interfaces: List,  database_interfaces: List, store_data: bool = True):
        self.interfaces = interfaces
        self.database_interfaces =  database_interfaces
        self.store_data = store_data

    # Get All Accounts Info
    def get_all_accounts_info(self) -> Dict:
        interfaces_info = {}
        for interface in self.interfaces:
            interfaces_info[interface.name] = interface.get_info()
        return interfaces_info

    def start(self):
        for interface in self.interfaces:
            t = threading.Thread(target=interface.get_data)
            t.start()

    def stop(self):
        for interface in self.interfaces:
            interface.stop()

    def get_interfaces_historic_data(self, 
                                     symbols_data: Dict[str, Any] = {"Crash 1000 Index": [TimeFrames.TIMEFRAME_D1]}, 
                                     start_date: datetime = (datetime.utcnow() - timedelta(days=30)), 
                                     end_date: datetime = datetime.utcnow()) -> Dict[str, pd.DataFrame]:
        """
            Get Historic data [All Interfaces]
        """
        if self.store_data:
            # Get database driver
            pass

        data = {}
        for interface in self.interfaces:
            data[interface.name] = interface.get_historic_data()
        return data
    
