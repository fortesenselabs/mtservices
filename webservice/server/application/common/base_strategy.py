import pymt5adapter as mt5
from datetime import datetime
from .base_order_manager import BaseOrderManager


class BaseStrategy(BaseOrderManager):
    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

    def strategy_algorithm(self, symbol, point, now):
        """
            Strategy algorithm
        """
        return
