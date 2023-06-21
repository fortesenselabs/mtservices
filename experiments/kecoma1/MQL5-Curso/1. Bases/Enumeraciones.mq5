
void OnInit() {

   // Con una enumeración estamos creando nuestro propio tipo y aparte estamos determinando que valores puede tener
   enum custom
     {
         BUY, // Automáticamente se le asigna el valor 0
         SELL, // Automáticamente se asigna un valor por encima del anterior 0+1=1
         OTHER = 3
     };
     
   // Las para declarar una variable usando una enumeración hacemos lo mismo
   custom a, b = BUY;
   
   // Se pueden declarar varias variables en la misma línea y no es necesario siempre dar un valor inicial
   
   a = SELL;
   
   Print(a);
   Print(b);
   
   // Tambien podemos enviar valores, no es necesario siempre enviar una variable
   Print(OTHER);
   Print("Hola: ", 5);
   
   // Como veremos a continuación en el probador de estrategias los valores de una enumeración, no dejan de ser números.
   
   
   // Vamos a probar el código en el probador de estrategias
}