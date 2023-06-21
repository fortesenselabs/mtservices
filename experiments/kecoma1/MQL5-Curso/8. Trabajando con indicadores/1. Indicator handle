int macd_h;

int OnInit() {
   macd_h = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   //iMA(_Symbol, _Period, 12, 0, MODE_SMA, PRICE_CLOSE);
   if (macd_h == INVALID_HANDLE) {
      Print("MACD couldn't be loaded");
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}