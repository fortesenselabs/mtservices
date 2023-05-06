import pytz
import pandas as pd

import pymt5adapter as mt5
from datetime import datetime
from application.data_interfaces.metatrader import BaseCollector

class Rates(BaseCollector):
    """
        MetaTrader broker Rates
    """

    def __init__(self, metatrader_obj: mt5) -> None:
        super().__init__(metatrader_obj)

    def get_rates(self, symbol_pair: str = "EURUSD", timeframe: int = mt5.TIMEFRAME_H4, date_from: str = '09/11/2021', date_to: int = '12/11/2021') -> pd.DataFrame:
        """
            Get Rates of Symbol Pair

            :param date_from must be string and [day/month/year] format
            :param date_to must be string and [day/month/year] format
        """
        # set time zone to UTC
        timezone = pytz.timezone("Etc/UTC")

        # create 'datetime' object in UTC time zone to avoid the implementation of a local time zone offset
        # utc_from = datetime(2020, 1, 10, tzinfo=timezone)

        date_time_obj_from = datetime.strptime(
            date_from, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        utc_from = datetime(
            date_time_obj_from.year, date_time_obj_from.month, date_time_obj_from.day, tzinfo=timezone)

        date_time_obj_to = datetime.strptime(
            date_to, '%d/%m/%Y')  # '%d/%m/%y %H:%M:%S'
        utc_to = datetime(
            date_time_obj_to.year, date_time_obj_to.month, date_time_obj_to.day, tzinfo=timezone)

        # get symbol_pair bars starting from date_from to date_to in UTC time zone
        rates = self.metatrader_obj.copy_rates_range(
            symbol_pair, timeframe, utc_from, utc_to)

        # create DataFrame out of the obtained data
        rates_frame = pd.DataFrame(rates)

        # convert time in seconds into the datetime format
        rates_frame['time'] = pd.to_datetime(rates_frame['time'], unit='s')

        # display data
        # print("\nDisplay dataframe with data")
        # print(rates_frame)
        return rates_frame

    def get_rates_from_index(self, symbol_pair: str = "GBPUSD", timeframe: int = mt5.TIMEFRAME_D1, start_index: int = 0, count: int = 10) -> pd.DataFrame:
        """
            Get bars from the MetaTrader 5 terminal starting from the specified index
        """
        # get 10 GBPUSD D1 bars from the current day
        rates = self.metatrader_obj.copy_rates_from_pos(
            symbol=symbol_pair, timeframe=timeframe, start_pos=start_index, count=count)

        # display each element of obtained data in a new line
        # print("Display obtained data 'as is'")
        # for rate in rates:
        #     print(rate)

        # create DataFrame out of the obtained data
        rates_frame = pd.DataFrame(rates)
        # convert time in seconds into the datetime format
        rates_frame['time'] = pd.to_datetime(rates_frame['time'], unit='s')

        # display data
        # print("\nDisplay dataframe with data")
        # print(rates_frame)
        return rates_frame
