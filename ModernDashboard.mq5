//------------------------------------------------------------------
// ModernDashboard.mq5  
// Version 7.13 - Fixed Icons (Reliable & Clean)
//------------------------------------------------------------------
#property copyright "Modern Dashboard EA - OrderCalcProfit Method"
#property version   "7.13"
#property strict

#include <Trade\Trade.mqh>

CTrade trade;

// Dashboard settings
input int DashboardX = 30;
input int DashboardY = 30;
input int DashboardWidth = 420;
input int CardSpacing = 15;

// Auto Stop-Loss Settings
input group "Auto Stop-Loss Protection"
input bool EnableAutoSL = true;
input double InitialAccountBalance = 100000.0;
input double AutoSLRiskPercent = 1.0;
input int AutoSLTimeoutSeconds = 60;
input bool ShowAutoSLNotifications = false;
input int MaxRetryAttempts = 5;
input bool RecheckIfSLRemoved = true;

// Risk rule limits  
double RISK_RULE_MARGIN_MIN = 20.0;
double RISK_RULE_MARGIN_MAX = 30.0;
double RISK_RULE_MARGIN_HARD = 70.0;
double RISK_RULE_PER_TRADE = 1.0;
double RISK_RULE_TOTAL = 3.0;

// Colors
color bgColor = clrWhite;
color cardBgColor = C'250,250,250';
color textDark = C'26,26,26';
color textMuted = C'136,136,136';
color accentGreen = C'93,122,62';
color profitGreen = C'76,175,80';
color lossRed = C'244,67,54';
color borderColor = C'240,240,240';
color warningOrange = C'255,152,0';
color accentBlue = C'33,150,243';

string prefix = "MD_";

struct PositionTracker
{
   ulong ticket;
   datetime openTime;
   bool slSet;
   int retryCount;
   datetime lastRetryTime;
};

PositionTracker trackedPositions[];
datetime lastDashboardUpdate = 0;
int dashboardUpdateInterval = 5;

//------------------------------------------------------------------
int OnInit()
{
   if(EnableAutoSL && InitialAccountBalance <= 0)
   {
      Alert("ERROR: Initial Account Balance must be set!");
      return(INIT_PARAMETERS_INCORRECT);
   }

   ArrayResize(trackedPositions, 0);

   Print("╔══════════════════════════════════════════════════════════╗");
   Print("║   MODERN DASHBOARD - Fixed Icons v7.13                  ║");
   Print("╚══════════════════════════════════════════════════════════╝");
   Print("Using OrderCalcProfit for accurate SL calculation");
   Print("");

   CreateDashboard();
   UpdateDashboard();
   EventSetMillisecondTimer(1000);

   if(EnableAutoSL)
   {
      Print("✅ Auto Stop-Loss Protection ENABLED");
      Print("- Initial Balance: ", InitialAccountBalance);
      Print("- Risk Per Trade: ", AutoSLRiskPercent, "%");
      Print("- Timeout: ", AutoSLTimeoutSeconds, " seconds");
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, prefix);
   EventKillTimer();
   ArrayResize(trackedPositions, 0);
}

void OnTick() {}

void OnTimer()
{
   datetime currentTime = TimeCurrent();
   if(currentTime - lastDashboardUpdate >= dashboardUpdateInterval)
   {
      UpdateDashboard();
      lastDashboardUpdate = currentTime;
   }
   if(EnableAutoSL) CheckAndSetAutoStopLoss();
}

//------------------------------------------------------------------
void CheckAndSetAutoStopLoss()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || 
      !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      return;

   datetime currentTime = TimeCurrent();
   int totalPositions = PositionsTotal();
   UpdateTrackedPositions();

   for(int i = 0; i < totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;

      double sl = PositionGetDouble(POSITION_SL);
      string symbol = PositionGetString(POSITION_SYMBOL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double volume = PositionGetDouble(POSITION_VOLUME);

      int trackerIndex = FindPositionInTracker(ticket);

      if(trackerIndex < 0)
      {
         datetime positionOpenTime = (datetime)PositionGetInteger(POSITION_TIME);
         AddPositionToTracker(ticket, positionOpenTime);
         trackerIndex = FindPositionInTracker(ticket);
         Print("🎯 Tracking position #", ticket, " (", symbol, ")");
      }

      if(sl != 0)
      {
         if(trackerIndex >= 0 && !trackedPositions[trackerIndex].slSet)
         {
            trackedPositions[trackerIndex].slSet = true;
            Print("✅ Position #", ticket, " has SL");
         }
         continue;
      }
      else
      {
         if(trackerIndex >= 0 && trackedPositions[trackerIndex].slSet && RecheckIfSLRemoved)
         {
            Print("⚠ SL REMOVED from #", ticket, " - resetting");
            trackedPositions[trackerIndex].slSet = false;
            trackedPositions[trackerIndex].retryCount = 0;
         }
      }

      if(trackerIndex >= 0 && !trackedPositions[trackerIndex].slSet)
      {
         int secondsElapsed = (int)(currentTime - trackedPositions[trackerIndex].openTime);

         if(secondsElapsed >= AutoSLTimeoutSeconds)
         {
            if(trackedPositions[trackerIndex].retryCount >= MaxRetryAttempts)
            {
               trackedPositions[trackerIndex].slSet = true;
               continue;
            }

            if(trackedPositions[trackerIndex].retryCount > 0 && 
               currentTime - trackedPositions[trackerIndex].lastRetryTime < 5)
               continue;

            trackedPositions[trackerIndex].retryCount++;
            trackedPositions[trackerIndex].lastRetryTime = currentTime;

            Print("⚠ Timeout for #", ticket, " (", symbol, ") - Setting Auto SL");

            double autoSL = CalculateAutoStopLoss(symbol, posType, openPrice, volume);

            if(autoSL > 0)
            {
               if(trade.PositionModify(ticket, autoSL, PositionGetDouble(POSITION_TP)))
               {
                  trackedPositions[trackerIndex].slSet = true;

                  string message = StringFormat("✅ Auto SL Set: %s #%I64u @ %.5f | Risk: %.2f%%",
                                                symbol, ticket, autoSL, AutoSLRiskPercent);
                  Print(message);
                  if(ShowAutoSLNotifications) Alert(message);
               }
               else
               {
                  Print("❌ Failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
               }
            }
         }
      }
   }
}

//------------------------------------------------------------------
// WORKING LOGIC: Using OrderCalcProfit Method
//------------------------------------------------------------------
double CalculateAutoStopLoss(string symbol, ENUM_POSITION_TYPE posType, double openPrice, double lotSize)
{
   if(lotSize <= 0)
   {
      Print("❌ Error: Lot size must be greater than 0");
      return 0;
   }

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   if(point <= 0)
   {
      Print("❌ Error: Invalid symbol data");
      return 0;
   }

   double riskMoney = InitialAccountBalance * (AutoSLRiskPercent / 100.0);
   double slDirection = (posType == POSITION_TYPE_BUY) ? -1.0 : 1.0;
   double testDistance = 100 * point;
   double testPrice = openPrice + (slDirection * testDistance);
   double testProfit = 0;

   ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   Print("===========================================================");
   PrintFormat("SYMBOL: %s | LOTS: %.2f | RISK: %.1f%%", symbol, lotSize, AutoSLRiskPercent);
   PrintFormat("ACCOUNT BALANCE: %.2f", InitialAccountBalance);
   PrintFormat("CASH AT RISK: $%.2f", riskMoney);
   Print("-----------------------------------------------------------");

   if(!OrderCalcProfit(orderType, symbol, lotSize, openPrice, testPrice, testProfit))
   {
      Print("❌ Error: OrderCalcProfit failed for ", symbol);
      return 0;
   }

   PrintFormat("Test: 100 points = $%.2f loss", MathAbs(testProfit));

   double lossPerPoint = MathAbs(testProfit) / testDistance;
   PrintFormat("Loss Per Point: $%.5f", lossPerPoint);

   double finalDistPoints = riskMoney / lossPerPoint;
   PrintFormat("Required Distance: %.0f points (%.5f price units)", finalDistPoints / point, finalDistPoints);

   double targetSL = openPrice + (slDirection * finalDistPoints);

   if(posType == POSITION_TYPE_BUY)
      PrintFormat("FOR BUY  @ %.*f | STOP LOSS: %.*f", digits, openPrice, digits, targetSL);
   else
      PrintFormat("FOR SELL @ %.*f | STOP LOSS: %.*f", digits, openPrice, digits, targetSL);

   targetSL = NormalizeDouble(targetSL, digits);

   double minStopLevel = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                         SymbolInfoDouble(symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(symbol, SYMBOL_ASK);

   if(posType == POSITION_TYPE_BUY)
   {
      if(currentPrice - targetSL < minStopLevel)
      {
         targetSL = currentPrice - minStopLevel;
         targetSL = NormalizeDouble(targetSL, digits);
         Print("⚠ Adjusted to minimum stop level: ", minStopLevel / point, " points");
      }
   }
   else
   {
      if(targetSL - currentPrice < minStopLevel)
      {
         targetSL = currentPrice + minStopLevel;
         targetSL = NormalizeDouble(targetSL, digits);
         Print("⚠ Adjusted to minimum stop level: ", minStopLevel / point, " points");
      }
   }

   Print("===========================================================");
   return targetSL;
}

void UpdateTrackedPositions()
{
   for(int i = ArraySize(trackedPositions) - 1; i >= 0; i--)
   {
      bool found = false;
      for(int j = 0; j < PositionsTotal(); j++)
      {
         if(PositionGetTicket(j) == trackedPositions[i].ticket)
         {
            found = true;
            break;
         }
      }
      if(!found) RemovePositionFromTracker(i);
   }
}

int FindPositionInTracker(ulong ticket)
{
   for(int i = 0; i < ArraySize(trackedPositions); i++)
      if(trackedPositions[i].ticket == ticket) return i;
   return -1;
}

void AddPositionToTracker(ulong ticket, datetime openTime)
{
   int size = ArraySize(trackedPositions);
   ArrayResize(trackedPositions, size + 1);
   trackedPositions[size].ticket = ticket;
   trackedPositions[size].openTime = openTime;
   trackedPositions[size].slSet = false;
   trackedPositions[size].retryCount = 0;
   trackedPositions[size].lastRetryTime = 0;
}

void RemovePositionFromTracker(int index)
{
   int size = ArraySize(trackedPositions);
   if(index < 0 || index >= size) return;
   for(int i = index; i < size - 1; i++)
      trackedPositions[i] = trackedPositions[i + 1];
   ArrayResize(trackedPositions, size - 1);
}

//------------------------------------------------------------------
// DASHBOARD FUNCTIONS
//------------------------------------------------------------------

void CreateDashboard()
{
   int totalWidth = (DashboardWidth * 2) + CardSpacing;
   CreateRoundedRect(prefix + "MainBg", DashboardX, DashboardY, totalWidth, 560, bgColor, 0);
   string accountName = AccountInfoString(ACCOUNT_NAME);
   if(accountName == "") accountName = "Trader";
   UpdateGreeting(accountName);
}

void UpdateGreeting(string accountName)
{
   MqlDateTime dt;
   TimeToStruct(TimeLocal(), dt);
   string greeting;
   if(dt.hour >= 5 && dt.hour < 12)
      greeting = "Good morning, " + accountName + "!";
   else if(dt.hour >= 12 && dt.hour < 17)
      greeting = "Good afternoon, " + accountName + "!";
   else if(dt.hour >= 17 && dt.hour < 21)
      greeting = "Good evening, " + accountName + "!";
   else
      greeting = "Good night, " + accountName + "!";
   CreateText(prefix + "Greeting", greeting, DashboardX + 20, DashboardY + 20, textDark, 11, true);
}

void UpdateDashboard()
{
   string accountName = AccountInfoString(ACCOUNT_NAME);
   if(accountName == "") accountName = "Trader";
   UpdateGreeting(accountName);
   UpdateMarketStatus();
   UpdateAutoSLStatus();

   int yPos = DashboardY + 55;
   CreateStatCards(yPos);
   yPos += 115;

   int leftColumnX = DashboardX + 20;
   int leftYPos = yPos;
   CreatePerformanceSection(leftYPos, leftColumnX);
   leftYPos += 180;
   CreatePositionSection(leftYPos, leftColumnX);

   int rightColumnX = leftColumnX + DashboardWidth + CardSpacing - 40;
   CreateRiskRulesSection(yPos, rightColumnX);
}

void UpdateAutoSLStatus()
{
   int leftColumnX = DashboardX + 20;
   int rightColumnX = leftColumnX + DashboardWidth + CardSpacing - 40;
   int statusX = rightColumnX + DashboardWidth - 40 - 145 - 160;
   int statusY = DashboardY + 20;

   if(EnableAutoSL)
   {
      CreateRoundedRect(prefix + "AutoSLBg", statusX, statusY, 150, 22, C'232,245,233', 0);
      CreateTextWithFont(prefix + "AutoSLIcon", "l", statusX + 8, statusY + 3, profitGreen, 11, false, "Wingdings");
      CreateText(prefix + "AutoSLText", "AUTO SL ACTIVE", statusX + 28, statusY + 4, C'27,94,32', 8, true);
   }
   else
   {
      CreateRoundedRect(prefix + "AutoSLBg", statusX, statusY, 150, 22, C'250,250,250', 0);
      CreateTextWithFont(prefix + "AutoSLIcon", "n", statusX + 8, statusY + 3, textMuted, 11, false, "Wingdings");
      CreateText(prefix + "AutoSLText", "AUTO SL OFF", statusX + 28, statusY + 4, textMuted, 8, true);
   }
}

void UpdateMarketStatus()
{
   bool isMarketOpen = IsForexMarketOpen();
   int leftColumnX = DashboardX + 20;
   int rightColumnX = leftColumnX + DashboardWidth + CardSpacing - 40;
   int statusX = rightColumnX + DashboardWidth - 40 - 145;
   int statusY = DashboardY + 20;

   color badgeBg = isMarketOpen ? C'212,237,218' : C'248,215,218';
   CreateRoundedRect(prefix + "StatusBg", statusX, statusY, 145, 22, badgeBg, 0);

   color iconColor = isMarketOpen ? profitGreen : lossRed;
   color textColor = isMarketOpen ? C'21,87,36' : C'114,28,36';
   CreateTextWithFont(prefix + "StatusIcon", "l", statusX + 8, statusY + 3, iconColor, 11, false, "Wingdings");

   string statusText = isMarketOpen ? "MARKET OPEN" : "MARKET CLOSED";
   CreateText(prefix + "StatusText", statusText, statusX + 24, statusY + 4, textColor, 8, true);
}

void CreateStatCards(int &yPos)
{
   int leftColumnWidth = DashboardWidth - 40;
   int cardWidth = (leftColumnWidth - 10) / 2;
   int xStart = DashboardX + 20;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   int openPositions = PositionsTotal();
   datetime startOfDay = GetStartOfDay();
   double todayProfit = GetProfitBetween(startOfDay, TimeCurrent());

   int xPos = xStart;
   // Wingdings "ô" = Dollar/Money bag icon for Account Balance
   CreateStatCard(xPos, yPos, cardWidth, "💰", FormatMoney(balance), "Account Balance", textDark);
   xPos += cardWidth + 10;
   // Wingdings "g" = List/Menu icon for Open Positions
   CreateStatCard(xPos, yPos, cardWidth, "📊", IntegerToString(openPositions), "Open Positions", textDark);

   xPos = xStart + DashboardWidth + CardSpacing - 40;
   // Wingdings "[" = Balance/Scale icon for Current Equity
   CreateStatCard(xPos, yPos, cardWidth, "💵", FormatMoney(equity), "Current Equity", textDark);
   xPos += cardWidth + 10;

   color plColor = todayProfit >= 0 ? profitGreen : lossRed;
   string plSign = todayProfit >= 0 ? "+" : "";
   // Wingdings: "é" (up arrow) for profit, "ê" (down arrow) for loss
   string plIcon = todayProfit >= 0 ? "📈" : "📉";
   CreateStatCard(xPos, yPos, cardWidth, plIcon, plSign + FormatMoney(todayProfit), "Today's P/L", plColor);
}

void CreateStatCard(int x, int y, int width, string icon, string value, string label, color valueColor)
{
   string cardName = prefix + "Card_" + label;
   CreateRoundedRect(cardName + "_Bg", x, y, width, 85, cardBgColor, 1);
   // Fixed icon size to 16 and proper spacing
   CreateTextWithFont(cardName + "_Icon", icon, x + 12, y + 14, textDark, 16, false, "Wingdings");
   CreateText(cardName + "_Val", value, x + 12, y + 40, valueColor, 10, true);
   CreateText(cardName + "_Lbl", label, x + 12, y + 65, textMuted, 7, false);
}

void CreatePerformanceSection(int &yPos, int xPos)
{
   CreateRoundedRect(prefix + "PerfBg", xPos, yPos, DashboardWidth - 40, 160, cardBgColor, 1);
   CreateText(prefix + "PerfTitle", "Performance Overview", xPos + 15, yPos + 15, textDark, 9, true);

   datetime now = TimeCurrent();
   double todayProfit = GetProfitBetween(GetStartOfDay(), now);
   double weekProfit = GetProfitBetween(GetStartOfWeek(), now);
   double monthProfit = GetProfitBetween(GetStartOfMonth(), now);

   MqlDateTime dt;
   TimeToStruct(now, dt);
   string monthName = GetMonthName(dt.mon);

   int rowY = yPos + 45;
   CreatePerformanceRow(xPos + 15, rowY, "Today", todayProfit);
   rowY += 35;
   CreatePerformanceRow(xPos + 15, rowY, "This Week", weekProfit);
   rowY += 35;
   CreatePerformanceRow(xPos + 15, rowY, monthName, monthProfit);
}

void CreatePerformanceRow(int x, int y, string label, double value)
{
   string rowName = prefix + "Perf_" + label;
   CreateText(rowName + "_Lbl", label, x, y, textMuted, 8, false);

   color valColor = value >= 0 ? profitGreen : lossRed;
   string sign = value >= 0 ? "+" : "";
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   CreateText(rowName + "_Val", sign + FormatMoney(value) + " " + currency, x + 210, y, valColor, 8, true);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance > 0)
   {
      double pct = (value / balance) * 100;
      string pctStr = (pct >= 0 ? "+" : "") + DoubleToString(pct, 1) + "%";
      CreateBadge(rowName + "_Badge", x + 100, y - 2, pctStr, pct >= 0);
   }
}

void CreatePositionSection(int &yPos, int xPos)
{
   int sectionHeight = 185;
   CreateRoundedRect(prefix + "PosBg", xPos, yPos, DashboardWidth - 40, sectionHeight, cardBgColor, 1);
   CreateText(prefix + "PosTitle", "Open Positions Analysis", xPos + 15, yPos + 15, textDark, 9, true);

   int totalPositions = PositionsTotal();
   int rowY = yPos + 45;
   string currency = AccountInfoString(ACCOUNT_CURRENCY);

   if(totalPositions == 0)
   {
      CreateText(prefix + "NoPos", "No open positions", xPos + 15, rowY, textMuted, 8, false);
   }
   else
   {
      double currentPL = 0;
      double potentialWin = 0;
      double potentialLoss = 0;

      for(int i = 0; i < totalPositions; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;

         string symbol = PositionGetString(POSITION_SYMBOL);
         double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         currentPL += profit;

         ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

         if(tp > 0)
         {
            double tpProfit = 0;
            if(OrderCalcProfit(orderType, symbol, volume, openPrice, tp, tpProfit))
               potentialWin += MathAbs(tpProfit);
         }

         if(sl > 0)
         {
            double slLoss = 0;
            if(OrderCalcProfit(orderType, symbol, volume, openPrice, sl, slLoss))
               potentialLoss += MathAbs(slLoss);
         }
      }

      color plColor = currentPL >= 0 ? profitGreen : lossRed;
      string plSign = currentPL >= 0 ? "+" : "";
      CreateText(prefix + "CurPLLbl", "Current P/L", xPos + 15, rowY, textMuted, 8, false);
      CreateText(prefix + "CurPLVal", plSign + FormatMoney(currentPL) + " " + currency, xPos + 210, rowY, plColor, 8, true);
      rowY += 27;

      CreateText(prefix + "PotWinLbl", "Potential Win (TP)", xPos + 15, rowY, textMuted, 8, false);
      CreateText(prefix + "PotWinVal", "+" + FormatMoney(potentialWin) + " " + currency, xPos + 210, rowY, profitGreen, 8, true);
      rowY += 27;

      CreateText(prefix + "PotLossLbl", "Potential Loss (SL)", xPos + 15, rowY, textMuted, 8, false);
      CreateText(prefix + "PotLossVal", "-" + FormatMoney(potentialLoss) + " " + currency, xPos + 210, rowY, lossRed, 8, true);
      rowY += 32;
   }

   string countdownStr = GetMarketCountdown();
   bool isMarketOpen = IsForexMarketOpen();

   CreateRoundedRect(prefix + "PosLine", xPos + 15, rowY, DashboardWidth - 70, 1, borderColor, 0);
   rowY += 12;

   string marketLabel = isMarketOpen ? "Market Closes In:" : "Market Opens In:";
   CreateText(prefix + "CountLbl", marketLabel, xPos + 15, rowY, textMuted, 7, false);
   rowY += 18;

   color countdownColor = isMarketOpen ? accentBlue : warningOrange;
   CreateText(prefix + "CountVal", countdownStr, xPos + 15, rowY, countdownColor, 11, true);
}

bool IsForexMarketOpen()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week == 6) return false;
   if(dt.day_of_week == 0 && dt.hour < 22) return false;
   if(dt.day_of_week == 5 && dt.hour >= 22) return false;
   return true;
}

string GetMarketCountdown()
{
   datetime currentTime = TimeLocal();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   datetime targetTime;

   if(dt.day_of_week == 6 || (dt.day_of_week == 0 && dt.hour < 22))
      return "WEEKEND";
   else if(dt.day_of_week == 0 && dt.hour >= 22)
   {
      MqlDateTime nextDay = dt;
      nextDay.day += 1;
      nextDay.hour = 0;
      nextDay.min = 0;
      nextDay.sec = 0;
      targetTime = StructToTime(nextDay);
   }
   else if(dt.day_of_week == 5 && dt.hour >= 22)
      return "WEEKEND";
   else
   {
      MqlDateTime endOfDay = dt;
      endOfDay.hour = 23;
      endOfDay.min = 59;
      endOfDay.sec = 59;
      targetTime = StructToTime(endOfDay);
   }

   int secondsRemaining = (int)(targetTime - currentTime);
   if(secondsRemaining < 0) secondsRemaining = 0;

   int hours = secondsRemaining / 3600;
   int minutes = (secondsRemaining % 3600) / 60;
   int seconds = secondsRemaining % 60;

   return (hours < 10 ? "0" : "") + IntegerToString(hours) + ":" +
          (minutes < 10 ? "0" : "") + IntegerToString(minutes) + ":" +
          (seconds < 10 ? "0" : "") + IntegerToString(seconds);
}

void CreateRiskRulesSection(int yPos, int xPos)
{
   int sectionHeight = 365;
   int sectionWidth = DashboardWidth - 40;
   CreateRoundedRect(prefix + "RiskBg", xPos, yPos, sectionWidth, sectionHeight, cardBgColor, 1);
   CreateText(prefix + "RiskTitle", "FundedNext Risk Rules", xPos + 15, yPos + 15, textDark, 9, true);

   double marginUsage = GetMarginUsagePercent();
   double riskPerTrade = GetRiskPerTradePercent();
   double totalRisk = GetTotalRiskPercent();

   int rowY = yPos + 50;
   int barWidth = sectionWidth - 30;

   CreateRiskRuleRow(xPos + 15, rowY, "Margin Usage", marginUsage, RISK_RULE_MARGIN_MIN, RISK_RULE_MARGIN_MAX, RISK_RULE_MARGIN_HARD, true, barWidth);
   rowY += 80;
   CreateRiskRuleRow(xPos + 15, rowY, "Risk Per Trade", riskPerTrade, 0, RISK_RULE_PER_TRADE, RISK_RULE_PER_TRADE, false, barWidth);
   rowY += 80;
   CreateRiskRuleRow(xPos + 15, rowY, "Total Risk", totalRisk, 0, RISK_RULE_TOTAL, RISK_RULE_TOTAL, false, barWidth);
   rowY += 85;

   bool hasViolation = (marginUsage >= RISK_RULE_MARGIN_HARD || riskPerTrade >= RISK_RULE_PER_TRADE || totalRisk >= RISK_RULE_TOTAL);
   bool hasCaution = !hasViolation && ((marginUsage >= RISK_RULE_MARGIN_MAX || marginUsage < RISK_RULE_MARGIN_MIN) || 
                                       riskPerTrade >= RISK_RULE_PER_TRADE * 0.7 || totalRisk >= RISK_RULE_TOTAL * 0.7);

   if(hasViolation)
   {
      CreateText(prefix + "RiskWarn1", "! VIOLATION", xPos + 15, rowY, lossRed, 7, true);
      CreateText(prefix + "RiskWarn2", "Reduce positions now", xPos + 15, rowY + 15, lossRed, 7, false);
   }
   else if(hasCaution)
   {
      CreateText(prefix + "RiskWarn1", "! CAUTION", xPos + 15, rowY, warningOrange, 7, true);
      CreateText(prefix + "RiskWarn2", "Target 20-30% margin", xPos + 15, rowY + 15, warningOrange, 7, false);
   }
   else
   {
      CreateText(prefix + "RiskWarn1", "v All compliant", xPos + 15, rowY, accentGreen, 7, true);
      ObjectDelete(0, prefix + "RiskWarn2");
   }
}

void CreateRiskRuleRow(int x, int y, string label, double current, double targetMin, double targetMax, double hardMax, bool hasRange, int barWidth)
{
   string rowName = prefix + "RiskRule_" + label;

   color statusColor = accentGreen;
   if(current >= hardMax)
      statusColor = lossRed;
   else if(hasRange && (current >= targetMax || current < targetMin))
      statusColor = warningOrange;
   else if(!hasRange && current >= targetMax * 0.7)
      statusColor = warningOrange;

   CreateText(rowName + "_Lbl", label, x, y, textDark, 8, true);
   string valStr = DoubleToString(current, 2) + "%";
   CreateText(rowName + "_Val", valStr, x + barWidth - 35, y, statusColor, 9, true);

   string targetStr;
   if(hasRange)
      targetStr = "Target: " + DoubleToString(targetMin, 0) + "-" + DoubleToString(targetMax, 0) + "%";
   else
      targetStr = "Max: " + DoubleToString(targetMax, 1) + "%";

   CreateText(rowName + "_Target", targetStr, x, y + 18, textMuted, 7, false);

   int barY = y + 38;
   CreateProgressBar(rowName + "_Bar", x, barY, barWidth, current, hardMax, hasRange ? targetMax : targetMax * 0.7);
}

void CreateProgressBar(string name, int x, int y, int width, double value, double maxValue, double warningThreshold)
{
   CreateRoundedRect(name + "_Bg", x, y, width, 8, C'240,240,240', 0);

   int fillWidth = (int)((value / maxValue) * width);
   if(fillWidth > width) fillWidth = width;
   if(fillWidth < 0) fillWidth = 0;

   color fillColor = accentGreen;
   if(value >= maxValue)
      fillColor = lossRed;
   else if(value >= warningThreshold)
      fillColor = warningOrange;

   if(fillWidth > 0)
      CreateRoundedRect(name + "_Fill", x, y, fillWidth, 8, fillColor, 0);
}

double GetMarginUsagePercent()
{
   double accountMargin = AccountInfoDouble(ACCOUNT_MARGIN);
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(accountEquity == 0) return 0;
   return (accountMargin / accountEquity) * 100;
}

double GetRiskPerTradePercent()
{
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(accountEquity == 0) return 0;

   double maxRiskPerTrade = 0;
   int totalPositions = PositionsTotal();

   for(int i = 0; i < totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(sl == 0) continue;

      ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double slLoss = 0;

      if(OrderCalcProfit(orderType, symbol, volume, openPrice, sl, slLoss))
      {
         double riskPercent = (MathAbs(slLoss) / accountEquity) * 100;
         if(riskPercent > maxRiskPerTrade)
            maxRiskPerTrade = riskPercent;
      }
   }

   return maxRiskPerTrade;
}

double GetTotalRiskPercent()
{
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(accountEquity == 0) return 0;

   double totalRisk = 0;
   int totalPositions = PositionsTotal();

   for(int i = 0; i < totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(sl == 0) continue;

      ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double slLoss = 0;

      if(OrderCalcProfit(orderType, symbol, volume, openPrice, sl, slLoss))
      {
         double riskPercent = (MathAbs(slLoss) / accountEquity) * 100;
         totalRisk += riskPercent;
      }
   }

   return totalRisk;
}

void CreateRoundedRect(string name, int x, int y, int width, int height, color bg, int borderWidth)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   if(borderWidth > 0)
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
}

void CreateText(string name, string text, int x, int y, color clr, int size, bool bold)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateTextWithFont(string name, string text, int x, int y, color clr, int size, bool bold, string font)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateBadge(string name, int x, int y, string text, bool isPositive)
{
   CreateRoundedRect(name + "_Bg", x, y, 50, 18, isPositive ? C'212,237,218' : C'248,215,218', 0);
   color txtColor = isPositive ? C'21,87,36' : C'114,28,36';
   CreateText(name + "_Txt", text, x + 8, y + 3, txtColor, 7, true);
}

string FormatMoney(double value)
{
   return DoubleToString(MathAbs(value), 2);
}

datetime GetStartOfDay()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

datetime GetStartOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return GetStartOfDay() - (dt.day_of_week * 86400);
}

datetime GetStartOfMonth()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

double GetProfitBetween(datetime from, datetime to)
{
   double total = 0;
   HistorySelect(from, to);
   int deals = HistoryDealsTotal();

   for(int i = 0; i < deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);

      if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
      {
         total += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         total += HistoryDealGetDouble(ticket, DEAL_SWAP);
         total += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      }
   }

   return total;
}

string GetMonthName(int month)
{
   string months[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
   if(month >= 1 && month <= 12)
      return months[month - 1];
   return "";
}
//------------------------------------------------------------------
