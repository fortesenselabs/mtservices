import socket
import json

# Create a socket object
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the server
s.connect(("127.0.0.1", 9000))

# Create a dictionary to send as JSON
data_to_send = {"action": "ACCOUNT"}  # Add your data as needed

# Serialize the data to JSON
json_data = json.dumps(data_to_send)

# Send JSON data to the server
# s.send(b"Hello")
s.send(json_data.encode())
# Receive data from the server
data = s.recv(1024)

# Print the data that was received from the server
print(data.decode())

# Close the socket
s.close()
