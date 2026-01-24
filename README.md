# Modern Trading Dashboard

A sophisticated MQL5 Expert Advisor that displays a modern, real-time trading dashboard directly on your MetaTrader 5 chart.

## Features

### 📊 Real-time Account Overview
- **Account Balance**: Current account balance display
- **Open Positions**: Live count of active trades
- **Current Equity**: Real-time equity calculation
- **Today's P&L**: Daily profit/loss with color coding

### 📈 Performance Analytics
- **Daily Performance**: Today's trading results
- **Weekly Summary**: Current week performance
- **Monthly Overview**: Current month trading statistics
- **Percentage Badges**: Visual indicators with color coding

### 💼 Position Analysis
- **Current P&L**: Real-time profit/loss from open positions
- **Potential Win**: Calculated profit if all take profits are hit
- **Potential Loss**: Calculated loss if all stop losses are triggered
- **Smart Calculations**: Accounts for swaps, commissions, and position sizes

## Installation

1. Copy `ModernDashboard.mq5` to your MetaTrader 5 `MQL5/Experts` folder
2. Restart MetaTrader 5 or refresh the Expert Advisors list
3. Drag the dashboard onto any chart
4. Adjust input parameters as needed

## Configuration

### Input Parameters

- **DashboardX**: Horizontal position (default: 30)
- **DashboardY**: Vertical position (default: 30)  
- **DashboardWidth**: Width of the dashboard (default: 420)
- **CardSpacing**: Spacing between cards (default: 15)

### Customization

The dashboard uses a modern color scheme that can be easily modified in the source code:

- **Background**: Clean white with subtle card backgrounds
- **Text**: Dark primary text with muted secondary text
- **Indicators**: Green for profits, red for losses
- **Badges**: Color-coded performance indicators

## Technical Details

### Update Frequency
- **Timer**: Updates every 200ms for smooth real-time display
- **Event-driven**: Also updates on each tick for maximum responsiveness

### Performance Considerations
- **Efficient Rendering**: Objects are reused rather than recreated
- **Memory Management**: Proper cleanup on deinitialization
- **Optimized Calculations**: Minimal resource usage

### Compatibility
- **Platform**: MetaTrader 5 (MT5)
- **Account Types**: Works with any MT5 account type
- **Timeframes**: Compatible with all chart timeframes

## Dashboard Sections

### 1. Header Section
- Personalized greeting with account name
- Clean, modern design

### 2. Statistics Cards
Four key metrics displayed as cards:
- 💰 Account Balance
- 📊 Open Positions  
- 💵 Current Equity
- 📈/📉 Today's P&L

### 3. Performance Overview
Time-based performance tracking:
- Today's results
- This week's summary
- Current month statistics
- Percentage change indicators

### 4. Position Analysis
Detailed open position breakdown:
- Current unrealized P&L
- Potential profit at take profit levels
- Potential loss at stop loss levels

## Security & Best Practices

- **No Trading Functions**: Dashboard only - doesn't place trades
- **Read-only Access**: Only reads account and position data
- **Safe Object Management**: Proper cleanup prevents memory leaks
- **No External Dependencies**: Self-contained implementation

## Troubleshooting

### Dashboard Not Visible
- Check that Expert Advisors are enabled in MT5
- Verify auto-trading is activated
- Ensure the dashboard is attached to the correct chart

### Data Not Updating
- Confirm you have an active internet connection
- Check that MT5 is connected to your broker
- Verify account has trading history enabled

### Performance Issues
- The dashboard is optimized for minimal resource usage
- If experiencing lag, try increasing the timer interval in the code

## Version History

### v1.00
- Initial release with core dashboard functionality
- Real-time account and position monitoring
- Modern UI design with responsive layout

## Support

For issues or feature requests, please check the code comments for detailed implementation notes.

---

**Disclaimer**: This dashboard is for informational purposes only. Past performance does not guarantee future results. Always trade responsibly.
