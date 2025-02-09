//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.github.com/FortesenseLabs                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280
// - ejTrader

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.github.com/FortesenseLabs"
#property version "0.10"
#property description "Wise Finance Socket Server Trading Request Processor"

#include <Trade/Trade.mqh>
// #include <Trade\PositionInfo.mqh>
#include <mtTools/formats/Json.mqh>
#include <mtTools/sockets/SocketFunctions.mqh>
#include <mtTools/Types.mqh>
#include <mtTools/Utils.mqh>

//+------------------------------------------------------------------+
//| Trade confirmation                                               |
//+------------------------------------------------------------------+
void OrderDoneOrError(ClientSocket &client, bool error, string funcName, CTrade &trade)
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
  client.responseData = t;
  ServerSocketSend(client);
}

// Check if it's a market order
bool IsMarketOrder(string actionType)
{
  return (actionType == "ORDER_TYPE_BUY" || actionType == "ORDER_TYPE_SELL");
}

// Check if it's a pending order
bool IsPendingOrder(string actionType)
{
  return (actionType == "ORDER_TYPE_BUY_LIMIT" || actionType == "ORDER_TYPE_SELL_LIMIT" || actionType == "ORDER_TYPE_BUY_STOP" || actionType == "ORDER_TYPE_SELL_STOP");
}

// Check if it's a position modify action
bool IsPositionModify(string actionType)
{
  return (actionType == "POSITION_MODIFY");
}

// Check if it's a position close partial action
bool IsPositionClosePartial(string actionType)
{
  return (actionType == "POSITION_PARTIAL");
}

// Check if it's a position close by ID action
bool IsPositionCloseById(string actionType)
{
  return (actionType == "POSITION_CLOSE_ID");
}

// Check if it's a position close by symbol action
bool IsPositionCloseBySymbol(string actionType)
{
  return (actionType == "POSITION_CLOSE_SYMBOL");
}

// Check if it's an order modify action
bool IsOrderModify(string actionType)
{
  return (actionType == "ORDER_MODIFY");
}

// Check if it's an order cancel action
bool IsOrderCancel(string actionType)
{
  return (actionType == "ORDER_CANCEL");
}

// Place market order
bool PlaceMarketOrder(CTrade &trade, TradeRequestData &rdata, double price)
{
  ENUM_ORDER_TYPE orderType = (rdata.actionType == "ORDER_TYPE_SELL") ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
  return trade.PositionOpen(rdata.symbol, orderType, rdata.volume, price, rdata.stoploss, rdata.takeprofit, rdata.comment);
}

// Place pending order
bool PlacePendingOrder(CTrade &trade, TradeRequestData &rdata, double price, ENUM_ORDER_TYPE_TIME exp_type, datetime expiration)
{
  if (rdata.actionType == "ORDER_TYPE_BUY_LIMIT")
  {
    return trade.BuyLimit(rdata.volume, price, rdata.symbol, rdata.stoploss, rdata.takeprofit, exp_type, expiration, rdata.comment);
  }
  else if (rdata.actionType == "ORDER_TYPE_SELL_LIMIT")
  {
    return trade.SellLimit(rdata.volume, price, rdata.symbol, rdata.stoploss, rdata.takeprofit, exp_type, expiration, rdata.comment);
  }
  else if (rdata.actionType == "ORDER_TYPE_BUY_STOP")
  {
    return trade.BuyStop(rdata.volume, price, rdata.symbol, rdata.stoploss, rdata.takeprofit, exp_type, expiration, rdata.comment);
  }
  else if (rdata.actionType == "ORDER_TYPE_SELL_STOP")
  {
    return trade.SellStop(rdata.volume, price, rdata.symbol, rdata.stoploss, rdata.takeprofit, exp_type, expiration, rdata.comment);
  }

  return false;
}

// Modify a position
bool ModifyPosition(CTrade &trade, ulong ticketId, double stoploss, double takeprofit)
{
  return trade.PositionModify(ticketId, stoploss, takeprofit);
}

// Close a position partially
bool ClosePartialPosition(CTrade &trade, ulong ticketId, double volume)
{
  return trade.PositionClosePartial(ticketId, volume);
}

// Close a position by ID
bool ClosePositionByTicketId(CTrade &trade, ulong ticketId)
{
  return trade.PositionClose(ticketId);
}

// Close a position by symbol
bool ClosePositionBySymbol(CTrade &trade, string symbol)
{
  return trade.PositionClose(symbol);
}

// Modify an order
bool ModifyOrder(CTrade &trade, ulong ticketId, double price, double stoploss, double takeprofit, int expiration)
{
  ENUM_ORDER_TYPE_TIME exp_type = ORDER_TIME_GTC;
  datetime dtExpiration = 0;

  if (expiration != 0)
  {
    exp_type = ORDER_TIME_SPECIFIED;
    dtExpiration = expiration;
  }

  return trade.OrderModify(ticketId, price, stoploss, takeprofit, exp_type, dtExpiration);
}

// Cancel an order
bool CancelOrder(CTrade &trade, ulong ticketId)
{
  return trade.OrderDelete(ticketId);
}

//+------------------------------------------------------------------+
//| Trading module                                                   |
//+------------------------------------------------------------------+
void TradingModule(ClientSocket &client, TradeRequestData &rdata)
{
  mControl.mResetLastError();
  CTrade trade;

  SymbolInfoString(rdata.symbol, SYMBOL_DESCRIPTION);
  CheckError(client, __FUNCTION__);

  ENUM_ORDER_TYPE_TIME exp_type = ORDER_TIME_GTC;
  datetime expiration = 0;

  if (rdata.expiration != 0)
  {
    exp_type = ORDER_TIME_SPECIFIED;
    expiration = rdata.expiration;
  }

  double price = (rdata.actionType == "ORDER_TYPE_SELL") ? SymbolInfoDouble(rdata.symbol, SYMBOL_BID) : SymbolInfoDouble(rdata.symbol, SYMBOL_ASK);

  if (IsMarketOrder(rdata.actionType))
  {
    if (PlaceMarketOrder(trade, rdata, price))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsPendingOrder(rdata.actionType))
  {
    if (PlacePendingOrder(trade, rdata, price, exp_type, expiration))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsPositionModify(rdata.actionType))
  {
    if (ModifyPosition(trade, rdata.id, rdata.stoploss, rdata.takeprofit))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsPositionClosePartial(rdata.actionType))
  {
    if (ClosePartialPosition(trade, rdata.id, rdata.volume))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsPositionCloseById(rdata.actionType))
  {
    if (ClosePositionByTicketId(trade, rdata.id))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsPositionCloseBySymbol(rdata.actionType))
  {
    Print("rdata.symbol: ", rdata.symbol);
    if (ClosePositionBySymbol(trade, rdata.symbol))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsOrderModify(rdata.actionType))
  {
    if (ModifyOrder(trade, rdata.id, rdata.price, rdata.stoploss, rdata.takeprofit, rdata.expiration))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else if (IsOrderCancel(rdata.actionType))
  {
    if (CancelOrder(trade, rdata.id))
    {
      OrderDoneOrError(client, false, __FUNCTION__, trade);
      return;
    }
  }
  else
  {
    mControl.mSetUserError(65538, GetErrorType(65538));
    CheckError(client, __FUNCTION__);
  }

  // This part of the code runs if the order was not completed
  OrderDoneOrError(client, true, __FUNCTION__, trade);
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
  ENUM_TRADE_TRANSACTION_TYPE trans_type = trans.type;

  switch (trans.type)
  {
  case TRADE_TRANSACTION_REQUEST:
    ProcessTradeRequest(request, result);
    break;

  default:
    // Handle other transaction types if needed.
    break;
  }
}

void ProcessTradeRequest(const MqlTradeRequest &request, const MqlTradeResult &result)
{
  Print("ProcessTradeRequest => ", result.request_id, result.retcode);

  // CJAVal data;
  // CJAVal req = ConvertRequestToCJAVal(request);
  // CJAVal res = ConvertResultToCJAVal(result);

  // data["request"].Set(req);
  // data["result"].Set(res);

  // Print("ProcessTradeRequest => ", &data);
  // Check for data from any of the clients
  // for (int i = 0; i < ArraySize(clients); i++)
  // {
  //   CJAVal dataObject;

  //   if (StringLen(clients[i].requestData) > 0 && !dataObject.Deserialize(clients[i].requestData))
  //   {
  //     Print("Failed to deserialize request command");
  //     mControl.mSetUserError(65537, GetErrorType(65537));
  //     CheckError(clients[i], __FUNCTION__);
  //   }

  // int id = (int)dataObject["id"].ToInt();
  // if (clients[i].socket != INVALID_SOCKET64 && req["order"] == id)
  //   if (clients[i].socket != INVALID_SOCKET64)
  //   {
  //     string serializedData = data.Serialize();
  //     clients[i].responseData = serializedData;
  //     ServerSocketSend(clients[i]);
  //   }
  // }
}

CJAVal ConvertRequestToCJAVal(const MqlTradeRequest &request)
{
  CJAVal req;
  req["action"] = EnumToString(request.action);
  req["order"] = (int)request.order;
  req["symbol"] = (string)request.symbol;
  req["volume"] = (double)request.volume;
  req["price"] = (double)request.price;
  req["stoplimit"] = (double)request.stoplimit;
  req["sl"] = (double)request.sl;
  req["tp"] = (double)request.tp;
  req["deviation"] = (int)request.deviation;
  req["type"] = EnumToString(request.type);
  req["type_filling"] = EnumToString(request.type_filling);
  req["type_time"] = EnumToString(request.type_time);
  req["expiration"] = (int)request.expiration;
  req["comment"] = (string)request.comment;
  req["position"] = (int)request.position;
  req["position_by"] = (int)request.position_by;

  Print("MqlTradeRequest: ", &req);
  return req;
}

CJAVal ConvertResultToCJAVal(const MqlTradeResult &result)
{
  CJAVal res;
  res["retcode"] = (int)result.retcode;
  res["result"] = (string)GetRetcodeID(result.retcode);
  res["deal"] = (int)result.deal;
  res["order"] = (int)result.order;
  res["volume"] = (double)result.volume;
  res["price"] = (double)result.price;
  res["comment"] = (string)result.comment;
  res["request_id"] = (int)result.request_id;
  res["retcode_external"] = (int)result.retcode_external;

  Print("MqlTradeResult: ", &res);
  return res;
}

//+------------------------------------------------------------------+
//| Validate history info data request                               |
//+------------------------------------------------------------------+
// bool ValidateTradeRequestData(TradeRequestData &rdata)
// {
//   bool valid = true;

//   // List of fields to validate
//   string fieldsToValidate[] = {
//       "actionType",
//       "symbol",
//       "volume",
//       "stoploss",
//       "takeprofit",
//       "price",
//       "deviation"};

//   for (int i = 0; i < ArraySize(fieldsToValidate); i++)
//   {
//     string fieldName = fieldsToValidate[i];
//     string value = GetStructFieldValue(rdata, fieldName);

//     if (value == NULL)
//     {
//       Print("Error: Field '" + fieldName + "' is NULL in the request.");
//       valid = false;
//       break;
//     }
//   }

//   return valid;
// }
