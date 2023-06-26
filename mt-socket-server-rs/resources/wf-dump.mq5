//+------------------------------------------------------------------+
//| Example usage of sending a POST request                          |
//+------------------------------------------------------------------+

void SendPostRequest(string url, string data)
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

            //--- send POST request to the server
            if (HTTPPost(socket, url, data))
            {
                Print("POST request sent");

                //--- read the response
                if (!HTTPRecv(socket, 1000))
                    Print("Failed to get a response, error ", GetLastError());
            }
            else
                Print("Failed to send POST request, error ", GetLastError());
        }
        else
            Print("Connection to ", Address, ":", Port, " failed, error ", GetLastError());

        //--- close a socket after using
        SocketClose(socket);
    }
    else
        Print("Failed to create a socket, error ", GetLastError());
}