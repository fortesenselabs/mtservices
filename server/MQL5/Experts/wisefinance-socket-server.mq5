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
// #define  SYMBOLS_TRADING    "EURUSD","GBPUSD","USDJPY","USDCHF"
#define SYMBOLS_TRADING "Step Index", "Boom 1000 Index", "Volatility 100 Index", "Volatility 25 Index" // get all symbols
#define CHART_EVENT_SYMBOL CHARTEVENT_ALL

#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/Trade.mqh>
#include <StringToEnumInt.mqh>

// Load wiseFinanceMT includes
// Required:

#include <wiseFinanceMT/ControlErrors.mqh>
#include <wisefinanceMT/SocketServer.mqh>
#include <wisefinanceMT/RequestHandlers.mqh>
#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wiseFinanceMT/Calendar.mqh>
#include <wiseFinanceMT/Utils.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 9000; // int

// Global variables

// Timer interval in milliseconds
int timerInterval = 3 * 1000;
bool debug = true;

// Variables for handling price data stream
bool liveStream = false;

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
  // Setting up error reporting
  mControl.SetAlert(true);
  mControl.SetSound(false);
  mControl.SetWriteFlag(false);

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
