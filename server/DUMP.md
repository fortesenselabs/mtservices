# DUMP

```cpp
// int SocketRecv(SOCKET64 socket, string &body)
// {

//   if (socket != INVALID_SOCKET64)
//   {

//     char buf[1024];

//     int request_len = recv(socket, buf, sizeof(buf), 0);

//     if (request_len > 0)

//     {

//       uchar data[];

//       ArrayCopy(data, buf, ArraySize(data), 0, request_len);

//       string body = CharArrayToString(data);

//       // Pull request to RequestHandler().

//       // RequestHandler(body);

//       // Process received data here

//       // Print("Received Data: ", body);

//       // Example HTTP response

//       // string httpResponseData = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 19\r\n\r\n<html><body>Hello</body></html>";

//       // Send the HTTP response back to the client

//       // SocketSend(socket, httpResponseData);
//     }
//     else if (request_len == 0)
//     {
//       // The client has disconnected
//       closesocket(socket);
//       socket = INVALID_SOCKET64;
//     }
//     else
//     {
//       // An error occurred
//       int err = WSAGetLastError();
//       if (err != WSAEWOULDBLOCK)
//       {
//         Print("recv failed with error: %d\n", err);
//         closesocket(socket);
//         socket = INVALID_SOCKET64;
//       }
//     }
//   }

//   return socket;
// }


// //+------------------------------------------------------------------+
// //| ProcessClientsData                                                        |
// //+------------------------------------------------------------------+
// void ProcessClientsData()
// {
//   for (int i = 0; i < ArraySize(clients); i++)
//   {
//     clients[i] = SocketRecv(clients[i]);
//     //
//     ProcessClientRequest(clients[i]);
//   }
// }


      // Example HTTP response
      // string httpResponseData = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 19\r\n\r\n<html><body>Hello</body></html>";

      // Send the HTTP response back to the client
      // SocketSend(client.socket, httpResponseData);


//+------------------------------------------------------------------+
//| Trading module                                                   |
//+------------------------------------------------------------------+
// void TradingModuleHandler(ClientSocket &client, RequestData &rdata)
// {
//   mControl.mResetLastError();
//   CTrade trade;

//   SymbolInfoString(rdata.symbol, SYMBOL_DESCRIPTION);
//   CheckError(client, __FUNCTION__);

//   // Order expiration section
//   ENUM_ORDER_TYPE_TIME exp_type = ORDER_TIME_GTC;
//   datetime expiration = 0;
//   if (rdata.expiration != 0)
//   {
//     exp_type = ORDER_TIME_SPECIFIED;
//     expiration = rdata.expiration;
//   }

//   // Market orders
//   if (rdata.actionType == "ORDER_TYPE_BUY" || rdata.actionType == "ORDER_TYPE_SELL")
//   {
//     ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
//     price = SymbolInfoDouble(rdata.symbol, SYMBOL_ASK);
//     if (rdata.actionType == "ORDER_TYPE_SELL")
//     {
//       orderType = ORDER_TYPE_SELL;
//       price = SymbolInfoDouble(rdata.symbol, SYMBOL_BID);
//     }

//     if (trade.PositionOpen(rdata.symbol, orderType, rdata.volume, rdata.price, rdata.stoploss, rdata.takeprofit, rdata.comment))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }

//   // Pending orders
//   else if (rdata.actionType == "ORDER_TYPE_BUY_LIMIT" || rdata.actionType == "ORDER_TYPE_SELL_LIMIT" || rdata.actionType == "ORDER_TYPE_BUY_STOP" || rdata.actionType == "ORDER_TYPE_SELL_STOP")
//   {
//     if (rdata.actionType == "ORDER_TYPE_BUY_LIMIT")
//     {
//       if (trade.BuyLimit(volume, price, symbol, SL, TP, ORDER_TIME_GTC, expiration, comment))
//       {
//         OrderDoneOrError(client, false, __FUNCTION__, trade);
//         return;
//       }
//     }
//     else if (rdata.actionType == "ORDER_TYPE_SELL_LIMIT")
//     {
//       if (trade.SellLimit(volume, price, symbol, SL, TP, ORDER_TIME_GTC, expiration, comment))
//       {
//         OrderDoneOrError(client, false, __FUNCTION__, trade);
//         return;
//       }
//     }
//     else if (rdata.actionType == "ORDER_TYPE_BUY_STOP")
//     {
//       if (trade.BuyStop(volume, price, symbol, SL, TP, ORDER_TIME_GTC, expiration, comment))
//       {
//         OrderDoneOrError(client, false, __FUNCTION__, trade);
//         return;
//       }
//     }
//     else if (rdata.actionType == "ORDER_TYPE_SELL_STOP")
//     {
//       if (trade.SellStop(volume, price, symbol, SL, TP, ORDER_TIME_GTC, expiration, comment))
//       {
//         OrderDoneOrError(client, false, __FUNCTION__, trade);
//         return;
//       }
//     }
//   }
//   // Position modify
//   else if (rdata.actionType == "POSITION_MODIFY")
//   {
//     if (trade.PositionModify(idNimber, SL, TP))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Position close partial
//   else if (rdata.actionType == "POSITION_PARTIAL")
//   {
//     if (trade.PositionClosePartial(idNimber, volume))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Position close by id
//   else if (rdata.actionType == "POSITION_CLOSE_ID")
//   {
//     if (trade.PositionClose(idNimber))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Position close by symbol
//   else if (rdata.actionType == "POSITION_CLOSE_SYMBOL")
//   {
//     if (trade.PositionClose(symbol))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Modify pending order
//   else if (rdata.actionType == "ORDER_MODIFY")
//   {
//     if (trade.OrderModify(idNimber, price, SL, TP, ORDER_TIME_GTC, expiration))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Cancel pending order
//   else if (rdata.actionType == "ORDER_CANCEL")
//   {
//     if (trade.OrderDelete(idNimber))
//     {
//       OrderDoneOrError(client, false, __FUNCTION__, trade);
//       return;
//     }
//   }
//   // Action type dosen't exist
//   else
//   {
//     mControl.mSetUserError(65538, GetErrorID(65538));
//     CheckError(client, __FUNCTION__);
//   }

//   // This part of the code runs if order was not completed
//   OrderDoneOrError(client, true, __FUNCTION__, trade);
// }



// void OnTradeTransaction(const MqlTradeTransaction &trans,
//                         const MqlTradeRequest &request,
//                         const MqlTradeResult &result)
// {
//   ENUM_TRADE_TRANSACTION_TYPE trans_type = trans.type;
//   switch (trans.type)
//   {
//   case TRADE_TRANSACTION_REQUEST:
//   {
//     CJAVal data, req, res;

//     req["action"] = EnumToString(request.action);
//     req["order"] = (int)request.order;
//     req["symbol"] = (string)request.symbol;
//     req["volume"] = (double)request.volume;
//     req["price"] = (double)request.price;
//     req["stoplimit"] = (double)request.stoplimit;
//     req["sl"] = (double)request.sl;
//     req["tp"] = (double)request.tp;
//     req["deviation"] = (int)request.deviation;
//     req["type"] = EnumToString(request.type);
//     req["type_filling"] = EnumToString(request.type_filling);
//     req["type_time"] = EnumToString(request.type_time);
//     req["expiration"] = (int)request.expiration;
//     req["comment"] = (string)request.comment;
//     req["position"] = (int)request.position;
//     req["position_by"] = (int)request.position_by;

//     res["retcode"] = (int)result.retcode;
//     res["result"] = (string)GetRetcodeID(result.retcode);
//     res["deal"] = (int)result.order;
//     res["order"] = (int)result.order;
//     res["volume"] = (double)result.volume;
//     res["price"] = (double)result.price;
//     res["comment"] = (string)result.comment;
//     res["request_id"] = (int)result.request_id;
//     res["retcode_external"] = (int)result.retcode_external;

//     data["request"].Set(req);
//     data["result"].Set(res);

//     string t = data.Serialize();
//     client.responseData = t;
//     SocketSend(streamSocket, t);
//   }
//   break;
//   default:
//   {
//   }
//   break;
//   }
// }
```
