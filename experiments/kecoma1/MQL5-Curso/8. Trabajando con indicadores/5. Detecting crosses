int macd_h;

double macd[];
double signal[];

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
   CopyBuffer(macd_h, MAIN_LINE, 0, 3, macd);
   CopyBuffer(macd_h, SIGNAL_LINE, 0, 3, signal);
   
   if (signal[1] < macd[1] && signal[0] > macd[0]) { // Sell cross
      Print("SELL!");
   } else if (signal[1] > macd[1] && signal[0] < macd[0]) { // Buy cross
      Print("BUY!");
   }
   
}