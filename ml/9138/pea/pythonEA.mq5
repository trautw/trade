//+------------------------------------------------------------------+
//|                                               pythonEA.mq5       |
//|                        Copyright 2022, Christoph Trautwein       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Christoph Trautwein"
#property link      "https://www.mql5.com"
#property version   "1.01"
sinput int lrlenght = 150;

#include <JAson.mqh>

CJAVal sendRequest(CJAVal &rq) {   
   //--- serialize to string  {"login":"Login","password":"Pass"}
   char data[]; 
   ArrayResize(data, StringToCharArray(rq.Serialize(), data, 0, WHOLE_ARRAY)-1);
   
   // Use MT5's WebRequest() to send the JSON data to the server.
   char serverResult[];
   string serverHeaders=NULL;   
   
   string requestHeaders = "Content-Type: application/json; charset=utf-8\r\nConnection: Keep-Alive";

   int res = WebRequest("POST", "http://localhost:43560/Predict", requestHeaders, 10000, data, serverResult, serverHeaders);

   Print("Request result: ", res, ", error: #", (res == -1 ? GetLastError() : 0));
   //--- Checking the request result
   if(res!=200)
     {
      Print("Error sending request to the server #"+(string)res+", LastError="+(string)GetLastError());
      return(false);
     }
   CJAVal result;
   result.Deserialize(serverResult);
   return result; 
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
 return(INIT_SUCCEEDED); }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) { }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
 CJAVal rq;
 
 double clpr[];
 int copyed = CopyClose(_Symbol,PERIOD_CURRENT,0,lrlenght,clpr);

 for (int i=0; i<ArraySize(clpr); ++i) rq["clprArray"].Add((string)clpr[i]);
 
 CJAVal answer = sendRequest(rq);
 Print ("Received from server: ", answer.Serialize());
 
 drawlr(answer["from"].ToStr(),answer["to"].ToStr());
} 
 
void drawlr(string from, string to) {     
  Print(StringToDouble(from));
  Print(StringToDouble(to));
  datetime temp[]; 
  CopyTime(Symbol(),Period(),TimeCurrent(),lrlenght,temp); 
  ObjectCreate(0,"regrline",OBJ_TREND,0,TimeCurrent(),NormalizeDouble(StringToDouble(from),_Digits),temp[0],NormalizeDouble(StringToDouble(to),_Digits)); 
}
//+------------------------------------------------------------------+
//| EOF                                                              |
//+------------------------------------------------------------------+