
# 
# Signals are generate stored and an event is emmitted to alert the trader module that a signal is ready

class PivotAnalyzer:
    """
        Fetches Data from the current database, analyses it using Support and Resistance 
    """

    def __init__(self, config):
        """
            Create a new operation object using its definition.

            :param config: Initialization parameters defining what is in the database including its persistent parameters and schema
        """

        self.config = config

    #
    # Analysis (features, predictions, signals etc.)
    #

    def analyze(self):
        """
        1. Convert klines to df
        2. Derive (compute) features (use same function as for model training)
        3. Derive (predict) labels by applying models trained for each label
        4. Generate buy/sell signals by applying rule models trained for best overall trade performance
        """
        symbol = App.config["symbol"]

        last_kline_ts = self.get_last_kline_ts(symbol)
        last_kline_ts_str = str(pd.to_datetime(last_kline_ts, unit='ms'))

        log.info(f"Analyze {symbol}. Last kline timestamp: {last_kline_ts_str}")

        #
        # 1.
        # MERGE: Produce a single data frame with înput data from all sources
        #
        data_sources = App.config.get("data_sources", [])
        if not data_sources:
            data_sources = [{"folder": App.config["symbol"], "file": "klines", "column_prefix": ""}]

        # Read data from online sources into data frames
        for ds in data_sources:
            if ds.get("file") == "klines":
                try:
                    klines = self.klines.get(ds.get("folder"))
                    df = klines_to_df(klines)

                    # Validate
                    source_columns = ['open', 'high', 'low', 'close', 'volume', 'close_time', 'quote_av', 'trades', 'tb_base_av', 'tb_quote_av']
                    if df.isnull().any().any():
                        null_columns = {k: v for k, v in df.isnull().any().to_dict().items() if v}
                        log.warning(f"Null in source data found. Columns with Null: {null_columns}")
                    # TODO: We might receive empty strings or 0s in numeric data - how can we detect them?
                    # TODO: Check that timestamps in 'close_time' are strictly consecutive
                except Exception as e:
                    log.error(f"Error in klines_to_df method: {e}. Length klines: {len(klines)}")
                    return
            else:
                log.error("Unknown data sources. Currently only 'klines' is supported. Check 'data_sources' in config, key 'file'")
                return
            ds["df"] = df

        # Merge in one df with prefixes and common regular time index
        df = merge_data_frames(data_sources)

        #
        # 2.
        # Generate all necessary derived features (NaNs are possible due to short history)
        #
        # We want to generate features only for last rows (for performance reasons)
        # Therefore, determine how many last rows we actually need
        buy_window = App.config["signal_model"]["buy_window"]
        sell_window = App.config["signal_model"]["sell_window"]
        last_rows = max(buy_window, sell_window) + 1

        feature_sets = App.config.get("feature_sets", [])
        if not feature_sets:
            log.error(f"ERROR: no feature sets defined. Nothing to process.")
            return
            # By default, we generate standard kline features
            #feature_sets = [{"column_prefix": "", "generator": "binance_main", "feature_prefix": ""}]

        # Apply all feature generators to the data frame which get accordingly new derived columns
        # The feature parameters will be taken from App.config (depending on generator)
        for fs in feature_sets:
            df, _ = generate_feature_set(df, fs, last_rows=last_rows)

        df = df.iloc[-last_rows:]  # For signal generation, ew will need only several last rows

        #
        # 3.
        # Apply ML models and generate score columns
        #

        # kline feature set
        features = App.config["train_features"]
        predict_df = df[features]
        if predict_df.isnull().any().any():
            null_columns = {k: v for k, v in predict_df.isnull().any().to_dict().items() if v}
            log.error(f"Null in predict_df found. Columns with Null: {null_columns}")
            return

        # Do prediction by applying all models (for the score columns declared in config) to the data
        score_df = pd.DataFrame(index=predict_df.index)
        try:
            for score_column_name, model_pair in self.models.items():
                if score_column_name.endswith("_gb"):
                    df_y_hat = predict_gb(model_pair, predict_df, get_model("gb"))
                elif score_column_name.endswith("_nn"):
                    df_y_hat = predict_nn(model_pair, predict_df, get_model("nn"))
                elif score_column_name.endswith("_lc"):
                    df_y_hat = predict_lc(model_pair, predict_df, get_model("lc"))
                else:
                    raise ValueError(f"Unknown column name algorithm suffix {score_column_name[-3:]}. Currently only '_gb', '_nn', '_lc' are supported.")
                score_df[score_column_name] = df_y_hat
        except Exception as e:
            log.error(f"Error in predict: {e}. {score_column_name=}")
            return

        # This df contains only one (last) record
        df = df.join(score_df)
        #df = pd.concat([predict_df, score_df], axis=1)

        #
        # 4.
        # Generate buy/sell signals using the signal model parameters
        #
        model = App.config["signal_model"]
        buy_labels = App.config["buy_labels"]
        sell_labels = App.config["sell_labels"]

        # Produce boolean signal (buy and sell) columns from the current patience parameters
        aggregate_score(df, 'buy_score_column', buy_labels, model.get("buy_point_threshold"), model.get("buy_window"))
        aggregate_score(df, 'sell_score_column', sell_labels, model.get("sell_point_threshold"), model.get("sell_window"))

        if model.get("combine") == "relative":
            combine_scores_relative(df, 'buy_score_column', 'sell_score_column', 'buy_score_column', 'sell_score_column')
        elif model.get("combine") == "difference":
            combine_scores_difference(df, 'buy_score_column', 'sell_score_column', 'buy_score_column', 'sell_score_column')

        #
        # 5.
        # Collect results and create signal object
        #
        row = df.iloc[-1]

        buy_score = row["buy_score_column"]
        buy_signal = buy_score >= model.get("buy_signal_threshold")

        sell_score = row["sell_score_column"]
        sell_signal = sell_score >= model.get("sell_signal_threshold")

        close_price = row["close"]
        close_time = row.name+timedelta(minutes=1)  # Add 1 minute because timestamp is start of the interval

        signal = dict(
            side="",
            buy_score=buy_score, sell_score=sell_score,
            buy_signal=buy_signal, sell_signal=sell_signal,
            close_price=close_price, close_time=close_time
        )

        if pd.isnull(buy_score) or pd.isnull(sell_score):
            pass  # Something is wrong with the computation results
        elif buy_signal and sell_signal:  # Both signals are true - should not happen
            pass
        elif buy_signal:
            signal["side"] = "BUY"
        elif sell_signal:
            signal["side"] = "SELL"
        else:
            signal["side"] = ""

        App.signal = signal

        # store signal in db and fire an event 

        log.info(f"Analyze finished. Signal: {signal['side']}. Buy score: {buy_score:+.3f}. Sell score: {sell_score:+.3f}. Price: {int(close_price):,}")


