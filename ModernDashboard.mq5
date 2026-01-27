//+------------------------------------------------------------------+
//|                                    ModernDashboard.mq5            |
//|                                  Modern Trading Dashboard         |
//+------------------------------------------------------------------+
#property copyright "Modern Dashboard EA"
#property version   "1.43"
#property strict

// Dashboard settings
input int DashboardX = 30;
input int DashboardY = 30;
input int DashboardWidth = 420;
input int CardSpacing = 15;

// Risk rule limits
double RISK_RULE_MARGIN_MIN   = 20.0;
double RISK_RULE_MARGIN_MAX   = 30.0;
double RISK_RULE_MARGIN_HARD  = 70.0;
double RISK_RULE_PER_TRADE    = 1.0;
double RISK_RULE_TOTAL        = 3.0;

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    CreateDashboard();
    UpdateDashboard();
    EventSetMillisecondTimer(1000); // Changed to 1 second for countdown
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, prefix);
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
    UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Create dashboard structure                                        |
//+------------------------------------------------------------------+
void CreateDashboard()
{
    // Main background - expanded width for grid layout
    int totalWidth = (DashboardWidth * 2) + CardSpacing;
    CreateRoundedRect(prefix + "MainBg", DashboardX, DashboardY, totalWidth, 560, bgColor, 0);
    
    // Greeting text - will be updated dynamically
    string accountName = AccountInfoString(ACCOUNT_NAME);
    if(accountName == "") accountName = "Trader";
    UpdateGreeting(accountName);
}

//+------------------------------------------------------------------+
//| Update greeting based on time of day                             |
//+------------------------------------------------------------------+
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
    
    CreateText(prefix + "Greeting", greeting, DashboardX + 20, DashboardY + 20, 
               textDark, 11, true);
}

//+------------------------------------------------------------------+
//| Update dashboard content                                         |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    // Update greeting based on time
    string accountName = AccountInfoString(ACCOUNT_NAME);
    if(accountName == "") accountName = "Trader";
    UpdateGreeting(accountName);
    
    // Update market status in header
    UpdateMarketStatus();
    
    int yPos = DashboardY + 55;
    
    // Create stat cards - aligned with columns below
    CreateStatCards(yPos);
    yPos += 115;
    
    // LEFT COLUMN: Performance and Position sections
    int leftColumnX = DashboardX + 20;
    int leftYPos = yPos;
    
    CreatePerformanceSection(leftYPos, leftColumnX);
    leftYPos += 180;
    
    // Extended position section to match right column height
    CreatePositionSection(leftYPos, leftColumnX);
    
    // RIGHT COLUMN: Risk Rules Monitor - aligned with left column
    int rightColumnX = leftColumnX + DashboardWidth + CardSpacing - 40;
    CreateRiskRulesSection(yPos, rightColumnX);
}

//+------------------------------------------------------------------+
//| Update Market Status in Header                                   |
//+------------------------------------------------------------------+
void UpdateMarketStatus()
{
    bool isMarketOpen = IsForexMarketOpen();
    
    // Position aligned with right column (Risk Monitor box)
    int leftColumnX = DashboardX + 20;
    int rightColumnX = leftColumnX + DashboardWidth + CardSpacing - 40;
    int statusX = rightColumnX + (DashboardWidth - 40) - 145; // Align to right edge of risk box
    int statusY = DashboardY + 20;
    
    // Status badge background
    color badgeBg = isMarketOpen ? C'212,237,218' : C'248,215,218';
    CreateRoundedRect(prefix + "StatusBg", statusX, statusY, 145, 22, badgeBg, 0);
    
    // Status indicator dot and text
    string statusIcon = "●";
    color iconColor = isMarketOpen ? profitGreen : lossRed;
    color textColor = isMarketOpen ? C'21,87,36' : C'114,28,36';
    
    CreateText(prefix + "StatusIcon", statusIcon, statusX + 8, statusY + 3, iconColor, 11, false);
    
    string statusText = isMarketOpen ? "MARKET OPEN" : "MARKET CLOSED";
    CreateText(prefix + "StatusText", statusText, statusX + 24, statusY + 4, textColor, 8, true);
}

//+------------------------------------------------------------------+
//| Create stat cards (top row) - aligned with columns               |
//+------------------------------------------------------------------+
void CreateStatCards(int yPos)
{
    // Calculate card width to align with columns below
    int leftColumnWidth = DashboardWidth - 40;
    int cardWidth = (leftColumnWidth - 10) / 2;
    int xStart = DashboardX + 20;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    int openPositions = PositionsTotal();
    
    // Get today's profit
    datetime startOfDay = GetStartOfDay();
    double todayProfit = GetProfitBetween(startOfDay, TimeCurrent());
    
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    // LEFT SIDE - 2 cards aligned with Performance/Position column
    int xPos = xStart;
    
    // Card 1: Balance
    CreateStatCard(xPos, yPos, cardWidth, "💰", FormatMoney(balance), "Account Balance", textDark);
    xPos += cardWidth + 10;
    
    // Card 2: Open Positions
    CreateStatCard(xPos, yPos, cardWidth, "📊", IntegerToString(openPositions), "Open Positions", textDark);
    
    // RIGHT SIDE - 2 cards aligned with Risk Monitor column
    xPos = xStart + DashboardWidth + CardSpacing - 40;
    
    // Card 3: Equity
    CreateStatCard(xPos, yPos, cardWidth, "💵", FormatMoney(equity), "Current Equity", textDark);
    xPos += cardWidth + 10;
    
    // Card 4: Today's P&L
    color plColor = todayProfit >= 0 ? profitGreen : lossRed;
    string plSign = todayProfit >= 0 ? "+" : "";
    CreateStatCard(xPos, yPos, cardWidth, todayProfit >= 0 ? "📈" : "📉", 
                   plSign + FormatMoney(todayProfit), "Today's P&L", plColor);
}

//+------------------------------------------------------------------+
//| Create single stat card                                          |
//+------------------------------------------------------------------+
void CreateStatCard(int x, int y, int width, string icon, string value, string label, color valueColor)
{
    string cardName = prefix + "Card_" + label;
    
    // Card background
    CreateRoundedRect(cardName + "_Bg", x, y, width, 85, cardBgColor, 1);
    
    // Icon
    CreateText(cardName + "_Icon", icon, x + 12, y + 12, textDark, 18, false);
    
    // Value
    CreateText(cardName + "_Val", value, x + 12, y + 40, valueColor, 10, true);
    
    // Label
    CreateText(cardName + "_Lbl", label, x + 12, y + 65, textMuted, 7, false);
}

//+------------------------------------------------------------------+
//| Create performance section                                       |
//+------------------------------------------------------------------+
void CreatePerformanceSection(int yPos, int xPos)
{
    // Section background
    CreateRoundedRect(prefix + "PerfBg", xPos, yPos, DashboardWidth - 40, 160, cardBgColor, 1);
    
    // Title
    CreateText(prefix + "PerfTitle", "Performance Overview", xPos + 15, yPos + 15, textDark, 9, true);
    
    // Get profit data
    datetime now = TimeCurrent();
    double todayProfit = GetProfitBetween(GetStartOfDay(), now);
    double weekProfit = GetProfitBetween(GetStartOfWeek(), now);
    double monthProfit = GetProfitBetween(GetStartOfMonth(), now);
    
    MqlDateTime dt;
    TimeToStruct(now, dt);
    string monthName = GetMonthName(dt.mon);
    
    int rowY = yPos + 45;
    
    // Today
    CreatePerformanceRow(xPos + 15, rowY, "Today", todayProfit);
    rowY += 35;
    
    // This Week
    CreatePerformanceRow(xPos + 15, rowY, "This Week", weekProfit);
    rowY += 35;
    
    // This Month
    CreatePerformanceRow(xPos + 15, rowY, monthName, monthProfit);
}

//+------------------------------------------------------------------+
//| Create performance row                                           |
//+------------------------------------------------------------------+
void CreatePerformanceRow(int x, int y, string label, double value)
{
    string rowName = prefix + "Perf_" + label;
    
    // Label
    CreateText(rowName + "_Lbl", label, x, y, textMuted, 8, false);
    
    // Value
    color valColor = value >= 0 ? profitGreen : lossRed;
    string sign = value >= 0 ? "+" : "";
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    CreateText(rowName + "_Val", sign + FormatMoney(value) + " " + currency, x + 210, y, valColor, 8, true);
    
    // Percentage badge
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance > 0)
    {
        double pct = (value / balance) * 100;
        string pctStr = (pct >= 0 ? "+" : "") + DoubleToString(pct, 1) + "%";
        
        CreateBadge(rowName + "_Badge", x + 100, y - 2, pctStr, pct >= 0);
    }
}

//+------------------------------------------------------------------+
//| Create position section - EXTENDED HEIGHT                        |
//+------------------------------------------------------------------+
void CreatePositionSection(int yPos, int xPos)
{
    int sectionHeight = 185; // Extended to fill the gap
    
    // Section background
    CreateRoundedRect(prefix + "PosBg", xPos, yPos, DashboardWidth - 40, sectionHeight, cardBgColor, 1);
    
    // Title
    CreateText(prefix + "PosTitle", "Open Positions Analysis", xPos + 15, yPos + 15, textDark, 9, true);
    
    int totalPositions = PositionsTotal();
    
    int rowY = yPos + 45;
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    if(totalPositions == 0)
    {
        CreateText(prefix + "NoPos", "No open positions", xPos + 15, rowY, textMuted, 8, false);
        rowY += 35;
    }
    else
    {
        double currentPL = 0;
        double potentialWin = 0;
        double potentialLoss = 0;
        
        // Analyze positions
        for(int i = 0; i < totalPositions; i++)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0)
            {
                string symbol = PositionGetString(POSITION_SYMBOL);
                double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
                double volume = PositionGetDouble(POSITION_VOLUME);
                double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double sl = PositionGetDouble(POSITION_SL);
                double tp = PositionGetDouble(POSITION_TP);
                
                currentPL += profit;
                
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
                
                if(tp > 0)
                {
                    double tpDistance = MathAbs(tp - openPrice);
                    potentialWin += (tpDistance / tickSize) * pointValue * volume;
                }
                
                if(sl > 0)
                {
                    double slDistance = MathAbs(openPrice - sl);
                    potentialLoss += (slDistance / tickSize) * pointValue * volume;
                }
            }
        }
        
        // Current P&L
        color plColor = currentPL >= 0 ? profitGreen : lossRed;
        string plSign = currentPL >= 0 ? "+" : "";
        CreateText(prefix + "CurPL_Lbl", "Current P&L", xPos + 15, rowY, textMuted, 8, false);
        CreateText(prefix + "CurPL_Val", plSign + FormatMoney(currentPL) + " " + currency, 
                   xPos + 210, rowY, plColor, 8, true);
        rowY += 27;
        
        // Potential Win
        CreateText(prefix + "PotWin_Lbl", "Potential Win (TP)", xPos + 15, rowY, textMuted, 8, false);
        CreateText(prefix + "PotWin_Val", "+" + FormatMoney(potentialWin) + " " + currency, 
                   xPos + 210, rowY, profitGreen, 8, true);
        rowY += 27;
        
        // Potential Loss
        CreateText(prefix + "PotLoss_Lbl", "Potential Loss (SL)", xPos + 15, rowY, textMuted, 8, false);
        CreateText(prefix + "PotLoss_Val", "-" + FormatMoney(potentialLoss) + " " + currency, 
                   xPos + 210, rowY, lossRed, 8, true);
        rowY += 32;
    }
    
    // Market Countdown Section - COMPACT
    string countdownStr = GetMarketCountdown();
    bool isMarketOpen = IsForexMarketOpen();
    
    // Separator line
    CreateRoundedRect(prefix + "PosLine", xPos + 15, rowY, DashboardWidth - 70, 1, borderColor, 0);
    rowY += 12;
    
    // Countdown label and time on same area
    string marketLabel = isMarketOpen ? "Market Closes In:" : "Market Opens In:";
    CreateText(prefix + "CountLbl", marketLabel, xPos + 15, rowY, textMuted, 7, false);
    rowY += 18;
    
    // Countdown timer - clean and simple
    color countdownColor = isMarketOpen ? accentBlue : warningOrange;
    CreateText(prefix + "CountVal", countdownStr, xPos + 15, rowY, countdownColor, 11, true);
}

//+------------------------------------------------------------------+
//| Check if Forex market is open                                    |
//+------------------------------------------------------------------+
bool IsForexMarketOpen()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Forex market is closed on Saturday and most of Sunday
    if(dt.day_of_week == 6) return false; // Saturday
    if(dt.day_of_week == 0 && dt.hour < 22) return false; // Sunday before 22:00 GMT
    
    // Friday after 22:00 GMT market is closed
    if(dt.day_of_week == 5 && dt.hour >= 22) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get market countdown timer - DAILY SESSION VERSION                |
//+------------------------------------------------------------------+
string GetMarketCountdown()
{
    datetime currentTime = TimeLocal(); // Use local time
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    datetime targetTime;
    
    // Weekend - market is closed
    if(dt.day_of_week == 6 || (dt.day_of_week == 0 && dt.hour < 22))
    {
        // Show "MARKET CLOSED" for weekend
        return "WEEKEND";
    }
    else if(dt.day_of_week == 0 && dt.hour >= 22)
    {
        // Sunday after 22:00 - count to Monday 00:00
        MqlDateTime nextDay = dt;
        nextDay.day += 1;
        nextDay.hour = 0;
        nextDay.min = 0;
        nextDay.sec = 0;
        targetTime = StructToTime(nextDay);
    }
    else if(dt.day_of_week == 5 && dt.hour >= 22)
    {
        // Friday after 22:00 - show weekend
        return "WEEKEND";
    }
    else
    {
        // Weekday - count to end of current day (23:59:59)
        MqlDateTime endOfDay = dt;
        endOfDay.hour = 23;
        endOfDay.min = 59;
        endOfDay.sec = 59;
        targetTime = StructToTime(endOfDay);
    }
    
    // Calculate remaining time
    int secondsRemaining = (int)(targetTime - currentTime);
    if(secondsRemaining < 0) secondsRemaining = 0;
    
    int hours = secondsRemaining / 3600;
    int minutes = (secondsRemaining % 3600) / 60;
    int seconds = secondsRemaining % 60;
    
    // Format output
    return (hours < 10 ? "0" : "") + IntegerToString(hours) + ":" + 
           (minutes < 10 ? "0" : "") + IntegerToString(minutes) + ":" + 
           (seconds < 10 ? "0" : "") + IntegerToString(seconds);
}

//+------------------------------------------------------------------+
//| Create Risk Rules Section - RIGHT COLUMN                         |
//+------------------------------------------------------------------+
void CreateRiskRulesSection(int yPos, int xPos)
{
    int sectionHeight = 365; // Matches combined height of performance + position
    int sectionWidth = DashboardWidth - 40;
    
    // Section background
    CreateRoundedRect(prefix + "RiskBg", xPos, yPos, sectionWidth, sectionHeight, cardBgColor, 1);
    
    // Title
    CreateText(prefix + "RiskTitle", "⚠️ FundedNext Risk Rules", xPos + 15, yPos + 15, textDark, 9, true);
    
    // Get risk metrics
    double marginUsage = GetMarginUsagePercent();
    double riskPerTrade = GetRiskPerTradePercent();
    double totalRisk = GetTotalRiskPercent();
    
    int rowY = yPos + 50;
    int barWidth = sectionWidth - 30;
    
    // Rule 1: Margin Usage
    CreateRiskRuleRow(xPos + 15, rowY, "Margin Usage", marginUsage, 
                      RISK_RULE_MARGIN_MIN, RISK_RULE_MARGIN_MAX, RISK_RULE_MARGIN_HARD, true, barWidth);
    rowY += 80;
    
    // Rule 2: Risk Per Trade
    CreateRiskRuleRow(xPos + 15, rowY, "Risk Per Trade", riskPerTrade, 
                      0, RISK_RULE_PER_TRADE, RISK_RULE_PER_TRADE, false, barWidth);
    rowY += 80;
    
    // Rule 3: Total Risk
    CreateRiskRuleRow(xPos + 15, rowY, "Total Risk", totalRisk, 
                      0, RISK_RULE_TOTAL, RISK_RULE_TOTAL, false, barWidth);
    rowY += 85;
    
    // Warning message at bottom
    bool hasViolation = (marginUsage > RISK_RULE_MARGIN_HARD) || 
                        (riskPerTrade > RISK_RULE_PER_TRADE) || 
                        (totalRisk > RISK_RULE_TOTAL);
    
    bool hasCaution = !hasViolation && 
                      ((marginUsage > RISK_RULE_MARGIN_MAX || marginUsage < RISK_RULE_MARGIN_MIN) || 
                       (riskPerTrade > RISK_RULE_PER_TRADE * 0.7) || 
                       (totalRisk > RISK_RULE_TOTAL * 0.7));
    
    if(hasViolation)
    {
        CreateText(prefix + "RiskWarn1", "⚠️ VIOLATION:", 
                   xPos + 15, rowY, lossRed, 7, true);
        CreateText(prefix + "RiskWarn2", "Account termination risk!", 
                   xPos + 15, rowY + 15, lossRed, 7, false);
        CreateText(prefix + "RiskWarn3", "Reduce positions now", 
                   xPos + 15, rowY + 30, lossRed, 7, false);
    }
    else if(hasCaution)
    {
        CreateText(prefix + "RiskWarn1", "⚠️ CAUTION:", 
                   xPos + 15, rowY, warningOrange, 7, true);
        CreateText(prefix + "RiskWarn2", "Use FundedNext calculator", 
                   xPos + 15, rowY + 15, warningOrange, 7, false);
        CreateText(prefix + "RiskWarn3", "Target: 20-30% margin", 
                   xPos + 15, rowY + 30, warningOrange, 7, false);
    }
    else
    {
        CreateText(prefix + "RiskWarn1", "✅ All rules compliant", 
                   xPos + 15, rowY, accentGreen, 7, true);
        ObjectDelete(0, prefix + "RiskWarn2");
        ObjectDelete(0, prefix + "RiskWarn3");
    }
}

//+------------------------------------------------------------------+
//| Create risk rule row with progress bar                           |
//+------------------------------------------------------------------+
void CreateRiskRuleRow(int x, int y, string label, double current, double targetMin, double targetMax, double hardMax, bool hasRange, int barWidth)
{
    string rowName = prefix + "RiskRule_" + label;
    
    // Determine status color
    color statusColor = accentGreen;
    
    if(current > hardMax)
    {
        statusColor = lossRed;
    }
    else if(hasRange && (current > targetMax || current < targetMin))
    {
        statusColor = warningOrange;
    }
    else if(!hasRange && current > targetMax * 0.7)
    {
        statusColor = warningOrange;
    }
    
    // Label
    CreateText(rowName + "_Lbl", label, x, y, textDark, 8, true);
    
    // Current value - right aligned
    string valStr = DoubleToString(current, 2) + "%";
    CreateText(rowName + "_Val", valStr, x + barWidth - 35, y, statusColor, 9, true);
    
    // Target range
    string targetStr;
    if(hasRange)
        targetStr = "Target: " + DoubleToString(targetMin, 0) + "-" + DoubleToString(targetMax, 0) + 
                    "% | Max: " + DoubleToString(hardMax, 0) + "%";
    else
        targetStr = "Maximum: " + DoubleToString(targetMax, 1) + "%";
    
    CreateText(rowName + "_Target", targetStr, x, y + 18, textMuted, 7, false);
    
    // Progress bar
    int barY = y + 38;
    CreateProgressBar(rowName + "_Bar", x, barY, barWidth, current, hardMax, hasRange ? targetMax : targetMax * 0.7);
}

//+------------------------------------------------------------------+
//| Create progress bar                                              |
//+------------------------------------------------------------------+
void CreateProgressBar(string name, int x, int y, int width, double value, double maxValue, double warningThreshold)
{
    // Background bar
    CreateRoundedRect(name + "_Bg", x, y, width, 8, C'240,240,240', 0);
    
    // Calculate fill width
    int fillWidth = (int)((value / maxValue) * width);
    if(fillWidth > width) fillWidth = width;
    if(fillWidth < 0) fillWidth = 0;
    
    // Determine fill color
    color fillColor = accentGreen;
    if(value >= maxValue)
        fillColor = lossRed;
    else if(value >= warningThreshold)
        fillColor = warningOrange;
    
    // Fill bar
    if(fillWidth > 0)
        CreateRoundedRect(name + "_Fill", x, y, fillWidth, 8, fillColor, 0);
}

//+------------------------------------------------------------------+
//| Calculate margin usage percentage                                |
//+------------------------------------------------------------------+
double GetMarginUsagePercent()
{
    double accountMargin = AccountInfoDouble(ACCOUNT_MARGIN);
    double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(accountEquity <= 0) return 0;
    
    return (accountMargin / accountEquity) * 100;
}

//+------------------------------------------------------------------+
//| Calculate risk per trade percentage                             |
//+------------------------------------------------------------------+
double GetRiskPerTradePercent()
{
    double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(accountEquity <= 0) return 0;
    
    double maxRiskPerTrade = 0;
    int totalPositions = PositionsTotal();
    
    for(int i = 0; i < totalPositions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            
            if(sl > 0)
            {
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
                double slDistance = MathAbs(openPrice - sl);
                double riskAmount = (slDistance / tickSize) * pointValue * volume;
                double riskPercent = (riskAmount / accountEquity) * 100;
                
                if(riskPercent > maxRiskPerTrade)
                    maxRiskPerTrade = riskPercent;
            }
        }
    }
    
    return maxRiskPerTrade;
}

//+------------------------------------------------------------------+
//| Calculate total portfolio risk percentage                        |
//+------------------------------------------------------------------+
double GetTotalRiskPercent()
{
    double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(accountEquity <= 0) return 0;
    
    double totalRisk = 0;
    int totalPositions = PositionsTotal();
    
    for(int i = 0; i < totalPositions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            
            if(sl > 0)
            {
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
                double slDistance = MathAbs(openPrice - sl);
                double riskAmount = (slDistance / tickSize) * pointValue * volume;
                double riskPercent = (riskAmount / accountEquity) * 100;
                
                totalRisk += riskPercent;
            }
        }
    }
    
    return totalRisk;
}

//+------------------------------------------------------------------+
//| Create rounded rectangle (simulated with border)                 |
//+------------------------------------------------------------------+
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
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
    
    if(borderWidth > 0)
    {
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, borderWidth);
    }
}

//+------------------------------------------------------------------+
//| Create text label                                                |
//+------------------------------------------------------------------+
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
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Create badge                                                     |
//+------------------------------------------------------------------+
void CreateBadge(string name, int x, int y, string text, bool isPositive)
{
    // Badge background
    CreateRoundedRect(name + "_Bg", x, y, 50, 18, isPositive ? C'212,237,218' : C'248,215,218', 0);
    
    // Badge text
    color txtColor = isPositive ? C'21,87,36' : C'114,28,36';
    CreateText(name + "_Txt", text, x + 8, y + 3, txtColor, 7, true);
}

//+------------------------------------------------------------------+
//| Format money value                                               |
//+------------------------------------------------------------------+
string FormatMoney(double value)
{
    return DoubleToString(MathAbs(value), 2);
}

//+------------------------------------------------------------------+
//| Get start of day                                                 |
//+------------------------------------------------------------------+
datetime GetStartOfDay()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Get start of week                                                |
//+------------------------------------------------------------------+
datetime GetStartOfWeek()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    return GetStartOfDay() - (dt.day_of_week * 86400);
}

//+------------------------------------------------------------------+
//| Get start of month                                               |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Get profit between dates - FIXED VERSION                         |
//+------------------------------------------------------------------+
double GetProfitBetween(datetime from, datetime to)
{
    double total = 0;
    HistorySelect(from, to);
    
    int deals = HistoryDealsTotal();
    for(int i = 0; i < deals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0)
        {
            // Get deal type and entry type
            ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
            
            // Skip balance operations (deposits, withdrawals, credit)
            if(dealType == DEAL_TYPE_BALANCE)
            {
                continue; // Skip deposits/withdrawals
            }
            
            // Skip if it's not an actual trade entry/exit
            // Only count IN (opening) and OUT (closing) trades
            if(dealEntry != DEAL_ENTRY_IN && 
               dealEntry != DEAL_ENTRY_OUT && 
               dealEntry != DEAL_ENTRY_INOUT)
            {
                continue;
            }
            
            // Only count actual trading profits (BUY and SELL deals)
            if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
            {
                total += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                total += HistoryDealGetDouble(ticket, DEAL_SWAP);
                total += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            }
        }
    }
    
    return total;
}

//+------------------------------------------------------------------+
//| Get month name                                                    |
//+------------------------------------------------------------------+
string GetMonthName(int month)
{
    string months[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
    if(month >= 1 && month <= 12)
        return months[month - 1];
    return "";
}
//+------------------------------------------------------------------+
