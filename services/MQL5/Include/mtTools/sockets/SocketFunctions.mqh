#include <mtTools/sockets/Socketlib.mqh>
#include <mtTools/Types.mqh>
#include <mtTools/formats/Json.mqh>

char SOCKET_BUFFER[8192]; // Adjust the buffer size as needed (4096 | 8192)

//+------------------------------------------------------------------+
//| Send Socket response                                               |
//+------------------------------------------------------------------+
int ServerSocketSend(ClientSocket &client)
{
  uchar response[];
  int len = StringToCharArray(client.responseData, response) - 1;
  if (len < 0)
    return 0;

  Print("ServerSocketSend -> client.responseData: ", client.responseData);
  Print("client.socket: ", client.socket);
  // TODO: examine thoroughly
  // Send the HTTP response back to the client
  return send(client.socket, response, ArraySize(response), 0);
}

//+------------------------------------------------------------------+
//| Read Socket request                                                |
//+------------------------------------------------------------------+
ClientSocket SocketRecv(ClientSocket &client)
{
  if (client.socket != INVALID_SOCKET64)
  {
    int request_len = recv(client.socket, SOCKET_BUFFER, sizeof(SOCKET_BUFFER), 0);

    if (request_len > 0)
    {
      uchar data[];
      ArrayCopy(data, SOCKET_BUFFER, ArraySize(data), 0, request_len);
      client.requestData = CharArrayToString(data);
      // Process received data here
      // Print("Received Data: ", client.requestData);
    }
    else if (request_len == 0)
    {
      // The client has disconnected
      closesocket(client.socket);
      client.socket = INVALID_SOCKET64;
    }
    else
    {
      // An error occurred
      int err = WSAGetLastError();
      if (err != WSAEWOULDBLOCK)
      {
        Print("recv failed with error: ", err);
        closesocket(client.socket);
        client.socket = INVALID_SOCKET64;
      }
    }
  }

  return client;
}