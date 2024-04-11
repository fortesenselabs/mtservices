#include <mtTools/sockets/SocketFunctions.mqh>
#include <mtTools/Types.mqh>
#include <mtTools/formats/Json.mqh>


//+------------------------------------------------------------------+
//| Action confirmation                                              |
//+------------------------------------------------------------------+
void ActionDoneOrError(ClientSocket &client, int lastError, string funcName, string desc)
{

  CJAVal conf;

  conf["error"] = (bool)true;
  if (lastError == 0)
    conf["error"] = (bool)false;

  conf["lastError"] = (string)lastError;
  conf["description"] = (string)desc;
  conf["function"] = (string)funcName;

  string t = conf.Serialize();
  client.responseData = t;
  ServerSocketSend(client);
}

/**
 * Generates an error message with the given type and message.
 *
 * @param type The error type.
 * @param message The error message.
 * @return The generated error message.
 */
string generateErrorMessage(string errorType, string message)
{
  return "error=true|type=" + errorType + "|message=" + message + "\r\n";
}

void SendErrorMessage(ClientSocket &client, int errorID, string message) {
    CJAVal info;

    info["error"] = true;
    info["type"] = GetErrorType(errorID);
    info["message"] = message;

    string errMessage = info.Serialize();
    Print(errMessage);

    client.responseData = errMessage;
    ServerSocketSend(client);
    closesocket(client.socket);
    return;

    // if (ServerSocketSend(client)) {
        // Close the client socket
        // closesocket(client.socket);
        // return true;
    // }

    // return false;
}