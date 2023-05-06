from datetime import datetime
from application.investor.orders_manager.base_order_manager import BaseOrderManager

class BaseStrategy(BaseOrderManager):
    def __init__(self) -> None:
        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

    def _algorithm(self, symbol, point, now):
        """
            Strategy algorithm
        """
        return
