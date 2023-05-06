# Define base 
import pymt5adapter as mt5

class BaseCollector:
    def __init__(self, metatrader_obj: mt5) -> None:
        self.metatrader_obj = metatrader_obj

# Imports
# from application.data_collectors.metatrader.base import *
from application.data_interfaces.metatrader.account_info import *
from application.data_interfaces.metatrader.symbols import *
from application.data_interfaces.metatrader.orders import *
from application.data_interfaces.metatrader.rates import *
# 
from application.data_interfaces.metatrader._interface import *
