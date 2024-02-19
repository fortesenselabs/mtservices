from client import MetaTrader
from constants import TIME_FRAMES, ACTION_TYPE

if __name__ == "__main__":
    meta_trader = MetaTrader(authorization_code="123456")

    # Connect to the server
    meta_trader.connect()

    # Send a request to the server
    print(meta_trader.accountInfo())
    # print(meta_trader.balance())
    # print(meta_trader.get_orders())
    # while True:
    #     print(meta_trader.get_current_price("Step Index"))
    #     time.sleep(3)

    # print(
    #     meta_trader.get_historical_data(
    #         symbol="Step Index",
    #         time_frame=TIME_FRAMES.D1,
    #         action_type=ACTION_TYPE.PRICE,
    #         from_date="13-02-2022 00:00:00",
    #         to_date="13-02-2024 00:00:00",
    #     )
    # )

    # current_price = meta_trader.get_current_price("Step Index")
    # print(current_price)
    # pips = 100
    # stop_level = 0.1
    # normalized_pips = pips * stop_level

    # BUY
    # stoploss = float(current_price["data"]["tick"][1]) - normalized_pips
    # takeprofit = float(current_price["data"]["tick"][1]) + normalized_pips

    # print(stoploss, takeprofit)
    # print(meta_trader.buy("Step Index", 0.1, stoploss, takeprofit))

    # SELL
    # stoploss = float(current_price["data"]["tick"][2]) + normalized_pips
    # takeprofit = float(current_price["data"]["tick"][2]) - normalized_pips

    # print(stoploss, takeprofit)
    # print(meta_trader.sell("Step Index", 0.5, stoploss, takeprofit))

    # Positions & Manipulation
    # positions = meta_trader.get_positions()
    # print(positions)
    # print(meta_trader.close_all_positions())
