//+------------------------------------------------------------------+
//|                                                        NGate.mq4 |
//|                         Copyright 2021, FXScalper Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, FXScalper Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern string  Program        =  "======= FXScalper Pro V1.3 =======";
extern int     MagicNumber    =  110110;
extern int     Slippage       =  3;
extern int     Spread         =  30;
extern int     Max_order      =  3;
extern double  DistanceBar    =  25;
extern double  TrailingStop   =  50.0;
extern double  Lots           =  0.01;
extern double  StopLoss       =  40;
extern double  TakeProfit     =  100;

extern string  Filter_Settings;
extern string  Header_MACD       =  "======= MACD Settings =======";
extern int     FastMACDPeriod    =  9;
extern int     SlowMACDPeriod    =  10;
extern int     SignalMACDPeriod  =  6;
extern string  Header_RSI        =  "======= RSI Settings =======";
extern int     RSI_period        =  10;
extern int     RSI_price         =  10;
extern int     RSI_Overbought_level    =  60;
extern int     RSI_Oversold_level      =  40;
extern string  Header_CCI        =  "======= CCI Settings =======";
extern int     CCIPeriod         =  14;
extern int     CCI_Overbought_level    =  80;
extern int     CCI_Oversold_level      =  -80;
extern string  Header_MA         =  "======= MA Settings =======";
extern int     FastEMAPeriod     =  100;
extern int     SlowEMAPeriod     =  200;
extern int     SignalEMAPeriod   =  25;
extern double  DistanceEMA       =  150; // Trend Analysis
extern double  DistanceSignal    =  100;
extern string  Header_Fisher     =  "======= Fisher Settings =======";
extern int     FisherPeriod      =  10;

// -----------------------    Configuration Follow Trend   ----------------------- //
extern string  Configuration_Follow_Trend       =  "======= Follow Trend Settings =======";
extern double  FL_HIST_HIGH      =  0.003;
extern double  FL_HIST_LOW       =  -0.003;
extern double  FL_DISTANCE       =  6;
extern double  FL_CCI_HIGH       =  100;
extern double  FL_CCI_LOW        =  -100;
extern double  FL_RSI_HIGH       =  70;
extern double  FL_RSI_LOW        =  30;
extern double  FL_STO_HIGH       =  80;
extern double  FL_STO_LOW        =  20;
// -----------------------    External Indicator   ----------------------- //

int      _Tick;
int      _Spread;
double   _LastBars;
string   _Trend       = "Idle";

void OnTick()
{
   GetValue();
   EntryOrder();
   if (_LastBars != Bars)
   {
      _LastBars   =  Bars;
   }
   Comment(
      "FX Scalper Pro Thailand" + "\n" +
      ".................................................................." + "\n" +
      "Trend = " + _Trend + "\n" +
      "Fish = " + fisher_value + "\n" +
      "..................................................................");
}

void EntryOrder()
{
   double MyPoint=Point;
   if(Digits==3 || Digits==5) MyPoint=Point*10;
   
   double TheStopLoss=0;
   double TheTakeProfit=0;
  
   if( TotalOrdersCount() < Max_order ) 
   {
      int result = 0;
      if ( _Trend == "UP Trend" )
      {
         bool state_buy = histrogram_value > signal_value && cci_value <= CCI_Oversold_level && rsi_value <= RSI_Oversold_level && fisher_value > 0.001 && MathAbs(_LastBars - MarketInfo(Symbol(), MODE_ASK)) >= DistanceBar / 10000;
         bool follow_trend = histrogram_value <= FL_HIST_LOW && MathAbs(histrogram_value - signal_value) <= FL_DISTANCE && cci_value <= FL_CCI_LOW && rsi_value < FL_RSI_LOW && stochastic_hist <= FL_STO_LOW && MathAbs(_LastBars - MarketInfo(Symbol(), MODE_ASK)) >= DistanceBar / 10000;
         if (follow_trend){
            result = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,"NGate System Thailand",MagicNumber,0,Blue);
            _LastBars = MarketInfo(Symbol(), MODE_ASK);
            if(result>0)
            {
               TheStopLoss=0;
               TheTakeProfit=0;
               if(TakeProfit>0) TheTakeProfit=Ask+TakeProfit*MyPoint;
               if(StopLoss>0) TheStopLoss=Ask-StopLoss*MyPoint;
               OrderSelect(result,SELECT_BY_TICKET);
               OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(TheStopLoss,Digits),NormalizeDouble(TheTakeProfit,Digits),0,Green);
            }
         }
      }
      else if ( _Trend == "DOWN Trend" )
      {
         bool state_sell = histrogram_value < signal_value && cci_value >= CCI_Overbought_level && rsi_value >= RSI_Overbought_level && fisher_value < -0.001 && MathAbs(_LastBars - MarketInfo(Symbol(), MODE_BID)) >= DistanceBar / 10000;
         bool follow_trend = histrogram_value >= FL_HIST_HIGH && MathAbs(histrogram_value - signal_value) <= FL_DISTANCE && cci_value >= FL_CCI_HIGH && rsi_value > FL_RSI_HIGH && stochastic_hist >= FL_STO_HIGH && MathAbs(_LastBars - MarketInfo(Symbol(), MODE_ASK)) >= DistanceBar / 10000;
         if (follow_trend){
            result = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,"NGate System Thailand",MagicNumber,0,Red);
            _LastBars = MarketInfo(Symbol(), MODE_BID);
            if(result>0)
            {
               TheStopLoss=0;
               TheTakeProfit=0;
               if(TakeProfit>0) TheTakeProfit=Bid-TakeProfit*MyPoint;
               if(StopLoss>0) TheStopLoss=Bid+StopLoss*MyPoint;
               OrderSelect(result,SELECT_BY_TICKET);
               OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(TheStopLoss,Digits),NormalizeDouble(TheTakeProfit,Digits),0,Green);
            }
         }
      }
   }
   for(int cnt=0;cnt<OrdersTotal();cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   
         OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber 
         )  
        {
         if(OrderType()==OP_BUY)  
           {
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>MyPoint*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-MyPoint*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStop*MyPoint,OrderTakeProfit(),0,Green);
                    }
                 }
              }
           }
         else 
           {
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(MyPoint*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+MyPoint*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+MyPoint*TrailingStop,OrderTakeProfit(),0,Red);
                    }
                 }
              }
           }
        }
   }
}

double ma25_value, ma100_value, ma200_value, rsi_value, signal_value, histrogram_value, fisher_value, cci_value, stochastic_hist;

void GetValue()
{
   ma25_value         =   iMA(NULL,0,SignalEMAPeriod,0,MODE_EMA,PRICE_OPEN,0);
   ma100_value        =   iMA(NULL,0,FastEMAPeriod,0,MODE_EMA,PRICE_OPEN,0);
   ma200_value        =   iMA(NULL,0,SlowEMAPeriod,0,MODE_EMA,PRICE_OPEN,0);
   rsi_value          =   iRSI(NULL,0,RSI_period,PRICE_CLOSE,0);
   signal_value       =   iMACD(NULL,0,FastMACDPeriod,SlowMACDPeriod,SignalMACDPeriod,PRICE_CLOSE,MODE_SIGNAL,0);
   histrogram_value   =   iMACD(NULL,0,FastMACDPeriod,SlowMACDPeriod,SignalMACDPeriod,PRICE_CLOSE,MODE_MAIN,0);
   fisher_value       =   iCustom(NULL,0,"Fisher_Yur4ik",FisherPeriod,0,0);
   cci_value          =   iCCI(NULL,0,CCIPeriod,PRICE_TYPICAL,0);
   stochastic_hist    =   iStochastic(NULL,0,25,5,5,MODE_EMA,0,MODE_MAIN,0);
   
   
   //--- Update Trend
   TrendAnalysis(ma100_value, ma200_value, ma25_value);
}

double Calcurate_Distance(double fastema, double slowema, double target)
{
   if (MathAbs(fastema - slowema) >= target / 10000){
      return true;
   }else {
      return false;
   }
}

void TrendAnalysis(double fastema, double slowema, double signalma)
{
   if (fastema > slowema && Calcurate_Distance(fastema, slowema, DistanceEMA) && Calcurate_Distance(signalma, fastema, DistanceSignal) && signalma > fastema && fastema > slowema ){
      _Trend = "UP Trend";
   }
   else if (fastema < slowema && Calcurate_Distance(fastema, slowema, DistanceEMA) && Calcurate_Distance(signalma, fastema, DistanceSignal) && signalma < fastema && fastema < slowema ){
      _Trend = "DOWN Trend";
   }
   else {
      _Trend = "Sideways";
   }
}

int TotalOrdersCount()
{
  int result=0;
  for(int i=0;i<OrdersTotal();i++)
  {
     OrderSelect(i,SELECT_BY_POS ,MODE_TRADES);
     if (OrderMagicNumber()==MagicNumber) result++;

   }
  return (result);
}
