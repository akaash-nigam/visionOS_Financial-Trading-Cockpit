# Troubleshooting Guide

Comprehensive guide for diagnosing and fixing common issues in Trading Cockpit.

## Table of Contents

- [Build and Compilation Issues](#build-and-compilation-issues)
- [Authentication Problems](#authentication-problems)
- [Market Data Issues](#market-data-issues)
- [Trading Execution Problems](#trading-execution-problems)
- [3D Visualization Issues](#3d-visualization-issues)
- [Performance Problems](#performance-problems)
- [Crash and Stability Issues](#crash-and-stability-issues)
- [Testing Issues](#testing-issues)
- [Deployment Issues](#deployment-issues)
- [Diagnostic Tools](#diagnostic-tools)

---

## Build and Compilation Issues

### Error: "No such module 'TradingCockpit'"

**Symptoms:**
- Build fails with import errors
- Module not found errors

**Causes:**
- Build products not generated
- Wrong scheme selected
- Derived data corruption

**Solutions:**

1. **Clean Build Folder:**
   ```bash
   # In Xcode: Product → Clean Build Folder (Cmd + Shift + K)
   # Or command line:
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Rebuild:**
   ```bash
   # Product → Build (Cmd + B)
   ```

3. **Check Scheme:**
   - Ensure "TradingCockpit" scheme is selected
   - Not "TradingCockpitTests" or wrong target

---

### Error: "Command PhaseScriptExecution failed"

**Symptoms:**
- Build fails during script phase
- Script errors in build log

**Causes:**
- Script dependencies missing
- Permission issues
- Path issues

**Solutions:**

1. **Check Script Permissions:**
   ```bash
   chmod +x Scripts/*.sh
   ```

2. **Verify Paths:**
   - Check script paths are correct
   - Use absolute paths if needed

3. **Check Dependencies:**
   ```bash
   # Ensure all required tools installed
   which swiftlint
   which swiftformat
   ```

---

### Error: "Signing for 'TradingCockpit' requires a development team"

**Symptoms:**
- Build fails at signing step
- No valid signing identity

**Causes:**
- No development team selected
- Certificates not installed
- Provisioning profile issues

**Solutions:**

1. **Select Development Team:**
   - Xcode → Project → Signing & Capabilities
   - Select your team from dropdown

2. **Install Certificates:**
   - Download from Apple Developer Portal
   - Double-click to install in Keychain

3. **Enable Automatic Signing:**
   - Check "Automatically manage signing"
   - Let Xcode handle provisioning

---

### Error: "The visionOS deployment target is not compatible"

**Symptoms:**
- Build fails with deployment target error
- Version mismatch warnings

**Causes:**
- Deployment target too low
- SDK version mismatch

**Solutions:**

1. **Update Deployment Target:**
   - Project → Build Settings → visionOS Deployment Target
   - Set to 2.0 or higher

2. **Update Xcode:**
   ```bash
   # Ensure Xcode 15.2+ installed
   xcodebuild -version
   ```

---

## Authentication Problems

### Issue: "Authentication Failed" on Login

**Symptoms:**
- Login fails with "Invalid Credentials" error
- Cannot connect to broker API

**Causes:**
- Invalid API keys
- Expired credentials
- Network connectivity issues
- API endpoint down

**Solutions:**

1. **Verify Credentials:**
   - Log in to [alpaca.markets](https://alpaca.markets)
   - Verify API key and secret are correct
   - Check if keys are for paper or live trading

2. **Regenerate Keys:**
   - Alpaca Dashboard → API Keys → Regenerate
   - Update in app

3. **Check Network:**
   ```bash
   # Test Alpaca API connectivity
   curl https://paper-api.alpaca.markets/v2/account \
     -H "APCA-API-KEY-ID: YOUR_KEY" \
     -H "APCA-API-SECRET-KEY: YOUR_SECRET"
   ```

4. **Check API Status:**
   - Visit [status.alpaca.markets](https://status.alpaca.markets)
   - Check for service outages

**Debug Logging:**
```swift
// Enable authentication debug logging
Logger.setLevel(.debug)

// Check console for detailed error messages
```

---

### Issue: "Credentials Not Found in Keychain"

**Symptoms:**
- App asks for credentials on every launch
- "No credentials found" error

**Causes:**
- Keychain access denied
- Credentials not saved correctly
- Keychain corruption

**Solutions:**

1. **Grant Keychain Access:**
   - Settings → Privacy & Security → Trading Cockpit
   - Ensure Keychain access enabled

2. **Re-save Credentials:**
   - Log out completely
   - Log in again
   - Check "Remember Me" if available

3. **Reset Keychain:**
   ```bash
   # Remove Trading Cockpit keychain entries
   security delete-generic-password -s "com.tradingcockpit.alpaca.apiKey"
   security delete-generic-password -s "com.tradingcockpit.alpaca.secretKey"
   security delete-generic-password -s "com.tradingcockpit.polygon.apiKey"

   # Re-login in app
   ```

---

## Market Data Issues

### Issue: "No Market Data Received"

**Symptoms:**
- Quotes not updating
- "Connecting..." status indefinitely
- Empty watchlist prices

**Causes:**
- WebSocket connection failed
- Invalid Polygon API key
- Network firewall blocking WebSocket
- Market closed (no data flowing)

**Solutions:**

1. **Check Polygon API Key:**
   - Verify at [polygon.io](https://polygon.io)
   - Check key is active and has quota remaining

2. **Test WebSocket Connection:**
   ```bash
   # Test WebSocket connectivity
   wscat -c "wss://socket.polygon.io/stocks"
   # Should connect successfully
   ```

3. **Check Network:**
   - Ensure WebSocket (WSS) not blocked by firewall
   - Try different network (e.g., disable VPN)

4. **Verify Market Hours:**
   - Market open: 9:30 AM - 4:00 PM ET (Mon-Fri)
   - Extended hours: 4:00 AM - 8:00 PM ET
   - No data on weekends/holidays

**Debug Steps:**
```swift
// Enable WebSocket debug logging
export WEBSOCKET_DEBUG=1

// Check console for connection attempts
// Look for: "WebSocket connected", "Subscription confirmed"
```

---

### Issue: "Quotes Delayed or Stale"

**Symptoms:**
- Quotes updating slowly (> 1 second delay)
- Last update timestamp shows old time

**Causes:**
- Network latency
- API rate limiting
- Subscription not active
- Quote cache full

**Solutions:**

1. **Check Latency:**
   ```bash
   # Ping Polygon servers
   ping socket.polygon.io
   # Should be < 100ms
   ```

2. **Clear Quote Cache:**
   ```swift
   // In app settings, clear cache
   // Or restart app
   ```

3. **Check Rate Limits:**
   - Free tier: 5 requests/minute
   - Paid tier: Higher limits
   - Upgrade if needed

4. **Verify Subscription:**
   ```swift
   // Check subscribed symbols in debug console
   print(marketDataHub.subscribedSymbols)
   ```

---

### Issue: "Invalid Symbol" Error

**Symptoms:**
- Symbol search returns no results
- "Symbol not found" when adding to watchlist

**Causes:**
- Typo in symbol
- Symbol not tradable
- Delisted company
- Symbol format incorrect

**Solutions:**

1. **Verify Symbol:**
   - Check on [finance.yahoo.com](https://finance.yahoo.com)
   - Ensure proper format (e.g., "AAPL" not "Apple")

2. **Check Tradability:**
   ```bash
   # Verify symbol via Alpaca API
   curl https://paper-api.alpaca.markets/v2/assets/AAPL \
     -H "APCA-API-KEY-ID: YOUR_KEY"
   ```

3. **Use Correct Format:**
   - Stocks: Just ticker (AAPL)
   - Not: AAPL.US, NASDAQ:AAPL

---

## Trading Execution Problems

### Issue: "Order Rejected - Insufficient Funds"

**Symptoms:**
- Order fails with insufficient buying power error
- Shows buying power but still rejected

**Causes:**
- Not enough cash for order
- Existing positions use buying power
- Position size too large

**Solutions:**

1. **Check Buying Power:**
   ```swift
   // View in Portfolio → Account Info
   print("Buying Power: \(tradingService.buyingPower)")
   ```

2. **Calculate Required:**
   - Market order: `quantity × last_price`
   - Include commission (if any)

3. **Reduce Order Size:**
   - Use position sizing calculator
   - Reduce quantity

4. **Close Existing Positions:**
   - Sell shares to free up buying power
   - Wait for settlement (T+2)

---

### Issue: "Market Closed" Error

**Symptoms:**
- All orders rejected with "market closed"
- Cannot place any trades

**Causes:**
- Market not open (outside 9:30 AM - 4:00 PM ET)
- Weekend or holiday
- After-hours trading not enabled

**Solutions:**

1. **Check Market Hours:**
   ```swift
   // Current time in ET
   let etTime = Date().convertToET()
   print("Current ET: \(etTime)")

   // Market status
   let isOpen = marketDataHub.isMarketOpen()
   print("Market Open: \(isOpen)")
   ```

2. **Wait for Market Open:**
   - Pre-market: 4:00 AM - 9:30 AM ET
   - Regular: 9:30 AM - 4:00 PM ET
   - After-hours: 4:00 PM - 8:00 PM ET

3. **Enable Extended Hours:**
   - For limit orders only
   - Set `extended_hours: true` in order request

---

### Issue: "Order Stuck in Pending"

**Symptoms:**
- Order shows "pending" status indefinitely
- No fill notification

**Causes:**
- Limit price not reached (for limit orders)
- Low volume symbol
- Order not submitted correctly

**Solutions:**

1. **Check Order Status:**
   ```swift
   let order = try await tradingService.getOrder(orderId: orderId)
   print("Status: \(order.status)")
   print("Filled Qty: \(order.filledQuantity)/\(order.quantity)")
   ```

2. **For Limit Orders:**
   - Check if limit price reasonable
   - Compare to current market price
   - Consider adjusting or canceling

3. **Cancel and Retry:**
   ```swift
   try await tradingService.cancelOrder(orderId: orderId)
   // Submit new order
   ```

---

## 3D Visualization Issues

### Issue: "3D View Not Rendering"

**Symptoms:**
- Black screen in 3D view
- "Loading..." indefinitely
- Crash when entering 3D view

**Causes:**
- RealityKit initialization failed
- No positions to visualize
- Memory issue
- GPU performance problem

**Solutions:**

1. **Check Positions:**
   ```swift
   if tradingService.positions.isEmpty {
       print("No positions to visualize")
   }
   ```

2. **Restart App:**
   - Force quit and relaunch
   - Clears any initialization issues

3. **Reduce Terrain Grid:**
   - Settings → 3D Visualization → Grid Size
   - Reduce from 10x10 to 5x5

4. **Check Memory:**
   - Xcode → Debug Navigator → Memory
   - Should be < 500MB
   - Close other apps if needed

---

### Issue: "3D View Laggy or Slow"

**Symptoms:**
- Low frame rate (< 30 FPS)
- Gestures not responsive
- Terrain updates slow

**Causes:**
- Too many positions
- Complex mesh generation
- Simulator performance (use device)
- Background processing

**Solutions:**

1. **Profile Performance:**
   ```bash
   # In Xcode: Product → Profile → Time Profiler
   # Look for hot spots in terrain generation
   ```

2. **Optimize Settings:**
   - Reduce grid resolution
   - Limit position count shown
   - Disable real-time updates temporarily

3. **Use Device, Not Simulator:**
   - Simulator has limited GPU
   - Device performance much better

4. **Close Background Apps:**
   - Free up system resources

---

## Performance Problems

### Issue: "App Slow to Launch"

**Symptoms:**
- App takes > 5 seconds to launch
- Splash screen visible too long

**Causes:**
- Too much initialization on startup
- Database migration
- Large cache loading

**Solutions:**

1. **Profile Launch:**
   ```bash
   # Instruments → App Launch
   # Identify slow operations
   ```

2. **Defer Non-Critical Loads:**
   - Load watchlists asynchronously
   - Fetch account info in background

3. **Clear Cache:**
   - Settings → Clear Cache
   - Reduces initial load time

---

### Issue: "High Memory Usage"

**Symptoms:**
- Memory warnings
- App crashes with "jetsam" errors
- Memory usage > 1GB

**Causes:**
- Quote cache too large
- Memory leak
- Too many images/assets loaded

**Solutions:**

1. **Check Memory in Xcode:**
   - Debug Navigator → Memory
   - Look for leaks (use Instruments)

2. **Reduce Cache Size:**
   ```swift
   // Reduce quote cache from 1000 to 500
   let cache = LRUCache<String, Quote>(maxSize: 500)
   ```

3. **Profile for Leaks:**
   ```bash
   # Instruments → Leaks
   # Look for cycles, strong references
   ```

---

## Crash and Stability Issues

### Issue: "App Crashes on Launch"

**Symptoms:**
- App crashes immediately after launch
- Crash before UI appears

**Causes:**
- Missing API credentials
- Database corruption
- Initialization error

**Solutions:**

1. **Check Crash Logs:**
   - Xcode → Window → Devices and Simulators → View Device Logs
   - Look for exception type and stack trace

2. **Reset App Data:**
   ```bash
   # On simulator
   xcrun simctl uninstall booted com.tradingcockpit.TradingCockpit
   xcrun simctl install booted build/TradingCockpit.app

   # On device - uninstall and reinstall
   ```

3. **Check Console Logs:**
   ```bash
   # View console output
   log stream --predicate 'process == "TradingCockpit"' --level debug
   ```

---

### Issue: "Crash When Placing Order"

**Symptoms:**
- App crashes during order submission
- Crash after tapping "Submit Order"

**Causes:**
- Invalid order parameters
- Force unwrap of optional
- Network error handling bug

**Solutions:**

1. **Enable Exception Breakpoint:**
   - Xcode → Breakpoint Navigator → + → Exception Breakpoint
   - Run in debugger to catch exact line

2. **Check Order Validation:**
   ```swift
   // Ensure all fields validated
   guard let symbol = orderRequest.symbol else {
       throw TradingError.invalidSymbol
   }
   ```

3. **Handle Errors:**
   ```swift
   do {
       let order = try await submitOrder(request)
   } catch {
       print("Order failed: \(error)")
       // Don't crash - show error to user
   }
   ```

---

## Testing Issues

### Issue: "Tests Fail on CI but Pass Locally"

**Symptoms:**
- All tests pass on local machine
- CI tests fail

**Causes:**
- Environment differences
- Missing environment variables
- Timing issues

**Solutions:**

1. **Check Environment Variables:**
   ```yaml
   # .github/workflows/ci.yml
   env:
     ALPACA_API_KEY: ${{ secrets.ALPACA_API_KEY }}
     ALPACA_SECRET_KEY: ${{ secrets.ALPACA_SECRET_KEY }}
   ```

2. **Add Longer Timeouts:**
   ```swift
   // For async tests
   let expectation = XCTestExpectation(description: "Async operation")
   wait(for: [expectation], timeout: 10.0)  // Increase from 5.0
   ```

3. **Mock External Dependencies:**
   - Don't rely on actual API calls in CI
   - Use mocks for deterministic tests

---

### Issue: "Integration Tests Failing"

**Symptoms:**
- Integration tests fail with network errors
- Tests timeout

**Causes:**
- API credentials not configured
- API rate limiting
- Network connectivity issues

**Solutions:**

1. **Configure Credentials:**
   ```bash
   export ALPACA_API_KEY="your_key"
   export ALPACA_SECRET_KEY="your_secret"
   export POLYGON_API_KEY="your_polygon_key"
   ```

2. **Add Retries:**
   ```swift
   var attempt = 0
   while attempt < 3 {
       do {
           let result = try await apiCall()
           return result
       } catch {
           attempt += 1
           try await Task.sleep(nanoseconds: 1_000_000_000)
       }
   }
   ```

3. **Skip if No Credentials:**
   ```swift
   func testOrderSubmission() throws {
       guard ProcessInfo.processInfo.environment["ALPACA_API_KEY"] != nil else {
           throw XCTSkip("API credentials not configured")
       }
       // Test implementation
   }
   ```

---

## Deployment Issues

### Issue: "Archive Validation Failed"

**Symptoms:**
- Archive fails validation before upload
- "Invalid Binary" error

**Causes:**
- Wrong architecture
- Missing required frameworks
- Code signing issues

**Solutions:**

1. **Check Build Settings:**
   - Build Active Architecture Only: NO (for release)
   - Supported Platforms: visionOS

2. **Validate Archive:**
   - Archive Organizer → Validate
   - Review all warnings

3. **Check Framework Embedding:**
   - Build Phases → Embed Frameworks
   - Ensure all required frameworks included

---

### Issue: "TestFlight Build Processing Stuck"

**Symptoms:**
- Build stuck in "Processing" for > 1 hour
- Never becomes available to testers

**Causes:**
- Server-side processing delay
- Build issue detected by Apple

**Solutions:**

1. **Wait 24 Hours:**
   - Sometimes processing takes time
   - Check App Store Connect status page

2. **Upload New Build:**
   - Increment build number
   - Upload fresh build

3. **Contact Apple Support:**
   - If stuck > 48 hours
   - Open support ticket

---

## Diagnostic Tools

### Enable Debug Logging

```swift
// In AppDelegate or main entry point
#if DEBUG
Logger.setLevel(.debug)
#else
Logger.setLevel(.info)
#endif
```

### View Console Logs

```bash
# macOS Console app
# Or command line:
log show --predicate 'process == "TradingCockpit"' --last 5m
```

### Instruments Profiling

```bash
# Time Profiler
instruments -t "Time Profiler" -D trace.trace TradingCockpit.app

# Leaks
instruments -t "Leaks" -D leaks.trace TradingCockpit.app

# Network
instruments -t "Network" -D network.trace TradingCockpit.app
```

### Network Debugging

```swift
// Enable URLSession logging
setenv("CFNETWORK_DIAGNOSTICS", "1", 1)

// View requests/responses in console
```

### Crash Symbolication

```bash
# Symbolicate crash log
symbolicatecrash crash.log TradingCockpit.app.dSYM > symbolicated.crash

# View readable stack trace
cat symbolicated.crash
```

---

## Getting Help

If you're still experiencing issues:

1. **Search Existing Issues**: [GitHub Issues](https://github.com/OWNER/REPO/issues)
2. **Ask Community**: [Discussions](https://github.com/OWNER/REPO/discussions)
3. **Report Bug**: [Bug Report](https://github.com/OWNER/REPO/issues/new?template=bug_report.yml)
4. **Email Support**: [support@tradingcockpit.com](mailto:support@tradingcockpit.com)

When reporting issues, please include:
- visionOS version
- App version
- Steps to reproduce
- Error messages
- Console logs
- Screenshots/videos (if applicable)

---

**Last Updated:** 2025-11-24
**Version:** 1.0.0
**Platform:** visionOS 2.0+
