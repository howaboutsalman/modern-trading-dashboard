# 📊 Modern Trading Dashboard for MT5

![Version](https://img.shields.io/badge/version-1.43-blue.svg)

A professional trading dashboard for MetaTrader 5 designed for **FundedNext** prop traders. Monitor your performance, risk compliance, and market status in real-time.
![Platform](https://github.com/howaboutsalman/modern-trading-dashboard/blob/main/image.png?raw=true)

---

## ✨ Key Features

- **Real-Time Monitoring** - Balance, equity, open positions, and daily P&L
- **Performance Tracking** - Today, This Week, This Month with percentage returns
- **Position Analysis** - Current P&L, potential wins/losses based on TP/SL
- **FundedNext Risk Rules** - Automatic compliance monitoring:
  - Margin Usage (Target: 20-30%, Max: 70%)
  - Risk Per Trade (Max: 1.0%)
  - Total Portfolio Risk (Max: 3.0%)
- **Market Status** - Live open/closed indicator with countdown timer

---

## 🚀 Quick Start

1. **Install**
   - Copy `ModernDashboard_Fixed.mq5` to `MT5/MQL5/Experts/`
   - Restart MetaTrader 5

2. **Activate**
   - Drag EA onto any chart
   - Enable "AutoTrading" button
   - Dashboard appears instantly

3. **Configure** (Optional)
   ```mql5
   DashboardX = 30;      // Position from left
   DashboardY = 30;      // Position from top
   DashboardWidth = 420; // Column width
   ```

---

## 📋 Dashboard Layout

```
┌──────────────────────────────────────────────────────┐
│  Good afternoon, Trader!        ● MARKET OPEN        │
├─────────────────┬─────────────────┬─────────────────┤
│ 💰 Balance      │ 📊 Positions    │ 💵 Equity       │
│ 200000.00       │ 0               │ 200000.00       │
├─────────────────┴─────────────────┼─────────────────┤
│ Performance Overview              │ ⚠️ Risk Rules   │
│ • Today:    +0.00 USD  +0.0%     │ Margin: 0.00%   │
│ • Week:     +0.00 USD  +0.0%     │ [▓░░░░░░░░░]    │
│ • Jan:      +0.00 USD  +0.0%     │ Risk/Trade: 0%  │
├───────────────────────────────────┤ [░░░░░░░░░░]    │
│ Open Positions Analysis           │ Total Risk: 0%  │
│ • No open positions               │ [░░░░░░░░░░]    │
│ • Market Closes In: 10:16:08      │ ✅ All OK       │
└───────────────────────────────────┴─────────────────┘
```

---

## 🔧 How It Works

**Performance Calculation**
- ✅ Includes: Trading profits, swap, commission
- ❌ Excludes: Deposits, withdrawals, balance adjustments

**Risk Calculation**
- **Margin Usage**: `(Used Margin / Equity) × 100`
- **Risk Per Trade**: `(SL Distance × Lot Size × Point Value / Equity) × 100`
- **Total Risk**: Sum of all position risks

---

## 💡 Quick Tips

1. Keep margin between 20-30% for optimal risk
2. Always set stop losses for accurate risk calculations
3. Red alerts = close positions immediately
4. Dashboard is view-only, never places trades

---

## 🛠️ Troubleshooting

**Dashboard not showing?**
- Enable AutoTrading button
- Check EA is attached (smile icon in corner)

**Wrong P&L values?**
- Ensure you have trading history
- Restart MT5 to refresh

**Risk shows 0%?**
- Open positions must have stop-loss orders

---

## ⚠️ Important Notes

- **Non-trading EA** - Display only, never modifies positions
- **Compatible with** - FundedNext accounts, standard MT5, demo accounts
- **Updates every second** - Real-time monitoring
- **Zero chart clutter** - Clean overlay design

---

## 📜 License

MIT License - Free to use and modify

---

## 🚀 Getting Started Checklist

- [ ] Copy MQ5 file to Experts folder
- [ ] Restart MT5
- [ ] Attach EA to chart
- [ ] Enable AutoTrading
- [ ] Verify dashboard visible
- [ ] Start trading with confidence! 🎯

---

**Version 1.43** | Designed for FundedNext Traders | Trading involves risk

For support or feature requests, contact through MT5 community channels.
