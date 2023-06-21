
void OnInit() {
   // Tarea: Declarar la variable "i" y asignarle el valor 0
   int i = 0;
   
   do {
      // Tarea: Mostrar en cada iteración si i es par o impar
      Print( (i % 2 == 0) ? i+" es par" : i+" no es par" );
      i++;
   } while(i < 10);
}