import re
import json
from pathlib import Path



PACKAGE_ROOT = Path(__file__).parent.parent.parent
#PACKAGE_PARENT = '..'
#SCRIPT_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
#sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))
#PACKAGE_ROOT = os.path.dirname(os.path.abspath(__file__))


class Config:
    def __init__(self, config_file_path) -> None:
        self.config_file_path = config_file_path
        #
        # Constant configuration parameters
        #
        self.config = {
            "actions": ["notify"],  # Values: notify, trade

            # Binance
            "api_key": "",
            "api_secret": "",

            # Telegram
            "telegram_bot_token": "",  # Source address of messages
            "telegram_chat_id": "",  # Destination address of messages

            #
            # Naming conventions
            #
            "merge_file_name": "data",
            "feature_file_name": "features",
            "matrix_file_name": "matrix",
            "predict_file_name": "predictions",  # predict, predict-rolling
            "signal_file_name": "performance",

            "time_column": "timestamp",

            # File locations
            "data_folder": "data",  # Location for all source and generated data/models

            # ==============================================
            # === DOWNLOADER, MERGER and (online) READER ===

            # Symbol determines sub-folder and used in other identifiers
            "symbol": "BTCUSDT",  # BTCUSDT ETHUSDT ^gspc

            # This parameter determines the time raster (granularity) for the data
            # Currently 1m for binance, and 1d for yahoo are supported (only workdays)
            "freq": "1m",

            # This list is used for downloading and then merging data
            # "folder" is symbol name for downloading. prefix will be added column names during merge
            "data_sources": [
                {"folder": "BTCUSDT", "file": "klines", "column_prefix": ""}
            ],

            # ==========================
            # === FEATURE GENERATION ===

            # What columns to pass to which feature generator and how to prefix its derived features
            # Each executes one feature generation function applied to columns with the specified prefix
            "feature_sets": [
                {"column_prefix": "", "generator": "binance_main", "feature_prefix": ""}
            ],
            # Parameters of some feature generators
            # They influence generated feature names (below)
            "base_window": 360,
            "averaging_windows": [1, 10, 60],
            "area_windows": [10, 60],

            # ========================
            # === LABEL GENERATION ===

            "label_sets": [
                {"column_prefix": "", "generator": "highlow", "feature_prefix": ""},
            ],
            # highlow label parameter: max (of high) and min (of low) for this horizon ahead
            "highlow_horizon": 60,  # 1 hour prediction

            # ===========================
            # === MODEL TRAIN/PREDICT ===
            #     predict off-line and on-line

            # This number of tail rows will be excluded from model training
            "label_horizon": 60,
            # train set maximum size. algorithms may decrease this length
            "train_length": int(0.5 * 525_600),

            # List all features to be used for training/prediction by selecting them from the result of reature generation
            # Remove: "_std_1", "_trend_1"
            "train_features": [
                "close_1", "close_10", "close_60",
                "close_std_10", "close_std_60",
                "volume_1", "volume_10", "volume_60",
                "span_1", "span_10", "span_60",
                "trades_1", "trades_10", "trades_60",
                "tb_base_1", "tb_base_10", "tb_base_60",
                "close_area_10", "close_area_60",
                "close_trend_10", "close_trend_60",
                "volume_trend_10", "volume_trend_60"
            ],
            # algorithm descriptors from model store
            # gb, nn, lc - these are names from the model store which stores all the necessary parameters for each algorithm
            "algorithms": ["lc"],

            # Models (for each algorithm) will be trained for these target labels
            "labels": [
                "high_10", "high_15", "high_20", "high_25", "high_30",
                #"high_01", "high_02", "high_03", "high_04", "high_05",
                #"low_01", "low_02", "low_03", "low_04", "low_05",
                "low_10", "low_15", "low_20", "low_25", "low_30"
            ],

            # ONLINE (PREDICTION) PARAMETERS
            # Minimum history length required to compute derived features
            # It is used in online mode where we need to maintain data window of this size or larger
            # Take maximum aggregation windows from feature generation code (and add something to be sure that we have all what is needed)
            # Basically, should be equal to base_window
            "features_horizon": 10180,

            # =========================
            # === SIGNAL GENERATION ===

            # These predicted columns (scores) will be used for generating buy/sell signals
            "buy_labels": ["high_10_lc", "high_15_lc", "high_20_lc"],
            "sell_labels": ["low_10_lc", "low_15_lc", "low_20_lc"],

            # It defines how signal scores, trade signals, and notification signals will be generated
            # from point-wise prediction scores for two groups of labels
            "signal_model": {
                # First, aggregation in group over various algorithms and label parameters
                # Second, produce boolean column (optional)
                "buy_point_threshold": None,
                "buy_window": 3,  # Third, aggregate in time
                # Now we have the final score
                # To decide whether to buy/sell after all aggregations/combinations
                "buy_signal_threshold": 0.65,
                # To decide whether to notify (can be an option of individual users/consumers)
                "buy_notify_threshold": 0.05,

                "combine": "",  # "no_combine", "relative", "difference"  Find relative/difference

                "sell_point_threshold": None,
                "sell_window": 3,
                "sell_signal_threshold": 0.65,
                "sell_notify_threshold": 0.05,

                "trade_icon_step": 0.1,  # For each step, one icon added
                # 1m, 5m, 10m, 15m etc. Minutes will be divided by this number
                "notify_frequency_minutes": 10,
            },

            # =====================
            # === TRADER SERVER ===
            "base_asset": "",  # BTC ETH
            "quote_asset": "",

            "trader": {
                # For debugging: determine what parts of code will be executed
                # in market or out of market processing is excluded (all below parameters ignored)
                "no_trades_only_data_processing": False,
                # Send test submit to the server as part of validation
                "test_order_before_submit": False,
                # Instead of real orders, simulate their execution (immediate buy/sell market orders and use high price of klines for limit orders)
                "simulate_order_execution": False,

                # in % to the available USDT quantity, that is, we will derive how much BTC to buy using this percentage
                "percentage_used_for_trade": 99,
                # Limit price of orders will be better than the latest close price (0 means no change, positive - better for us, negative - worse for us)
                "limit_price_adjustment": -0.0001,

                # Signal model (trade strategy) - currently NOT USED
                "sell_timeout": 70,  # Seconds
                # our planned profit per trade via limit sell order (part of the model)
                "percentage_sell_price": 1.018,
            },

            # ==================
            # === COLLECTORS ===
            "collector": {
                "folder": "data",
                "flush_period": 300,  # seconds
                "depth": {
                    "folder": "depth",
                    "symbols": ["BTCUSDT", "ETHBTC", "ETHUSDT", "IOTAUSDT", "IOTABTC", "IOTAETH"],
                    # Legal values (depth): '5, 10, 20, 50, 100, 500, 1000, 5000' <100 weight=1
                    "limit": 100,
                    "freq": "1m",  # Binance standard frequency: 5s, 1m etc.
                },
                "stream": {
                    "folder": "stream",
                    # Stream formats:
                    # For kline channel: <symbol>@kline_<interval>, Event type: "e": "kline", Symbol: "s": "BNBBTC"
                    # For depth channel: <symbol>@depth<levels>[@100ms], Event type: NO, Symbol: NO
                    # btcusdt@ticker
                    # kline_1m, depth20, depth5
                    "channels": ["kline_1m", "depth20"],
                    "symbols": ["BTCUSDT", "ETHBTC", "ETHUSDT", "IOTAUSDT", "IOTABTC", "IOTAETH"],
                    # "BTCUSDT", "ETHBTC", "ETHUSDT", "IOTAUSDT", "IOTABTC", "IOTAETH"
                }
            },
        }

        #  Load Config
        if self.config_file_path:
            # config_file_path = PACKAGE_ROOT / config_file
            config_file_path = self.config_file_path
            with open(config_file_path, encoding='utf-8') as json_file:
                #conf_str = json.load(json_file)
                conf_str = json_file.read()

                # Remove everything starting with // and till the line end
                conf_str = re.sub(r"//.*$", "", conf_str, flags=re.M)

                conf_json = json.loads(conf_str)

                self.config.update(conf_json)
