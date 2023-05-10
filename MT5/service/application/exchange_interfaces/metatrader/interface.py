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
from sqlalchemy import Integer, String, Float, DateTime, Column
from application.utils.conversion import convert_dict_to_list
from application.exchange_interfaces.metatrader.orders import Order
from application.exchange_interfaces.metatrader.account_info import AccountInfo
from application.exchange_interfaces.metatrader.types import TimeFrames
from application.exchange_interfaces.metatrader.dwxconnect import DWXClient

# Define base 
class BaseMTInterface(DWXClient, AccountInfo, Order):
    """
        Base MT Interface
    """
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
        
        
        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

    
    # On tick Event
    def on_tick(self, symbol, bid, ask):
        """
            On tick Event
        """
        now = datetime.utcnow()
        data = {'current_datetime': now.strftime("%Y.%m.%d %H:%M:%S"),
                'symbol': symbol,
                'bid': bid, 
                'ask': ask}
        self.logger.info(f"on_tick => {data}")
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
    def on_bar_data(self, symbol, time_frame, time, open, high, low, close, tick_volume):
        """
            On Bar Data Event
        """
        now = datetime.utcnow()
        data = {'current_datetime': now.strftime("%Y.%m.%d %H:%M:%S"),
                'symbol': symbol,
                'time_frame': time_frame, 
                'time': time,
                'open': open,
                'high': high,
                'low': low,
                'close': close,
                'tick_volume': tick_volume}
        self.logger.info(f'on_bar_data => {data}')

    def on_historic_data(self, symbol, time_frame, data):
        """
            On Historic Data
        """
        # you can also access the historic data via self.historic_data. 
        # self.logger.info(data)
        # with open('output.json', 'w') as f:
        #     json.dump(data, f)
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

    This Interface will subscribe to tick data and bar data,
    It also holds the database schema for the historic data. 

    !!! ----- IMPORTANT ----- !!!

    If open_test_trades = True, it will open many trades. 
    Please only run this on a demo account!

    Format of the selected_symbols is => {
    '<symbol_name_1>': ['<timeframe_1>', '<timeframe_2>', '...'],
    '<symbol_name_2>': ['<timeframe_1>', '<timeframe_2>', '...'],
    ...
    '<symbol_name_N>': ['<timeframe_1>', '<timeframe_2>', '...']}
    """

    def __init__(self, 
                 logger: logging.Logger,
                 files_path: str = "C:/Metatrader5/MQL5/Files/", 
                 sleep_delay: float = 0.005,           # 5 ms for time.sleep()
                 max_retry_command_seconds: int = 10,  # retry to send the commend for 10 seconds if not successful. 
                 verbose: bool = True,
                 open_test_trades: bool = False,
                 selected_symbols: Dict[str, List] = {},
                 subscribe_type: List[str] = ["tick", "bar"]):
        
        # super().__init__(files_path, sleep_delay, max_retry_command_seconds, verbose, open_test_trades)
      
        self.name = "MetaTrader"
        # if true, it will randomly try to open and close orders every few seconds. 
        self.open_test_trades = open_test_trades
        self.files_path = files_path
        self.logger = logger
        self.subscribe_type = subscribe_type
        self.selected_symbols = selected_symbols
        if (self.selected_symbols) == 0:
            self.selected_symbols = {
                "EURUSD": [],
                "GBPJPY": [TimeFrames.TIMEFRAME_M5],
                "AUDCAD": [TimeFrames.TIMEFRAME_M1]}


        # database schema
        self.table_schema = [
            ('id', Integer),
            ('datetime', DateTime),
            ('open', Float),
            ('high', Float),
            ('low', Float),
            ('close', Float),
            ('tick_volume', Integer)]

        self.base_interface = BaseMTInterface(
                                 files_path = self.files_path, 
                                 sleep_delay = sleep_delay, 
                                 max_retry_command_seconds = max_retry_command_seconds, 
                                 verbose = verbose,
                                 open_test_trades = self.open_test_trades,
                                 logger = self.logger)

        self.base_interface.start()
        sleep(1)

    def get_info(self):
        """
            Get account Info
        """
        self.logger.info('MetaTraderInterface.get_info')
        return self.base_interface.get_account_info()
    
    def get_symbols(self):
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
        self.logger.info('MetaTraderInterface.get_symbols')
        # list(self.selected_symbols.keys())
        return self.selected_symbols
    
    def subscribe(self):
        """
            Subscribe to symbols
        """
        self.logger.info('MetaTraderInterface.subscribe')
        if len(self.subscribe_type) == 0:
            self.subscribe_type = ["tick", "bar"]

        # subscribe to tick data:
        if "tick" in self.subscribe_type:
            sub_symbols = list(self.selected_symbols.keys())
            self.base_interface.subscribe_symbols(sub_symbols)

        # subscribe to bar data:
        if "bar" in self.subscribe_type:
            sub_symbols = convert_dict_to_list(self.selected_symbols)
            self.base_interface.subscribe_symbols_bar_data(sub_symbols)
        return
    
    def get_historic_data(self, symbol: str = "EURUSD", time_frame: str = TimeFrames.TIMEFRAME_D1, 
                          start_date: datetime = (datetime.utcnow() - timedelta(days=30)), end_date: datetime = datetime.utcnow()) -> pd.DataFrame:
        """
            Get Historic Data
        """
        self.logger.info(f'MetaTraderInterface.get_historic_data => {symbol} | {time_frame}')
        # request historic data:
        # start = end_date - timedelta(days=30)  # last 30 days
        start_date = start_date.timestamp()
        end_date = end_date.timestamp()
        self.base_interface.get_historic_data(symbol = symbol, time_frame = time_frame, start = start_date, end = end_date)
        sleep(5)
        
        symbol_time_frame_key = symbol + '_' + time_frame
        current_available_symbols = list(self.base_interface.historic_data.keys())
        if len(self.base_interface.historic_data) != 0 and symbol_time_frame_key in current_available_symbols:
            self.logger.info(current_available_symbols)
            # self.logger.info(self.base_interface.historic_data)
            # create a dataframe from the nested dictionary
            converted_dict = {'datetime': [], 'open': [], 'high': [], 'low': [], 'close': [], 'tick_volume': []}
            for key, values in self.base_interface.historic_data[symbol_time_frame_key].items():
                converted_dict['datetime'].append(key)
                converted_dict['open'].append(values['open'])
                converted_dict['high'].append(values['high'])
                converted_dict['low'].append(values['low'])
                converted_dict['close'].append(values['close'])
                converted_dict['tick_volume'].append(values['tick_volume'])

            data = pd.DataFrame(converted_dict)
            return data
        
        return pd.DataFrame()
    
    def _start(self):
        """
            Start the Interface
        """
        self.logger.info('MetaTraderInterface._start')
        self.subscribe()

        if not self.base_interface.START and not self.base_interface.ACTIVE: 
            while self.base_interface.ACTIVE:
                sleep(1)

    def _stop(self):
        """
            Stop the Interface 
        """
        self.logger.info('MetaTraderInterface._stop')
        self.base_interface.START = False
        self.base_interface.ACTIVE = False

        self.logger.info('Closing all open orders')
        self.base_interface.close_all_orders()
        self.logger.info('Done')
        
