import pandas as pd
from application.database.database import DataBaseSQLStore
from application.investor.strategies.base_strategy import BaseStrategy

class AIStrategyInterface(BaseStrategy):
    """
        This Strategy is based on Pure Machine learning/Deep learning analysis and the N-pips Portfolio Management Expectation(PME)

        Using AI predctions from the AI predictor service
    """

    def __init__(self, database_interface: DataBaseSQLStore) -> None:
        super().__init__(database_interface)

    def run_algorithm(self):
        return



#
# Using clustering and PCA, for dividing data into classes
