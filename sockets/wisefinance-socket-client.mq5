//+------------------------------------------------------------------+
//|                                         WiseFinanceSocketClient  |
//|                                 Copyright 2023, Fortesense Labs. |
//|                                      https://www.wisefinance.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "1.00"
#property description "Wise Finance Socket Client"

#include <Json.mqh>

input string Address = "localhost";
input int Port = 9090;

bool ExtTLS = false;

int timerInterval = 65 * 1000; // Timer interval in milliseconds

MqlRates candles[];

// Function to establish a socket connection
int ConnectSocket(string address, int port)
{
  int socket = SocketCreate();
  if (socket != INVALID_HANDLE)
  {
    if (SocketConnect(socket, address, port, 1000))
    {
      Print("Established connection to ", address, ":", port);
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
      Print("Connection to ", address, ":", port, " failed, error ", GetLastError());
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
          Print("HTTP header received:");
          Print(StringSubstr(result, 0, header_end));

          //--- parse the body
          string body = StringSubstr(result, header_end + 4);
          Print("HTTP body received:");
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
                                       "User-Agent: MT5\r\n"
                                       "\r\n";

  return HTTPSend(socket, request);
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
  int socket = ConnectSocket(Address, Port);
  if (socket != INVALID_HANDLE)
  {
    //--- send GET request to the server
    if (HTTPGetRequest(socket, "", ""))
    {
      Print("GET request sent");

      //--- read the response
      if (!HTTPRecv(socket, 1000))
        Print("Failed to get a response, error ", GetLastError());
    }
    else
      Print("Failed to send GET request, error ", GetLastError());

    SocketClose(socket);
  }
}

//+------------------------------------------------------------------+
//| for every symbol tick function                                    |
//+------------------------------------------------------------------+
void OnTick()
{
  CopyRates(_Symbol, _Period, 0, 1, candles);
  Print("[INFO]\tSending close price: ", candles[0].close);

  int socket = ConnectSocket(Address, Port);
  if (socket != INVALID_HANDLE)
  {
    // Prepare the POST request
    string endpoint = "/price/stream";

    CJAVal jv;
    jv["symbol"] = (string)_Symbol;
    jv["period"] = (string)_Period;
    jv["open"] = candles[0].open;
    jv["high"] = candles[0].high;
    jv["low"] = candles[0].low;
    jv["close"] = candles[0].close;

    // Serialize to string
    string postData = jv.Serialize();

    Print("[POST] Sending Data: ", postData);

    //--- send POST request to the server
    if (HTTPPostRequest(socket, endpoint, postData))
    {
      Print("POST request sent");

      //--- read the response
      if (!HTTPRecv(socket, 1000))
        Print("Failed to get a response, error ", GetLastError());
    }
    else
      Print("Failed to send POST request, error ", GetLastError());

    SocketClose(socket);
  }
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnInit()
{
  // Initializing candles
  ArraySetAsSeries(candles, true);

  // Set up the timer
  EventSetTimer(timerInterval);
}
