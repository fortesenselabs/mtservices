//### <Include/mtTools/HistoryInfo.mqh>
//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.github.com/FortesenseLabs                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280
// - https://www.mql5.com/en/docs/convert/stringtotime
// - https://www.mql5.com/en/docs/basis/types/integer/datetime
// - ejTrader

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.github.com/FortesenseLabs"
#property version "0.10"
#property description "Wise Finance Socket Server History Info Processor"

#include <mtTools/sockets/SocketFunctions.mqh>
#include <mtTools/Types.mqh>
#include <mtTools/Utils.mqh>
#include <mtTools/AppErrors.mqh>

// int MAX_BAR_COUNT = 5000;
// int MAX_TICKS_COUNT = 5000;
int MAX_DATA_COUNT = 1000; // for a one day timeframe: this should give us close to 3 years of data

//+------------------------------------------------------------------+
//| Push historical data to socket                                   |
//+------------------------------------------------------------------+
bool PushHistoricalData(ClientSocket &client, CJAVal &jdata)
{
  string t = jdata.Serialize();

  client.responseData = t;
  ServerSocketSend(client);
  return true;
}

//+------------------------------------------------------------------+
//| Function to retrieve and send tick data                          |
//+------------------------------------------------------------------+
void RetrieveAndSendTickData(ClientSocket &client, string symbol, string chartTimeFrame, datetime fromDate, datetime toDate)
{
  Print("RetrieveAndSendTickData()");

  CJAVal data;
  string tick;
  MqlTick _ticks[];

  // Retrieve fromDate, toDate, and tick data
  ENUM_TIMEFRAMES period = GetTimeframe(chartTimeFrame);

  // Calculate the difference in seconds between fromDate and toDate
  // int diffInSeconds = MathAbs(TimeSeconds(toDate - fromDate));

  // // Check if the difference is more than 5 years (5 * 365 * 24 * 60 * 60 seconds)
  // // 12hrs => 12 * 60 * 60
  // if (diffInSeconds > 12 * 60 * 60)
  // {
  //   // Adjust toDate to be 5 years after fromDate
  //   toDate = TimeAdd(fromDate, PERIOD_YEARS, 5);
  // }

  int tickCount = 0;
  ulong fromDateM = StringToTime(fromDate);
  ulong toDateM = StringToTime(toDate);

  if (CopyTicksRange(symbol, _ticks, COPY_TICKS_ALL, 1000 * (ulong)fromDateM, 1000 * (ulong)toDateM) > 0) {
    int tickCount = ArraySize(_ticks);

    Print("Tick Count: ", tickCount);

    if (tickCount > MAX_DATA_COUNT) {
      SendErrorMessage(client, 02105, "maximum data transfer limit exceeded");
      return;
    }

  for (int i = 0; i < tickCount; i++)
  {
    tick = _ticks[i].time_msc + "||" + _ticks[i].bid + "||" + _ticks[i].ask;

    data["ticks"].Add(tick);

    Print("Tick: ", tick);

    // Error handling
    CheckError(client, __FUNCTION__);
  }

  } else {
      // data["error"] = (bool)false;
      // data["ticks"].Add(tick);
      // data["ticks"] = tick;
      SendErrorMessage(client, 65541, "could not fetch ticks data");
      return;
  }

  data["error"] = (bool)false;
  // PushHistoricalData(client, data);
  string msg = data.Serialize();
  client.responseData = msg;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Function to retrieve and send non-tick data (bar data)           |
//+------------------------------------------------------------------+
void RetrieveAndSendBarData(ClientSocket &client, string symbol, string chartTimeFrame, datetime fromDate, datetime toDate)
{
  CJAVal data;
  string c;
  MqlRates _rates[];
  int spread[];
  int barCount = 0;

  // Retrieve fromDate, toDate, and OHLCV data
  ENUM_TIMEFRAMES period = GetTimeframe(chartTimeFrame);

  if (CopyRates(symbol, period, fromDate, toDate, _rates) > 0) {
    int barCount = ArraySize(_rates);

    Print("Bar Count: ", barCount);
    
    if (barCount > MAX_DATA_COUNT) {
      SendErrorMessage(client, 02104, "maximum data transfer limit exceeded");
      return;
    }

    if (CopySpread(symbol, period, fromDate, toDate, spread) != 1) { 
      /*mControl.Check();*/
      mControl.mSetUserError(65541, GetErrorType(65541));
    }

    for (int i = 0; i < barCount; i++)
    {
      c = _rates[i].time + "||" + _rates[i].open + "||" + _rates[i].high + "||" + _rates[i].low + "||" + _rates[i].close + "||" + _rates[i].tick_volume + "||" + _rates[i].real_volume + "||" + spread[i];

      data["rates"].Add(c);

      Print("Rate: ", c);
    }

    // data["data"].Set(c);
    // Print("Rate: ", r);

  } else {
    // data["data"].Add(c);
    SendErrorMessage(client, 65541, "could not fetch rates data");
    return;
  }

  // data["rates"].Set(r);

  data["symbol"] = symbol;
  data["timeframe"] = chartTimeFrame;
  data["error"] = (bool)false;

  // ... Prepare data and send to the client
  // PushHistoricalData(client, data);
  string msg = data.Serialize();
  client.responseData = msg;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Function to handle trade data                                    |
//+------------------------------------------------------------------+
void HandleTradeData(ClientSocket &client)
{
  CDealInfo tradeInfo;
  CJAVal trades;
  string data;

  if (HistorySelect(0, TimeCurrent()))
  {
    // Get total deals in history
    int total = HistoryDealsTotal();
    ulong ticket; // deal ticket

    for (int i = 0; i < total; i++)
    {
      if ((ticket = HistoryDealGetTicket(i)) > 0)
      {
        tradeInfo.Ticket(ticket);

        data = tradeInfo.Ticket() + "||" + tradeInfo.Time() + "||" + tradeInfo.Price() + "||" + tradeInfo.Volume() + "||" + tradeInfo.Symbol() + "||" + tradeInfo.TypeDescription() + "||" + tradeInfo.Entry() + "||" + tradeInfo.Profit();

        Print("Trade: ", data);

        trades["trades"].Add(data);
      }
    }
  }
  else
  {
    trades["trades"].Add(data);
  }

  trades["error"] = (bool)false;

  // Serialize and send trade data to the client
  string t = trades.Serialize();
  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Validate history info data request                               |
//+------------------------------------------------------------------+
bool ValidateHistoryInfoRequest(RequestData &rdata)
{
  bool valid = true;

  // List of fields to validate
  string fieldsToValidate[] = {
      "actionType",
      "symbol",
      "chartTimeFrame",
      "fromDate"};

  for (int i = 0; i < ArraySize(fieldsToValidate); i++)
  {
    string fieldName = fieldsToValidate[i];
    string value = GetStructFieldValue(rdata, fieldName);

    if (value == NULL)
    {
      Print("Error: Field '" + fieldName + "' is NULL in the request.");
      valid = false;
      break;
    }
  }

  return valid;
}