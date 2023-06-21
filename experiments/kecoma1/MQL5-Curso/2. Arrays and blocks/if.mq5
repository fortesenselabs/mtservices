
void OnInit() {
   // EJ 
   int a = 5, b = 5;
   
   if (a == b) {
      Print(">>> 1");
   } else if (a < 5) {
      Print(">>> 2");
   } else if (b <= 5) {
      Print(">>> 3");
   } else if (b != a) {
      Print(">>> 4")
   else {
      Print(">>> 5");
   }
   
   bool result = a != b;
   
   Print(result);
   
   if (result) Print("Result is true: ", result);
   else Print("Result is false: ", result);
}
