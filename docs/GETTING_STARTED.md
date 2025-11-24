# Getting Started with Trading Cockpit

Welcome to Trading Cockpit! This guide will help you set up and start using the first professional-grade trading platform built exclusively for Apple Vision Pro.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [First Run](#first-run)
- [Basic Usage](#basic-usage)
- [Next Steps](#next-steps)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have the following:

### Hardware Requirements

- **Apple Vision Pro** (recommended) or
- **Mac with visionOS Simulator**
  - macOS 14.0 (Sonoma) or later
  - Apple Silicon (M1, M2, M3) or Intel processor
  - 16GB RAM minimum (32GB recommended)
  - 20GB free disk space

### Software Requirements

- **Xcode 15.2 or later** with visionOS SDK
- **Swift 6.0 or later**
- **Git** for version control
- **Active Apple Developer account** (for device deployment)

### API Credentials

Trading Cockpit requires API credentials from:

1. **Alpaca Markets** (required for trading)
   - Sign up at [alpaca.markets](https://alpaca.markets)
   - Use paper trading account for testing
   - Get API Key and Secret Key

2. **Polygon.io** (required for market data)
   - Sign up at [polygon.io](https://polygon.io)
   - Free tier available
   - Get API Key

## Installation

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/OWNER/visionOS_Financial-Trading-Cockpit.git

# Navigate to the project directory
cd visionOS_Financial-Trading-Cockpit
```

### Step 2: Open in Xcode

```bash
# Open the Xcode project
open TradingCockpit/TradingCockpit.xcodeproj
```

Alternatively, you can:
1. Launch Xcode
2. Select "Open a project or file"
3. Navigate to `TradingCockpit/TradingCockpit.xcodeproj`
4. Click "Open"

### Step 3: Select Build Destination

In Xcode:
1. Click the destination selector (next to the scheme selector)
2. Choose one of:
   - **Apple Vision Pro** (if you have a device)
   - **visionOS Simulator** → **Apple Vision Pro**

### Step 4: Build the Project

```bash
# Option 1: Build from Xcode
# Press Cmd + B or Product > Build

# Option 2: Build from command line
xcodebuild \
  -scheme TradingCockpit \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

**Expected output:**
```
** BUILD SUCCEEDED **
```

## Configuration

### API Credentials Setup

You'll need to configure your API credentials before using the app.

#### Method 1: Environment Variables (Development)

```bash
# Add to your shell profile (~/.zshrc or ~/.bash_profile)
export ALPACA_API_KEY="your_alpaca_key_here"
export ALPACA_SECRET_KEY="your_alpaca_secret_here"
export POLYGON_API_KEY="your_polygon_key_here"

# Reload your shell
source ~/.zshrc  # or source ~/.bash_profile
```

#### Method 2: In-App Configuration (First Run)

1. Launch the app
2. On the login screen, enter:
   - **Alpaca API Key**
   - **Alpaca Secret Key**
   - **Polygon API Key**
3. Tap "Login"
4. Credentials are securely stored in Keychain

#### Method 3: Keychain Direct Entry (Advanced)

```bash
# Store in Keychain using command line
security add-generic-password \
  -s "com.tradingcockpit.alpaca.apiKey" \
  -a "default" \
  -w "your_alpaca_key_here"

security add-generic-password \
  -s "com.tradingcockpit.alpaca.secretKey" \
  -a "default" \
  -w "your_alpaca_secret_here"

security add-generic-password \
  -s "com.tradingcockpit.polygon.apiKey" \
  -a "default" \
  -w "your_polygon_key_here"
```

### Verify Configuration

Run the configuration check:

```bash
# From the project root
swift run --package-path TradingCockpit ConfigCheck
```

**Expected output:**
```
✅ Alpaca API Key: Configured
✅ Alpaca Secret Key: Configured
✅ Polygon API Key: Configured
✅ All credentials configured successfully!
```

## First Run

### Launch the App

#### On visionOS Simulator

1. In Xcode, press **Cmd + R** or click the Run button
2. Wait for the simulator to boot (may take 1-2 minutes)
3. The app will automatically launch

#### On Apple Vision Pro Device

1. Connect your Vision Pro to your Mac
2. Trust the connection on both devices
3. In Xcode, select your device as the destination
4. Press **Cmd + R** to build and run
5. The app will install and launch on your device

### Initial Setup Walkthrough

#### 1. Authentication Screen

<img src="screenshots/login-screen.png" width="600" alt="Login Screen">

- Enter your Alpaca and Polygon API credentials
- Tap "Login"
- Wait for authentication (2-3 seconds)

**What happens:**
- App validates credentials with Alpaca API
- Retrieves account information
- Stores credentials securely in Keychain
- Establishes WebSocket connection for market data

#### 2. Main Menu

<img src="screenshots/main-menu.png" width="600" alt="Main Menu">

You'll see six main options:
- **Portfolio** - View your positions and P&L
- **Place Order** - Execute trades
- **Watchlist** - Track symbols
- **3D View** - Visualize portfolio in 3D
- **Market Data** - Real-time quotes
- **Settings** - App configuration

#### 3. First Trade

Let's place your first order:

1. **Tap "Place Order"**
2. **Enter symbol**: Type "AAPL" (Apple Inc.)
3. **Select order type**: Choose "Market" or "Limit"
4. **Set quantity**: Use the slider or enter a number
5. **Review order**: Check the details
6. **Confirm**: Tap "Submit Order"
7. **Confirmation**: You'll see order status

**⚠️ Paper Trading Notice:**
By default, all orders use Alpaca's paper trading environment. No real money is used.

## Basic Usage

### Viewing Your Portfolio

1. From Main Menu, tap **"Portfolio"**
2. You'll see:
   - List of all positions
   - Current market value
   - Unrealized P&L (profit/loss)
   - Cost basis
   - Quantity held

**Actions:**
- Tap a position to see details
- Swipe left to close position
- Pull down to refresh

### Creating a Watchlist

1. From Main Menu, tap **"Watchlist"**
2. Tap the **"+"** button
3. Search for symbols (e.g., "TSLA", "GOOGL")
4. Tap a symbol to add it
5. View real-time quotes

**Features:**
- Multiple watchlists supported
- Real-time price updates
- Gainers/losers statistics
- Quick order entry

### Using 3D Visualization

1. From Main Menu, tap **"3D View"**
2. You'll see your portfolio as a 3D terrain
3. **Gesture controls:**
   - **Drag**: Rotate camera
   - **Pinch**: Zoom in/out
   - **Tap**: Select position

**Color coding:**
- 🟢 **Green**: Profitable positions (mountains)
- 🟡 **Yellow**: Break-even positions
- 🔴 **Red**: Losing positions (valleys)

### Real-Time Market Data

Market data streams automatically via WebSocket:
- **Quote updates**: ~100ms latency
- **Price changes**: Color-coded (↑ green, ↓ red)
- **Volume data**: Real-time trading volume
- **Spread**: Bid-ask spread

**Connection status:**
- 🟢 **Connected**: Receiving real-time data
- 🟡 **Connecting**: Establishing connection
- 🔴 **Disconnected**: No data (tap to reconnect)

## Next Steps

### Learn More

- 📖 **[System Architecture](system-architecture.md)** - Understand how the app works
- 🎨 **[UI/UX Design System](ui-ux-design-system.md)** - Design principles
- 🧪 **[Testing Guide](TEST_GUIDE.md)** - Run tests and contribute
- 🔒 **[Security & Compliance](security-compliance.md)** - Security best practices

### Advanced Features

- **Custom Watchlists** - Organize symbols by sector or strategy
- **Position Sizing** - Calculate optimal position sizes based on risk
- **Order History** - Review all past trades
- **Performance Analytics** - Track returns over time

### Contributing

Want to contribute? See our [Contributing Guide](../CONTRIBUTING.md):
- 🐛 [Report a bug](https://github.com/OWNER/REPO/issues/new?template=bug_report.yml)
- ✨ [Request a feature](https://github.com/OWNER/REPO/issues/new?template=feature_request.yml)
- 💻 [Submit a pull request](https://github.com/OWNER/REPO/pulls)

### Get Help

- 📚 **[Documentation](https://github.com/OWNER/REPO/tree/main/docs)** - Comprehensive docs
- 💬 **[Discussions](https://github.com/OWNER/REPO/discussions)** - Ask questions
- 🐛 **[Issues](https://github.com/OWNER/REPO/issues)** - Report problems
- 📧 **[Email](mailto:support@tradingcockpit.com)** - Direct support

## Troubleshooting

### Common Issues

#### Issue: "Build Failed" in Xcode

**Solution:**
1. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Rebuild: **Product → Build** (Cmd + B)

#### Issue: "Authentication Failed"

**Possible causes:**
- Invalid API credentials
- Expired API keys
- Network connectivity issues

**Solution:**
1. Verify credentials at [alpaca.markets](https://alpaca.markets)
2. Regenerate API keys if needed
3. Check internet connection
4. Try logging in again

#### Issue: "No Market Data Received"

**Solution:**
1. Check Polygon API key is valid
2. Verify internet connection
3. Check WebSocket connection status
4. Restart the app

#### Issue: "Order Rejected"

**Common reasons:**
- Insufficient buying power
- Market closed (outside 9:30 AM - 4:00 PM ET)
- Invalid symbol
- Quantity exceeds position size limits

**Solution:**
1. Check error message for specific reason
2. Verify account buying power
3. Check market hours
4. Reduce order quantity

#### Issue: "Simulator Slow or Laggy"

**Solution:**
1. Allocate more RAM to simulator
2. Close other applications
3. Reduce 3D terrain grid size in settings
4. Use actual device for better performance

### Debug Mode

Enable debug logging:

```bash
# Set environment variable
export TRADING_COCKPIT_DEBUG=1

# Run from Xcode
# Edit Scheme → Run → Arguments → Environment Variables
# Add: TRADING_COCKPIT_DEBUG = 1
```

**Output location:**
```
~/Library/Logs/TradingCockpit/
```

### Reset Application

To completely reset the app:

```bash
# Remove Keychain entries
security delete-generic-password -s "com.tradingcockpit.alpaca.apiKey"
security delete-generic-password -s "com.tradingcockpit.alpaca.secretKey"
security delete-generic-password -s "com.tradingcockpit.polygon.apiKey"

# Clear app data (on simulator)
xcrun simctl uninstall booted com.tradingcockpit.TradingCockpit
```

### Getting More Help

If you're still experiencing issues:

1. **Check logs**: Look for error messages in Xcode console
2. **Search issues**: Check [GitHub Issues](https://github.com/OWNER/REPO/issues)
3. **Ask for help**: Post in [Discussions](https://github.com/OWNER/REPO/discussions)
4. **Report a bug**: Create a [Bug Report](https://github.com/OWNER/REPO/issues/new?template=bug_report.yml)

## Success Checklist

✅ You've successfully set up Trading Cockpit if you can:
- [ ] Build and run the app without errors
- [ ] Log in with your API credentials
- [ ] See real-time market data streaming
- [ ] View your portfolio (even if empty)
- [ ] Search for symbols in watchlist
- [ ] View 3D portfolio visualization
- [ ] Place a test order (paper trading)

**🎉 Congratulations! You're ready to start trading in spatial computing!**

---

**Version:** 1.0.0
**Last Updated:** 2025-11-24
**Platform:** visionOS 2.0+
**License:** MIT

**Need help?** Email [support@tradingcockpit.com](mailto:support@tradingcockpit.com)
