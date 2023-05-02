import pymt5adapter as mt5
from common.base_strategy import BaseStrategy
from database.database import DataBaseStore


#
# Using the 20_pips_challenge to supplement this strategy
#


class PivotStrategy(BaseStrategy):
    """
                This Strategy is based on Support and Resistance analysis, RSI on other technical indicators
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    async def strategy_algorithm(self):
        signal = await DataBaseStore.get_signal('Pivot')
        return
