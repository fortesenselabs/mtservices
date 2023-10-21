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
#include <wisefinanceMT/Socketlib.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 9000; // int

// Global variables

// Sockets

SOCKET64 serverSocket = INVALID_SOCKET64;
struct ClientSocket
{
  SOCKET64 socket;
  string requestData;
  string responseData;
};

ClientSocket clients[1024];

// Timer interval in milliseconds
int timerInterval = 3 * 1000;
bool debug = true;

// Variables for handling price data stream
struct SymbolSubscription
{
  string symbol;
  string chartTimeframe;
  datetime lastBar;
};
SymbolSubscription symbolSubscriptions[];
int symbolSubscriptionCount = 0;

datetime tm;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  EventSetMillisecondTimer(timerInterval);

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

  EventKillTimer();
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
  serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (serverSocket == INVALID_SOCKET64)
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
  if (bind(serverSocket, ref.ref, sizeof(addrin)) == SOCKET_ERROR)
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
  res = ioctlsocket(serverSocket, (int)FIONBIO, non_block);
  if (res != NO_ERROR)
  {
    Print("ioctlsocket failed error: " + string(res));
    CloseServer();
    return;
  }

  // Listen on the port and accept client connections
  if (listen(serverSocket, SOMAXCONN) == SOCKET_ERROR)
  {
    Print("Listen failed with error: ", WSAErrorDescript(WSAGetLastError()));
    CloseServer();
    return;
  }

  Print("Server started successfully");
}

//+------------------------------------------------------------------+
//| Send Socket response                                               |
//+------------------------------------------------------------------+
int SocketSend(ClientSocket &client)
{
  uchar response[];
  int len = StringToCharArray(client.responseData, response) - 1;
  if (len < 0)
    return 0;

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
    char buf[1024];
    int request_len = recv(client.socket, buf, sizeof(buf), 0);

    if (request_len > 0)
    {
      uchar data[];
      ArrayCopy(data, buf, ArraySize(data), 0, request_len);
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
        Print("recv failed with error: %d\n", err);
        closesocket(client.socket);
        client.socket = INVALID_SOCKET64;
      }
    }
  }

  return client;
}

//+------------------------------------------------------------------+
//| Process Client Request and Respond                                |
//+------------------------------------------------------------------+
void ProcessClientRequest(ClientSocket &client)
{
  // char buffer[4096];
  // int bytesRead = recv(clientSocket, buffer, sizeof(buffer), 0);
  // client = SocketRecv(client);

  if (client.socket <= 0)
  {
    // Error or connection closed
    closesocket(client.socket);
    return;
  }

  RequestHandler(client);

  // Close the client socket
  // closesocket(client.socket);
}

// Handle Tick data request [GET request]
void RequestHandler(ClientSocket &client)
{
  CJAVal msg;

  if (!msg.Deserialize(client.requestData))
  {
    Print("Failed to deserialize request command");
  }

  Print("Request: ", client.requestData);

  string action = msg["action"].ToStr();
  if (action == "ACCOUNT")
  {
    GetAccountInfo(client);
  }
  else
  {
    GetTick(client);
  }
}

//+------------------------------------------------------------------+
//| Account information                                              |
//+------------------------------------------------------------------+
void GetAccountInfo(ClientSocket &client)
{

  CJAVal info;

  info["error"] = false;
  info["broker"] = AccountInfoString(ACCOUNT_COMPANY);
  info["currency"] = AccountInfoString(ACCOUNT_CURRENCY);
  info["server"] = AccountInfoString(ACCOUNT_SERVER);
  info["trading_allowed"] = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
  info["bot_trading"] = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
  info["balance"] = AccountInfoDouble(ACCOUNT_BALANCE);
  info["equity"] = AccountInfoDouble(ACCOUNT_EQUITY);
  info["margin"] = AccountInfoDouble(ACCOUNT_MARGIN);
  info["margin_free"] = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
  info["margin_level"] = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
  info["time"] = string(tm); // sending time for localtime dataframe

  string t = info.Serialize();
  if (debug)
    Print(t);

  client.responseData = t;
  SocketSend(client);
}

//+------------------------------------------------------------------+
//| Get Tick                                                       |
//+------------------------------------------------------------------+
void GetTick(ClientSocket &client)
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
    client.responseData = jsonStr;
    SocketSend(client);

    Print("[TICK] Sent Tick Data for ", symbol, " (", timeframe, ")");
    // Debug
    if (debug)
    {
      Print("New event on symbol: ", symbol);
      Print("data: ", jsonStr);
      // Sleep(1000);
    }
  }
  else
  {
    Print("Failed to get tick data for ", symbol, " (", timeframe, ")");
  }
}

//+------------------------------------------------------------------+
//| AcceptClients                                                        |
//+------------------------------------------------------------------+
void AcceptClients()
{
  if (serverSocket == INVALID_SOCKET64)
  {
    return;
  }

  // Accept any new incoming connections
  SOCKET64 client = INVALID_SOCKET64;

  ref_sockaddr ch;
  int len = sizeof(ref_sockaddr);
  client = accept(serverSocket, ch.ref, len);
  if (client != INVALID_SOCKET64)
  {
    // Add the new client socket to the list of clients
    for (int i = 0; i < ArraySize(clients); i++)
    {
      if (clients[i].socket == INVALID_SOCKET64)
      {
        clients[i].socket = client;
        clients[i] = SocketRecv(clients[i]);
        break;
      }
    }
  }

  // Check for data from any of the clients
  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i].socket != INVALID_SOCKET64)
    {
      clients[i] = SocketRecv(clients[i]);
      ProcessClientRequest(clients[i]);
    }
  }

  Print("Waiting for Connections!!!");
}

//+------------------------------------------------------------------+
//| CloseServer                                                        |
//+------------------------------------------------------------------+
void CloseServer()
{
  // Close all client sockets
  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i].socket != INVALID_SOCKET64)
    {
      closesocket(clients[i].socket);
      clients[i].socket = INVALID_SOCKET64;
    }
  }

  // Close the server socket
  if (serverSocket != INVALID_SOCKET64)
  {
    closesocket(serverSocket);
    serverSocket = INVALID_SOCKET64;
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
  //
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{

  tm = TimeTradeServer();

  // Accept any new incoming connections
  AcceptClients();
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
