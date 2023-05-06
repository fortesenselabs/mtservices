#!/usr/bin/env python
import logging
from flask import Flask, jsonify
from application.config import Config
from application.data_interfaces.metatrader import MetaTraderInterface
from application.data_interfaces.manager import DataInterfaceManager

def setup_logging():
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    )

def main():
    """
        Main
    """
    setup_logging()

    try:
        # Config
        config = Config('config.json')
        logging.info("Using config file: %s", config.config_file_path)
        logging.info("MySQL Hostname: %s", config.mysql['Hostname'])
        logging.info("MetaTrader Terminal Path: %s", config.metatrader['TERMINAL_PATH'])

        # Data Collection 
        metatrade_interface = MetaTraderInterface(login="...", password="...", server="...", terminal_path="")
        data_manager = DataInterfaceManager([metatrade_interface], store_data=True)
        data_manager.start()
        logging.info("Received data: %s", data_manager.get_info())

        # Flask server
        app = Flask(__name__)

        @app.route("/")
        def get_data():
            return jsonify(data_manager.get_info())

        app.run()

    except KeyboardInterrupt:
        data_manager.stop()
        logging.info("Shutting Down...")

    except Exception as e:
        logging.error("Error: %s", str(e))

if __name__ == "__main__":
    main()
