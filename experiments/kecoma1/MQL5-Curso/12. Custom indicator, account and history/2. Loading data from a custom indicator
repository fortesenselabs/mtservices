int custom_h;
double buy_arrow[];
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
   CopyBuffer(custom_h, 1, 1, 1, sell_arrow);
   CopyBuffer(custom_h, 2, 1, 1, buy_arrow);
   
   if (sell_condition() && new_candle()) {
   
   }
}