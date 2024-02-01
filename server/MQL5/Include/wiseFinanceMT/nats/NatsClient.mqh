//+------------------------------------------------------------------+
//|                                         WiseFinanceNatsClient    |
//|                                 Copyright 2023, Fortesense Labs. |
//|                                      https://www.wisefinance.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance NATS.io Client"

#define MAX_BUFFER_SIZE 4096
#define DEFAULT_SOCKET_MESSAGE_LEN 1024

#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wisefinanceMT/SocketClient.mqh>
#include <wiseFinanceMT/Utils.mqh>

// Sockets
struct NATSClient
{
    SOCKET64 socket;
    string host;
    int port;
    string requestData;
    string responseData;
};

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool NatsSocketSend(NATSClient &client)
{
    char requestBuffer[]; // -> 1024

    int len = StringToCharArray(client.requestData, requestBuffer) - 1;
    if (len < 0)
        return (false);

    //--- if secure TLS connection is used via the port 443
    if (ExtTLS)
        return (SocketTlsSend(client.socket, requestBuffer, len) == len);

    //--- if standard TCP connection is used
    return (SocketSend(client.socket, requestBuffer, len) == len);
}

//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
bool NatsSocketRecv(NATSClient &client)
{
    char responseBuffer[MAX_BUFFER_SIZE];
    string result;

    uint messageLen = GetTickCount() + DEFAULT_SOCKET_MESSAGE_LEN; // timeout or message length

    //--- read data from sockets till they are still present but not longer than timeout or a set message length
    do
    {
        uint len = SocketIsReadable(client.socket);
        if (len)
        {
            int responseBufferLen;
            //--- various reading commands depending on whether the connection is secure or not
            if (ExtTLS)
                responseBufferLen = SocketTlsRead(client.socket, responseBuffer, len);
            else
                responseBufferLen = SocketRead(client.socket, responseBuffer, len, messageLen);

            //--- analyze the response
            if (responseBufferLen > 0)
            {
                result += CharArrayToString(responseBuffer, 0, responseBufferLen);

                //--- print only the response body
                int bodyEnd = StringFind(result, "\r\n");
                if (bodyEnd > 0)
                {
                    // Print("Response => ", result); // debug
                    client.responseData = result;

                    // TODO: Implement a parser for parsing commands
                    //--- parse the body
                    // string body = StringSubstr(result, bodyEnd + 4);
                    return (true);
                }
            }
        }
    } while (GetTickCount() < messageLen && !IsStopped());

    return (false);
}

//+------------------------------------------------------------------+
//| Function to establish a socket connection                        |
//+------------------------------------------------------------------+
NATSClient NAtsConnectSocket(string host, int port)
{
    NATSClient client;

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

            client.socket = socket;
            client.host = host;
            client.port = port;
            return client;
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

    client.socket = INVALID_HANDLE;
    return client;
}

//+------------------------------------------------------------------+
//| server-client handshake                                          |
//+------------------------------------------------------------------+
bool Handshake(NATSClient &client)
{
    if (NatsSocketRecv(client))
    {
        Print("Received INFO Data: ", client.responseData);

        // string request = "CONNECT {\"verbose\":true,\"pedantic\":true,\"tls_required\":false,\"name\":\"MT5\"}\r\n";
        client.requestData = "CONNECT {}\r\n";
        if (NatsSocketSend(client))
        {
            if (NatsSocketRecv(client))
            {
                Print("Received CONNECT data: ", client.responseData);
                return true;
            }
            else
            {
                Print("Handshake failed, error ", GetLastError());
            }
        }
    }

    Print("Failed to send handshake, error ", GetLastError());
    return false;
}

void NAtsCloseSocket(NATSClient &client)
{
    if (client.socket != INVALID_HANDLE)
    {
        SocketClose(client.socket);
        // closesocket(client.socket);
        client.socket = INVALID_HANDLE;
        client.host = "";
        client.port = 0;
    }

    // Clean up Winsock
    // WSACleanup();
}

// Pointers allow us to pass a reference to a variable to a function
// so that the function can modify the variable.
// https://www.learncpp.com/cpp-tutorial/613-pointers-and-arrays/
// They use less memory than passing by value.

// Connection to demo.nats.io:4222 failed, error 4014 => https://www.mql5.com/en/forum/349124
// https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes