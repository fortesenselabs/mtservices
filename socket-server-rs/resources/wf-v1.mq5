//+------------------------------------------------------------------+

//|                                                SocketExample.mq5 |

//|                        Copyright 2018, MetaQuotes Software Corp. |

//|                                             https://www.mql5.com |

//+------------------------------------------------------------------+

#property copyright "Copyright 2018, MetaQuotes Software Corp."

#property link "https://www.mql5.com"

#property version "1.00"

#property description "Add Address to the list of allowed ones in the terminal settings to let the example work"

#property script_show_inputs

input string Address = "localhost";

input int Port = 9090;

bool ExtTLS = false;

int serverTimeout = 5000;

MqlRates candles[];

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
//| for every symbol tick function                                    |
//+------------------------------------------------------------------+

void OnTick()
{
    CopyRates(_Symbol, _Period, 0, 1, candles);
}
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    // Initializing candles
    ArraySetAsSeries(candles, true);

    while (!IsStopped())
    {
        int socket = SocketCreate();

        //--- check the handle
        if (socket != INVALID_HANDLE)
        {
            //--- connect if all is well
            if (SocketConnect(socket, Address, Port, 1000))
            {
                Print("Established connection to ", Address, ":", Port);
                string subject, issuer, serial, thumbprint;
                datetime expiration;

                //--- if connection is secured by the certificate, display its data
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

                //--- send GET request to the server
                if (HTTPSend(socket, "GET / HTTP/1.1\r\nHost: www.mql5.com\r\nUser-Agent: MT5\r\n\r\n"))
                {
                    Print("GET request sent");

                    //--- read the response
                    if (!HTTPRecv(socket, 1000))
                        Print("Failed to get a response, error ", GetLastError());
                }
                else
                    Print("Failed to send GET request, error ", GetLastError());
            }
            else
                Print("Connection to ", Address, ":", Port, " failed, error ", GetLastError());

            //--- close a socket after using
            SocketClose(socket);
        }
        else
            Print("Failed to create a socket, error ", GetLastError());

        Sleep(serverTimeout); // Wait for N seconds before checking the server again
    }
}
