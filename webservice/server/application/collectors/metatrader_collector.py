import pytz
import pandas as pd
import pymt5adapter as mt5
from datetime import datetime

# import the 'pandas' module for displaying data obtained in the tabular form
# pd.set_option('display.max_columns', 500) # number of columns to be displayed
# pd.set_option('display.width', 1500)      # max table width to displayed
# import pytz module for working with time zone


class BaseCollector:
    def __init__(self, metatrader_obj: mt5) -> None:
        self.metatrader_obj = metatrader_obj


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


class Order(BaseCollector):
    """
         Metatrader Orders
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

        self.ORDER_TYPES = {
            'BUY': self.metatrader_obj.ORDER_TYPE_BUY,
            'SELL': self.metatrader_obj.ORDER_TYPE_SELL,
            'BUY_LIMIT': self.metatrader_obj.ORDER_TYPE_BUY_LIMIT,
            'SELL_LIMIT': self.metatrader_obj.ORDER_TYPE_SELL_LIMIT,
            'BUY_STOP': self.metatrader_obj.ORDER_TYPE_BUY_STOP,
            'SELL_STOP': self.metatrader_obj.ORDER_TYPE_SELL_STOP,
            'BUY_STOP_LIMIT': self.metatrader_obj.ORDER_TYPE_BUY_STOP_LIMIT,
            'SELL_STOP_LIMIT': self.metatrader_obj.ORDER_TYPE_SELL_STOP_LIMIT,
            'CLOSE_BY': self.metatrader_obj.ORDER_TYPE_CLOSE_BY,
        }

        self.TRADE_REQUEST_ACTIONS = {
            # Place an order for an instant deal with the specified parameters (set a market order)
            'DEAL': self.metatrader_obj.TRADE_ACTION_DEAL,
            # Place an order for performing a deal at specified conditions (pending order)
            'PENDING': self.metatrader_obj.TRADE_ACTION_PENDING,
            # Change open position Stop Loss and Take Profit
            'SLTP': self.metatrader_obj.TRADE_ACTION_SLTP,
            # Change parameters of the previously placed trading order
            'MODIFY': self.metatrader_obj.TRADE_ACTION_MODIFY,
            # Remove previously placed pending order
            'REMOVE': self.metatrader_obj.TRADE_ACTION_REMOVE,
            # Close a position by an opposite one
            'CLOSE_BY': self.metatrader_obj.TRADE_ACTION_CLOSE_BY,
        }

        self.ORDER_TYPE_FILLING = {
            'FOK': self.metatrader_obj.ORDER_FILLING_FOK,
            'IOC': self.metatrader_obj.ORDER_FILLING_IOC,
            'RETURN': self.metatrader_obj.ORDER_FILLING_RETURN
        }

        self.ORDER_TYPE_TIME = {
            # The order stays in the queue until it is manually canceled
            'GTC': self.metatrader_obj.ORDER_TIME_GTC,
            # The order is active only during the current trading day
            'DAY': self.metatrader_obj.ORDER_TIME_DAY,
            # The order is active until the specified date
            'SPECIFIED': self.metatrader_obj.ORDER_TIME_SPECIFIED,
            # The order is active until 23:59:59 of the specified day. If this time appears to be out of a trading session, the expiration is processed at the nearest trading time.
            'SPECIFIED_DAY': self.metatrader_obj.ORDER_TIME_SPECIFIED_DAY
        }

        # https://www.mql5.com/en/docs/integration/python_metatrader5/mt5ordercheck_py

        self.symbols = Symbols(self.metatrader_obj)
        self.account_info = AccountInfo(self.metatrader_obj)

    def get_total_active_orders(self):
        """
            Get the number of active orders
        """
        # check the presence of active orders
        orders = self.metatrader_obj.orders_total()
        if orders < 0:
            return None

        return orders

    def get_active_orders_info(self, symbol_pair: str = None, group: str = None, ticket: int = None, all: bool = True):
        """
            Get active orders with the ability to filter by symbol or ticket
        """
        # display data on active orders
        if symbol_pair != None and len(symbol_pair) != 0:
            orders = self.metatrader_obj.orders_get(symbol=symbol_pair)

        if group != None and len(group) != 0:
            orders = self.metatrader_obj.orders_get(group=group)

        if ticket != None and ticket > 0:
            orders = self.metatrader_obj.orders_get(ticket=ticket)

        if all:
            orders = self.metatrader_obj.orders_get()

        # display these orders as a table using pandas.DataFrame
        if orders != None and len(orders) != 0:
            df = pd.DataFrame(list(orders),
                              columns=orders[0]._asdict().keys())
            df['time_setup'] = pd.to_datetime(df['time_setup'], unit='s')
            df.drop(['time_done', 'time_done_msc', 'position_by_id',
                    'reason', 'volume_initial', 'price_stoplimit'], axis=1, inplace=True)

            return df

        return None

    def get_active_positions_info(self, symbol_pair: str = None, group: str = '*USD*', ticket: int = None, all: bool = True):
        """
            Get active positions with the ability to filter by symbol or ticket
        """
        # display data on active positions
        if symbol_pair != None and len(symbol_pair) != 0:
            positions = self.metatrader_obj.positions_get(symbol=symbol_pair)

        if group != None and len(group) != 0:
            positions = self.metatrader_obj.positions_get(group=group)

        if ticket != None and ticket > 0:
            positions = self.metatrader_obj.positions_get(ticket=ticket)

        if all:
            positions = self.metatrader_obj.positions_get()

        # display these positions as a table using pandas.DataFrame
        if positions != None and len(positions) != 0:
            df = pd.DataFrame(list(positions),
                              columns=positions[0]._asdict().keys())
            df['time'] = pd.to_datetime(df['time'], unit='s')
            df.drop(['time_update', 'time_msc', 'time_update_msc',
                    'external_id'], axis=1, inplace=True)

            return df

        return None

    def get_total_active_positions(self):
        """
            Get the number of active positions
        """
        # check the presence of active positions
        positions = self.metatrader_obj.positions_total()
        if positions > 0:
            return positions

        return None

    def calc_order_margin(self, symbols: list = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "EURJPY", "GBPJPY"],
                          action_type: str = 'BUY', lot: float = 0.1) -> (pd.DataFrame or None):
        """
            Return margin in the account currency to perform a specified trading operation
        """
        account_currency = AccountInfo(
            self.metatrader_obj).get_account_info()['currency']
        temp = []
        for symbol in symbols:
            symbol_info = self.metatrader_obj.symbol_info(symbol)

            if symbol_info is None:
                print(symbol, "not found, skipped")
                continue
            if not symbol_info.visible:
                print(symbol, "is not visible, trying to switch on")
                if not self.metatrader_obj.symbol_select(symbol, True):
                    print("symbol_select({}}) failed, skipped", symbol)
                    continue

            ask = self.symbols.get_symbol_info_tick(symbol).ask

            margin = self.metatrader_obj.order_calc_margin(
                self.ORDER_TYPES[action_type], symbol, lot, ask)

            if margin != None:
                # print("   {} buy {} lot margin: {} {}".format(
                #     symbol, lot, margin, account_currency))
                temp.append([symbol, action_type, lot,
                            margin, account_currency])

        df = pd.DataFrame(temp,
                          columns=['symbol', 'action_type', 'lot', 'margin', 'account_currency'])

        if len(df) != 0:
            return df

        return None

    def calc_order_profit(self, symbols: list = ["EURUSD", "GBPUSD", "USDJPY"], action_type: str = 'BUY', lot: float = 0.1, distance: int = 300):
        """
            Return profit in the account currency for a specified trading operation
        """

        # get account currency
        account_currency = self.account_info.get_account_info()['currency']

        # estimate profit for buying and selling
        action_type = action_type.upper()

        temp = []
        for symbol in symbols:
            symbol_info = self.metatrader_obj.symbol_info(symbol)

            if symbol_info is None:
                print(symbol, "not found, skipped")
                continue

            if not symbol_info.visible:
                print(symbol, "is not visible, trying to switch on")
                if not self.metatrader_obj.symbol_select(symbol, True):
                    print("symbol_select({}}) failed, skipped", symbol)
                    continue

            point = self.symbols.get_symbol_info(symbol).point

            # buy
            if action_type == 'BUY':
                open_price = self.symbols.get_symbol_info_tick(symbol).ask
            # sell
            elif action_type == 'SELL':
                open_price = self.symbols.get_symbol_info_tick(symbol).bid
            else:
                return None

            close_price = open_price - distance * point
            profit = self.metatrader_obj.order_calc_profit(
                self.ORDER_TYPES[action_type], symbol, lot, open_price, close_price)
            if profit != None:
                temp.append(
                    [symbol, lot, distance, profit, account_currency])

        df = pd.DataFrame()
        if len(df) != 0:
            return df

        return None

    def get_total_orders_history(self, date_from: str, date_to: str):
        """
            Get the number of orders in trading history within the specified interval
        """

        date_from_obj = datetime.strptime(
            date_from, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        date_to_obj = datetime.strptime(
            date_from, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'

        history_orders = self.metatrader_obj.history_orders_total(
            date_from_obj, date_to_obj)
        if history_orders > 0:
            return history_orders

        return None

    def get_orders_history(self, position_id: str = None, group: str = '*USD*', ticket: int = None, from_date: str = '01/10/2022', to_date: str = '10/11/2022'):
        """
            Get orders from trading history with the ability to filter by ticket or position
        """
        # display data on active positions
        if position_id != None and len(position_id) != 0:
            position_history_orders = self.metatrader_obj.history_orders_get(
                position=position_id)

        if group != None and len(group) != 0:
            date_from_obj = datetime.strptime(
                from_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            date_to_obj = datetime.strptime(
                to_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            position_history_orders = self.metatrader_obj.history_orders_get(
                date_from_obj, date_to_obj, group=group)

        if ticket != None and ticket > 0:
            position_history_orders = self.metatrader_obj.history_orders_get(
                ticket=ticket)

        # display these positions as a table using pandas.DataFrame
        if position_history_orders != None and len(position_history_orders) != 0:
            df = pd.DataFrame(list(position_history_orders),
                              columns=position_history_orders[0]._asdict().keys())
            df['time_setup'] = pd.to_datetime(df['time_setup'], unit='s')
            df['time_done'] = pd.to_datetime(df['time_done'], unit='s')
            df.drop(['time_expiration', 'type_time', 'state', 'position_by_id', 'reason',
                    'volume_current', 'price_stoplimit'], axis=1, inplace=True)

            return df

        return None

    def get_total_deals_history(self, from_date: str = '01/10/2022', to_date: str = '10/11/2022'):
        """
            Get the number of orders in trading history within the specified interval
        """

        date_from_obj = datetime.strptime(
            from_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        date_to_obj = datetime.strptime(
            to_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'

        history_orders = self.metatrader_obj.history_deals_total(
            date_from_obj, date_to_obj)
        if history_orders > 0:
            return history_orders

        return None

    def get_deals_history(self, position_id: str = None, group: str = '*USD*', ticket: int = None, from_date: str = '01/10/2022', to_date: str = '10/11/2022'):
        """
            Get deals from trading history within the specified interval with the ability to filter by ticket or position
        """
        # display data on active positions
        if position_id != None and len(position_id) != 0:
            position_deals = self.metatrader_obj.history_deals_get(
                position=position_id)

        if group != None and len(group) != 0:
            date_from_obj = datetime.strptime(
                from_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            date_to_obj = datetime.strptime(
                to_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            position_deals = self.metatrader_obj.history_deals_get(
                date_from_obj, date_to_obj, group=group)

        if ticket != None and ticket > 0:
            position_deals = self.metatrader_obj.history_deals_get(
                ticket=ticket)

        # display these positions as a table using pandas.DataFrame
        if position_deals != None and len(position_deals) != 0:
            df = pd.DataFrame(list(position_deals),
                              columns=position_deals[0]._asdict().keys())
            df['time'] = pd.to_datetime(df['time'], unit='s')
            return df

        return None

    def check_order(self, request: dict):
        result = self.metatrader_obj.order_check(request)
        return result


class AccountInfo(BaseCollector):
    """
        MetaTrader Account Info
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    def get_terminal_info(self):
        # display info on the terminal settings and status
        terminal_info = self.metatrader_obj.terminal_info()
        if terminal_info != None:
            terminal_info_dict = self.metatrader_obj.terminal_info()._asdict()
        return terminal_info_dict

    def get_account_info(self):
        account_info = self.metatrader_obj.account_info()
        if account_info != None:
            account_info_dict = self.metatrader_obj.account_info()._asdict()
        return account_info_dict


class Rates(BaseCollector):
    """
        MetaTrader broker Rates
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    def get_rates(self, symbol_pair: str = "EURUSD", timeframe: int = mt5.TIMEFRAME_H4, date_from: str = '09/11/2021', date_to: int = '12/11/2021') -> pd.DataFrame:
        """
            Get Rates of Symbol Pair

            :param date_from must be string and [day/month/year] format
            :param date_to must be string and [day/month/year] format
        """
        # set time zone to UTC
        timezone = pytz.timezone("Etc/UTC")

        # create 'datetime' object in UTC time zone to avoid the implementation of a local time zone offset
        # utc_from = datetime(2020, 1, 10, tzinfo=timezone)

        date_time_obj_from = datetime.strptime(
            date_from, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        utc_from = datetime(
            date_time_obj_from.year, date_time_obj_from.month, date_time_obj_from.day, tzinfo=timezone)

        date_time_obj_to = datetime.strptime(
            date_to, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        utc_to = datetime(
            date_time_obj_to.year, date_time_obj_to.month, date_time_obj_to.day, tzinfo=timezone)

        # get symbol_pair bars starting from date_from to date_to in UTC time zone
        rates = self.metatrader_obj.copy_rates_range(
            symbol_pair, timeframe, utc_from, utc_to)

        # create DataFrame out of the obtained data
        rates_frame = pd.DataFrame(rates)

        # convert time in seconds into the datetime format
        rates_frame['time'] = pd.to_datetime(rates_frame['time'], unit='s')

        # display data
        # print("\nDisplay dataframe with data")
        # print(rates_frame)
        return rates_frame

    def get_rates_from_index(self, symbol_pair: str = "GBPUSD", timeframe: int = mt5.TIMEFRAME_D1, start_index: int = 0, count: int = 10) -> pd.DataFrame:
        """
            Get bars from the MetaTrader 5 terminal starting from the specified index
        """
        # get 10 GBPUSD D1 bars from the current day
        rates = self.metatrader_obj.copy_rates_from_pos(
            symbol=symbol_pair, timeframe=timeframe, start_pos=start_index, count=count)

        # display each element of obtained data in a new line
        # print("Display obtained data 'as is'")
        # for rate in rates:
        #     print(rate)

        # create DataFrame out of the obtained data
        rates_frame = pd.DataFrame(rates)
        # convert time in seconds into the datetime format
        rates_frame['time'] = pd.to_datetime(rates_frame['time'], unit='s')

        # display data
        # print("\nDisplay dataframe with data")
        # print(rates_frame)
        return rates_frame
