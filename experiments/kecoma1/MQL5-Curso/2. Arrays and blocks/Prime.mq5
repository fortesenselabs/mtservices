
void OnInit() {
   // Tarea: Numeros primos hasta 100 (100 incluido)
   for (int i = 0; i <= 100; i++) {
      
      bool is_prime = true;
      for (int n = 2; n < i; n++) {
         if (i % n == 0) {
            is_prime = false;
            break;
         }
      }
      
      if (is_prime) Print(i+" es primo");
   }
}