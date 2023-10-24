//+------------------------------------------------------------------+

//|                                         WiseFinanceSocketClient  |

//|                                 Copyright 2023, Fortesense Labs. |

//|                                      https://www.wisefinance.com |

//+------------------------------------------------------------------+

/* Reference:

 - https://github.com/ejtraderLabs/Metatrader5-Docker

 - https://www.mql5.com/en/code/280

 */

#property copyright "Copyright 2023, Fortesense Labs."

#property link "https://www.wisefinance.com"

#property version "0.10"

#property description "Wise Finance Socket Client"

// #define  SYMBOLS_TRADING    "EURUSD","GBPUSD","USDJPY","USDCHF"

#define SYMBOLS_TRADING "Step Index", "Boom 1000 Index", "Volatility 100 Index", "Volatility 25 Index"

#define CHART_EVENT_SYMBOL CHARTEVENT_ALL

#include <wiseFinanceMT/Json.mqh>

#include <wiseFinanceMT/OnTickSymbol.mqh>

// Set host and Port
input string HOST = "localhost";
input int PORT = 9090;

bool ExtTLS = false; // for TLS socket connections

// Global variables
int timerInterval = 3 * 1000; // Timer interval in milliseconds
bool debug = false;
bool liveStream = true;
bool connectedFlag = true;
int deInitReason = -1;

// Sockets
int liveSocket;

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
//| Function to establish a socket connection                        |
//+------------------------------------------------------------------+
int ConnectSocket(string host, int port)
{
  int socket = SocketCreate();
  if (socket != INVALID_HANDLE)
  {
    if (SocketConnect(socket, host, port, 1000))
    {
      Print("Established connection to ", host, ":", port);
      string subject, issuer, serial, thumbprint;
      datetime expiration;
      if (SocketTlsCertificate(socket, subject, issuer, serial, thumbprint, expiration))
      {
        Print("TLS certificate:");
        Print("   Owner:  ", subject);
        Print("   Issuer:  ", issuer);
        Print("   Number:     ", serial);
        Print("   Print: ", thumbprint);
        Print("   Expiration: ", expiration);
        ExtTLS = true;
      }
      return socket;
    }
    else
    {
      Print("Connection to ", host, ":", port, " failed, error ", GetLastError());
    }
    SocketClose(socket);
  }
  else
  {
    Print("Failed to create a socket, error ", GetLastError());
  }
  return INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket, string request)
{
  char req[];
  int len = StringToCharArray(request, req) - 1;
  if (len < 0)
    return (false);
  //--- if secure TLS connection is used via the port 443
  if (ExtTLS)
    return (SocketTlsSend(socket, req, len) == len);
  //--- if standard TCP connection is used
  return (SocketSend(socket, req, len) == len);
}

//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket, uint timeout)
{
  char rsp[];
  string result;
  uint timeout_check = GetTickCount() + timeout;
  //--- read data from sockets till they are still present but not longer than timeout
  do
  {
    uint len = SocketIsReadable(socket);
    if (len)
    {
      int rsp_len;
      //--- various reading commands depending on whether the connection is secure or not
      if (ExtTLS)
        rsp_len = SocketTlsRead(socket, rsp, len);
      else
        rsp_len = SocketRead(socket, rsp, len, timeout);
      //--- analyze the response
      if (rsp_len > 0)
      {
        result += CharArrayToString(rsp, 0, rsp_len);
        //--- print only the response header
        int header_end = StringFind(result, "\r\n\r\n");
        if (header_end > 0)
        {
          // Print("HTTP header received:"); // debug
          Print(StringSubstr(result, 0, header_end));
          //--- parse the body
          string body = StringSubstr(result, header_end + 4);
          // Print("HTTP body received:"); // debug
          Print(body);
          return (true);
        }
      }
    }
  } while (GetTickCount() < timeout_check && !IsStopped());
  return (false);
}

//+------------------------------------------------------------------+
//| Send POST request to the server                                  |
//+------------------------------------------------------------------+

bool HTTPPostRequest(int socket, string endpoint, string data)

{

  string request = "POST " + endpoint + " HTTP/1.1\r\n"

                                        "Host: www.mql5.com\r\n"

                                        "Content-Type: application/json\r\n"

                                        "Content-Length: " +

                   IntegerToString(StringLen(data)) + "\r\n"

                                                      "\r\n" +
                   data;

  return HTTPSend(socket, request);
}

//+------------------------------------------------------------------+
//| Send GET request to the server                                  |
//+------------------------------------------------------------------+

bool HTTPGetRequest(int socket, string endpoint, string data)

{
  string request = "GET " + endpoint + " HTTP/1.1\r\n"
                                       "Host: www.mql5.com\r\n"
                                       "User-Agent: MT5 EA\r\n"
                                       "\r\n";

  return HTTPSend(socket, request);
}

//+------------------------------------------------------------------+
//| Inform Server via socket                                         |
//+------------------------------------------------------------------+
void InformServerSocket(int socket, string endpoint, string data, string socketType)
{
  if (socket != INVALID_HANDLE)
  {
    Print("[POST] Sending Data: ", data); // debug
    //--- send POST request to the server
    if (HTTPPostRequest(socket, endpoint, data))
    {
      // Print("POST request sent");
      //--- read the response
      if (!HTTPRecv(socket, 1024))
      {
        int err = GetLastError();
        Print("Failed to get a response, error ", err);

        // Check for connection failed errors
        if (err != 0)
        {
          Print("Retrying...");
          liveSocket = ConnectSocket(HOST, PORT);
        }
      }
    }
    else
      Print("Failed to send POST request, error ", GetLastError());
  }
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
//| Function to split a string into an array of strings              |
//+------------------------------------------------------------------+
void SplitString(const string in, const string delimiter, string &out[])
{
  int count = 0;
  string remaining = in;

  while (StringFind(remaining, delimiter) != -1)
  {
    string value = StringSubstr(remaining, 0, StringFind(remaining, delimiter));
    out[count] = value;
    remaining = StringSubstr(remaining, StringLen(value) + 1);
    count++;
  }

  out[count] = remaining;
}

//+------------------------------------------------------------------+
//| Function to send tick data to the server                          |
//+------------------------------------------------------------------+
void SendTickData(string symbol)
{
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
    InformServerSocket(liveSocket, "/api/price/stream/tick", jsonStr, "TICK");

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

//+------------------------------------------------------------------+
//| Function to send bar data to the server                          |
//+------------------------------------------------------------------+
void SendBarData(string symbol, string timeframe)
{
  MqlRates rates[1];
  int spread[1];

  ENUM_TIMEFRAMES period = StringToTimeframe(timeframe);

  if (CopyRates(symbol, period, 1, 1, rates) != -1 && CopySpread(symbol, period, 1, 1, spread) != -1)
  {
    CJAVal Data;
    Data[0] = "" + (long)rates[0].time;
    Data[1] = (double)rates[0].open;
    Data[2] = (double)rates[0].high;
    Data[3] = (double)rates[0].low;
    Data[4] = (double)rates[0].close;
    Data[5] = (double)rates[0].tick_volume;
    Data[6] = (double)spread[0];
    Data[7] = (double)rates[0].real_volume;

    CJAVal Vars;
    Vars[0] = Data;

    CJAVal barData;
    barData["symbol"] = symbol;
    barData["timeframe"] = timeframe;
    barData["bar"].Set(Vars);

    CJAVal jsonData;
    jsonData["event"] = "bar";
    jsonData["data"].Set(barData);

    string jsonStr = jsonData.Serialize();
    InformServerSocket(liveSocket, "/api/price/stream/bar", jsonStr, "BAR");

    Print("[BAR] Sent Bar Data for ", symbol, " (", timeframe, ")");
  }
  else
  {
    Print("Failed to get bar data for ", symbol, " (", timeframe, ")");
  }
}

//+------------------------------------------------------------------+
//| Function to subscribe to bar data                                |
//+------------------------------------------------------------------+
void SubscribeToBars(const string &symbol, const string &timeframe)
{
  SymbolSubscription sub;

  sub.symbol = symbol;

  sub.chartTimeframe = timeframe;

  sub.lastBar = 0;

  ArrayResize(symbolSubscriptions, symbolSubscriptionCount + 1);

  symbolSubscriptions[symbolSubscriptionCount] = sub;

  symbolSubscriptionCount++;

  Print("[BAR] Subscribed to ", symbol, " (", timeframe, ")");
}

//+------------------------------------------------------------------+
//| Expert multi tick function                                       |
//| Use this function instead of the standard OnTick() function      |
//| OnTick handler                                                   |
//+------------------------------------------------------------------+
void OnTick(string symbol)
{
  if (!liveStream || IsStopped())
    return;

  // Send tick data
  SendTickData(symbol);
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
  // Print("OnChartEvent id: ", id);
  // Print("OnChartEvent lparam: ", lparam);
  // Print("OnChartEvent dparam: ", dparam);
  // Print("OnChartEvent sparam: ", sparam);
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
  // Send bar data for subscribed symbols
  for (int i = 0; i < symbolSubscriptionCount; i++)
  {
    SymbolSubscription sub = symbolSubscriptions[i];
    datetime lastBar = sub.lastBar;
    datetime currentBar = iTime(sub.symbol, StringToTimeframe(sub.chartTimeframe), 0);
    if (currentBar > lastBar)
    {
      SendBarData(sub.symbol, sub.chartTimeframe);
      sub.lastBar = currentBar;
      symbolSubscriptions[i] = sub;
    }
  }

  // Test socket connection
  int pingSocket = ConnectSocket(HOST, PORT);
  if (pingSocket != INVALID_HANDLE)
  {
    // Also, Check for connection failed errors - reconnect the liveSocket
    if (liveSocket == INVALID_HANDLE)
    {
      Print("Failed to establish socket connection");
      Print("Retrying...");

      OnInit();
    }

    // Send GET request to the server
    if (HTTPGetRequest(pingSocket, "/health", ""))
    {
      // Print("GET request sent"); // debug

      // Read the response
      if (!HTTPRecv(pingSocket, 1024))
      {
        int err = GetLastError();
        Print("Failed to get a response, error ", err);
      }
    }
    else
    {
      int err = GetLastError();
      Print("Failed to send GET request, error ", err);
    }

    SocketClose(pingSocket);
  }
}

//+------------------------------------------------------------------+
//| OnDeinit handler                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  deInitReason = reason;

  EventKillTimer();

  // Cleanup
  SocketClose(liveSocket);
  Print("Socket connection closed");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  // Establish socket connection
  liveSocket = ConnectSocket(HOST, PORT);
  if (liveSocket == INVALID_HANDLE)
  {
    Print("Failed to establish socket connection");
    Print("Retrying...");
    // return;
  }

  // Split the trading symbols string into an array
  // string symbols = "" + SYMBOLS_TRADING;
  // Define the trading symbols as a string
  // string _SYMBOLS_TRADING = "Step Index,Boom 1000 Index,Volatility 100 Index,Volatility 25 Index";

  // const int MAX_SYMBOLS = 4; // Adjust the maximum number of symbols if needed

  // string symbolsArray[];
  // SplitString(SYMBOLS_TRADING, ",", symbolsArray);

  // Get All Symbols [currently getting only the ones in marketwatch]
  int totalSymbols = SymbolsTotal(true) - 1;
  for (int i = totalSymbols; i > 0; i--)

  {

    string symbolName = SymbolName(i, true);

    // Print("Number: " + string(i) + " Symbol Name: " + symbolName + " Close Price: ", iClose(symbolName, 0, 0));
    Print("Number: " + string(i) + " Symbol Name: " + symbolName);
  }

  string symbolsArray[] = {
      "Step Index",
      "Boom 1000 Index",
      "Volatility 100 Index",
      "Volatility 25 Index"};

  // Subscribe to bar data
  for (int i = 0; i < ArraySize(symbolsArray); i++)
  {
    string symbol = symbolsArray[i];
    string timeframe = "M1";
    SubscribeToBars(symbol, timeframe);
  }

  // Start timer for periodic data update
  EventSetMillisecondTimer(timerInterval);
  // Set up the timer
  // EventSetTimer(timerInterval);

  // Event loop
  // while (!IsStopped())
  // {
  //   OnTick();
  //   Sleep(10); // Yield to other tasks
  // }

  // ScriptConfiguration();
}
//+------------------------------------------------------------------+
//| Note: Compile the Multi-currency Indicator First                 |
//+------------------------------------------------------------------+

// https://www.mql5.com/en/articles/159
// https://www.mql5.com/en/forum/367260
// https://www.mql5.com/en/articles/599
// https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes