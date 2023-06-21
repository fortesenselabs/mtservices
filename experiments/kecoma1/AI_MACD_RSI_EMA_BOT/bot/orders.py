import MetaTrader5 as mt5
import datetime, pickle


AI_FILE = 'nn_model.pkl'
CANDLES_BETWEEN_OPERATIONS = 2


def close_position(market: str, lotage: float, result):
    """Function to close a position.

    Args:
        market (string)
        lotage (float)
        result: Result of the previous operation
        
    return:
        result after closing the position.
    """
    deal = mt5.history_deals_get(ticket=result.deal)[0]
    position = mt5.positions_get(ticket=deal.position_id)[0]
    close_order = {
        'action': mt5.TRADE_ACTION_DEAL,
        'type': mt5.ORDER_TYPE_BUY,
        'price': mt5.symbol_info_tick(market).ask,
        'symbol': position.symbol,
        'volume': position.volume,
        'position': position.ticket,
    }
    result = mt5.order_send(close_order)
    
    return result


def open_position(market: str, lotage: float, type):
    """Function to open a position.

    Args:
        market (string)
        lotage (float)
    """
    point = mt5.symbol_info(market).point
    price = mt5.symbol_info_tick(market).bid

    deviation = 20
    operation = {
        "action": mt5.TRADE_ACTION_DEAL,
        "symbol": market,
        "volume": lotage,
        "type": type,
        "price": price,
        "deviation": deviation,
        "magic": 234000,
        "comment": "python script open",
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_FOK,
    }

    # Sending the buy
    result = mt5.order_send(operation)
    print("[Thread - orders] 1. order_send(): by {} {} lots at {} with deviation={} points".format(market,lotage,price,deviation))
    if result.retcode != mt5.TRADE_RETCODE_DONE:
        print("[Thread - orders] Failed operation: retcode={}".format(result.retcode))
        return None
    
    return result    

def thread_orders_AI(stop_event, data, trading_data):
    """Function executed by a thread. It checks if the conditions to open orders
    are okay.

    Args:
        stop_event (thread.Event): Event to stop the thread.
        data (dict): Dictionary with candles and the indicator.
        trading_data (dict): Dictionary with the lotage and the market.
    """
    last_operation_time = 0
    ep = datetime.datetime(1970,1,1,0,0,0)
    
    operation_open = False
    result = None
    
    # Loading the Neural network
    with open("dt_model.pkl", "rb") as f:
        dt = pickle.load(f)

    # Waiting for the data to be loaded
    while data['data'] is None:
        if stop_event.is_set():
            return
    
    print("[INFO]\tOrders running")
    
    while not stop_event.is_set():
        cur_time = int((datetime.datetime.utcnow()- ep).total_seconds())
        
        if dt.predict([data['data']])[0] >= 0.5 and not operation_open \
        and data['signal'][1] > data['macd'][1] and data['signal'][0] < data['macd'][0]: # Open buy
            last_operation_time = cur_time
            result = open_position(trading_data["market"], trading_data["lotage"], mt5.ORDER_TYPE_BUY)
            operation_open = True
        
        if dt.predict([data['data']])[0] >= 0.5 and not operation_open \
        and data['signal'][1] < data['macd'][1] and data['signal'][0] > data['macd'][0]: # Open sell
            last_operation_time = cur_time
            result = open_position(trading_data["market"], trading_data["lotage"], mt5.ORDER_TYPE_SELL)
            operation_open = True
            
        if operation_open and cur_time > last_operation_time+trading_data["time_period"]*CANDLES_BETWEEN_OPERATIONS:
            operation_open = False
            close_position(trading_data["market"], trading_data["lotage"], result)
            
        
