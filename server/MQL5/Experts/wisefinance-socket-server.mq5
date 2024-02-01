//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.wisefinance.com                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280
// - ejTrader

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance Socket Server"
#define SYMBOLS_TRADING "EURUSD", "GBPUSD", "USDJPY", "USDCHF"
// #define SYMBOLS_TRADING "Step Index", "Boom 1000 Index", "Volatility 100 Index", "Volatility 25 Index" // get all symbols
#define CHART_EVENT_SYMBOL CHARTEVENT_ALL

#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/Trade.mqh>
#include <StringToEnumInt.mqh>

// Load wiseFinanceMT includes
// Required:

#include <wiseFinanceMT/ControlErrors.mqh>
// #include <wisefinanceMT/SocketServer.mqh>
// #include <wisefinanceMT/SocketClient.mqh>
#include <wisefinanceMT/nats/NatsClient.mqh>
#include <wisefinanceMT/RequestHandlers.mqh>
#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wiseFinanceMT/Calendar.mqh>
#include <wiseFinanceMT/Utils.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 9000; // int

// Set host and Port - for outgoing
input string DATA_COLLECTOR_HOST = "localhost";
input int DATA_COLLECTOR_PORT = 9090;

input string NATS_HOST = "demo.nats.io";
input int NATS_PORT = 4222;

// Global variables

// Timer interval in milliseconds
int timerInterval = 1 * 1000;
bool debug = true;

bool ExtTLS = false; // for TLS socket connections

bool connectedFlag = true;
int deInitReason = -1;

// Variables for handling price data stream
bool liveStream = true;

struct SymbolSubscription
{
  string symbol;
  string chartTimeFrame;
  datetime lastBar;
};
SymbolSubscription symbolSubscriptions[];
int symbolSubscriptionCount = 0;

datetime tm;

// Error handling
ControlErrors mControl;

NATSClient Client;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  // Setting up error reporting
  mControl.SetAlert(true);
  mControl.SetSound(false);
  mControl.SetWriteFlag(false);

  // Start timer for periodic data update
  EventSetMillisecondTimer(timerInterval);

  // Establish socket connection
  // liveSocket = ConnectSocket(DATA_COLLECTOR_HOST, DATA_COLLECTOR_PORT);
  // if (liveSocket == INVALID_HANDLE)
  // {
  //   Print("Failed to establish socket connection");
  //   Print("Retrying...");
  //   // return;
  // }

  // Establish socket connection
  Client = NAtsConnectSocket(NATS_HOST, NATS_PORT);
  if (Client.socket == INVALID_HANDLE)
  {
    Print("Failed to establish socket connection to NATS server");
    Print("Retrying...");
    // return;
  }

  // Print(Client);
  // Handshake
  if (Handshake(Client))
  {
    Print("Connected to NATS server");
    Print("Response Data => ", Client.responseData);
  }
  else
  {
    Print("Handshake failed");
  };

  // Split the trading symbols string into an array
  // string symbols = "" + SYMBOLS_TRADING;
  // Define the trading symbols as a string
  // string _SYMBOLS_TRADING = "Step Index,Boom 1000 Index,Volatility 100 Index,Volatility 25 Index";

  // const int MAX_SYMBOLS = 4; // Adjust the maximum number of symbols if needed

  // string symbolsArray[];
  // SplitString(SYMBOLS_TRADING, ",", symbolsArray);

  // Get All Symbols [currently getting only the ones in marketwatch]
  // int totalSymbols = SymbolsTotal(true) - 1;
  // for (int i = totalSymbols; i > 0; i--)

  // {

  //   string symbolName = SymbolName(i, true);

  //   // Print("Number: " + string(i) + " Symbol Name: " + symbolName + " Close Price: ", iClose(symbolName, 0, 0));
  //   Print("Number: " + string(i) + " Symbol Name: " + symbolName);
  // }

  // string symbolsArray[] = {
  //     "Step Index",
  //     "Boom 1000 Index",
  //     "Volatility 100 Index",
  //     "Volatility 25 Index"};

  // Subscribe to bar data
  // for (int i = 0; i < ArraySize(symbolsArray); i++)
  // {
  //   string symbol = symbolsArray[i];
  //   string timeframe = "M1";
  //   SubscribeToBars(symbol, timeframe);
  // }

  // Set up the timer
  // EventSetTimer(timerInterval);
  // Event loop
  // while (!IsStopped())
  // {
  //   OnTick();
  //   Sleep(10); // Yield to other tasks
  // }

  // ScriptConfiguration();

  // Start the server socket
  // StartServer(HOST, PORT);
}

//+------------------------------------------------------------------+
//| OnDeinit handler                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Close the server socket
  // CloseServer();

  // Print a message to the console
  // printf("Server Socket connection closed\n");

  // deInitReason = reason;

  // EventKillTimer();

  // Cleanup
  // SocketClose(liveSocket);
  NAtsCloseSocket(Client);
  Print("Socket connection closed");
  //  Print("Data collector Socket connection closed");

  // EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert multi tick function                                       |
//| Use this function instead of the standard OnTick() function      |
//| OnTick handler                                                   |
//+------------------------------------------------------------------+
void OnTick(string symbol)
{
  // if (!liveStream || IsStopped())
  //   return;

  // // Send tick data
  // SendTickData(symbol);
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
  // // Accept any new incoming connections
  // AcceptClients();

  // tm = TimeTradeServer();

  // // Send bar data for subscribed symbols
  // for (int i = 0; i < symbolSubscriptionCount; i++)
  // {
  //   SymbolSubscription sub = symbolSubscriptions[i];
  //   datetime lastBar = sub.lastBar;
  //   datetime currentBar = iTime(sub.symbol, GetTimeframe(sub.chartTimeFrame), 0);
  //   if (currentBar > lastBar)
  //   {
  //     SendBarData(sub.symbol, sub.chartTimeFrame);
  //     sub.lastBar = currentBar;
  //     symbolSubscriptions[i] = sub;
  //   }
  // }

  // // Test socket connection
  // int pingSocket = ConnectSocket(HOST, PORT);
  // if (pingSocket != INVALID_HANDLE)
  // {
  //   // Also, Check for connection failed errors - reconnect the liveSocket
  //   if (liveSocket == INVALID_HANDLE)
  //   {
  //     Print("Failed to establish socket connection");
  //     Print("Retrying...");

  //     OnInit();
  //   }

  //   // Send GET request to the server
  //   if (HTTPGetRequest(pingSocket, "/api/v1/health", ""))
  //   {
  //     // Print("GET request sent"); // debug

  //     // Read the response
  //     if (!HTTPRecv(pingSocket, 1024))
  //     {
  //       int err = GetLastError();
  //       Print("Failed to get a response, error ", err);
  //     }
  //   }
  //   else
  //   {
  //     int err = GetLastError();
  //     Print("Failed to send GET request, error ", err);
  //   }

  //   SocketClose(pingSocket);
  // }
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
