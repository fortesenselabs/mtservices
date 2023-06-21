
void OnInit() {
   int n;
   for (n = 0; n < 10; n++) {
      Print(n);
   }
   
   for(int i = 0; i < 10; i++) {
      Print((i % 2 == 0) ? i+" es par" : i+" no es par");
   }
}