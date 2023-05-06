import json

class Config:
    def __init__(self, config_file_path):
        self.config_file_path = config_file_path
        
        with open(self.config_file_path) as f:
            config = json.load(f)

        self.server_logs = config.get("SERVER_LOGS")
        self.mysql = config.get("DATABASES", {}).get("MySQL", {}).get("WiseFinanceDB", {})
        self.metatrader = config.get("EXCHANGE_PLATFORMS", {}).get("METATRADER", {})
        self.coinbase = config.get("EXCHANGE_PLATFORMS", {}).get("COINBASE", {})
        self.binance = config.get("EXCHANGE_PLATFORMS", {}).get("BINANCE", {})
        self.telegram = config.get("NOTIFICATIONS", {}).get("TELEGRAM", {})

