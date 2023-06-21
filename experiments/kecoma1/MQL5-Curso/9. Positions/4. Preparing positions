int rsi_h;

double rsi[];

int bars = Bars(_Symbol, _Period);

bool buy_condition() {
   return rsi[0] < 20;
}

bool sell_condition() {
   return rsi[0] > 80;
}

bool new_candle() {
   int current_bars = Bars(_Symbol, _Period);
   
   if (bars != current_bars) {
      bars = current_bars;
      return true;
   }
   
   return false;
}


int OnInit() {
   // Loading the rsi
   rsi_h = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   if (rsi_h == INVALID_HANDLE) {
      Print("Error loading the RSI");
      return INIT_FAILED;
   }
   
   // Setting the array as a series
   ArraySetAsSeries(rsi, true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if (rsi_h != INVALID_HANDLE)
      IndicatorRelease(rsi_h);
}

void OnTick() {
   CopyBuffer(rsi_h, 0, 1, 1, rsi);
   
   // Buy
   if (buy_condition() && new_candle()) {
      Print("Buy");
   }
   // Sell
   else if (sell_condition() && new_candle()) {
      Print("Sell");
   }
}