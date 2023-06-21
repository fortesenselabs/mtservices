import socket

PORT = 8680
ADDR = "localhost"

def socket_ini():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    server_socket.bind((ADDR, PORT))
    server_socket.listen(10)
    
    connection, addr = server_socket.accept()
    print("[INFO]\t", addr, "connected")
    
    return connection, server_socket
    

def thread_data(stop_event, data):
    msg = ""
    
    connection, server_socket = socket_ini()
    
    while not stop_event.is_set() and "END CONNECTION" not in msg:
        msg = connection.recv(1024).decode()
        
        if "END CONNECTION" in msg:
            break
        
        msg_splitted = msg.split(',')
        
        try:
            msg_splitted = [ float(elem) for elem in msg_splitted ]
            data['data'] = msg_splitted
            data['macd'] = msg_splitted[40:59]
            data['signal'] = msg_splitted[60:79]
        except:
            print("[INFO]\tError trying to convert to float, ignored");
        
    connection.close()
    server_socket.close()
        
     