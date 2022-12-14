//+------------------------------------------------------------------+
//|                                               pythonEA.mq5       |
//|                        Copyright 2022, Christoph Trautwein       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Christoph Trautwein"
#property link      "https://www.mql5.com"
#property version   "1.01"
sinput int lrlenght = 150;


// Use macros to remove any mention of MT4Orders.
#define Alert PrintTmp
#define Print PrintTmp
void PrintTmp( string ) {}

#include <MT4Orders.mqh> // https://www.mql5.com/en/code/16006
#undef Print
#undef Alert

#include <Trade\AccountInfo.mqh>

sinput int      OrderMagic = 666;       //Orders magic
input int stoploss = 2000;              //Stop loss
input int takeprofit = 500;             //Take profit
input float lotsize = 15.0;             //Lot size
static datetime last_time=0;
#define Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)
MqlDateTime hours;

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
   printf("ACCOUNT_BALANCE =  %G",AccountInfoDouble(ACCOUNT_BALANCE));
   printf("ACCOUNT_CREDIT =  %G",AccountInfoDouble(ACCOUNT_CREDIT));
   printf("ACCOUNT_PROFIT =  %G",AccountInfoDouble(ACCOUNT_PROFIT));
   printf("ACCOUNT_EQUITY =  %G",AccountInfoDouble(ACCOUNT_EQUITY));
   printf("ACCOUNT_MARGIN =  %G",AccountInfoDouble(ACCOUNT_MARGIN));
   printf("ACCOUNT_MARGIN_FREE =  %G",AccountInfoDouble(ACCOUNT_MARGIN_FREE));
   printf("ACCOUNT_MARGIN_LEVEL =  %G",AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
   printf("ACCOUNT_MARGIN_SO_CALL = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
   printf("ACCOUNT_MARGIN_SO_SO = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_SO));
   
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
  
  MqlTick last_tick;
  if(!SymbolInfoTick(Symbol(), last_tick))
    Print("SymbolInfoTick() failed, error = ",GetLastError());
  
  rq["tickTime"] = StringFormat("%s,%03d",TimeToString(last_tick.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS),last_tick.time_msc%1000);
  rq["symbol"] = Symbol();
  rq["last"] = last_tick.last;
  rq["ask"] = last_tick.ask;
  rq["bid"] = last_tick.bid;
  rq["orderCount"] = countOrders();
  rq["marketOrderCount0"] = count_market_orders(0);
  rq["marketOrderCount1"] = count_market_orders(1);
  rq["isNewBar"] = isNewBar();
 
  for(int k=OrdersTotal()-1; k>=0; k--) {
   if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
     if(OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol)        
       rq["orders"].Add(OrderType());
  }
 
  double clpr[];
  int copyed = CopyClose(_Symbol,PERIOD_CURRENT,0,lrlenght,clpr);
  for (int i=0; i<ArraySize(clpr); ++i) rq["clprArray"].Add((string)clpr[i]);
 
  CJAVal answer = sendRequest(rq);
  Print ("Received from server: ", answer.Serialize());
 
  drawlr(answer["from"].ToStr(),answer["to"].ToStr());
  
  double sig = StringToDouble(answer["sig"].ToStr());
  double meta_sig = StringToDouble(answer["meta_sig"].ToStr());
  
  Print (sig, " ", meta_sig);
  
  // close positions by an opposite signal
  if(meta_sig > 0.5)
      if(count_market_orders(0) || count_market_orders(1))
         for(int b = OrdersTotal() - 1; b >= 0; b--)
            if(OrderSelect(b, SELECT_BY_POS) == true) {
               if(OrderType() == 0 && OrderSymbol() == _Symbol && OrderMagicNumber() == OrderMagic && sig > 0.5)
                  if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) < MathAbs(Bid - OrderOpenPrice()) && OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Red)) {
                  }
               if(OrderType() == 1 && OrderSymbol() == _Symbol && OrderMagicNumber() == OrderMagic && sig < 0.5)
                  if( SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) < MathAbs(Bid - OrderOpenPrice()) && OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Red)) {
                  }
            }
            

  // open positions and pending orders by signals
  if(meta_sig > 0.5)
      if(countOrders() == 0) {
         // double l = 0.01;
         double l = lotsize * AccountInfoDouble(ACCOUNT_BALANCE)*_Point;
         l = NormalizeDouble(l,2);
         if(sig < 0.5) {
            OrderSend(Symbol(),OP_BUY,l, Ask, 0, Bid-stoploss*_Point, Ask+takeprofit*_Point, NULL, OrderMagic);
         }

         else {
            OrderSend(Symbol(),OP_SELL,l, Bid, 0, Ask+stoploss*_Point, Bid-takeprofit*_Point, NULL, OrderMagic);
         }
      }
} 
 
void drawlr(string from, string to) {     
  Print(StringToDouble(from));
  Print(StringToDouble(to));
  datetime temp[]; 
  CopyTime(Symbol(),Period(),TimeCurrent(),lrlenght,temp); 
  ObjectCreate(0,"regrline",OBJ_TREND,0,TimeCurrent(),NormalizeDouble(StringToDouble(from),_Digits),temp[0],NormalizeDouble(StringToDouble(to),_Digits)); 
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int countOrders() {
   int result=0;
   for(int k=OrdersTotal()-1; k>=0; k--) {
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
         if(OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol) result++;
   }
   return(result);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int count_market_orders(int type) {
   int result=0;
   for(int k=OrdersTotal()-1; k>=0; k--) {
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
         if(OrderType() == type && OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol) result++;
   }
   return(result);
}

//+------------------------------------------------------------------+
//| New bar func                                                     |
//+------------------------------------------------------------------+
bool isNewBar() {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE));

   if(last_time==0) {
      last_time=lastbar_time;
      return(false);
   }
   if(last_time!=lastbar_time) {
      last_time=lastbar_time;
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//| EOF                                                              |
//+------------------------------------------------------------------+