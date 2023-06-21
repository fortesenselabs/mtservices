#define MAX_BUFF_LEN 2048
#define TIMEOUT 10000

/* Input parameters */
input int            PORT = 8688;                  // Puerto de conexión
input string         ADDR = "localhost";           // Dirección a la que conectarse
input int            num_data_to_save = 10;        // Número de los datos a guardar

/* To check whether there is an error or not */
bool     error = false;

/* Socket variables */
int      socket;                 // Socket handle

/* EMA variables */
int ema_h;                       // EMA handle
double ema[];                    // EMA array

/* RSI variables */
int      rsi_h;                  // RSI handle
double   rsi[];                  // RSI array

/* MACD variables */
int macd_h;                      // MACD handle
double macd[];                   // MACD array
double signal[];                 // SIGNAL array

/* Velas */
MqlRates candles[];              // Velas

/* Operation */
enum op_types  // enumeración de las constantes concretas
{ SELL, BUY };

op_types last_operation;

/* To check if a message has been sent */
bool sent = false;

// Function to know if there is a BUY cross
// Función para saber si hay un cruce de COMPRA
bool buy_cross() { return signal[1] > macd[1] && signal[0] < macd[0]; }

// Function to know if there is a SELL cross
// Función para saber si hay un cruce de VENTA
bool sell_cross() { return signal[1] < macd[1] && signal[0] > macd[0]; }

void OnInit() {

   // Inicializando rsi, macd y ema
   // Initializing rsi, macd and ema
   rsi_h = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   if (rsi_h == INVALID_HANDLE) Print("Error - 3.1: iRSI failure. ", GetLastError());

   macd_h = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   if (macd_h == INVALID_HANDLE) Print("Error - 3.2: iMACD failure. ", GetLastError());

   ema_h = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   if (ema_h == INVALID_HANDLE) Print("Error - 3.3: iMA failure. ", GetLastError());

   if (rsi_h == INVALID_HANDLE || macd_h == INVALID_HANDLE || ema_h == INVALID_HANDLE) {
      error = true;
      return;
   }

   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(macd, true);
   ArraySetAsSeries(signal, true);
   ArraySetAsSeries(ema, true);
   ArraySetAsSeries(candles, true);

   // Initializing the socket
   socket = SocketCreate();
   if (socket == INVALID_HANDLE) {
      Print("Error - 1: SocketCreate failure. ", GetLastError());
      error = true;
   } else {
      if (SocketConnect(socket, ADDR, PORT, TIMEOUT)) Print("[INFO]\tConnection stablished");
      else Print("Error - 2: SocketConnect failure. ", GetLastError());
   }
}


void OnDeinit(const int reason) {

   if (error) return;

   /* Closing the socket */
   // Creating the message
   char req[];
   
   Print("[INFO]\tClosing the socket.");
   
   int len = StringToCharArray("END CONNECTION\0", req)-1;
   SocketSend(socket, req, len);
   SocketClose(socket);
}


void OnTick() {

   if (error) return;

   // Cargando velas, el rsi y los valores del std
   // Loading the candles, rsi and std values
   CopyBuffer(rsi_h, 0, 0, num_data_to_save, rsi);
   CopyBuffer(ema_h, 0, 0, num_data_to_save, ema);
   CopyBuffer(macd_h, MAIN_LINE, 0, num_data_to_save, macd);
   CopyBuffer(macd_h, SIGNAL_LINE, 0, num_data_to_save, signal);
   CopyRates(_Symbol, _Period, 0, num_data_to_save, candles);

   // Si hay cruce vamos preparar los datos para enviarlos
   // If the previous one is cross we are going to save data in the file
   if ((buy_cross() || sell_cross()) && !sent) {

      string data = "";
   
      // Saving the EMA
      // Guardamos el EMA
      string ema_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double ema_normalized = NormalizeDouble(ema[i], _Digits);
         ema_data += DoubleToString(ema_normalized)+",";
      }
      
      // Saving the RSI
      // Guardamos el RSI
      string rsi_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double rsi_normalized = NormalizeDouble(rsi[i], _Digits);
         rsi_data += DoubleToString(rsi_normalized)+",";
      }
      
      // Saving the MACD
      // Guardamos el MACD
      string macd_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double macd_normalized = NormalizeDouble(macd[i], _Digits);
         macd_data += DoubleToString(macd_normalized)+",";
      }
      
      // Saving the SIGNAL
      // Guardamos el SIGNAL
      string signal_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double signal_normalized = NormalizeDouble(signal[i], _Digits);
         signal_data += DoubleToString(signal_normalized)+",";
      }
      
      // ¿Está el precio encima o debajo de la EMA? 1 (encima) 0 (debajo)
      // Is the price above or below the EMA? 1 (above) 0 (below) 
      string above_below = candles[0].close >= ema[0] ? "1," : "0,";
      
      // Guardamos el tipo de cruce
      // Saving the type of the cross
      string cross_type = "";
      if (buy_cross()) {cross_type = "1,"; last_operation = BUY;}
      else if (sell_cross()) {cross_type = "0,"; last_operation = SELL;}
      
      data = ema_data+rsi_data+macd_data+signal_data+above_below+cross_type;

      // Sending data
      Print("[INFO]\tSending RSI and STD deviation");
      
      char req[];
      int len = StringToCharArray(data, req)-1;
      SocketSend(socket, req, len);
      
      sent = true;
      
      EventSetTimer(PeriodSeconds());
   }
}

void OnTimer() {
   sent = false;
   EventKillTimer();
}
