
void OnInit() {
   int a = 5, b = 5, c = 23;
   if (a == b && c < 20) {
      Print(">>> 1");
   }
   
   if (a == b || c < 20) {
      Print(">>> 2");
   }
   
   if (!(c < 20)) {
      Print(">>> 3");
   }
}