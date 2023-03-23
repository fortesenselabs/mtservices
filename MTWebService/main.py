import time
import json
import uvicorn
import argparse
import asyncio
import logging
import threading
from time import sleep
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
# 
from processor import TickProcessor
# from dotenv import load_dotenv

# load_dotenv()  # take environment variables from .env.
MT_files_dir = '/root/Metatrader/MQL5/Files'
# MT_files_dir = '/home/seekersoftec/.mt5/drive_c/Program Files/MetaTrader 5/MQL5/Files/'
HOST = "0.0.0.0"
PORT = 8000 # 5000

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("MT5 FastAPI web app")

app = FastAPI()
processor = TickProcessor(MT_files_dir)

symbols = ['EURUSD', 'GBPUSD', 'AUDCAD']  
# symbols = ['XAGUSD', 'XAUUSD', 'EURUSD', 'GBPUSD', 'AUDCAD']
symbols_count = len(symbols)


async def heavy_data_processing(data: dict):
    """Some (fake) heavy data processing logic."""
    await asyncio.sleep(2)
    message_processed = data.get("message", "").upper()
    return message_processed

async def processor_connector():
    await asyncio.sleep(1)  # wait for 1 second
    processor.subscribe_symbols_tick(symbols=symbols) # join symbols
    
async def symbol_watcher(symbols: list):
    """A function that watches the list of symbols for any changes."""
    global processor # , symbols_count

    symbols_count = 0
    # while True:
    # In this example, we'll just add a new symbol every 5 seconds.
    # await asyncio.sleep(5)
    # symbols.append("EURJPY")
    # Check if any new symbols have been added.
    if len(symbols) > symbols_count:
        new_symbols = list(set(symbols))
        # Reinitialize the TickProcessor with the updated symbols.
        processor = TickProcessor(MT_files_dir)
        processor.subscribe_symbols_tick(symbols=new_symbols)
        symbols_count = len(new_symbols)
    # else:
    #     break
    return None
    
async def start_watcher():
    """A function that starts the symbol watcher in a separate thread."""
    # asyncio.set_event_loop(asyncio.new_event_loop())  # create new event loop
    # loop = asyncio.get_event_loop()
    # loop.create_task(symbol_watcher())  # create a task for the coroutine
    # loop.run_forever()  # run the event loop

    # Start the tick sender loop in the background.
    asyncio.create_task(symbol_watcher())

async def tick_sender(websocket: WebSocket):
    """A function that periodically sends ticks to the client."""
    while True:
        # Generate some tick data.
        # tick_data = {
        #     "symbol": "EURUSD",
        #     "bid": 1.1234,
        #     "ask": 1.1235,
        #     "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        # }
        tick_data = processor.on_tick_data

        # Send the tick data to the client.
        await websocket.send_json(tick_data)

        # print(tick_data)

        # Wait for some time before sending the next tick.
        await asyncio.sleep(1)

@app.websocket("/tick")
async def websocket_endpoint(websocket: WebSocket):
    # Accept the connection from a client.
    await websocket.accept()


    while True:
        try:
            # Receive the JSON data sent by a client.
            data = await websocket.receive_json()
            print(data)

            # data['tick_symbols']
            # symbols.append("GBPJPY")
            # symbols.extend(data['tick_symbols'])
            await symbol_watcher(data['tick_symbols'])

            # Some (fake) heavey data processing logic.
            message_processed = await heavy_data_processing(data)
            # Send JSON data to the client.
            await websocket.send_json(
                {
                    "message": message_processed,
                    "time": datetime.now().strftime("%H:%M:%S"),
                }
            )
            
            # Start the tick sender loop in the background.
            asyncio.create_task(tick_sender(websocket))
        except WebSocketDisconnect:
            logger.info("The connection is closed.")
            break

@app.get('/accountInfo')
def account_info():
    response = processor.get_account_info()
    return response


if __name__ == '__main__':
    # ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    time.sleep(5) # wait for MT to load during production
    print(symbols)  
    # 
    asyncio.run(processor_connector())
    # asyncio.run(start_watcher())
    # asyncio.run(symbol_watcher())
    
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True, workers=4)
