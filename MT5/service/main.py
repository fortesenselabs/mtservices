from time import sleep
from application.config import Config
from application.exchange_interfaces.metatrader._interface import MetaTraderInterface
from application.exchange_interfaces.manager import ExchangeInterfaceManager
from application.investor.strategies.ai import AIStrategyInterface
from application.investor.manager import InvestorManager
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
        logger.info("MetaTrader Terminal Path: %s", config.metatrader['TERMINAL_PATH'])
        logger.info("MetaTrader Files Path: %s", config.metatrader['FILES_PATH'])

        # Init Database Interface
        database_interface = ""

        # Init Exchange Interfaces for Data Collection and Order placing 
        metatrader_interface = MetaTraderInterface(logger = logger, files_path=config.metatrader['FILES_PATH'])
        exchange_manager = ExchangeInterfaceManager([metatrader_interface], [database_interface], store_data=True)
        logger.info("Exchange Info: %s", exchange_manager.get_all_accounts_info())

       # Init Strategy Interfaces
        ai_interface = AIStrategyInterface()

        # Init Notification Interfaces for send notifications 
        notification_interface = ""

        # Selected Symbols 
        # "Step Index" "Volatility 25 Index" "Crash 1000 Index" "BTCUSD" "ETHUSD"
        # symbol = "USDJPY"
        # crypto_symbols = ["ETHUSD"]
        selected_symbols = ["EURUSD", "GBPUSD", "XAUUSD",
                            "XAGUSD", "USDJPY", "AUDCAD"]

        # Init Investor
        investor_manager = InvestorManager(exchange_manager, [ai_interface], 
                                           [notification_interface], [database_interface], 
                                           logger = logger, selected_symbols = selected_symbols, store_data=True)
        investor_manager.start()
        while investor_manager.ACTIVE:
            sleep(1)
            logger.info("Investor Info: %s", investor_manager.on_info()) # on_info() streams any event conducted to the outside world 

    except KeyboardInterrupt:
        investor_manager.stop()
        logger.info("Shutting Down Investor...")

    except Exception as e:
        logger.error("Error Encountered during execution: %s", str(e))

if __name__ == "__main__":
    main()
