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

#include <mtTools/formats/Json.mqh>
#include <mtTools/OnTickSymbol.mqh>
#include <mtTools/Utils.mqh>

// Sockets
int liveSocket;

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
        InformServerSocket(liveSocket, "/api/v1/price/stream/tick", jsonStr, "TICK");

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

    ENUM_TIMEFRAMES period = GetTimeframe(timeframe);

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
        InformServerSocket(liveSocket, "/api/v1/price/stream/bar", jsonStr, "BAR");

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

    sub.chartTimeFrame = timeframe;

    sub.lastBar = 0;

    ArrayResize(symbolSubscriptions, symbolSubscriptionCount + 1);

    symbolSubscriptions[symbolSubscriptionCount] = sub;

    symbolSubscriptionCount++;

    Print("[BAR] Subscribed to ", symbol, " (", timeframe, ")");
}

//+------------------------------------------------------------------+
//| Note: Compile the Multi-currency Indicator First                 |
//+------------------------------------------------------------------+

// https://www.mql5.com/en/articles/159
// https://www.mql5.com/en/forum/367260
// https://www.mql5.com/en/articles/599
// https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes