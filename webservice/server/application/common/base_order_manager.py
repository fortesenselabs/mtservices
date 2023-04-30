import pymt5adapter as mt5
from collectors.metatrader_collector import Order


class BaseOrderManager(Order):
    """
         Metatrader Order Manager
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    def open_order(self, symbol: str, lot: float, price: float,
                   stop_loss: float = None, take_profit: float = None,
                   order_type: str = 'SELL', deviation: int = 5,
                   magic: int = 234000, comment: str = "python script open",
                   action_type: str = 'DEAL'):

        if stop_loss is None or take_profit is None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "type": self.ORDER_TYPES[order_type.upper()],
                "price": price,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
                # "type_time": self.ORDER_TYPE_TIME['GTC'],
                # "type_filling": self.ORDER_TYPE_FILLING['RETURN'],
            }

        if stop_loss is not None or take_profit is None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume":  lot,
                "type": self.ORDER_TYPES[order_type.upper()],
                "price": price,
                "sl":  stop_loss,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
                # "type_time": self.ORDER_TYPE_TIME['GTC'],
                # "type_filling": self.ORDER_TYPE_FILLING['RETURN'],
            }

        if stop_loss is None or take_profit is not None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "type": self.ORDER_TYPES[order_type.upper()],
                "price":  price,
                "tp":  take_profit,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
                # "type_time": self.ORDER_TYPE_TIME['GTC'],
                # "type_filling": self.ORDER_TYPE_FILLING['RETURN'],
            }

        if stop_loss is not None or take_profit is not None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume":  lot,
                "type": self.ORDER_TYPES[order_type.upper()],
                "price": price,
                "sl": stop_loss,
                "tp": take_profit,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
                # "type_time": self.ORDER_TYPE_TIME['GTC'],
                # "type_filling": self.ORDER_TYPE_FILLING['RETURN'],
            }

        print("New Order", request)
        result = self.execute_order(request)
        return result

    def update_order(self, position_id: int, symbol: str, lot: float, price: float,
                     stop_loss: float = None, take_profit: float = None,
                     deviation: int = 20, magic: int = 234000,
                     comment: str = "python script modify", action_type: str = 'MODIFY'):

        if stop_loss is None or take_profit is None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "position": position_id,
                "price": price,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
            }

        if stop_loss is not None or take_profit is None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "position": position_id,
                "price": price,
                "sl": stop_loss,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
            }

        if stop_loss is None or take_profit is not None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "position": position_id,
                "price": price,
                "tp": take_profit,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
            }

        if stop_loss is not None or take_profit is not None:
            request = {
                "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
                "symbol": symbol,
                "volume": lot,
                "position": position_id,
                "price": price,
                "sl": stop_loss,
                "tp": take_profit,
                "deviation": deviation,
                "magic": magic,
                "comment": comment,
            }

        print("Modify Order", request)
        result = self.execute_order(request)
        return result

    def close_order_request(self, position_id: int, symbol: str, lot: float, price: float,
                            order_type: str = 'SELL', deviation: int = 20,
                            magic: int = 234000, comment: str = "python script close", action_type: str = 'DEAL'):
        """
            Close a previously opened order
        """
        request = {
            "action": self.TRADE_REQUEST_ACTIONS[action_type.upper()],
            "symbol": symbol,
            "volume": lot,
            "type": self.ORDER_TYPES[order_type.upper()],
            "position": position_id,
            "price": price,
            "deviation": deviation,
            "magic": magic,
            "comment": comment,
        }

        print("Close Order", request)
        result = self.execute_order(request)
        return result

    def close_order_by_ticket(self, symbol, ticket):
        """
            Close Order By Ticket/Position ID

        """
        res = self.metatrader_obj.Close(symbol=symbol, ticket=ticket)
        return res

    def close_all_orders(self):
        """
            Close all Orders
        """
        positions = self.get_active_positions_info()
        if positions is not None:
            tickets = positions[['ticket', 'symbol']].to_dict()
            for key, value in tickets['ticket'].items():
                self.close_order_by_ticket(
                    symbol=tickets['symbol'][key], ticket=value)

            print('Closing All Tickets: ', tickets)

            return True

        return False

    def execute_order(self, request: dict):
        """
            Validate and submit order

            MT => Send a request to perform a trading operation from the terminal to the trade server
        """
        result = self.metatrader_obj.order_send(request)
        if result.retcode != self.metatrader_obj.TRADE_RETCODE_DONE:
            return result.retcode

        return result.order  # position ticket

    def normalize_price(self, symbol: str, price: float):
        """
            Normalize Price
        """
        ts = self.symbols.get_symbol_info(symbol).trade_tick_size
        return round(price/ts)*ts

    def normalize_volume(self, symbol: str, volume: float):
        """
            Normalize Lots/Volume
        """
        ls = self.symbols.get_symbol_info(symbol).volume_step
        return round(volume/ls)*ls


# https://www.mql5.com/en/forum/137301#comment_3474196
# https://stackoverflow.com/questions/60971841/how-close-an-mt5-order-from-python
