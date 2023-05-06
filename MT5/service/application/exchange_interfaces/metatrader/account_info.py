class AccountInfo:
    """
        MetaTrader Account Info
    """
    def get_account_info(self):
        """
            Get Account Info
        """
        account_info = self.account_info
        if account_info != None:
            return account_info
        return {}

    # def get_terminal_info(self):
    #     # display info on the terminal settings and status
    #     terminal_info = self.terminal_info()
    #     if terminal_info != None:
    #         terminal_info_dict = self.terminal_info()._asdict()
    #     return terminal_info_dict


