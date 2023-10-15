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
// #define  SYMBOLS_TRADING    "EURUSD","GBPUSD","USDJPY","USDCHF"
#define SYMBOLS_TRADING "Step Index", "Boom 1000 Index", "Volatility 100 Index", "Volatility 25 Index"
#define CHART_EVENT_SYMBOL CHARTEVENT_ALL

#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wisefinanceMT/socketlib.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 9000; // int

// Global variables

// Sockets
SOCKET64 server = INVALID_SOCKET64;
SOCKET64 clients[1024];

// Timer interval in milliseconds
int timerInterval = 3 * 1000;
bool debug = false;

// Variables for handling price data stream
struct SymbolSubscription
{
  string symbol;
  string chartTimeframe;
  datetime lastBar;
};
SymbolSubscription symbolSubscriptions[];
int symbolSubscriptionCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  // Start the server socket
  StartServer(HOST, PORT);
}

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
//| Send HTTP response                                               |
//+------------------------------------------------------------------+
int HTTPSend(SOCKET64 socket, string data)
{
  uchar response[];
  int len = StringToCharArray(data, response) - 1;
  if (len < 0)
    return 0;

  // Send the HTTP response back to the client
  return send(socket, response, ArraySize(response), 0);
}

//+------------------------------------------------------------------+
//| Read HTTP request                                                |
//+------------------------------------------------------------------+
int HTTPRecv(SOCKET64 socket)
{
  if (socket != INVALID_SOCKET64)
  {
    char buf[1024];
    int request_len = recv(socket, buf, sizeof(buf), 0);

    if (request_len > 0)
    {
      uchar data[];
      ArrayCopy(data, buf, ArraySize(data), 0, request_len);
      string body = CharArrayToString(data);
      // Process received data here
      // Print("Received Data: ", body);

      // Example HTTP response
      // string httpResponseData = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 19\r\n\r\n<html><body>Hello</body></html>";

      // Send the HTTP response back to the client
      // HTTPSend(socket, httpResponseData);
    }
    else if (request_len == 0)
    {
      // The client has disconnected
      closesocket(socket);
      socket = INVALID_SOCKET64;
    }
    else
    {
      // An error occurred
      int err = WSAGetLastError();
      if (err != WSAEWOULDBLOCK)
      {
        Print("recv failed with error: %d\n", err);
        closesocket(socket);
        socket = INVALID_SOCKET64;
      }
    }
  }

  return socket;
}

//+------------------------------------------------------------------+
//| Parse GET Request                                                |
//+------------------------------------------------------------------+
bool ParseGetRequest(string getRequest, string &endpoint, string &requestData)
{
  // Initialize the output variables
  endpoint = "";
  requestData = "";

  // Split the GET request into lines
  string requestLines[];
  int lineCount = StringSplit(getRequest, "\r\n", requestLines);

  if (lineCount < 1)
  {
    Print("Invalid GET request: No lines found");
    return (false);
  }

  // The first line of the GET request contains the endpoint
  string firstLine = requestLines[0];

  // Find the position of the first space character (indicating the endpoint)
  int spacePos = StringFind(firstLine, " ");

  if (spacePos < 0)
  {
    Print("Invalid GET request: Missing space character");
    return (false);
  }

  // Extract the endpoint
  endpoint = StringSubstr(firstLine, spacePos + 1);

  // Find the position of the first space character after the endpoint (indicating the HTTP version)
  int secondSpacePos = StringFind(endpoint, " ");

  if (secondSpacePos < 0)
  {
    Print("Invalid GET request: Missing space character after the endpoint");
    return (false);
  }

  // Remove the HTTP version part from the endpoint
  endpoint = StringSubstr(endpoint, 0, secondSpacePos);

  // If there are more lines in the request, they may contain data
  if (lineCount > 1)
  {
    // Join the remaining lines to extract any request data
    for (int i = 1; i < lineCount; i++)
    {
      requestData += requestLines[i];
      if (i < lineCount - 1)
      {
        requestData += "\r\n"; // Restore newline characters
      }
    }
  }

  return (true);
}

//+------------------------------------------------------------------+
//| Parse POST Request                                               |
//+------------------------------------------------------------------+
bool ParsePostRequest(string postRequest, string &endpoint, string &contentType, string &requestData)
{
  // Initialize the output variables
  endpoint = "";
  contentType = "";
  requestData = "";

  // Split the POST request into lines
  string requestLines[];
  int lineCount = StringSplit(postRequest, "\r\n", requestLines);

  if (lineCount < 1)
  {
    Print("Invalid POST request: No lines found");
    return (false);
  }

  // The first line of the POST request contains the endpoint
  string firstLine = requestLines[0];

  // Find the position of the first space character (indicating the endpoint)
  int spacePos = StringFind(firstLine, " ");

  if (spacePos < 0)
  {
    Print("Invalid POST request: Missing space character");
    return (false);
  }

  // Extract the endpoint
  endpoint = StringSubstr(firstLine, spacePos + 1);

  // Find the Content-Type header
  for (int i = 1; i < lineCount; i++)
  {
    string line = requestLines[i];
    if (StringFind(line, "Content-Type:") == 0)
    {
      contentType = StringSubstr(line, StringLen("Content-Type:") + 1);
      break;
    }
  }

  // If there are more lines in the request, they may contain data
  if (lineCount > 1)
  {
    // Join the remaining lines to extract the request data
    for (int i = 1; i < lineCount; i++)
    {
      if (StringLen(requestData) > 0)
      {
        requestData += "\r\n"; // Restore newline characters
      }
      requestData += requestLines[i];
    }
  }

  return (true);
}

//+------------------------------------------------------------------+
//| Process Client Request and Respond                                |
//+------------------------------------------------------------------+
void ProcessClientRequest(SOCKET64 clientSocket)
{
  char buffer[4096];
  // int bytesRead = recv(clientSocket, buffer, sizeof(buffer), 0);
  int bytesRead = HTTPRecv(clientSocket);

  if (bytesRead <= 0)
  {
    // Error or connection closed
    closesocket(clientSocket);
    return;
  }

  HandleGetRequest(clientSocket, "/");
  // // Convert the received data to a string
  // string requestData = CharArrayToString(buffer, 0, bytesRead);

  // // Determine if it's a GET or POST request
  // if (StringFind(requestData, "GET ") == 0)
  // {
  //   // It's a GET request
  //   string getRequest = "/";
  //   string getEndpoint;
  //   if (ParseGetRequest("GET", getEndpoint, requestData))
  //   {
  //     // Handle the GET request
  //     HandleGetRequest(clientSocket, getEndpoint);
  //   }
  // }
  // else if (StringFind(requestData, "POST ") == 0)
  // {
  //   // It's a POST request
  //   string postRequest, postEndpoint, postContentType, postData;
  //   if (ParsePostRequest(requestData, postEndpoint, postContentType, postData))
  //   {
  //     // Handle the POST request
  //     HandlePostRequest(clientSocket, postEndpoint, postContentType, postData);
  //   }
  // }

  // Close the client socket
  closesocket(clientSocket);
}

// Handle a GET request
void HandleGetRequest(SOCKET64 clientSocket, string endpoint)
{
  // GET request handling code here
  // send an appropriate response back to the client
  string symbol = "Step Index";

  MqlTick tick;

  ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;

  if (SymbolInfoTick(symbol, tick))
  {
    CJAVal Data;
    Data[0] = (string)tick.time_msc;
    Data[1] = (double)tick.bid;
    Data[2] = (double)tick.ask;

    CJAVal tickData;
    tickData["symbol"] = symbol;
    tickData["timeframe"] = TimeframeToString(timeframe);
    tickData["tick"].Set(Data);

    CJAVal jsonData;
    jsonData["event"] = "tick";
    jsonData["data"].Set(tickData);

    string jsonStr = jsonData.Serialize();
    // InformServerSocket(liveSocket, "/api/price/stream/tick", jsonStr, "TICK");
    HTTPSend(clientSocket, jsonStr);
    Print("[TICK] Sent Tick Data for ", symbol, " (", timeframe, ")");

    // Debug
    if (debug)
    {
      Print("New event on symbol: ", symbol);
      Print("data: ", jsonStr);
    }
  }
  else
  {
    Print("Failed to get tick data for ", symbol, " (", timeframe, ")");
  }
}

// Handle a POST request
void HandlePostRequest(int clientSocket, string endpoint, string contentType, string data)
{
  // POST request handling code here
  // send an appropriate response back to the client
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
    clients[i] = HTTPRecv(clients[i]);
    //
    ProcessClientRequest(clients[i]);
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
//| Expert multi tick function                                       |
//| Use this function instead of the standard OnTick() function      |
//| OnTick handler                                                   |
//+------------------------------------------------------------------+
void OnTick(string symbol)
{
  // Accept any new incoming connections
  AcceptClients();

  // Check for data from any of the clients
  ProcessClientsData();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//| This function must be declared, even if it empty.                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, // event id

                  const long &lparam, // event param of long type

                  const double &dparam, // event param of double type

                  const string &sparam) // event param of string type

{

  //--- Add code here...
  Print("OnChartEvent id: ", id);
  // Print("OnChartEvent lparam: ", lparam);
  // Print("OnChartEvent dparam: ", dparam);
  // Print("OnChartEvent sparam: ", sparam);
}

//+------------------------------------------------------------------+
//| Convert enum chart timeframe to string                           |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES timeframe)
{
  string tf;

  switch (timeframe)
  {
  case PERIOD_CURRENT:
    tf = "TICK";
    break;
  case PERIOD_M1:
    tf = "M1";
    break;
  case PERIOD_M5:
    tf = "M5";
    break;
  case PERIOD_M15:
    tf = "M15";
    break;
  case PERIOD_M30:
    tf = "M30";
    break;
  case PERIOD_H1:
    tf = "H1";
    break;
  case PERIOD_H2:
    tf = "H2";
    break;
  case PERIOD_H3:
    tf = "H3";
    break;
  case PERIOD_H4:
    tf = "H4";
    break;
  case PERIOD_H6:
    tf = "H6";
    break;
  case PERIOD_H8:
    tf = "H8";
    break;
  case PERIOD_H12:
    tf = "H12";
    break;
  case PERIOD_D1:
    tf = "D1";
    break;
  case PERIOD_W1:
    tf = "W1";
    break;
  case PERIOD_MN1:
    tf = "MN1";
    break;
  default:
    tf = "UNKNOWN";
    break;
  }

  return tf;
}

//+------------------------------------------------------------------+
//| Convert chart timeframe from string to enum                      |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES StringToTimeframe(string timeframe)
{

  ENUM_TIMEFRAMES tf;
  tf = NULL;

  if (timeframe == "TICK")
    tf = PERIOD_CURRENT;

  if (timeframe == "M1")
    tf = PERIOD_M1;

  if (timeframe == "M5")
    tf = PERIOD_M5;

  if (timeframe == "M15")
    tf = PERIOD_M15;

  if (timeframe == "M30")
    tf = PERIOD_M30;

  if (timeframe == "H1")
    tf = PERIOD_H1;

  if (timeframe == "H2")
    tf = PERIOD_H2;

  if (timeframe == "H3")
    tf = PERIOD_H3;

  if (timeframe == "H4")
    tf = PERIOD_H4;

  if (timeframe == "H6")
    tf = PERIOD_H6;

  if (timeframe == "H8")
    tf = PERIOD_H8;

  if (timeframe == "H12")
    tf = PERIOD_H12;

  if (timeframe == "D1")
    tf = PERIOD_D1;

  if (timeframe == "W1")
    tf = PERIOD_W1;

  if (timeframe == "MN1")
    tf = PERIOD_MN1;

  // if tf == NULL an error will be raised in config function
  return (tf);
}