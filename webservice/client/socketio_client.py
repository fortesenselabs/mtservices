import json
from socketIO_client import SocketIO, LoggingNamespace

server_url = 'http://localhost'
room = 'EURUSD'

def on_tick(data):
    print('Received tick:', data)

with SocketIO(server_url, 5000, LoggingNamespace) as socketio:
    socketio.emit('join', {'username': 'user0', 'room': room})
    # socketio.emit('tick_data', {'tick': 'Hello', 'room': room})
    # 
    # 
    socketio.on('tick_data', on_tick)
    # socketio.on('response', on_tick)
    socketio.wait()

# 
# pip install socketIO-client

# pip install --upgrade python-socketio==4.6.0

# pip install --upgrade python-engineio==3.13.2

# pip install --upgrade Flask-SocketIO==4.3.1
