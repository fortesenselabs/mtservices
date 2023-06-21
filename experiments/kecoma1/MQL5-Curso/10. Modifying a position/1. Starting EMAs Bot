int ema_fast_h;
int ema_slow_h;

double ema_fast[];
double ema_slow[];

int OnInit() {
   // Loading the handles
   ema_fast_h = iMA(_Symbol, _Period, 10, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_h = iMA(_Symbol, _Period, 100, 0, MODE_EMA, PRICE_CLOSE);
   
   if (ema_fast_h == INVALID_HANDLE ||ema_slow_h == INVALID_HANDLE) {
      Print("Error loading the EMA handles");
      return INIT_FAILED;
   }
   
   // Setting the arrays as series
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if (ema_fast_h != INVALID_HANDLE) IndicatorRelease(ema_fast_h);
   if (ema_slow_h != INVALID_HANDLE) IndicatorRelease(ema_slow_h);
}