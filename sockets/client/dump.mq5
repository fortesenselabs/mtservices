//+------------------------------------------------------------------+
//| for every symbol tick function                                    |
//+------------------------------------------------------------------+
// void OnTick()
// {
//   MqlRates candles[];

//   // Initializing candles
//   ArraySetAsSeries(candles, true);

//   CopyRates(_Symbol, _Period, 0, 1, candles);
//   Print("[INFO]\tSending close price: ", candles[0].close);

// int socket = ConnectSocket(HOST, PORT);
// if (socket != INVALID_HANDLE)
// {
//   // Prepare the POST request
//   string endpoint = "/price/stream";

//   CJAVal jv;
//   jv["symbol"] = (string)_Symbol;
//   jv["period"] = (string)_Period;
//   jv["open"] = candles[0].open;
//   jv["high"] = candles[0].high;
//   jv["low"] = candles[0].low;
//   jv["close"] = candles[0].close;

//   // Serialize to string
//   string postData = jv.Serialize();

//   Print("[POST] Sending Data: ", postData);

//   //--- send POST request to the server
//   if (HTTPPostRequest(socket, endpoint, postData))
//   {
//     Print("POST request sent");

//     //--- read the response
//     if (!HTTPRecv(socket, 1000))
//       Print("Failed to get a response, error ", GetLastError());
//   }
//   else
//     Print("Failed to send POST request, error ", GetLastError());

//   SocketClose(socket);
// }
// }

//+------------------------------------------------------------------+
//| Check if subscribed to symbol and timeframe combination          |
//+------------------------------------------------------------------+
bool HasChartSymbol(string symbol, string chartTimeframe)
{
    for (int i = 0; i < ArraySize(symbolSubscriptions); i++)
    {
        if (symbolSubscriptions[i].symbol == symbol && symbolSubscriptions[i].chartTimeframe == chartTimeframe)
        {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Stream live price data                                           |
//+------------------------------------------------------------------+
void StreamPriceData()
{
    while (!IsStopped())
    {
        if (liveStream)
        {
            Print("StreamPriceData()");
            CJAVal last;
            if (TerminalInfoInteger(TERMINAL_CONNECTED))
            {
                connectedFlag = true;
                for (int i = 0; i < symbolSubscriptionCount; i++)
                {
                    string symbol = symbolSubscriptions[i].symbol;
                    string chartTimeframe = symbolSubscriptions[i].chartTimeframe;
                    datetime lastBar = symbolSubscriptions[i].lastBar;
                    CJAVal Data;
                    ENUM_TIMEFRAMES period = GetTimeframe(chartTimeframe);

                    Print("symbol: ", symbol);
                    Print("chartTimeframe: ", chartTimeframe);
                    Print("period: ", period);

                    datetime thisBar = 0;
                    float price;
                    MqlTick tick;
                    MqlRates rates[1];
                    int spread[1];

                    if (chartTimeframe == "TICK")
                    {
                        if (SymbolInfoTick(symbol, tick) != true)
                        {
                            // Handle error or continue loop
                            continue;
                        }
                        thisBar = (datetime)tick.time_msc;
                    }
                    else
                    {
                        if (CopyRates(symbol, period, 1, 1, rates) != 1)
                        {
                            // Handle error or continue loop
                            continue;
                        }
                        if (CopySpread(symbol, period, 1, 1, spread) != 1)
                        {
                            // Handle error or continue loop
                            continue;
                        }
                        thisBar = (datetime)rates[0].time;
                    }

                    if (lastBar != thisBar)
                    {
                        if (lastBar != 0) // skip first price data after startup/reset
                        {
                            if (chartTimeframe == "TICK")
                            {
                                Data[0] = (long)tick.time_msc;
                                Data[1] = (double)tick.bid;
                                Data[2] = (double)tick.ask;
                            }
                            else
                            {
                                Data[0] = (long)rates[0].time;
                                Data[1] = (double)rates[0].open;
                                Data[2] = (double)rates[0].high;
                                Data[3] = (double)rates[0].low;
                                Data[4] = (double)rates[0].close;
                                Data[5] = (double)rates[0].tick_volume;
                            }
                            last["status"] = "CONNECTED";
                            last["symbol"] = (string)symbol;
                            last["timeframe"] = (string)chartTimeframe;
                            last["data"].Set(Data);

                            string t = last.Serialize();
                            Print(t);
                            if (debug)
                                Print(t);
                            InformServerSocket(liveSocket, t, "STREAM");
                            symbolSubscriptions[i].lastBar = thisBar;
                        }
                        else
                            symbolSubscriptions[i].lastBar = thisBar;
                    }
                }
            }
            else
            {
                // send disconnect message only once
                if (connectedFlag)
                {
                    last["status"] = (string) "DISCONNECTED";
                    string t = last.Serialize();
                    if (debug)
                        Print(t);
                    InformServerSocket(liveSocket, t, "STREAM");
                    connectedFlag = false;
                }
            }
        }
        Sleep(timerInterval); // Wait for 1 second before checking again
    }
}

//+------------------------------------------------------------------+
//| Convert chart timeframe from string to enum                      |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetTimeframe(string chartTimeframe)
{

    ENUM_TIMEFRAMES tf;
    tf = NULL;

    if (chartTimeframe == "TICK")
        tf = PERIOD_CURRENT;

    if (chartTimeframe == "M1")
        tf = PERIOD_M1;

    if (chartTimeframe == "M5")
        tf = PERIOD_M5;

    if (chartTimeframe == "M15")
        tf = PERIOD_M15;

    if (chartTimeframe == "M30")
        tf = PERIOD_M30;

    if (chartTimeframe == "H1")
        tf = PERIOD_H1;

    if (chartTimeframe == "H2")
        tf = PERIOD_H2;

    if (chartTimeframe == "H3")
        tf = PERIOD_H3;

    if (chartTimeframe == "H4")
        tf = PERIOD_H4;

    if (chartTimeframe == "H6")
        tf = PERIOD_H6;

    if (chartTimeframe == "H8")
        tf = PERIOD_H8;

    if (chartTimeframe == "H12")
        tf = PERIOD_H12;

    if (chartTimeframe == "D1")
        tf = PERIOD_D1;

    if (chartTimeframe == "W1")
        tf = PERIOD_W1;

    if (chartTimeframe == "MN1")
        tf = PERIOD_MN1;

    // if tf == NULL an error will be raised in config function
    return (tf);
}

//+------------------------------------------------------------------+

//| Reconfigure the script params                                    |

//+------------------------------------------------------------------+

void ScriptConfiguration()

{

    // string symbol = dataObject["symbol"].ToStr();

    // string chartTimeframe = dataObject["chartTimeframe"].ToStr();

    string symbol = "Step Index";

    string chartTimeframe = "H1";

    ArrayResize(symbolSubscriptions, symbolSubscriptionCount + 1);

    symbolSubscriptions[symbolSubscriptionCount].symbol = symbol;

    symbolSubscriptions[symbolSubscriptionCount].chartTimeframe = chartTimeframe;

    // to initialze with value 0 skips the first price

    symbolSubscriptions[symbolSubscriptionCount].lastBar = 0;

    symbolSubscriptionCount++;

    // mControl.mResetLastError();

    SymbolInfoString(symbol, SYMBOL_DESCRIPTION);

    // if (!CheckError(__FUNCTION__))

    //   ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");
}