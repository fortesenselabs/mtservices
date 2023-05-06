import random
import pymt5adapter as mt5
from datetime import datetime, timedelta
from database.database import DataBaseStore
from common.base_strategy import BaseStrategy
#


#
# Using the 20_pips_challenge to supplement this strategy
#


class RandomStrategy(BaseStrategy):
    """
        This Strategy is based on random values

        Open a list of random buy and sell trades
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

    def strategy_algorithm(self, symbol, point, digits, trade_tick_size, now):
        # print("Applying Random Strategy")

        if now > self.last_open_time + timedelta(seconds=1):
            self.last_open_time = now

            #
            # LIMIT ORDERS
            #
            # action_type = 'PENDING'
            # order_type = 'BUY_LIMIT'
            # price = self.symbols.get_symbol_info_tick(
            #     symbol).ask + (100 * point)
            # stop_loss = round(
            #     price - (15.4 * point), digits)
            # take_profit = round(price + (20 * point), digits)

            # if random.random() > 0.5:
            #     order_type = 'SELL_LIMIT'
            #     price = self.symbols.get_symbol_info_tick(
            #         symbol).bid - (100 * point)
            #     stop_loss = round(price + (15.4 * point), digits)
            #     take_profit = round(price - (20 * point), digits)

            #
            # INSTANT ORDERS
            #
            action_type = 'DEAL'
            order_type = 'BUY'
            price = self.symbols.get_symbol_info_tick(symbol).ask
            # round(price - (2000 * point), digits)
            # (200 * trade_tick_size)  # price - 5
            # round(price/trade_tick_size) - (15.4 * trade_tick_size)
            # price - (20 * point)
            stop_loss = round(price -
                              (115 * trade_tick_size), digits)
            # round(price + (20 * point), digits)
            # round(price/trade_tick_size) + (15.4 * trade_tick_size)
            take_profit = round(price + (120 * trade_tick_size), digits)

            random_value = random.random()
            if random_value > 0.5:
                order_type = 'SELL'
                price = self.symbols.get_symbol_info_tick(
                    symbol).bid
                # round(price + (2000 * point), digits)
                # (200 * trade_tick_size)  # price - 5 # round(price/trade_tick_size)
                # round(price/trade_tick_size) + (15.4 * trade_tick_size)
                # price + (15.4 * point)
                # e.g EURUSD, XAUUSD = 115, 120 | BTCUSD, ETHUSD = 1150000, 1200000
                stop_loss = round(price +
                                  (115 * trade_tick_size), digits)
                # round(price - (20 * point), digits)
                take_profit = round(
                    price - (120 * trade_tick_size), digits)
                # self.normalize_price(symbol, take_profit)

            ls = self.symbols.get_symbol_info(symbol).volume_min

            position_id = self.open_order(symbol=symbol,
                                          lot=ls,
                                          price=price,
                                          order_type=order_type,
                                          stop_loss=stop_loss,
                                          take_profit=take_profit,
                                          action_type=action_type,
                                          comment=f'{random_value}')

            # position_id = self.open_order(symbol=symbol,
            #                               lot=max(0.5, round(
            #                                       random.random(), 2)),
            #                               price=price,
            #                               order_type=order_type,
            #                               action_type=action_type)

            # print(point, self.symbols.get_symbol_info())
            # position_id = self.open_order(symbol=symbol,
            #                               lot=max(0.5, round(
            #                                       random.random(), 2)),
            #                               price=price,
            #                               stop_loss=stop_loss,
            #                               order_type=order_type,
            #                               action_type=action_type)

            # position_id = self.open_order(symbol=symbol,
            #                               lot=max(0.5, round(
            #                                       random.random(), 2)),
            #                               price=price,
            #                               take_profit=take_profit,
            #                               order_type=order_type,
            #                               action_type=action_type)

            print(position_id)

            if now > self.last_modification_time + timedelta(seconds=60):
                positions = self.get_active_positions_info()
                if positions is not None:
                    print(positions)
                    self.last_modification_time = now

                    tickets = positions[['ticket', 'symbol']].to_dict()
                    for key, value in tickets['ticket'].items():
                        self.close_order_by_ticket(
                            symbol=tickets['symbol'][key], ticket=value)

            # if self.get_active_positions_info() is not None and len(self.get_active_positions_info()) >= 10:
            #     self.close_all_orders()
            self.close_all_orders()


#
#
# SymbolInfo(custom=False, chart_mode=0, select=True, visible=True, session_deals=0, session_buy_orders=0, session_sell_orders=0, volume=0, volumehigh=0, volumelow=0, time=1668586522, digits=3, spread=14, spread_float=True, ticks_bookdepth=0, trade_calc_mode=0, trade_mode=4, start_time=0, expiration_time=0, trade_stops_level=3, trade_freeze_level=3, trade_exemode=2, swap_mode=0, swap_rollover3days=3, margin_hedged_use_leg=False, expiration_mode=15, filling_mode=1, order_mode=63, order_gtc_mode=0, option_mode=0, option_right=0, bid=144.995, bidhigh=145.279, bidlow=143.862, ask=145.009, askhigh=145.295, asklow=143.877, last=0.0, lasthigh=0.0, lastlow=0.0, volume_real=0.0, volumehigh_real=0.0, volumelow_real=0.0, option_strike=0.0, point=0.001, trade_tick_value=0.7173395311468824, trade_tick_value_profit=0.7173395311468824, trade_tick_value_loss=0.7173961389739801, trade_tick_size=0.001, trade_contract_size=100000.0, trade_accrued_interest=0.0, trade_face_value=0.0,
#            trade_liquidity_rate=0.0, volume_min=0.01, volume_max=10.0, volume_step=0.01, volume_limit=15.0, swap_long=2.56, swap_short=-7.8, margin_initial=0.0, margin_maintenance=0.0, session_volume=0.0, session_turnover=0.0, session_interest=0.0, session_buy_orders_volume=0.0, session_sell_orders_volume=0.0, session_open=143.93, session_close=143.93, session_aw=0.0, session_price_settlement=0.0, session_price_limit_min=0.0, session_price_limit_max=0.0, margin_hedged=0.0, price_change=0.7427, price_volatility=0.0, price_theoretical=0.0, price_greeks_delta=0.0, price_greeks_theta=0.0, price_greeks_gamma=0.0, price_greeks_vega=0.0, price_greeks_rho=0.0, price_greeks_omega=0.0, price_sensitivity=0.0, basis='', category='', currency_base='EUR', currency_profit='JPY', currency_margin='EUR', bank='', description='Euro vs Japanese Yen', exchange='', formula='', isin='', name='EURJPY', page='http://www.google.com/finance?q=EURJPY', path='Forex Major\\EURJPY')

#
# https://www.mql5.com/en/forum/348327
# https://www.mql5.com/en/forum/192909#comment_5070465
# https://www.mql5.com/en/forum/137301#comment_3474196
# https://www.mql5.com/en/forum/146370#comment_3693988
# https://www.mql5.com/en/docs/integration/python_metatrader5/mt5marketbookget_py
