import pandas as pd
from datetime import datetime
from application.exchange_interfaces.metatrader.account_info import AccountInfo
from application.exchange_interfaces.metatrader.symbols import Symbols


class Order:
    """
         Metatrader Orders
    """

    def __init__(self) -> None:

        self.ORDER_TYPES = {
            'BUY': self.ORDER_TYPE_BUY,
            'SELL': self.ORDER_TYPE_SELL,
            'BUY_LIMIT': self.ORDER_TYPE_BUY_LIMIT,
            'SELL_LIMIT': self.ORDER_TYPE_SELL_LIMIT,
            'BUY_STOP': self.ORDER_TYPE_BUY_STOP,
            'SELL_STOP': self.ORDER_TYPE_SELL_STOP,
            'BUY_STOP_LIMIT': self.ORDER_TYPE_BUY_STOP_LIMIT,
            'SELL_STOP_LIMIT': self.ORDER_TYPE_SELL_STOP_LIMIT,
            'CLOSE_BY': self.ORDER_TYPE_CLOSE_BY,
        }
        
        self.TRADE_REQUEST_ACTIONS = {
            # Place an order for an instant deal with the specified parameters (set a market order)
            'DEAL': self.TRADE_ACTION_DEAL,
            # Place an order for performing a deal at specified conditions (pending order)
            'PENDING': self.TRADE_ACTION_PENDING,
            # Change open position Stop Loss and Take Profit
            'SLTP': self.TRADE_ACTION_SLTP,
            # Change parameters of the previously placed trading order
            'MODIFY': self.TRADE_ACTION_MODIFY,
            # Remove previously placed pending order
            'REMOVE': self.TRADE_ACTION_REMOVE,
            # Close a position by an opposite one
            'CLOSE_BY': self.TRADE_ACTION_CLOSE_BY,
        }

        self.ORDER_TYPE_FILLING = {
            'FOK': self.ORDER_FILLING_FOK,
            'IOC': self.ORDER_FILLING_IOC,
            'RETURN': self.ORDER_FILLING_RETURN
        }

        self.ORDER_TYPE_TIME = {
            # The order stays in the queue until it is manually canceled
            'GTC': self.ORDER_TIME_GTC,
            # The order is active only during the current trading day
            'DAY': self.ORDER_TIME_DAY,
            # The order is active until the specified date
            'SPECIFIED': self.ORDER_TIME_SPECIFIED,
            # The order is active until 23:59:59 of the specified day. If this time appears to be out of a trading session, the expiration is processed at the nearest trading time.
            'SPECIFIED_DAY': self.ORDER_TIME_SPECIFIED_DAY
        }

        # https://www.mql5.com/en/docs/integration/python_metatrader5/mt5ordercheck_py

        self.symbols = Symbols(self)
        self.account_info = AccountInfo(self)

    def get_total_active_orders(self):
        """
            Get the number of active orders
        """
        # check the presence of active orders
        orders = self.orders_total()
        if orders < 0:
            return None

        return orders

    def get_active_orders_info(self, symbol_pair: str = None, group: str = None, ticket: int = None, all: bool = True):
        """
            Get active orders with the ability to filter by symbol or ticket
        """
        # display data on active orders
        if symbol_pair != None and len(symbol_pair) != 0:
            orders = self.orders_get(symbol=symbol_pair)

        if group != None and len(group) != 0:
            orders = self.orders_get(group=group)

        if ticket != None and ticket > 0:
            orders = self.orders_get(ticket=ticket)

        if all:
            orders = self.orders_get()

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
            positions = self.positions_get(symbol=symbol_pair)

        if group != None and len(group) != 0:
            positions = self.positions_get(group=group)

        if ticket != None and ticket > 0:
            positions = self.positions_get(ticket=ticket)

        if all:
            positions = self.positions_get()

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
        positions = self.positions_total()
        if positions > 0:
            return positions

        return None

    def calc_order_margin(self, symbols: list = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "EURJPY", "GBPJPY"],
                          action_type: str = 'BUY', lot: float = 0.1) -> (pd.DataFrame or None):
        """
            Return margin in the account currency to perform a specified trading operation
        """
        account_currency = AccountInfo(
            self).get_account_info()['currency']
        temp = []
        for symbol in symbols:
            symbol_info = self.symbol_info(symbol)

            if symbol_info is None:
                print(symbol, "not found, skipped")
                continue
            if not symbol_info.visible:
                print(symbol, "is not visible, trying to switch on")
                if not self.symbol_select(symbol, True):
                    print("symbol_select({}}) failed, skipped", symbol)
                    continue

            ask = self.symbols.get_symbol_info_tick(symbol).ask

            margin = self.order_calc_margin(
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
            symbol_info = self.symbol_info(symbol)

            if symbol_info is None:
                print(symbol, "not found, skipped")
                continue

            if not symbol_info.visible:
                print(symbol, "is not visible, trying to switch on")
                if not self.symbol_select(symbol, True):
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
            profit = self.order_calc_profit(
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

        history_orders = self.history_orders_total(
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
            position_history_orders = self.history_orders_get(
                position=position_id)

        if group != None and len(group) != 0:
            date_from_obj = datetime.strptime(
                from_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            date_to_obj = datetime.strptime(
                to_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            position_history_orders = self.history_orders_get(
                date_from_obj, date_to_obj, group=group)

        if ticket != None and ticket > 0:
            position_history_orders = self.history_orders_get(
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

        history_orders = self.history_deals_total(
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
            position_deals = self.history_deals_get(
                position=position_id)

        if group != None and len(group) != 0:
            date_from_obj = datetime.strptime(
                from_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            date_to_obj = datetime.strptime(
                to_date, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
            position_deals = self.history_deals_get(
                date_from_obj, date_to_obj, group=group)

        if ticket != None and ticket > 0:
            position_deals = self.history_deals_get(
                ticket=ticket)

        # display these positions as a table using pandas.DataFrame
        if position_deals != None and len(position_deals) != 0:
            df = pd.DataFrame(list(position_deals),
                              columns=position_deals[0]._asdict().keys())
            df['time'] = pd.to_datetime(df['time'], unit='s')
            return df

        return None

    def check_order(self, request: dict):
        result = self.order_check(request)
        return result

