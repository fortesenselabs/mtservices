
void OnInit() {

   // Vamos a empezar ahora con las operaciones. Podemos operar usando +, -, /, * y %
   // Las sumas son siempre entre números, 
   int a = 5, b = 3;
   
   int c = a + b;
   Print(c);
   
   //lo mejor sería siempre intentar usar el mismo tipo en ambas partes de la suma
   int d = 1 + 1.03; // En la variable d a pesar de que intentamos guardar un resultado que es decimal, no se va a hacer ya que la variable es entera
   // Vemos como el compilador nos da error y si imprimimos el valor se ignoran los decimales.
   
   Print("D: ", d);
   
   // Si hacemos lo mismo usando un tipo decimal este problema no pasa
   double e = 1 + 1.04;
   
   Print("E: ", e);
   
   // Las restas son iguales que las sumas
   int resta = 1 - 3;
   Print("RESTA: ", resta);
   
   // Las divisiones es mejor no hacerlas usando un tipo entero a no ser que siempre vayamos a obtener un valor entero
   double div = 1.0 / 2.0;
   Print("DIVISION: ", div);
   
   // Las multiplicaciones son igual de simples
   int mul = 2 * a;
   Print("MULTIPLICACION: ", a);
   
   // Por último tenemos el operador módulo que nos da el resto de una división
   int modulo = 5 % 2;
   Print("MODULO: ", modulo);
   
   // Vamos a probar el código en el probador de estrategias
}