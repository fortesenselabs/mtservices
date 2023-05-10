import logging
import random
from threading import Thread
from typing import List
from datetime import datetime, timedelta
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
        self.earliest_get_data_start_date = None
        # 
        self.ACTIVE = False

    def _exchange_interfaces_get_historic_data(self):
        """
            Exchange Interface [Get Historic Data]
        """
        while True:
            for interface in self.exchange_manager.exchange_interfaces:
                symbols_data = interface.get_symbols()
                end_date = datetime.utcnow()
                start_date = (end_date - timedelta(days=10))
                # control start and end date from here 
                # 10 - 15 days per request should be fast enough
                # to ensure the current response data is not equal to the already existing data in the database,  use hashing
                self.exchange_manager.get_interfaces_historic_data_background(symbols_data = symbols_data, start_date = start_date, end_date = end_date)
                time.sleep(1)
            
        return
        
    def start(self):
        """
            start() can be used to initialize the manager.  
        """
        self.logger.info("InvestorManager.start")
        self.exchange_manager.start()

        # Taken from https://superfastpython.com/thread-periodic-background/
        # create and start the daemon thread
        self.logger.info('InvestorManager._exchange_interfaces_get_historic_data > Starting background task...')
        daemon = Thread(target=self._exchange_interfaces_get_historic_data, daemon=True, name='InvestorManager._exchange_interfaces_get_historic_data_Background')
        daemon.start()
        # self.logger.info(data)
        self.logger.info('Main thread is carrying on...')
        self.ACTIVE = True
        self.logger.info('Investor activated')
        

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
    
