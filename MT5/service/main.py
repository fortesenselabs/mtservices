from time import sleep
from application.config import Config
from application.database.database import DataBaseSQLStore
from application.exchange_interfaces.metatrader.interface import MetaTraderInterface
from application.exchange_interfaces.metatrader.types import TimeFrames
from application.exchange_interfaces.manager import ExchangeInterfaceManager
from application.investor.strategies.ai import AIStrategyInterface
from application.investor.manager import InvestorManager
from application.notifications.telegram import TelegramNotificationInterface
from application.utils.logging import setup_logging

def main():
    """
        Main
    """
    logger = setup_logging("logs/main_service.log")
    
    try:
        # Config
        config = Config('config.json')
        logger.info("Using config file: %s", config.config_file_path)
        logger.info("MySQL Hostname: %s", config.mysql['Hostname'])
        logger.info("MySQL Database Name: %s", config.mysql['Name'])
        logger.info("MetaTrader Files Path: %s", config.metatrader['FILES_PATH'])

        # Init Database Interface
        database_interface = DataBaseSQLStore(logger = logger, user = config.mysql['Username'], 
                                              password = config.mysql['Password'], host = config.mysql['Hostname'], 
                                              port = int(config.mysql['Port']), database = config.mysql['Name'])

        # Init Exchange Interfaces for Data Collection and Order placing 
        # selected_symbols = ["EURUSD", "GBPUSD", "XAUUSD", "XAGUSD", "USDJPY", "AUDCAD", "BTCUSD", "ETHUSD"]
        selected_symbols = {
            "Step Index": [TimeFrames.TIMEFRAME_H1],
            "Volatility 25 Index": [TimeFrames.TIMEFRAME_M5],
            "Volatility 50 Index": [TimeFrames.TIMEFRAME_M1],
            "Volatility 75 Index": [TimeFrames.TIMEFRAME_M30],
            "Crash 500 Index": [TimeFrames.TIMEFRAME_H4],
            "Crash 1000 Index": [TimeFrames.TIMEFRAME_D1],
            "Boom 500 Index": [TimeFrames.TIMEFRAME_H4, TimeFrames.TIMEFRAME_H1],
            "Boom 1000 Index": [TimeFrames.TIMEFRAME_D1, TimeFrames.TIMEFRAME_M30]
        } 
        metatrader_interface = MetaTraderInterface(logger = logger, files_path=config.metatrader['FILES_PATH'], selected_symbols=selected_symbols, open_test_trades=False)
        exchange_manager = ExchangeInterfaceManager(logger = logger, exchange_interfaces=[metatrader_interface], database_interface=database_interface, store_data=True)
        logger.info("Exchange Info: %s", exchange_manager.get_all_accounts_info())

       # Init Strategy Interfaces
        ai_interface = AIStrategyInterface(database_interface=database_interface)

        # Init Notification Interfaces for send notifications 
        notification_interface = TelegramNotificationInterface()

        # Init Investor
        investor_manager = InvestorManager(exchange_manager = exchange_manager, strategy_interface = ai_interface, 
                                           notification_interfaces = [notification_interface], database_interface=database_interface, 
                                           logger = logger, store_data=True)
        investor_manager.start()
        while investor_manager.ACTIVE:
            sleep(1)
            # logger.info("Investor Info: %s", investor_manager.on_info()) # on_info() streams any event conducted to the outside world 

    except KeyboardInterrupt:
        logger.info("Shutting Down WiseFinance MT service...")
        exchange_manager.stop()
        investor_manager.stop()
        logger.info("Done!!!...")

    except Exception as e:
        logger.error("Error Encountered during execution: %s", str(e))

if __name__ == "__main__":
    main()
