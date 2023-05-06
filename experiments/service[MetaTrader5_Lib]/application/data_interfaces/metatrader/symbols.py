import pandas as pd
import pymt5adapter as mt5
from application.data_interfaces.metatrader import BaseCollector

class Symbols(BaseCollector):
    """
        Metatrader Symbols
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    def get_total_symbols(self):
        """
            Get the number of financial instruments
        """
        num_symbols = self.metatrader_obj.symbols_total()
        if num_symbols <= 0:
            return None

        return num_symbols

    def get_symbols(self, group: str = '*USD*'):
        """
            Get all financial instruments from the MetaTrader 5 terminal

            --------------------------------------
            symbols=mt5.symbols_get()
            print('Symbols: ', len(symbols))
            --------------------------------------
            Display the first five ones

            ---------------------------------------
            count=0
            for s in symbols:
                count+=1
                print("{}. {}".format(count,s.name))
                if count==5: break
            print()
            ------------------------------------------

            Get symbols containing RU in their names

            ------------------------------------------
            ru_symbols=mt5.symbols_get("*RU*")
            print('len(*RU*): ', len(ru_symbols))
            for s in ru_symbols:
                print(s.name)
            print()
            ----------------------------------------------------------------

            Get symbols whose names do not contain USD, EUR, JPY and GBP

            ------------------------------------------------------------------
            group_symbols=mt5.symbols_get(group="*,!*USD*,!*EUR*,!*JPY*,!*GBP*")
            print('len(*,!*USD*,!*EUR*,!*JPY*,!*GBP*):', len(group_symbols))
            for s in group_symbols:
                print(s.name,":",s)
            -------------------------------------------------------------------
        """
        if len(group) != 0:
            return self.metatrader_obj.symbols_get(group=group)

        return self.metatrader_obj.symbols_get()

    def select_symbol(self, symbol_pair: str, enable: bool = True):
        """
            Select a symbol in the MarketWatch window or remove a symbol from the window
        """
        # attempt to enable the display of a symbol pair in MarketWatch
        selected = self.metatrader_obj.symbol_select(symbol_pair, enable)

        if not selected:
            raise ValueError(f"Failed to select {symbol_pair}")

        return selected

    def get_symbol_info(self, symbol_pair: str = "EURJPY"):
        """
        Get data on the specified financial instrument.

        """
        # attempt to enable the display of the symbol in MarketWatch
        self.select_symbol(symbol_pair, True)

        # display symbol properties
        symbol_info = self.metatrader_obj.symbol_info(symbol_pair)

        if symbol_info != None:
            return symbol_info

        return None

    def get_symbol_info_tick(self, symbol_pair: str = "GBPUSD"):
        """
            Get the last tick for the specified financial instrument
        """
        # attempt to enable the display of the symbol in MarketWatch
        self.select_symbol(symbol_pair, True)

        # display the last symbol_pair tick
        last_tick = self.metatrader_obj.symbol_info_tick(symbol_pair)

        return last_tick

