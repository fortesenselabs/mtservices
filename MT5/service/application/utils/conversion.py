from application.exchange_interfaces.metatrader.types import TimeFrames

def convert_dict_to_list(d):
    # expand it to support multiple timeframes for a symbol i.e {"EURUSD": ["M15", "M1"]} => [["EURUSD", "M15"], ["EURUSD", "M1"]]
    default_tf = TimeFrames.TIMEFRAME_M15
    result = []
    for key, value in d.items():
        tf = value[0] if len(value) > 0 else default_tf
        result.append([key, tf])
    return result