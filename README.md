# Wise Finance MetaTrader Interface

MetaTrader application interface

## Execution

**For MT5:**

```bash
cd MT5
make run

```

**For MT4:**

```bash
cd MT4
make run

```

Goto http://localhost:8080/

## Note

- MT4 is not fully supported yet

## Docs

gh release create v0.1.0 --title "v0.1.0 (beta)" --notes "this is a beta release" --prerelease

docker run --rm -d -p 8080:8080 --name metatrader -v metatrader:/data metatrader:5

```sql
    DROP DATABASE IF EXISTS wisefinance_db;
```

### Start and Use MindsDB

Run the command below to start MindsDB in Docker.

```bash
   docker run -p 47334:47334 -p 47335:47335 mindsdb/mindsdb
```

If you wish to simply spin up the container without the logs, run the following command:

```bash
   docker run -d -p 47334:47334 -p 47335:47335 mindsdb/mindsdb
```

With access to the MySQL located in the host machine

```bash
   docker run --network="host" -p 47334:47334 -p 47335:47335 -v ./mdb_data:/root/mdb_storage mindsdb/mindsdb
```

https://stackoverflow.com/questions/24319662/from-inside-of-a-docker-container-how-do-i-connect-to-the-localhost-of-the-mach
https://dev.to/narayanadithya/using-mindsdb-for-time-series-forecasting-honey-production-in-the-usa-4p05
https://aicoding.substack.com/p/mindsdb-time-series
https://github.com/AlainDaccache/Quantropy
https://github.com/meppps/ML-Financial-Analysis-WebApp
https://github.com/philipperemy/FX-1-Minute-Data
https://github.com/constverum/Quantdom
https://github.com/ashishpapanai/stockDL
https://github.com/karthic2510/anomaly-detection

**Some commands in mindsdb:**

```sql
-- Connection success
--- You can list all the linked databases using the command below:
-- SHOW DATABASES;
-- SHOW TABLES FROM wisefinance;
-- SELECT * FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices LIMIT 10;
-- SELECT COUNT(*) FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices;

-- Create and Train the Model
-- CREATE PREDICTOR mindsdb.wisefinance_predictor_volatility_75_index_M30
-- FROM wisefinance
--     (SELECT * FROM MetaTrader_volatility_75_index_M30_historic_prices)
-- PREDICT is_close_diff_gt_threshold
-- ORDER BY datetime
-- WINDOW 25
-- HORIZON 2

-- [A New Set of WINDOWs and Horizons]
-- WINDOW 12
-- HORIZON 1


-- Check if the Model has finished training
SELECT * FROM predictors;

-- Time To Forecast

-- [COPY 1]
-- SELECT orig_table.datetime AS DATETIME, pred_table.close AS PREDICTED_CLOSE, orig_table.close AS ACTUAL_CLOSE
-- FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS orig_table
-- JOIN mindsdb.wisefinance_predictor_volatility_75_index_m30 AS pred_table
-- WHERE orig_table.datetime > LATEST
-- ORDER BY orig_table.ds DESC
-- LIMIT 10;

-- [COPY 2] [Recommended]
-- SELECT m.datetime AS DateTime, m.close AS PredictedClosePrice
-- FROM mindsdb.wisefinance_predictor_volatility_75_index_m30 AS m
-- JOIN wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS t
-- WHERE t.datetime > LATEST;

-- [COPY 3]
-- SELECT t.datetime, t.open, t.high, t.low, t.tick_volume, t.close AS actual_close_price,
--        m.close AS predicted_close_price
-- FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS t
-- JOIN mindsdb.wisefinance_predictor_volatility_75_index_m30 AS m
-- WHERE t.datetime > LATEST
-- LIMIT 4;


-- DELETE MODEL
-- DROP PREDICTOR mindsdb.wisefinance_predictor_volatility_75_index_m30;
```

**New:**

```sql
   -- Connection success
--- You can list all the linked databases using the command below:
-- SHOW DATABASES;
-- SHOW TABLES FROM wisefinance;
-- SELECT * FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices LIMIT 10;
-- SELECT COUNT(*) FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices;

-- Create and Train the Model
-- CREATE PREDICTOR mindsdb.wisefinance_predictor_volatility_75_index_M30
-- FROM wisefinance
--     (SELECT datetime, open, high, low, close, rsi_ta, close_diff, rise_above_threshold, fall_below_threshold FROM MetaTrader_volatility_75_index_M30_historic_prices)
-- PREDICT close
-- -- ORDER BY datetime
-- WINDOW 25
-- HORIZON 2

-- [A New Set of WINDOWs and HORIZONs]
-- PREDICT is_close_diff_gt_threshold
-- WINDOW 12 (20, 25)
-- HORIZON 1


-- Check if the Model has finished training
-- SELECT * FROM predictors;

-- Time To Forecast

-- [COPY 1]
-- SELECT orig_table.datetime AS DATETIME, pred_table.close AS PREDICTED_CLOSE, orig_table.close AS ACTUAL_CLOSE
-- FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS orig_table
-- JOIN mindsdb.wisefinance_predictor_volatility_75_index_m30 AS pred_table
-- WHERE orig_table.datetime > LATEST
-- ORDER BY orig_table.ds DESC
-- LIMIT 10;

-- [COPY 2] [Recommended]
SELECT m.datetime AS DateTime, m.close AS Forecast
FROM mindsdb.wisefinance_predictor_volatility_75_index_m30 AS m
JOIN wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS t
WHERE t.datetime > LATEST;

-- m.is_close_diff_gt_threshold

-- [COPY 3]
-- SELECT t.datetime, t.open, t.high, t.low, t.tick_volume, t.close AS actual_close_price,
--        m.close AS predicted_close_price
-- FROM wisefinance.MetaTrader_volatility_75_index_M30_historic_prices AS t
-- JOIN mindsdb.wisefinance_predictor_volatility_75_index_m30 AS m
-- WHERE t.datetime > LATEST
-- LIMIT 4;


-- DELETE MODEL
-- DROP PREDICTOR mindsdb.wisefinance_predictor_volatility_75_index_m30;
```

**Notes:**

```txt

```
