import pandas as pd
from datetime import datetime
from application.database.database import DataBaseSQLStore

class BaseStrategy:
    def __init__(self, database_interface: DataBaseSQLStore) -> None:
        self.database_interface = database_interface
        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()
        self.pme = None

    def load_pme_file(self, file_path: str = "pme.xlsx"):
        """
            Portfolio Management Expectation(PME) File [it should be an excel file .xlsx],
            abstract steps for portfolio management, 
            includes Std. Lot size to use, expected Ending balance, expected Risk in dollars, the Profit Percentage, etc for each trade taken \n

            uses [experimental]30-pips by default 
        """
        # Automate this part kind off
        # like it should be stored in the database and recalculated once every milestone has been reached
                # signal = await DataBaseStore.get_signal('AI')
        df = pd.read_excel(file_path)
        print(df)
        # ['Level', 'Starting Balance ', 'Percentage Risk', 'Risk dollars', 'Profit Percentage', 'Profit Dollars',
        #     'Stop Loss Pips', 'TP Pips', 'Std. Lot size', 'Ending balance', 'Completed', 'Notes']

        levels = df['Level'].dropna().astype(int).to_list()
        completed = {}

        # move to run_algorithm()
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
        return

    def run_algorithm(self):
        """
            Strategy algorithm
        """
        # use indicator and pme steps here
        return
