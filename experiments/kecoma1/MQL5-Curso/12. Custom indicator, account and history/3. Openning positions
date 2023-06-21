#include <Trade/Trade.mqh>
CTrade trade;
ulong trade_ticket;

int custom_h;
double sell_arrow[];

int bars;
bool new_candle() {
   int current_bars = Bars(_Symbol, _Period);
   if (current_bars != bars) {
      bars = current_bars;
      return true;
   }
   
   return false;
}

bool sell_condition() {
   return sell_arrow[0] != 0;
}

bool operation_closed() {
   return !PositionSelectByTicket(trade_ticket);
}

int OnInit() {
   custom_h = iCustom(_Symbol, _Period, "Market/ArrowZigZag");
   if (custom_h == INVALID_HANDLE) {
      Print("Error loading the custom indicator");
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if (custom_h != INVALID_HANDLE) IndicatorRelease(custom_h);
}

void OnTick() {
   CopyBuffer(custom_h, 1, 2, 1, sell_arrow);
   
   if (sell_condition() && new_candle() && operation_closed()) {
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      trade.Sell(0.1, _Symbol, Bid, Bid+7000*_Point, Bid-12000*_Point);
      trade_ticket = trade.ResultOrder();
   }
}