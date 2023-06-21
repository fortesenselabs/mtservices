int macd_h;

double macd[];
double signal[];

int bars = 0;

int OnInit() {
   // Loading the MACD handle
   macd_h = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   //iMA(_Symbol, _Period, 12, 0, MODE_SMA, PRICE_CLOSE);
   if (macd_h == INVALID_HANDLE) {
      Print("MACD couldn't be loaded");
      return INIT_FAILED;
   }
   
   // Setting the array as series
   ArraySetAsSeries(macd, true);
   ArraySetAsSeries(signal, true);
   
   return INIT_SUCCEEDED;
}

void OnTick() {
   // Loading the MACD data
   CopyBuffer(macd_h, MAIN_LINE, 1, 3, macd);
   CopyBuffer(macd_h, SIGNAL_LINE, 1, 3, signal);
   
   int current_bars = Bars(_Symbol, _Period);
   
   if (signal[1] < macd[1] && signal[0] > macd[0] && bars != current_bars) { // Sell cross
      bars = current_bars;
      Print("SELL!");
   } else if (signal[1] > macd[1] && signal[0] < macd[0] && bars != current_bars) { // Buy cross
      bars = current_bars;
      Print("BUY!");
   }
   
}