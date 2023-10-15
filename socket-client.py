import socket

# Create a socket object
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the server
s.connect(("127.0.0.1", 9000))

# Send data to the server
s.send(b"Hello, world!")

# Receive data from the server
data = s.recv(1024)

# Print the data that was received from the server
print(data.decode())

# Close the socket
s.close()
