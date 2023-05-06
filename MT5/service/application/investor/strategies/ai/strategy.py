import random
import pandas as pd
# import pymt5adapter as mt5
from application.investor.strategies.base_strategy import BaseStrategy
from application.database.database import DataBaseSQLStore

#
# Using the 20_pips_challenge to supplement this strategy
#

class AIStrategyInterface(BaseStrategy):
    """
        This Strategy is based on Pure Machine learning/Deep learning analysis

        Using AI predctions from the AI predictor service
    """

    def __init__(self) -> None:
        super().__init__()

    async def strategy_algorithm(self, symbol, point, digits, trade_tick_size, now):
        # signal = await DataBaseStore.get_signal('AI')
        file_path = "20 pip challange.xlsx"
        df = pd.read_excel(file_path)
        print(df)
        # ['Level', 'Starting Balance ', 'Percentage Risk', 'Risk dollars', 'Profit Percentage', 'Profit Dollars',
        #     'Stop Loss Pips', 'TP Pips', 'Std. Lot size', 'Ending balance', 'Completed', 'Notes']

        levels = df['Level'].dropna().astype(int).to_list()
        completed = {}

        for level in levels:
            signal = random.sample(['BUY', 'SELL'], k=1)[0]
            #
            # INSTANT ORDERS
            #
            action_type = 'DEAL'
            order_type = signal
            price = self.symbols.get_symbol_info_tick(symbol).ask
            stop_loss = round(price -
                              (115 * trade_tick_size), digits)
            take_profit = round(price + (120 * trade_tick_size), digits)

            if signal == 'SELL':
                order_type = signal
                price = self.symbols.get_symbol_info_tick(
                    symbol).bid
                # e.g EURUSD, XAUUSD = 115, 120 | BTCUSD, ETHUSD = 1150000, 1200000
                stop_loss = round(price +
                                  (115 * trade_tick_size), digits)
                take_profit = round(
                    price - (120 * trade_tick_size), digits)

            ls = self.symbols.get_symbol_info(symbol).volume_min

            position_id = self.open_order(symbol=symbol,
                                          lot=ls,
                                          price=price,
                                          order_type=order_type,
                                          stop_loss=stop_loss,
                                          take_profit=take_profit,
                                          action_type=action_type,
                                          comment='AI Strategy Level => {level}')

            print(position_id)
            # Check if and order executed successfully and hit the TP or SL
            # 'DONE', 'FAILED'
            completed[level] = 'DONE'


#
# Using clustering and PCA
#  for dividing data into classes
#
#
#
