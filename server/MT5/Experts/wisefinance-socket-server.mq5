//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.wisefinance.com                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance Socket Server"

#include <wisefinanceMT/socketlib.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 9000; // int

// Global variables
SOCKET64 server = INVALID_SOCKET64;
SOCKET64 clients[1024];

//+------------------------------------------------------------------+
//| OnDeinit handler                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Close the server socket
  CloseServer();

  // Print a message to the console
  printf("Server Socket connection closed\n");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  // Start the server socket
  StartServer(HOST, PORT);
}

//+------------------------------------------------------------------+
//| StartServer                                                        |
//+------------------------------------------------------------------+
void StartServer(string addr, ushort port)
{
  // Initialize the library
  char wsaData[];
  ArrayResize(wsaData, sizeof(WSAData));
  int res = WSAStartup(MAKEWORD(2, 2), wsaData);
  if (res != 0)
  {
    Print("-WSAStartup failed error: " + string(res));
    return;
  }

  // Create a socket
  server = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (server == INVALID_SOCKET64)
  {
    Print("-Create failed error: " + WSAErrorDescript(WSAGetLastError()));
    CloseServer();
    return;
  }

  // Bind to address and port
  Print("Trying to bind " + addr + ":" + string(port));

  char ch[];
  StringToCharArray(addr, ch);
  sockaddr_in addrin;
  addrin.sin_family = AF_INET;
  addrin.sin_addr.u.S_addr = inet_addr(ch);
  addrin.sin_port = htons(port);
  ref_sockaddr ref;
  ref.in = addrin;
  if (bind(server, ref.ref, sizeof(addrin)) == SOCKET_ERROR)
  {
    int err = WSAGetLastError();
    if (err != WSAEISCONN)
    {
      Print("-Connect failed error: " + WSAErrorDescript(err) + ". Cleanup socket");
      CloseServer();
      return;
    }
  }

  // Set to non-blocking mode
  int non_block = 1;
  res = ioctlsocket(server, (int)FIONBIO, non_block);
  if (res != NO_ERROR)
  {
    Print("ioctlsocket failed error: " + string(res));
    CloseServer();
    return;
  }

  // Listen on the port and accept client connections
  if (listen(server, SOMAXCONN) == SOCKET_ERROR)
  {
    Print("Listen failed with error: ", WSAErrorDescript(WSAGetLastError()));
    CloseServer();
    return;
  }

  Print("Server started successfully");
}

//+------------------------------------------------------------------+
//| AcceptClients                                                        |
//+------------------------------------------------------------------+
void AcceptClients()
{
  if (server == INVALID_SOCKET64)
  {
    return;
  }

  // Accept any new incoming connections
  SOCKET64 client = INVALID_SOCKET64;

  ref_sockaddr ch;
  int len = sizeof(ref_sockaddr);
  client = accept(server, ch.ref, len);
  if (client != INVALID_SOCKET64)
  {
    // Add the new client socket to the list of clients
    for (int i = 0; i < ArraySize(clients); i++)
    {
      if (clients[i] == INVALID_SOCKET64)
      {
        clients[i] = client;
        break;
      }
    }
  }
}

//+------------------------------------------------------------------+
//| ProcessClientsData                                                        |
//+------------------------------------------------------------------+
void ProcessClientsData()
{
  if (ArraySize(clients) == 0)
  {
    Print("Waiting for Connections!!!");
    return;
  }

  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i] != INVALID_SOCKET64)
    {
      char buf[1024];
      int res = recv(clients[i], buf, sizeof(buf), 0);
      if (res > 0)
      {
        // Process the data from the client
        // ...
        Print("Processing data");

        uchar data[];
        ArrayCopy(data, buf, ArraySize(data), 0, res);
        string receivedData = CharArrayToString(data);

        // Process received data here
        Print("Received Data: ", receivedData);

        // Example HTTP response
        string httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 19\r\n\r\n<html><body>Hello</body></html>";

        char httpResponseArray[];
        StringToCharArray(httpResponse, httpResponseArray);

        // Send the HTTP response back to the client
        send(clients[i], httpResponseArray, ArraySize(httpResponseArray), 0);
      }
      else if (res == 0)
      {
        // The client has disconnected
        closesocket(clients[i]);
        clients[i] = INVALID_SOCKET64;
      }
      else
      {
        // An error occurred
        int err = WSAGetLastError();
        if (err != WSAEWOULDBLOCK)
        {
          printf("recv failed with error: %d\n", err);
          closesocket(clients[i]);
          clients[i] = INVALID_SOCKET64;
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//| CloseServer                                                        |
//+------------------------------------------------------------------+
void CloseServer()
{
  // Close all client sockets
  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i] != INVALID_SOCKET64)
    {
      closesocket(clients[i]);
      clients[i] = INVALID_SOCKET64;
    }
  }

  // Close the server socket
  if (server != INVALID_SOCKET64)
  {
    closesocket(server);
    server = INVALID_SOCKET64;
  }

  // Clean up Winsock
  WSACleanup();
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
  // Accept any new incoming connections
  AcceptClients();

  // Check for data from any of the clients
  ProcessClientsData();
}
