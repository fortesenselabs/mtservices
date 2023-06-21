
bool es_primo(int number) {
   for (int n = 2; n < number; n++) {
      if (number % n == 0) {
         return false;
      }
   }
   
   return true;
}

void show(int number) {
   Print(IntegerToString(number) + " es primo");
}

void OnInit() {
   for(int i = 0; i <= 100; i++) {
      if (es_primo(i)) show(i);
   }
}