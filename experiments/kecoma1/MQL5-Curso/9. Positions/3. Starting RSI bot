int rsi_h;

double rsi[];

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