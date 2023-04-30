import logging
import random
import pymt5adapter as mt5
#
from datetime import datetime
from common.module_loading import import_string
from common.base_order_manager import BaseOrderManager
from collectors.metatrader_collector import AccountInfo


log = logging.getLogger('TradingManager')
logging.basicConfig(
    filename="trading_manager.log",  # parameter in App
    level=logging.DEBUG,
    # format = "%(asctime)s.%(msecs)03d %(levelname)s %(module)s - %(funcName)s: %(message)s",
    format="%(asctime)s %(levelname)s %(message)s",
    # datefmt = '%Y-%m-%d %H:%M:%S',
)

STRATEGIES_DIR = 'strategies'  # put in config


class TradingManager(AccountInfo, BaseOrderManager):
    """
        Managing strategies
    """

    def __init__(self, metatrader_obj: mt5,
                 strategy_loc: str = 'random_strategy.RandomStrategy',
                 symbols_list: list = ['EURUSD', 'GBPUSD', 'BTCUSD', 'ETHUSD']) -> None:
        super().__init__(metatrader_obj)

        self.strategy = import_string(
            STRATEGIES_DIR + '.' + strategy_loc)

        self.strategy = self.strategy(self.metatrader_obj)

        self.symbols_list = symbols_list

    def main_task(self):
        """
            It is a highest level task which is added to the event loop and executed normally every 1 minute and then it calls other tasks.

            Where the main logic is written
        """
        try:
            # "Step Index" "Volatility 25 Index" "Crash 1000 Index" "BTCUSD" "ETHUSD"
            # symbol = "USDJPY"
            # crypto_symbols = ["ETHUSD"]
            symbols = ["EURUSD", "GBPUSD", "XAUUSD",
                       "XAGUSD", "USDJPY", "AUDCAD"]

            # point = float(self.symbols.get_symbol_info(symbol).point)
            # digits = self.symbols.get_symbol_info(symbol).digits
            # trade_tick_size = self.symbols.get_symbol_info(
            #     symbol).trade_tick_size

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
