#!/usr/bin/env python
import json
import logging
import asyncio
import pandas as pd

from time import sleep
from threading import Thread
from os.path import join, exists
from traceback import print_exc
from random import random
from datetime import datetime, timedelta
from typing import List, Dict
from application.exchange_interfaces.metatrader.orders import Order
from application.exchange_interfaces.metatrader.account_info import AccountInfo
from application.exchange_interfaces.metatrader._types import TimeFrames

# Define base 
from application.exchange_interfaces.metatrader.dwxconnect import DWXClient

# 
class BaseInterface(DWXClient, AccountInfo, Order):
    def __init__(self,                  
                 files_path: str, 
                 sleep_delay: float,          
                 max_retry_command_seconds: int,  
                 verbose: bool,
                 open_test_trades: bool,
                 logger: logging.Logger) -> None:
        
        self.files_path = files_path
        self.sleep_delay = sleep_delay
        self.max_retry_command_seconds = max_retry_command_seconds
        self.verbose = verbose
        self.open_test_trades = open_test_trades
        self.logger = logger

        # 
        self.load_orders_from_file = True
        self.event_handler = self

        super().__init__(self.event_handler, self.files_path, 
                         self.sleep_delay, self.max_retry_command_seconds, 
                         self.load_orders_from_file, self.verbose)

    
    def get_all_symbols(self):
        """
            Get all symbols\n
            - Synthetic Markets:\n
                    Volatility 10 Index
                    Volatility 100 Index
                    Volatility 25 Index
                    Volatility 50 Index
                    Volatility 75 Index
                    Step Index
                    Crash 1000 Index
                    Boom 1000 Index
                    Boom 500 Index
                    Crash 500 Index
                    Range Break 100 Index
                    Jump 100 Index
                    Volatility 10 (1s) Index
                    Volatility 25 (1s) Index
                    Volatility 50 (1s) Index
                    Volatility 75 (1s) Index
                    Volatility 100 (1s) Index
                    Volatility 200 (1s) Index
                    Volatility 300 (1s) Index
                    Boom 300 Index
                    Crash 300 Index
                    Range Break 200 Index
                    Jump 10 Index
                    Jump 25 Index
                    Jump 50 Index
                    Jump 75 Index
                    AUD Basket
                    EUR Basket
                    GBP Basket
                    USD Basket
                    Gold Basket
                    AUDUSD DFX 10 Index
                    EURUSD DFX 10 Index
                    GBPUSD DFX 10 Index
                    USDCHF DFX 10 Index
                    USDJPY DFX 10 Index
        """
        
        return
    
    # On tick Event
    def on_tick(self, symbol, bid, ask):
        """
            On tick Event
        """
        now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
        self.logger.info(f'on_tick => {now} | {symbol} | {bid} | {ask}')
        # to test trading. 
        # this will randomly try to open and close orders every few seconds. 
        if self.open_test_trades:
            if now > self.last_open_time + timedelta(seconds=3):

                self.last_open_time = now
                
                order_type = 'buy'
                price = ask
                if random() > 0.5:
                    order_type = 'sell'
                    price = bid

                self.open_order(symbol=symbol, order_type=order_type, 
                                    price=price, lots=0.5)

            if now > self.last_modification_time + timedelta(seconds=10):

                self.last_modification_time = now

                for ticket in self.open_orders.keys():
                    self.close_order(ticket, lots=0.1)

            if len(self.open_orders) >= 10:
                self.close_all_orders()
                # self.close_orders_by_symbol('GBPUSD')
                # self.close_orders_by_magic(0)


    # On Bar Data Event
    def on_bar_data(self, symbol, time_frame, time, open_price, high, low, close_price, tick_volume):
        """
            On Bar Data Event
        """
        now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
        self.logger.info(f'on_bar_data => {symbol} | {time_frame} |  {now} | {time} | {open_price}, {high} | {low} | {close_price}')

    def on_historic_data(self, symbol, time_frame, data):
        """
            On Historic Data
        """
        # you can also access the historic data via self.dwx.historic_data. 
        self.logger.info(f'historic_data => {symbol}, {time_frame}, {len(data)} bars')

    def on_historic_trades(self):
        """
            On Historic Data
        """
        self.logger.info(f'historic_trades => {len(self.historic_trades)}')

    def on_message(self, message):
        """
            On Message
        """
        if message['type'] == 'ERROR':
            # message['type']
            self.logger.error("Error Encountered =>  %s", message['error_type'] + '|' + message['description'])
        elif message['type'] == 'INFO':
            # message['type'] 
            self.logger.info(message['message'])

    # triggers when an order is added or removed, not when only modified. 
    def on_order_event(self):
        """
            On Order Event
        """
        self.logger.info(f'on_order_event. open_orders: {len(self.open_orders)} open orders')



class MetaTraderInterface:
    """
    MetaTraderInterface

    This Interface will subscribe to tick data and bar data. It will also request historic data. 

    !!! ----- IMPORTANT ----- !!!

    If open_test_trades = True, it will open many trades. 
    Please only run this on a demo account!
    """

    def __init__(self, 
                 logger: logging.Logger,
                 files_path: str = "C:/Metatrader5/MQL5/Files/", 
                 sleep_delay: float = 0.005,           # 5 ms for time.sleep()
                 max_retry_command_seconds: int = 10,  # retry to send the commend for 10 seconds if not successful. 
                 verbose: bool = True,
                 open_test_trades: bool = False,
                 selected_symbols: Dict = {}):
        
        # super().__init__(files_path, sleep_delay, max_retry_command_seconds, verbose, open_test_trades)
      
        self.name = "MetaTrader"
        # if true, it will randomly try to open and close orders every few seconds. 
        self.open_test_trades = open_test_trades
        self.files_path = files_path
        self.logger = logger
        self.selected_symbols = selected_symbols

        # self.last_open_time = datetime.utcnow()
        # self.last_modification_time = datetime.utcnow()

        self.base_interface = BaseInterface(
                                 files_path = self.files_path, 
                                 sleep_delay = sleep_delay, 
                                 max_retry_command_seconds = max_retry_command_seconds, 
                                 verbose = verbose,
                                 open_test_trades = self.open_test_trades,
                                 logger = self.logger)

        self.base_interface.start()
        sleep(1)

        self.subscribe()


    def get_info(self):
        """
            Get account Info
        """
        return self.base_interface.get_account_info()
    
    def subscribe(self, data_types: List[str] = ["tick", "bar"]):
        """
            Subscribe to symbols
        """
        if len(data_types) == 0:
            data_types = ["tick", "bar"]

        # subscribe to tick data:
        if "tick" in data_types:
            # self.base_interface.subscribe_symbols(['EURUSD', 'GBPUSD'])
            self.base_interface.subscribe_symbols(["Step Index", "Volatility 25 Index", "Crash 1000 Index"])

        # subscribe to bar data:
        if "bar" in data_types:
            # self.base_interface.subscribe_symbols_bar_data([['EURUSD', 'M15'], ['GBPJPY', 'M5'], ['AUDCAD', 'M1']])
            self.base_interface.subscribe_symbols_bar_data([["Step Index", 'M15'], ["Volatility 25 Index", 'M5'], ["Crash 1000 Index", 'M1']])

        return
    
    def get_historic_data(self, symbol: str = "Crash 1000 Index", time_frame: str = TimeFrames.TIMEFRAME_D1, 
                          start_date: datetime = (datetime.utcnow() - timedelta(days=30)), end_date: datetime = datetime.utcnow()) -> pd.DataFrame:
        """
            Get Historic Data
        """
        # request historic data:
        # start = end_date - timedelta(days=30)  # last 30 days
        self.base_interface.get_historic_data(symbol = symbol, time_frame = time_frame, start = start_date.timestamp(), end = end_date.timestamp())
        return
    
    def get_data(self):
        if not self.base_interface.START and not self.base_interface.ACTIVE: 
            while self.base_interface.ACTIVE:
                sleep(1)

    def stop(self):
        self.base_interface.START = False
        self.base_interface.ACTIVE = False
        
