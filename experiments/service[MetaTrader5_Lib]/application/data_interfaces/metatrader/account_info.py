import pandas as pd
import pymt5adapter as mt5
from application.data_interfaces.metatrader import BaseCollector

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
