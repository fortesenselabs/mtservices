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

#define CHART_EVENT_SYMBOL CHARTEVENT_TICK

#include <wiseFinanceMT/Json.mqh>

#include <wiseFinanceMT/OnTickSymbol.mqh>

// Set host and Port

input string HOST = "localhost";

input int PORT = 9090;

bool ExtTLS = false; // for TLS socket connections

// Global variables

int timerInterval = 5 * 1000; // Timer interval in milliseconds

bool debug = true;

bool liveStream = true;

bool connectedFlag = true;

int deInitReason = -1;

// sockets

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

//| Inform Server via socket                                         |

//+------------------------------------------------------------------+

void InformServerSocket(int socket, string endpoint, string data, string socketType)

{

  if (socket != INVALID_HANDLE)

  {

    Print("[POST] Sending Data: ", data);

    //--- send POST request to the server

    if (HTTPPostRequest(socket, endpoint, data))

    {

      Print("POST request sent");

      //--- read the response

      if (!HTTPRecv(socket, 1000))

        Print("Failed to get a response, error ", GetLastError());
    }

    else

      Print("Failed to send POST request, error ", GetLastError());
  }
}

//+------------------------------------------------------------------+

//| Expert multi tick function                                       |

//| Use this function instead of the standard OnTick() function      |

//+------------------------------------------------------------------+

void OnTick(string symbol)

{
  Print("New event on symbol: ", symbol);

  MqlTick tick;

  CJAVal last;

  CJAVal Data;

  if (SymbolInfoTick(symbol, tick) != true)
  {
  }

  Data[0] = (long)tick.time_msc;

  Data[1] = (double)tick.bid;

  Data[2] = (double)tick.ask;

  last["symbol"] = symbol;

  last["timeframe"] = (string)PERIOD_CURRENT;

  last["data"].Set(Data);

  string ticks = last.Serialize();

  Print("ticks: ", ticks);

  InformServerSocket(liveSocket, "/price/tick", ticks, "");
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
}

//+------------------------------------------------------------------+

//| Timer event handler                                              |

//+------------------------------------------------------------------+

// Timer event handler

void OnTimer()

{

  // Connect to the socket

  int socket = ConnectSocket(HOST, PORT);
  // int socket = liveSocket;

  if (socket != INVALID_HANDLE)

  {

    // we can also check if a socket connection is available
    // Send GET request to the server

    if (HTTPGetRequest(socket, "", ""))

    {

      Print("GET request sent");

      // Read the response

      if (!HTTPRecv(socket, 1000))

        Print("Failed to get a response, error ", GetLastError());
    }

    else

      Print("Failed to send GET request, error ", GetLastError());

    SocketClose(socket);
  }
}

//+------------------------------------------------------------------+

//| Expert initialization function                                   |

//+------------------------------------------------------------------+

void OnInit()

{

  //

  liveSocket = ConnectSocket(HOST, PORT);

  //

  // ScriptConfiguration();

  // Set up the timer

  EventSetTimer(timerInterval);
}