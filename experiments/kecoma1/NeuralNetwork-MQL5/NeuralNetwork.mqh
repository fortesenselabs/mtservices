class Capa;
class Neurona;
class Conexion;

// Puntero función
typedef double (*FuncionActivacion)(double);

/****************************************** RED NEURONAL ******************************************/

class RedNeuronal
  {
private:
                     Capa capas[];
                     FuncionActivacion derivadaFunc;
                     double tasaAprendizaje;
  
public:
                     RedNeuronal(void);
                    ~RedNeuronal(void);
                     void entrenamiento();
                     void clasificar();
                     void disparar(double &valores);
                     void retroPropagar(double salidaEsperada);
                     void deltaCapasOcultas();
                     void deltaNeurona();
                     void incrementoPesos();
  };

RedNeuronal::RedNeuronal(void) {}

RedNeuronal::~RedNeuronal(void) {}

void RedNeuronal::entrenamiento(void) {}

void RedNeuronal::clasificar(void) {}

void RedNeuronal::disparar(double &valores) {}

void RedNeuronal::retroPropagar(double salidaEsperada) {}

void RedNeuronal::deltaCapasOcultas(void) {}

void RedNeuronal::deltaNeurona(void) {}

void RedNeuronal::incrementoPesos(void) {}

/****************************************** CAPA ******************************************/

class Capa
  {
private:
   bool capaEntrada;
  
public:
                     Neurona neuronas[];
   
                     Capa(int num_neuronas, FuncionActivacion func, bool esCapaEntrada, bool esCapaSalida);
                     void getNeuronas(Neurona& array[]);
                     void disparar();
                     void conectarCapa(Capa &capa);
                     void conectarNeurona(Neurona &neurona);
                     void toString();
  };

Capa::Capa(int num_neuronas, FuncionActivacion func, bool esCapaEntrada, bool esCapaSalida) {
   this.capaEntrada = esCapaEntrada;
   
   // +1 Because of the bias
   if (esCapaSalida) ArrayResize(neuronas, num_neuronas);
   else ArrayResize(neuronas, num_neuronas+1);

   // Declaramos las neuronas
   for (int i = 0; i < num_neuronas; i++)
      this.neuronas[i] = Neurona(func, esCapaEntrada, false);
   
   if (!esCapaSalida) neuronas[num_neuronas] = Neurona(func, esCapaEntrada, true);
}

void Capa::disparar(void) {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].disparar();
}

void Capa::conectarCapa(Capa &capa) {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].ConectarCapa(&capa);
}

void Capa::conectarNeurona(Neurona &neurona) {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].ConectarNeurona(&neurona);
}

void Capa::toString() {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].toStringConexiones();
}


/****************************************** CONEXION ******************************************/

class Conexion
  {
private:
   Neurona* neurona_entrada;
   Neurona* neurona_salida;
   double peso;
  
public:
                     Conexion(Neurona &in, Neurona &out);
                     void disparar();
                     string toString();
                          
  };
  
Conexion::Conexion(Neurona &in, Neurona &out) {
   this.neurona_entrada = &in;
   this.neurona_salida = &out;
   this.peso = MathRand() / 32767.0;
}

void Conexion::disparar(void) {
   double resultado = this.peso * this.neurona_entrada.getValor();
   Print(">>>", resultado);
   this.neurona_salida.setValorEntrada(resultado+2);
}

string Conexion::toString() {
   return this.neurona_entrada.toString() + " --(" + DoubleToString(this.peso) + ")--> " + this.neurona_salida.toString();
}

/****************************************** NEURONA ******************************************/

class Neurona
  {
private:
   double               valor;
   double               valor_entrada;
   double               valor_entrada_backpropagation;
   double               delta;
   bool                 bias;
   bool                 en_capa_entrada;
   Conexion             conexiones[];
   FuncionActivacion    func;
   uint                 id;
   
  
public:

                     static uint neuronas;
               
                     Neurona(FuncionActivacion f, bool en_capa_entrada, bool bias);
                     void ConectarNeurona(Neurona &neurona);
                     void ConectarCapa(Capa &capa);
                     double getValor();
                     void setValorEntrada(double v);
                     void disparar();
                     string toString();
                     void toStringConexiones();
  };
  
Neurona::Neurona(FuncionActivacion f, bool ece, bool b) {
   this.valor = 0;
   this.valor_entrada = 0;
   this.valor_entrada_backpropagation = 0;
   this.delta = 0;
   this.func = f;
   this.en_capa_entrada = ece;
   this.bias = b;
   
   neuronas += 1;
   this.id = neuronas;
}
  
void Neurona::ConectarNeurona(Neurona &neurona) {
   // Si es bias no la conectamos
   if (neurona.bias) return;

   // Hacemos más grande el array
   int new_size = ArraySize(this.conexiones) + 1;
   ArrayResize(this.conexiones, new_size);
   
   // Añadimos una conexión
   this.conexiones[new_size-1] = Conexion(this, neurona);
}

void Neurona::ConectarCapa(Capa &capa) {
   for (int i = 0; i < ArraySize(capa.neuronas); i++)
      this.ConectarNeurona(&capa.neuronas[i]);
}

double Neurona::getValor(void) {
   return this.valor;
}

void Neurona::setValorEntrada(double v) {
   this.valor_entrada = v;
}

void Neurona::disparar(void) {
   if (!this.en_capa_entrada) {
      Print("---", this.id, " - ", this.valor_entrada);
      this.valor = this.func(this.valor_entrada);
      this.valor_entrada_backpropagation = this.valor_entrada;
      
      // Reset
      this.valor_entrada = 0;
   }
   
   if (this.bias) this.valor = 1;
   
   // Disparamos en las conexiones
   for (int i = 0; i < ArraySize(this.conexiones); i++)
      this.conexiones[i].disparar();
}

string Neurona::toString() {
   return "[" + IntegerToString(this.id) + "]";
}

void Neurona::toStringConexiones() {
   string result = "";
   for (int i = 0; i < ArraySize(this.conexiones); i++)
      Print(this.conexiones[i].toString());
}

uint Neurona::neuronas=0;