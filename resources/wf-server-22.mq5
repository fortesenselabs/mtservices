//+------------------------------------------------------------------+
//| WiseFinanceSocketServer                                          |
//| Copyright 2023, Fortesense Labs.                                  |
//| https://www.wisefinance.com                                       |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance Socket Server"

#define SYMBOLS_TRADING "Step Index", "Boom 1000 Index", "Volatility 100 Index", "Volatility 25 Index"
#define CHART_EVENT_SYMBOL CHARTEVENT_ALL

#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/Trade.mqh>
#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wisefinanceMT/Socketlib.mqh>
#include <wiseFinanceMT/ControlErrors.mqh>
#include <StringToEnumInt.mqh>

// Load wiseFinanceMT includes
// Required:
// #include <wiseFinanceMT/HistoryInfo.mqh>
// #include <wiseFinanceMT/Broker.mqh>
// #include <wiseFinanceMT/Calendar.mqh>
// Optional:
// #include <wiseFinanceMT/StartIndicator.mqh>
// #include <wiseFinanceMT/ChartControl.mqh>

// Set host and Port
input string HOST = "0.0.0.0";
input ushort PORT = 8000; // int

// Global variables
bool debug = true;
bool liveStream = false;
bool connectedFlag = true;
int deInitReason = -1;

// Sockets
SOCKET64 serverSocket = INVALID_SOCKET64;
SOCKET64 clients[1024];

// Timer interval in milliseconds
int timerInterval = 3 * 1000;

// Variables for handling price data stream
struct SymbolSubscription
{
    string symbol;
    string chartTf;
    datetime lastBar;
};

SymbolSubscription symbolSubscriptions[];
int symbolSubscriptionCount = 0;

// Error handling
ControlErrors mControl;
datetime tm;

//+------------------------------------------------------------------+
//| Get Data from Socket                                             |
//+------------------------------------------------------------------+
string GetDataFromSocket(SOCKET64 socket, string &body)
{
    if (socket != INVALID_SOCKET64)
    {
        Print("socket received");
        return SocketRecv(socket, body);
    }
    return "";
}

//+------------------------------------------------------------------+
//| Send Socket response                                             |
//+------------------------------------------------------------------+
int SocketSend(SOCKET64 socket, string data)
{
    uchar response[];
    int len = StringToCharArray(data, response) - 1;
    if (len < 0)
    {
        return 0;
    }
    // Send the HTTP response back to the client
    return send(socket, response, ArraySize(response), 0);
}

//+------------------------------------------------------------------+
//| Read Socket request                                              |
//+------------------------------------------------------------------+
int SocketRecv(SOCKET64 socket, string &body)
{
    if (socket != INVALID_SOCKET64)
    {
        char buf[4096];
        int request_len = recv(socket, buf, sizeof(buf), 0);
        if (request_len > 0)
        {
            uchar data[];
            ArrayCopy(data, buf, ArraySize(data), 0, request_len);
            body = CharArrayToString(data); // Store received data in the 'body' string.
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
                Print("recv failed with error: ", err);
                closesocket(socket);
                socket = INVALID_SOCKET64;
            }
        }
    }
    return socket;
}

//+------------------------------------------------------------------+
//| AcceptClients                                                    |
//+------------------------------------------------------------------+
void AcceptClients()
{
    if (serverSocket == INVALID_SOCKET64)
    {
        return;
    }
    // Accept any new incoming connections
    SOCKET64 client = INVALID_SOCKET64;
    ref_sockaddr clientAddress;
    int addressSize = sizeof(ref_sockaddr);
    client = accept(serverSocket, clientAddress.ref, addressSize);
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
//| StartServer                                                      |
//+------------------------------------------------------------------+
bool StartServer(string addr, ushort port)
{
    bool result = false;
    // Initialize the library
    char wsaData[];
    ArrayResize(wsaData, sizeof(WSAData));
    int res = WSAStartup(MAKEWORD(2, 2), wsaData);
    if (res != 0)
    {
        Print("-WSAStartup failed error: " + string(res));
        return result;
    }
    // Create a socket
    serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (serverSocket == INVALID_SOCKET64)
    {
        Print("-Create failed error: " + WSAErrorDescript(WSAGetLastError()));
        return result;
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
            return result;
        }
    }
    // Set to non-blocking mode
    int non_block = 1;
    res = ioctlsocket(serverSocket, (int)FIONBIO, non_block);
    if (res != NO_ERROR)
    {
        Print("ioctlsocket failed error: " + string(res));
        return result;
    }
    // Listen on the port and accept client connections
    if (listen(serverSocket, SOMAXCONN) == SOCKET_ERROR)
    {
        Print("Listen failed with error: ", WSAErrorDescript(WSAGetLastError()));
        return result;
    }
    return !result;
}

//+------------------------------------------------------------------+
//| CloseServer                                                      |
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
    if (serverSocket != INVALID_SOCKET64)
    {
        closesocket(serverSocket);
        serverSocket = INVALID_SOCKET64;
    }
    // Clean up Winsock
    WSACleanup();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
    // Setting up error reporting
    mControl.SetAlert(true);
    mControl.SetSound(false);
    mControl.SetWriteFlag(false);
    // Skip reloading of the EA script when the reason to reload is a chart timeframe change
    if (deInitReason != REASON_CHARTCHANGE)
    {
        EventSetMillisecondTimer(1);
        Print("Starting Server!!!");
        StartServer(HOST, PORT);
        Print("Server Started successfully...");
    }
}

//+------------------------------------------------------------------+
//| OnDeinit handler                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Close the server socket
    CloseServer();
    // TODO Ports do not get freed immediately under Wine. How to properly close ports? There is a timeout of about 60 sec.
    // https://forum.winehq.org/viewtopic.php?t=22758
    // https://github.com/zeromq/cppzmq/issues/139
    deInitReason = reason;
    // Print a message to the console
    printf("Server Socket connection closed\n");
    // Reset
    ResetSubscriptionsAndIndicators();
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Check if subscribed to symbol and timeframe combination          |
//+------------------------------------------------------------------+
bool HasChartSymbol(string symbol, string chartTF)
{
    for (int i = 0; i < ArraySize(symbolSubscriptions); i++)
    {
        if (symbolSubscriptions[i].symbol == symbol && symbolSubscriptions[i].chartTf == chartTF)
        {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Accept any new incoming connections
    AcceptClients();
    // Check for data from any of the clients
    ProcessClientsData();
    tm = TimeTradeServer();
}

//+------------------------------------------------------------------+
//| ProcessClientsData                                               |
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
        string data;
        clients[i] = SocketRecv(clients[i], data);
        ProcessClientRequest(clients[i]);
    }
}

//+------------------------------------------------------------------+
//| Process Client Request and Respond                               |
//+------------------------------------------------------------------+
void ProcessClientRequest(SOCKET64 clientSocket)
{
    char buffer[4096];
    // Get data from request
    string msg;
    int bytesRead = SocketRecv(clientSocket, msg);
    if (bytesRead <= 0)
    {
        // Error or connection closed
        closesocket(clientSocket);
        return;
    }
    RequestHandler(msg);
}

//+------------------------------------------------------------------+
//| Request handler - process commands                               |
//+------------------------------------------------------------------+
void RequestHandler(string msg)
{
    CJAVal incomingMessage;
    ResetLastError();
    if (debug)
        Print("Processing:" + msg);
    if (!incomingMessage.Deserialize(msg))
    {
        mControl.mSetUserError(65537, GetErrorID(65537));
        CheckError(__FUNCTION__);
    }
    // Send response to System socket that request was received
    // Some historical data requests can take a lot of time
    // InformClientSocket(socket, "OK");
    // Process action command
    Print("incoming message: ", &incomingMessage);
    string action = incomingMessage["action"].ToStr();
    if (action == "CONFIG")
    {
        ScriptConfiguration(incomingMessage);
    }
    else if (action == "ACCOUNT")
    {
        GetAccountInfo();
    }
    else
    {
        mControl.mSetUserError(65538, GetErrorID(65538));
        CheckError(__FUNCTION__);
    }
}

//+------------------------------------------------------------------+
//| Reconfigure the script params                                    |
//+------------------------------------------------------------------+
void ScriptConfiguration(CJAVal &dataObject)
{
    string symbol = dataObject["symbol"].ToStr();
    string chartTF = dataObject["chartTF"].ToStr();
    ArrayResize(symbolSubscriptions, symbolSubscriptionCount + 1);
    symbolSubscriptions[symbolSubscriptionCount].symbol = symbol;
    symbolSubscriptions[symbolSubscriptionCount].chartTf = chartTF;
    // to initialize with value 0 skips the first price
    symbolSubscriptions[symbolSubscriptionCount].lastBar = 0;
    symbolSubscriptionCount++;
    mControl.mResetLastError();
    SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
    if (!CheckError(__FUNCTION__))
    {
        ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");
    }
}

//+------------------------------------------------------------------+
//| Account information                                              |
//+------------------------------------------------------------------+
void GetAccountInfo()
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
    info["time"] = string(tm); // sending time to ejtraderMT for localtime data frame
    string t = info.Serialize();
    if (debug)
        Print(t);
    // InformClientSocket(serverSocket, t);
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
//| This function must be declared, even if it's empty.               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event id
                  const long &lparam,   // event param of long type
                  const double &dparam, // event param of double type
                  const string &sparam) // event param of string type
{
    // Print("OnChartEvent id: ", id);
    // Print("OnChartEvent lparam: ", lparam);
    // Print("OnChartEvent dparam: ", dparam);
    // Print("OnChartEvent sparam: ", sparam);
}

//+------------------------------------------------------------------+
//| Convert chart timeframe from string to enum                      |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetTimeframe(string chartTF)
{
    ENUM_TIMEFRAMES tf;
    tf = NULL;
    if (chartTF == "TICK")
        tf = PERIOD_CURRENT;
    if (chartTF == "M1")
        tf = PERIOD_M1;
    if (chartTF == "M5")
        tf = PERIOD_M5;
    if (chartTF == "M15")
        tf = PERIOD_M15;
    if (chartTF == "M30")
        tf = PERIOD_M30;
    if (chartTF == "H1")
        tf = PERIOD_H1;
    if (chartTF == "H2")
        tf = PERIOD_H2;
    if (chartTF == "H3")
        tf = PERIOD_H3;
    if (chartTF == "H4")
        tf = PERIOD_H4;
    if (chartTF == "H6")
        tf = PERIOD_H6;
    if (chartTF == "H8")
        tf = PERIOD_H8;
    if (chartTF == "H12")
        tf = PERIOD_H12;
    if (chartTF == "D1")
        tf = PERIOD_D1;
    if (chartTF == "W1")
        tf = PERIOD_W1;
    if (chartTF == "MN1")
        tf = PERIOD_MN1;
    // if tf == NULL an error will be raised in the config function
    return (tf);
}

//+------------------------------------------------------------------+
//| Trade confirmation                                               |
//+------------------------------------------------------------------+
void OrderDoneOrError(bool error, string funcName, CTrade &trade)
{
    CJAVal conf;
    conf["error"] = (bool)error;
    conf["retcode"] = (int)trade.ResultRetcode();
    conf["desription"] = (string)GetRetcodeID(trade.ResultRetcode());
    // conf["deal"]=(int) trade.ResultDeal();
    conf["order"] = (int)trade.ResultOrder();
    conf["volume"] = (double)trade.ResultVolume();
    conf["price"] = (double)trade.ResultPrice();
    conf["bid"] = (double)trade.ResultBid();
    conf["ask"] = (double)trade.ResultAsk();
    conf["function"] = (string)funcName;
    string t = conf.Serialize();
    if (debug)
        Print(t);
    // InformClientSocket(serverSocket, t);
}

//+------------------------------------------------------------------+
//| Error reporting                                                  |
//+------------------------------------------------------------------+
bool CheckError(string funcName)
{
    int lastError = mControl.mGetLastError();
    if (lastError)
    {
        string desc = mControl.mGetDesc();
        if (debug)
            Print("Error handling source: ", funcName, " description: ", desc);
        Print("Error handling source: ", funcName, " description: ", desc);
        mControl.Check();
        ActionDoneOrError(lastError, funcName, desc);
        return true;
    }
    else
        return false;
}

//+------------------------------------------------------------------+
//| Action confirmation                                              |
//+------------------------------------------------------------------+
void ActionDoneOrError(int lastError, string funcName, string desc)
{
    CJAVal conf;
    conf["error"] = (bool)true;
    if (lastError == 0)
        conf["error"] = (bool)false;
    conf["lastError"] = (string)lastError;
    conf["description"] = (string)desc;
    conf["function"] = (string)funcName;
    string t = conf.Serialize();
    if (debug)
        Print(t);

    // InformClientSocket(serverSocket, t);
}

//+------------------------------------------------------------------+
//| Inform Client via socket                                         |
//+------------------------------------------------------------------+
void InformClientSocket(SOCKET64 &socket, string data)
{
    // non-blocking
    // workingSocket.send(data, true);
    SocketSend(socket, data);
    // TODO: Array out of range error
    mControl.mResetLastError();
    // mControl.Check();
}

//+------------------------------------------------------------------+
//| Clear symbol subscriptions and indicators                        |
//+------------------------------------------------------------------+
void ResetSubscriptionsAndIndicators()
{
    ArrayFree(symbolSubscriptions);
    symbolSubscriptionCount = 0;
    bool error = false;
    ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");
}

//+------------------------------------------------------------------+
//| Get retcode message by retcode id                                |
//+------------------------------------------------------------------+
string GetRetcodeID(int retcode)
{
    switch (retcode)
    {
    case 10004:
        return ("TRADE_RETCODE_REQUOTE");
        break;
    case 10006:
        return ("TRADE_RETCODE_REJECT");
        break;
    case 10007:
        return ("TRADE_RETCODE_CANCEL");
        break;
    case 10008:
        return ("TRADE_RETCODE_PLACED");
        break;
    case 10009:
        return ("TRADE_RETCODE_DONE");
        break;
    case 10010:
        return ("TRADE_RETCODE_DONE_PARTIAL");
        break;
    case 10011:
        return ("TRADE_RETCODE_ERROR");
        break;
    case 10012:
        return ("TRADE_RETCODE_TIMEOUT");
        break;
    case 10013:
        return ("TRADE_RETCODE_SO_MANY_REQUESTS");
        break;
    case 10014:
        return ("TRADE_RETCODE_NO_MONEY");
        break;
    case 10015:
        return ("TRADE_RETCODE_PRICE_CHANGED");
        break;
    case 10016:
        return ("TRADE_RETCODE_SERVER_DISABLES_AT");
        break;
    default:
        return ("TRADE_RETCODE_UNKNOWN");
    }
}

//+------------------------------------------------------------------+
