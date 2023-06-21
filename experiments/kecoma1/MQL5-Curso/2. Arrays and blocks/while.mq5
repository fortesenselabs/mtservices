
void OnInit() {
   int i = 0;
   
   while (i < 10) {
      Print(i);
      i++; // ¡Cuidado bucle infinito!
   }
   
   // Tarea: Declarar un array con cinco elementos, inicializar el array con los valores 10, 20, 30, 40, 50
   int array[5] = {10, 20, 30, 40, 50};
   
   while (i < 5) {
      Print(array[i]);
      i++;
   }
}