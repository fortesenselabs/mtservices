//+------------------------------------------------------------------+
//|                                                          MT5.mq5 |
//|                                              jaffer wilson, 2020 |
//+------------------------------------------------------------------+
#property copyright "© 2020Jaffer Wilson"
#property link      "jafferwilson@gmail.com"
#property version   "1.00"

#include "socket-library-mt4-mt5.mqh"
input string   Hostname = "localhost";    // Server hostname or IP address
ushort   ServerPort = 0;        // Server port
ClientSocket * glbClientSocket = NULL;
// --------------------------------------------------------------------
// Initialisation (no action required)
// --------------------------------------------------------------------
datetime last_visit = 0;
bool is_History_Written = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   ServerPort = 0;
   int file  = FileOpen("sym_port.txt",FILE_READ|FILE_SHARE_READ|FILE_ANSI|FILE_TXT,'\n');
   if(file==INVALID_HANDLE)
     {
      Print("Error Opening File : ",GetLastError());
      FileClose(file);
      ExpertRemove();
     }
   else
     {
      while(!FileIsEnding(file) && !IsStopped())
        {
         string text = FileReadString(file);
         if(StringFind(text,_Symbol)>=0)
           {
            int replace_length = StringReplace(text,_Symbol+"=","");
            ServerPort = ushort(text);
            break;
           }
        }
     }
   FileClose(file);
   if(ServerPort<=0)
     {
      Print("The Symbol is found");
      ExpertRemove();
     }
   Print(_Symbol," is assigned with Port: ",ServerPort);
   last_visit = Time[0];
   Write_To_File_History();
  }
void OnDeinit(const int reason)
  {
   if(glbClientSocket)
     {
      delete glbClientSocket;
      glbClientSocket = NULL;
     }
  }
void OnTick()
  {
   if(!glbClientSocket)
     {
      glbClientSocket = new ClientSocket(Hostname, ServerPort);

      if(glbClientSocket.IsSocketConnected())
        {
         //MqlTick tick;
         //MqlRates rates[];
         //SymbolInfoTick(_Symbol,tick);
         //CopyRates(_Symbol,0,Time[0],Time[0],rates);
         string strMsg = StringFormat("quote,%s,%ld,%lf,%lf,%ld,%ld,%lf,%lf,%lf,%lf,%d,%ld,%ld,%lf,%lf,%lf,%lf,%d,%ld",_Symbol,long(TimeCurrent()),Ask,Bid,long(TimeCurrent()),
                                      long(Time[0]),Open[0],High[0],Low[0],Close[0],int(fabs(Ask-Bid)/Point),Volume[0]);
         //,long(rates[1].time),rates[1].open,rates[1].high,rates[1].low,rates[1].close,rates[1].spread,rates[1].tick_volume);
         //Print(strMsg);
         glbClientSocket.Send(strMsg);
        }
      if(last_visit != Time[0])
        {
         last_visit = Time[0];
         if(FileIsExist(StringFormat("MT4Hist//%s.csv",_Symbol),FILE_COMMON))
           {
            int file  = FileOpen(StringFormat("MT4Hist//%s.csv",_Symbol),FILE_COMMON|FILE_CSV|FILE_WRITE|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_ANSI,',');
            if(file!=INVALID_HANDLE)
              {
               FileSeek(file,0,SEEK_END);
               MqlRates rates[];
               CopyRates(_Symbol,0,Time[1],Time[1],rates);
               FileWrite(file,rates[0].time,rates[0].open,rates[0].high,rates[0].low,rates[0].close,rates[0].spread,rates[0].tick_volume);
              }
            FileClose(file);
           }
        }
      if(CheckPointer(glbClientSocket)!=POINTER_INVALID)
        {
         delete glbClientSocket;
         glbClientSocket = NULL;
        }
     }

  }
//+------------------------------------------------------------------+
void Write_To_File_History()
  {
   MqlRates rates[];
   if(FileIsExist(StringFormat("MT4Hist//%s.csv",_Symbol),FILE_COMMON))
      FileDelete(StringFormat("MT4Hist//%s.csv",_Symbol),FILE_COMMON);
   int file  = FileOpen(StringFormat("MT4Hist//%s.csv",_Symbol),FILE_COMMON|FILE_SHARE_WRITE|FILE_CSV|FILE_WRITE|FILE_READ|FILE_SHARE_READ|FILE_ANSI,',');
   datetime start_time = datetime(Time[0] - 1000*3600);//525600*60);
   Print(start_time);
   int length = CopyRates(_Symbol,0,start_time,Time[1],rates);
   Print("Length Data: ",length);
   if(file==INVALID_HANDLE)
     {
      Print("The file has Issues : ",GetLastError());
     }
   else
     {
      for(int i=0; i<length && !_StopFlag; i++)
        {
         FileWrite(file,rates[i].time,rates[i].open,rates[i].high,rates[i].low,rates[i].close,rates[i].spread,rates[i].tick_volume);
        }
      is_History_Written = true;
     }
   FileClose(file);
  }
//+------------------------------------------------------------------+
