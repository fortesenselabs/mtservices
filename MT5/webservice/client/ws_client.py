import json
import asyncio
import websockets

PORT = 8000
async def send_message():
    async with websockets.connect(f'ws://localhost:{PORT}/tick') as websocket:
        # message = input("Enter a message to send: ")
        tick_symbols = ['XAUUSD', 'XAGUSD', 'USDCHF', 'USDJPY', 'EURCAD', 'USDCAD', 'AUDJPY']
        data = {"message": "Hello world!", "tick_symbols": tick_symbols}
        await websocket.send(json.dumps(data))
        print(f"Sent data: {data}")

        while True:
            response = await websocket.recv()
            print(f"Received response: {response}")

asyncio.get_event_loop().run_until_complete(send_message())

# 
# https://github.com/OysterHQ/FastAPI-Production-Boilerplate
# https://github.com/Ahtii/chatapp
# https://github.com/co-demos/fastapi-boilerplate
# https://github.com/lynnkwong/websocket-fastapi-angular
# https://github.com/jobdeleij/real-time-web-app
# https://github.com/antkahn/flask-api-starter-kit
# https://www.mql5.com/en/articles/625?utm_source=www.metatrader4.com&utm_campaign=download.mt5.linux
# 
# 
# https://github.com/binance/binance-spot-api-docs
# https://binance-docs.github.io/apidocs/spot/en/
# 
# https://www.google.com/finance/markets/indexes?hl=en
# 
# 
# https://github.com/solrey3/incyd-web
# https://github.com/Buuntu/fastapi-react
# https://kafka-python.readthedocs.io/en/master/
# https://github.com/TreborNamor/TradingView-Machine-Learning-GUI
# https://github.com/brian-the-dev/python-tradingview-ta
# 