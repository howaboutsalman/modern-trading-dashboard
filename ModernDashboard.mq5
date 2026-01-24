//+------------------------------------------------------------------+
//|                                    ModernDashboard.mq5            |
//|                                  Modern Trading Dashboard         |
//+------------------------------------------------------------------+
#property copyright "Modern Dashboard EA"
#property version   "1.00"
#property strict

// Dashboard settings
input int DashboardX = 30;
input int DashboardY = 30;
input int DashboardWidth = 420;
input int CardSpacing = 15;

// Colors
color bgColor = clrWhite;
color cardBgColor = C'250,250,250';
color textDark = C'26,26,26';
color textMuted = C'136,136,136';
color accentGreen = C'93,122,62';
color profitGreen = C'76,175,80';
color lossRed = C'244,67,54';
color borderColor = C'240,240,240';

string prefix = "MD_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    CreateDashboard();
    UpdateDashboard();
    EventSetMillisecondTimer(200);
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
    // Main background
    CreateRoundedRect(prefix + "MainBg", DashboardX, DashboardY, DashboardWidth, 500, bgColor, 0);
    
    // Greeting text
    string accountName = AccountInfoString(ACCOUNT_NAME);
    if(accountName == "") accountName = "Trader";
    CreateText(prefix + "Greeting", "Good morning, " + accountName + "!", DashboardX + 20, DashboardY + 20, 
               textDark, 11, true);
}

//+------------------------------------------------------------------+
//| Update dashboard content                                         |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    int yPos = DashboardY + 55;
    
    // Create stat cards
    CreateStatCards(yPos);
    yPos += 115;
    
    // Performance section
    CreatePerformanceSection(yPos);
    yPos += 180;
    
    // Position analysis
    CreatePositionSection(yPos);
}

//+------------------------------------------------------------------+
//| Create stat cards (top row)                                     |
//+------------------------------------------------------------------+
void CreateStatCards(int yPos)
{
    int cardWidth = (DashboardWidth - 80) / 4;
    int xPos = DashboardX + 20;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    int openPositions = PositionsTotal();
    
    // Get today's profit
    datetime startOfDay = GetStartOfDay();
    double todayProfit = GetProfitBetween(startOfDay, TimeCurrent());
    
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    // Card 1: Balance
    CreateStatCard(xPos, yPos, cardWidth, "💰", FormatMoney(balance), "Account Balance", textDark);
    xPos += cardWidth + 10;
    
    // Card 2: Open Positions
    CreateStatCard(xPos, yPos, cardWidth, "📊", IntegerToString(openPositions), "Open Positions", textDark);
    xPos += cardWidth + 10;
    
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
void CreatePerformanceSection(int yPos)
{
    // Section background
    CreateRoundedRect(prefix + "PerfBg", DashboardX + 20, yPos, DashboardWidth - 40, 160, cardBgColor, 1);
    
    // Title
    CreateText(prefix + "PerfTitle", "Performance Overview", DashboardX + 35, yPos + 15, textDark, 9, true);
    
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
    CreatePerformanceRow(DashboardX + 35, rowY, "Today", todayProfit);
    rowY += 35;
    
    // This Week
    CreatePerformanceRow(DashboardX + 35, rowY, "This Week", weekProfit);
    rowY += 35;
    
    // This Month
    CreatePerformanceRow(DashboardX + 35, rowY, monthName, monthProfit);
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
    CreateText(rowName + "_Val", sign + FormatMoney(value) + " " + currency, x + 230, y, valColor, 8, true);
    
    // Percentage badge
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance > 0)
    {
        double pct = (value / balance) * 100;
        string pctStr = (pct >= 0 ? "+" : "") + DoubleToString(pct, 1) + "%";
        
        CreateBadge(rowName + "_Badge", x + 120, y - 2, pctStr, pct >= 0);
    }
}

//+------------------------------------------------------------------+
//| Create position section                                          |
//+------------------------------------------------------------------+
void CreatePositionSection(int yPos)
{
    // Section background
    CreateRoundedRect(prefix + "PosBg", DashboardX + 20, yPos, DashboardWidth - 40, 125, cardBgColor, 1);
    
    // Title
    CreateText(prefix + "PosTitle", "Open Positions Analysis", DashboardX + 35, yPos + 15, textDark, 9, true);
    
    int totalPositions = PositionsTotal();
    
    if(totalPositions == 0)
    {
        CreateText(prefix + "NoPos", "No open positions", DashboardX + 35, yPos + 50, textMuted, 8, false);
        return;
    }
    
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
    
    int rowY = yPos + 50;
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    // Current P&L
    color plColor = currentPL >= 0 ? profitGreen : lossRed;
    string plSign = currentPL >= 0 ? "+" : "";
    CreateText(prefix + "CurPL_Lbl", "Current P&L", DashboardX + 35, rowY, textMuted, 8, false);
    CreateText(prefix + "CurPL_Val", plSign + FormatMoney(currentPL) + " " + currency, 
               DashboardX + 230, rowY, plColor, 8, true);
    rowY += 30;
    
    // Potential Win
    CreateText(prefix + "PotWin_Lbl", "Potential Win (TP)", DashboardX + 35, rowY, textMuted, 8, false);
    CreateText(prefix + "PotWin_Val", "+" + FormatMoney(potentialWin) + " " + currency, 
               DashboardX + 230, rowY, profitGreen, 8, true);
    rowY += 30;
    
    // Potential Loss
    CreateText(prefix + "PotLoss_Lbl", "Potential Loss (SL)", DashboardX + 35, rowY, textMuted, 8, false);
    CreateText(prefix + "PotLoss_Val", "-" + FormatMoney(potentialLoss) + " " + currency, 
               DashboardX + 230, rowY, lossRed, 8, true);
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
//| Get profit between dates                                         |
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
            total += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            total += HistoryDealGetDouble(ticket, DEAL_SWAP);
            total += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
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