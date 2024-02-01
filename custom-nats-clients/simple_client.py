import socket
import json

class NATSClient:
    def __init__(self, server_address='127.0.0.1', server_port=4222):
        self.server_address = server_address
        self.server_port = server_port
        self.socket = None

    def connect(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.server_address, self.server_port))
        print("Connected to NATS server")

    def handshake(self):
        connect_msg = "CONNECT {}\r\n"
        self.socket.sendall(connect_msg.encode())
        
        # Wait for the "+OK" response
        response = self.socket.recv(4096).decode()
        print(response)
        if not response.strip().endswith("OK"):
            raise RuntimeError("Handshake failed")

        # Wait for the "PING" message
        ping_msg = self.socket.recv(4096).decode()
        if not ping_msg.strip().startswith("PING"):
            raise RuntimeError("Expected PING during handshake")

        # Respond with "PONG"
        pong_msg = "PONG\r\n"
        self.socket.sendall(pong_msg.encode())

    def publish(self, subject, message):
        publish_cmd = f"PUB {subject} {len(message)}\r\n{message}\r\n"
        self.socket.sendall(publish_cmd.encode())

    def subscribe(self, subject, sid="90"):
        subscribe_cmd = f"SUB {subject} {sid}\r\n"
        self.socket.sendall(subscribe_cmd.encode())

    def receive_message(self):
        data = self.socket.recv(4096)
        return data.decode()

    def close(self):
        self.socket.close()
        print("Connection closed")


# Example usage:
if __name__ == "__main__":
    # Replace with the actual NATS server address and port
    nats_client = NATSClient(server_address='demo.nats.io', server_port=4222)

    try:
        nats_client.connect()
        nats_client.handshake()

        # Subscribe to a subject
        nats_client.subscribe("foo.*")

        # Publish a message
        message_data = {"hey": "hello"}
        nats_client.publish("foo.bar", json.dumps(message_data))

        # Receive messages
        for _ in range(5):  # Receive 5 messages
            received_message = nats_client.receive_message()
            print("Received:", received_message)
            
            # Check if received message is a PING message
            if received_message.strip().startswith("PING"):
                # Respond with "PONG"
                pong_msg = "PONG\r\n"
                nats_client.socket.sendall(pong_msg.encode())

    except KeyboardInterrupt:
        print("Exiting...")
        nats_client.close()

    finally:
        print("Exiting...")
        nats_client.close()
