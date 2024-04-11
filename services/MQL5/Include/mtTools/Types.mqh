
#include <mtTools/sockets/Socketlib.mqh>

struct ClientSocket
{
  SOCKET64 socket;
  string requestData;
  string responseData;
};

struct RequestData
{
  string action;
  string actionType;
  string symbol;
  string chartTimeFrame;
  datetime fromDate;
  datetime toDate;
  //
  ulong id;
  string magic;
  double volume;
  double price;
  double stoploss;
  double takeprofit;
  int expiration;
  double deviation;
  string comment;
  string chartId;
  string indicatorChartId;
  string chartIndicatorSubWindow;
  string style;
};

enum msgStatus
{
  msCONNECTED,
  msDISCONNECTED,
};

enum msgType
{
  mtNORMAL,
  mtFLUSH,
};

struct TradeRequestData
{
  ulong id;
  string actionType;
  string symbol;

  double volume;
  double price;
  double stoploss;
  double takeprofit;
  int expiration;
  double deviation;
  string comment;
};