/* ###################################################################

*SCRIPT*, not EA, which sends a file to the example socket server.

The socket library has versions of ::Send() and ::Receive() which 
take arrays as parameters, instead of strings, letting you send and
receive binary data.

However... the issue then is that TCP/IP communication is not 
message-based. The receiver/server needs some way of knowing when a
file has been completely received. In essence, what you have to do is
implement your own messaging protocol over the top of TCP/IP.
For example, you would send some sort of header meaning "I am about
to send a file"; then you would send the file size; and then you 
would send the actual file data. The receiver/server then needs to
implement this protocol in reverse: look for the header; read the file
size; and keep storing up data until it has collected the expected
amount.

In short: the string versions of ::Send() and ::Receive() provide 
a simple built-in messaging protocol based around use of a terminator
such as \r\n. If you use the array versions of the functions, you then 
have to implement the messaging protocol yourself.

This script, and the corresponding functionality in the example server,
takes a different approach.

The script does the following:

* Reads a file
* ZIP-compresses the file (using built-in MQL CRYPT_ARCH_ZIP)
* Converts the data to a base64 string (using CRYPT_BASE64)
* Adds a header (FILE:) to the message
* Sends the file data as a string, not as an array, making use of
  the \r\n terminator to tell the server that a complete message 
  has been received.
  
The server then reverses this process, looking for the FILE: header,
and converting the received data from base64 and then unzipping it.

This process is relatively inefficient:

* base64 data is one-third larger than sending the raw data would be
* It involves conversions to strings, and string concatenation, which 
  could be avoided by sending binary data
  
But, crucially, this method is simple, and is also more than acceptably
fast with any amount of binary data which you are likely to need 
to send in real life.

################################################################### */


#property strict

#ifdef __MQL5__
#property script_show_inputs
#else
#property show_inputs
#endif

// --------------------------------------------------------------------
// Include socket library
// --------------------------------------------------------------------

#include <socket-library-mt4-mt5.mqh>


// --------------------------------------------------------------------
// Script user inputs 
// --------------------------------------------------------------------

input string   Hostname = "localhost";    // Server hostname or IP address
input ushort   ServerPort = 23456;        // Server port
input string   FileToSend = "send.dat";   // File to send (in MQLx\Files directory)

// --------------------------------------------------------------------
// Tick handling - set up a connection, if none already active,
// and send the current price quote
// --------------------------------------------------------------------

void OnStart()
{
   ClientSocket * socket = new ClientSocket(Hostname, ServerPort);
   if (socket.IsSocketConnected()) {
      Print("Client connection succeeded");
      
      // Open the file and read it 
      int f = FileOpen(FileToSend, FILE_BIN | FILE_READ);
      if (f != INVALID_HANDLE) {
         // Read and close the file 
         uchar arrFile[];
         FileReadArray(f, arrFile);
         FileClose(f);
         
         // Zip-compress the file data 
         uchar arrZip[], dummyKey[];
         if (CryptEncode(CRYPT_ARCH_ZIP, arrFile, dummyKey, arrZip)) {
            
            // Convert to a base64 array
            uchar arrBase64[];
            if (CryptEncode(CRYPT_BASE64, arrZip, dummyKey, arrBase64)) {
               
               // Convert the base64 array to a string 
               string strBase64 = CharArrayToString(arrBase64, 0, WHOLE_ARRAY);
               
               // Send a header, followed by the file data, followed by CRLF as a message terminator 
               socket.Send("FILE:");
               socket.Send(strBase64);
               socket.Send("\r\n");
               
               // Need to wait before terminating the socket
               Print("Sent file data (" , StringLen(strBase64) , " bytes of base64 data)");
               
               // Need to WAIT before destroying the socket, or else the data can be lost.
               // The length of the required delay will depend on the environment - whether we're
               // sending between sockets on the local computer, or whether we're doing a true
               // network send
               Sleep(5000);
               
            } else {
               Print("Failed to convert zipped data to base64");
            }
         } else {
            Print("Failed to zip-encode file");
         }
      
      } else {
         Print("Unable to open " + FileToSend + " file - does it exist?");
      }
   } else {
      Print("Client connection failed");
   }
   delete socket;
}

