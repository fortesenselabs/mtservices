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
#define MAX_SUBSCRIPTIONS 10

#include <wiseFinanceMT/Json.mqh>
#include <wiseFinanceMT/OnTickSymbol.mqh>
#include <wisefinanceMT/SocketClient.mqh>
#include <wiseFinanceMT/Utils.mqh>
// #include <Mql/Collection/HashMap.mqh>


struct Message {
    string Subject;
    string Reply;
    // string Data[];
    // Data    []byte;
    // Subscription Sub;  
};

// Sockets
class ClientSubscription
{
public:
    string subject;
    datetime timestamp;
};

struct ConnectionState {
    bool connect;
    int pingCount;
    int subscribeCount;
    int publishCount;
};

struct NATSClient
{
    SOCKET64 socket;
    string host;
    int port;
    string requestData;
    string responseData;
    ConnectionState state;
    // HashMap<string, string> subscriptions; // sid: subject
    string subscriptions; // subject1:sid1;subject2:sid2 (bad decision, but it's a start)
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
NATSClient NatsConnectSocket(string host, int port)
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
            client.state.connect = false;
            client.state.pingCount = 0;
            client.state.subscribeCount = 0;
            client.state.publishCount = 0;
            client.subscriptions = "";

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
//| server-client handshake connection                               |
//+------------------------------------------------------------------+
bool PerformHandshakeConnection(NATSClient& client)
{
    if (client.state.connect)
    {
        Print("PerformHandshakeConnection => connection still open");
        return true;
    }


    if (NatsSocketRecv(client))
    {
        Print("Received Data: ", client.responseData);

        if (!client.state.connect)
        {
            client.requestData = "CONNECT {}\r\n";
            if (NatsSocketSend(client) && NatsSocketRecv(client))
            {
                Print("Received CONNECT data: ", client.responseData);
                if (StringFind(client.responseData, "OK") != -1)
                {
                    client.state.connect = true;
                }
            }
        }

        return true;
    } 
    
  
    Print("PerformHandshakeConnection => error ", GetLastError());
    
    return false;
}


bool NatsConnectionKeepAlive(NATSClient& client)
{
    Print("Connection Pings: ", Client.state.pingCount);
    Print("Connection State: ", Client.state.connect);

    if (NatsSocketRecv(client))
    {
        Print("Received Data: ", client.responseData);
        
        // Respond to the server's Ping
        if (StringFind(client.responseData, "PING") != -1)
        {
            Print("Found PING data: ", StringFind(client.responseData, "PING"));

            client.requestData = "PONG\r\n";
            if (NatsSocketSend(client))
            {
                client.state.pingCount = client.state.pingCount + 1;
            }
        }

        return true;
    } 
    
    if (client.state.connect && client.state.pingCount > 0)
    {
        Print("NatsConnectionKeepAlive => connection still open");
        return true;
    }

    Print("NatsConnectionKeepAlive => error ", GetLastError());
    
    return false;
}

void NatsCloseSocket(NATSClient &client)
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

//+------------------------------------------------------------------+
//| PUB-SUB Functions                                                |
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| PUBLISH                                                          |
//+------------------------------------------------------------------+
bool NatsPublish(NATSClient &client, string subject, string message)
{
    // PUB foo.bar 5
    // hello
    if (client.state.pingCount > 0)
    {
        client.requestData = "PUB " + subject + " " + IntegerToString(StringLen(message)) + "\r\n" + message + "\r\n";
        if (NatsSocketSend(client) && NatsSocketRecv(client))
        {
            if (StringFind(client.responseData, "OK") != -1)
            {
                client.state.publishCount = client.state.publishCount + 1;

                Print("Published message: ", message);
                return true;
            }
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| SUBSCRIBE                                                        |
//+------------------------------------------------------------------+
bool NatsSubscribe(NATSClient &client, string subject, string sid) // sid = 90
{
    // SUB foo.* 90
    // +OK
    
    Print("client.state.subscribeCount => ", client.state.subscribeCount);

    if (client.state.pingCount <= 0)
    {
        Print("Waiting for server to send PING message");
        return false;
    }

    // if (StringFind(client.subscriptions, subject + ":" + sid) != -1)
    // {
    //     Print("Already subscribed to this subject with this sid");
    //     return false;
    // }

    // how do we keep track of subscriptions?
    // how do we tell the server to stop sending SUB messages? 

    // the client seems to send multiple subscription requests to the server
    // but after MAX_SUBSCRIPTIONS it stops sending requests
    if (client.state.subscribeCount < MAX_SUBSCRIPTIONS) // Ensure index is within bounds
    {
        client.requestData = "SUB " + subject + " " + sid + "\r\n";
        if (NatsSocketSend(client) && NatsSocketRecv(client))
        {
            if (StringFind(client.responseData, "OK") != -1)
            {
                // string subscription = subject;
                // ClientSubscription subscription = new ClientSubscription();
                // subscription.subject = subject;
                // subscription.timestamp = TimeCurrent();

                // TODO: Implement a subscription manager (keep track of subscriptions)
        
                // TODO: use a set to keep track of subscriptions (ArraySet<string> subscriptions; || HashSet<string>)
                // Print("client.subscriptions => ", client.subscriptions.size());

                // TODO: fix invalid pointer access in 'Collection.mqh' (156,10)
                // if (!client.subscriptions.contains(sid))
                // {
                //     Print("Already subscribed to: ", subject);
                //     return false;
                // }

                // client.subscriptions.set(sid, subject);
                // client.subscriptions = client.subscriptions + subject + ":" + sid + ";";
                client.state.subscribeCount = client.state.subscribeCount + 1;

                Print("Subscribed to: ", subject);
                return true;
            }
        }
    } 

    Print("Maximum number of subscriptions reached");
    return false;
}


//+------------------------------------------------------------------+
//| RECEIVE MESSAGE                                                  |
//+------------------------------------------------------------------+
bool NatsReceiveMessage(NATSClient &client)
{
    // MSG foo.bar 90 5
    // hello
    // if (client.state.subscribeCount <= 0)
    // {
    //     Print("No subscription found");
    //     return false;
    // }

    // if (client.state.pingCount > 0)
    // if (StringFind(client.subscriptions, subject + ":" + sid) != -1)
    // {
        if (NatsSocketRecv(client))
        {
            Print("Received message: ", client.responseData);
            if (StringFind(client.responseData, "MSG") != -1)
            {
                // Parse the message and extract the subject, reply subject, and payload
                string message = client.responseData;
                ParseMessage(message);

                return true;
            }
        }
    // }

    return false;
}


// TODO: Implement a parser for parsing commands and messages
void ParseMessage(const string& message)
{
    // MSG foo.bar 90 5
    // hello
    // 
    // Message msg;
    // 
    // Parse the message and extract the subject, reply subject, and payload
    // string command, subject, sid, msgLen, payload;
    // ...
    string result[];               // An array to get strings
    string sep=" ";                // A separator as a character
    ushort u_sep;                  // The code of the separator character

    //--- Get the separator code
    u_sep=StringGetCharacter(sep,0);

    //--- Split the string to substrings
    int k=StringSplit(message,u_sep,result);
  

    PrintFormat("Strings obtained: %d. Used separator '%s' with the code %d",k,sep,u_sep);
    for(int i=0;i<k;i++)
    {
        PrintFormat("String %d: %s",i,result[i]);
    }
}


// Some Potential -> Error Codes:
// -ERR 'Stale Connection'
// -ERR 'Authorization Violation'
// -ERR 'Invalid Subject'
// -ERR 'Slow Consumer'
// -ERR 'Maximum Connections Exceeded'
// -ERR 'Parser Error'
// -ERR 'Unknown Protocol Operation'
// -ERR 'Maximum Payload Violation'
// -ERR 'Invalid Client Protocol'
// -ERR 'Maximum Control Line Exceeded'
// -ERR 'Invalid Client Protocol'

//+------------------------------------------------------------------+

// Pointers allow us to pass a reference to a variable to a function
// so that the function can modify the variable.
// https://www.learncpp.com/cpp-tutorial/613-pointers-and-arrays/
// They use less memory than passing by value.

// Connection to demo.nats.io:4222 failed, error 4014 => https://www.mql5.com/en/forum/349124
// https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes
// https://www.mql5.com/en/docs/network/socketsend