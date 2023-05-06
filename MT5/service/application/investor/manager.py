import logging
import random
#
from datetime import datetime
from typing import List
from application.exchange_interfaces.manager import ExchangeInterfaceManager
from application.investor.orders_manager.base_order_manager import BaseOrderManager

class InvestorManager:
    """
        Investor Manager => used for managing strategies
    """
    def __init__(self, 
                 exchange_manager: ExchangeInterfaceManager,
                 strategy_interfaces: List,
                 notification_interfaces: List,
                 database_interfaces: List,
                 logger: logging.Logger,
                 selected_symbols: List = [],
                 store_data: bool =  True) -> None:
        
        # super().__init__()
        # AccountInfo, BaseOrderManager
        self.exchange_manager = exchange_manager
        self.strategy_interfaces = strategy_interfaces
        self.notification_interfaces = notification_interfaces
        self.database_interfaces = database_interfaces
        self.selected_symbols = selected_symbols
        self.logger = logger
        self.store_data = store_data
        # 
        self.ACTIVE = False

    def start(self):
        """
            start() can be used to initialize the manager.  
        """
        self.exchange_manager.start()
        self.ACTIVE = True

    def stop(self):
        """
            stop() can be used to de-initialize the manager.  
        """
        self.ACTIVE = False

    def main_task(self):
        """
            It is a highest level task which is added to the event loop and executed normally every 1 minute and then it calls other tasks.

            Where the main logic is written
        """
        try:
            # point = float(self.symbols.get_symbol_info(symbol).point)
            # digits = self.symbols.get_symbol_info(symbol).digits
            # trade_tick_size = self.symbols.get_symbol_info(symbol).trade_tick_size
            while True:
                symbol = random.sample(symbols, k=1)[0]
                point = float(self.symbols.get_symbol_info(symbol).point)
                digits = self.symbols.get_symbol_info(symbol).digits
                trade_tick_size = self.symbols.get_symbol_info(
                    symbol).trade_tick_size

                now = datetime.utcnow()
                # print(now)
                self.strategy.strategy_algorithm(
                    symbol, point, digits, trade_tick_size, now)

        except KeyboardInterrupt:
            res = self.close_all_orders()
            print(res)

    def on_info(self):
        """
            Any Info about what investor is currently doing can be gotten from here
        """
        
        return
    