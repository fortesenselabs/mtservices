import logging
import random
from typing import List
from datetime import datetime
from application.database.database import DataBaseSQLStore
from application.exchange_interfaces.manager import ExchangeInterfaceManager
from application.investor.strategies.base_strategy import BaseStrategy
from application.investor.orders_manager.base_order_manager import BaseOrderManager

class InvestorManager:
    """
        Investor Manager => used for managing strategies
    """
    def __init__(self, 
                 exchange_manager: ExchangeInterfaceManager,
                 strategy_interface: BaseStrategy,
                 notification_interfaces: List,
                 database_interface: DataBaseSQLStore,
                 logger: logging.Logger,
                 store_data: bool =  True) -> None:
        
        # super().__init__()
        # AccountInfo, BaseOrderManager
        self.exchange_manager = exchange_manager
        self.strategy_interface = strategy_interface
        self.notification_interfaces = notification_interfaces
        self.database_interface = database_interface
        self.logger = logger
        self.store_data = store_data
        # 
        self.ACTIVE = False

    def start(self):
        """
            start() can be used to initialize the manager.  
        """
        self.logger.info("InvestorManager.start")
        self.exchange_manager.start()
        
        for interface in self.exchange_manager.exchange_interfaces:
            symbols_data = interface.get_symbols()
            ## make this function a background running one
            self.exchange_manager.get_interfaces_historic_data_background(symbols_data = symbols_data) 
        # self.logger.info(data)
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
        # when getting historical info, calculate the average pip per timeframe 
        # using any timeframe lower than it
        # e.g for 1 hour you can use 30 mins and below historical chart 
        # if 30 mins is chosen it would be  [pips of the two 30 mins bars(1 hour)/2]
        
        return
    