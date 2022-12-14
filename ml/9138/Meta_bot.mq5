#property copyright "Copyright 2022, Dmitrievsky Max."
#property link      "https://www.mql5.com/en/users/dmitrievsky"
#property version   "1.0"

// Use macros to remove any mention of MT4Orders.
#define Alert PrintTmp
#define Print PrintTmp
void PrintTmp( string ) {}

#include <MT4Orders.mqh> // https://www.mql5.com/en/code/16006
#undef Print
#undef Alert

#include <Trade\AccountInfo.mqh>
#include "EURUSDcat_model_META_NEW1.mqh"

sinput int      OrderMagic = 666;       //Orders magic
input int stoploss = 2000;              //Stop loss
input int takeprofit = 500;             //Take profit
input float lotsize = 15.0;             //Lot size
static datetime last_time=0;
#define Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)
MqlDateTime hours;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
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
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(!isNewBar()) return;
   TimeToStruct(TimeCurrent(), hours);
   double features[];

   fill_arays1(features);
   if(ArraySize(features) !=ArraySize(MAs1)) {
      Print("No history available, will try again on next signal!");
      return;
   }
   double sig = catboost_model1(features);
   double meta_sig = catboost_meta_model1(features);

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
//         double l = 0.01;
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
