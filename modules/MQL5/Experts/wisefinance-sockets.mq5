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
#property description "Wise Finance Sockets"
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
// #include <wiseFinanceMT/Calendar.mqh>
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
  Client = NAtsConnectSocket(NATS_HOST, NATS_PORT);
  if (Client.socket == INVALID_HANDLE)
  {
    Print("Failed to establish socket connection to NATS server");
    Print("Retrying...");
    // return;
  }

  // Print(Client);
  // Handshake connection
  if (Client.state.connect)
  {
    Print("Connected to NATS server");
  } else {
    Print("Failed to connect to NATS server");
    Print("Server Response => ", Client.responseData);
  }
}

//+------------------------------------------------------------------+
//| OnDeinit handler                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Cleanup
  EventKillTimer();

  // Close the server socket
  NAtsCloseSocket(Client);
  Print("Socket connection closed");

  // EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert multi tick function                                       |
//| Use this function instead of the standard OnTick() function      |
//| OnTick handler                                                   |
//+------------------------------------------------------------------+
void OnTick(string symbol)
{
  // OnTick handler
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
  Print("Connection State: ", Client.state.connect);
  Print("Connection Pings: ", Client.state.pingCount);

  // perform handshake
  if (PerformHandshake(Client) && Client.state.pingCount > 0) {
     // Subscribe to a symbol => NatsSubscribe(Client, "EURUSD", "M1");
      NatsSubscribe(Client, "foo.*", "90");

      // Publish to a symbol
      NatsPublish(Client, "foo.bar", "Hello");

     // Receive message
      NatsReceiveMessage(Client);
  }

  // Print("Interval: ", timerInterval);

  // Get time
  tm = TimeTradeServer();
  // Print("Time: ", tm);
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


// TODO: Remove the chart event handler dependency => OnTickSymbol