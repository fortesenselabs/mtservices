import json
from time import sleep
from threading import Thread
from os.path import join, exists
from traceback import print_exc
from random import random
from datetime import datetime, timedelta
from api.dwx_client import DWXClient

class BaseProcessor:
    def __init__(self, open_test_trades: bool = False) -> None:
        # if true, it will randomly try to open and close orders every few seconds. 
        self.open_test_trades = open_test_trades
        self.on_tick_data = {}

    def test_trades(self, symbol, bid, ask, now):
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

                self.dwx.open_order(symbol=symbol, order_type=order_type, 
                                    price=price, lots=0.1)

            if now > self.last_modification_time + timedelta(seconds=10):

                self.last_modification_time = now

                for ticket in self.dwx.open_orders.keys():
                    self.dwx.close_order(ticket, lots=0.1)

            if len(self.dwx.open_orders) >= 10:
                self.dwx.close_all_orders()
                # self.dwx.close_orders_by_symbol('GBPUSD')
                # self.dwx.close_orders_by_magic(0)

    def on_tick(self, symbol, bid, ask):

        now = datetime.utcnow()
        datetime_string = now.strftime('%Y-%m-%d %H:%M:%S')

        # print('on_tick:', datetime_string, symbol, bid, ask)

        self.on_tick_data = {'data_type': 'on_tick:', 'datetime': datetime_string, 'symbol': symbol, 'bid': bid, 'ask': ask}
        # self.test_trades(self, symbol, bid, ask, now)

    def on_bar_data(self, symbol, time_frame, time, open_price, high, low, close_price, tick_volume):
        
        print('on_bar_data:', symbol, time_frame, datetime.utcnow(), time, open_price, high, low, close_price)

    
    def on_historic_data(self, symbol, time_frame, data):
        
        # you can also access the historic data via self.dwx.historic_data. 
        print('historic_data:', symbol, time_frame, f'{len(data)} bars')


    def on_historic_trades(self):

        print(f'historic_trades: {len(self.dwx.historic_trades)}')
    

    def on_message(self, message):

        if message['type'] == 'ERROR':
            print(message['type'], '|', message['error_type'], '|', message['description'])
        elif message['type'] == 'INFO':
            print(message['type'], '|', message['message'])


    # triggers when an order is added or removed, not when only modified. 
    def on_order_event(self):
        
        print(f'on_order_event. open_orders: {len(self.dwx.open_orders)} open orders')



class TickProcessor(BaseProcessor):
    """

    Example dwxconnect client in python


    This example client will subscribe to tick data and bar data. It will also request historic data. 

    !!! ----- IMPORTANT ----- !!!

    If open_test_trades=True, it will open many trades. 
    Please only run this on a demo account!

    !!! ----- IMPORTANT ----- !!!

    """

    def __init__(self, MT_directory_path, 
                 sleep_delay=0.005,             # 5 ms for time.sleep()
                 max_retry_command_seconds=10,  # retry to send the commend for 10 seconds if not successful. 
                 verbose=True
                 ):

        # if true, it will randomly try to open and close orders every few seconds. 
        open_test_trades = True
        super().__init__(open_test_trades)

        self.added_symbols = None
        # 
        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

        self.dwx = DWXClient(self, MT_directory_path, sleep_delay, 
                              max_retry_command_seconds, verbose=verbose)
        sleep(1)


        self.dwx.start()
        # account information is stored in self.dwx.account_info.
        # print("Account info:", self.dwx.account_info)

        # subscribe to tick data:
        # self.dwx.subscribe_symbols(['EURUSD', 'GBPUSD'])

        # subscribe to bar data:
        # self.dwx.subscribe_symbols_bar_data([['EURUSD', 'M15'], ['GBPJPY', 'M5'], ['AUDCAD', 'M1']])

        # request historic data:
        # end = datetime.utcnow()
        # start = end - timedelta(days=30)  # last 30 days
        # self.dwx.get_historic_data('EURUSD', 'D1', start.timestamp(), end.timestamp())

    # def __start(self):
    #     """
    #         Activate Processor
    #     """
    #     # self.dwx.start()
    #     # 
    #     # while self.dwx.ACTIVE:
    #     #     sleep(1)
        
    #     return None
    
    def _restart(self):
        """
            Restart
        """
        self.dwx.start()
        return None
    
    def get_account_info(self):
        """
            Get Account Info
        """
        return self.dwx.account_info
    
    def subscribe_symbols_tick(self, symbols: list = ['EURUSD', 'GBPUSD', 'XAUUSD']):
        # subscribe to tick data:
        symbols = [str(symbol).upper() for symbol in symbols]
        self.dwx.subscribe_symbols(symbols)
         
    def subscribe_symbols_bar_data(self, bar_symbols: list = [['EURUSD', 'M15'], ['GBPJPY', 'M5'], ['AUDCAD', 'M1']]):
        # subscribe to bar data:
        self.dwx.subscribe_symbols_bar_data(bar_symbols)
