// En mql5 existen diferentes tipos de variables.

// Las que más vamos a usar durante el curso son las siguientes:

int // Esta es una variable entera. Su nombre "int" viene de Integer que significa entero.
// En este tipo de variables solo podemos guardar números y estos, además, tienen que ser enteros.
// Las variables enteras ocupan 4 bytes en la memoria. ¿Qué significa esto? Si tenemos en cuenta que solo
// se pueden guardar números enteros positivos y negativos esto significa que podemos dar a una variable entera
// 2^(8*4) valores. En definitiva, muchos valores

short // Esta es otra variable para guardar valores enteros. short en ingles significa "corto", esta variable
// Ocupa menos espacio en la memoria. Se usa cuando se quiere ser eficiente.

long // Para guardar enteros pero ahora podemos poner númeors muy grandes. Desde -9 223 372 036 854 775 808 hasta 9 223 372 036 854 775 807

uint // La u viene de "unsigned", solo se pueden poner números positivos y 0

ushort // Números positivos pero no podemos poner tantos. El número más alto que podemos usar es 65535 mientras que con 4 294 967 295

ulong // Números positivos, podemos poner muchos. El más alto que podemos usar es 18 446 744 073 709 551 615

double // Para guardar números decimales

float // Para guardar números decimales pero esta variable ocupa menos y por lo tanto no se pueden poner tantos números