int custom_h;
double buy_arrow[];
double sell_arrow[];

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