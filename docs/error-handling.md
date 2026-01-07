# Error Handling & Edge Cases
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Error Taxonomy

### 1.1 Error Categories
```swift
enum TradingCockpitError: Error {
    // Network errors
    case networkError(NetworkError)
    case connectionTimeout
    case serverUnavailable

    // Authentication errors
    case authenticationFailed
    case tokenExpired
    case insufficientPermissions

    // Trading errors
    case orderRejected(reason: String)
    case insufficientFunds
    case positionNotFound
    case invalidOrderParameters

    // Data errors
    case dataParsingFailed
    case invalidData
    case staleData

    // System errors
    case outOfMemory
    case renderingFailed
    case deviceNotSupported
}

enum Severity {
    case info       // Informational only
    case warning    // Potential issue
    case error      // Operation failed
    case critical   // System failure
}
```

---

## 2. Error Handling Strategies

### 2.1 Retry Logic
```swift
class RetryHandler {
    func execute<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry on certain errors
                if shouldNotRetry(error) {
                    throw error
                }

                // Exponential backoff
                let delay = calculateBackoff(attempt: attempt)
                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw lastError ?? TradingCockpitError.networkError(.unknown)
    }

    private func shouldNotRetry(_ error: Error) -> Bool {
        switch error {
        case TradingCockpitError.authenticationFailed,
             TradingCockpitError.insufficientPermissions,
             TradingCockpitError.invalidOrderParameters:
            return true
        default:
            return false
        }
    }

    private func calculateBackoff(attempt: Int) -> Double {
        min(pow(2.0, Double(attempt)), 16.0)  // Max 16 seconds
    }
}
```

### 2.2 Circuit Breaker Pattern
```swift
actor CircuitBreaker {
    enum State {
        case closed     // Normal
        case open       // Failing
        case halfOpen   // Testing recovery
    }

    private var state: State = .closed
    private var failureCount = 0
    private let failureThreshold = 5
    private let resetTimeout: TimeInterval = 60

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .closed:
            do {
                let result = try await operation()
                onSuccess()
                return result
            } catch {
                onFailure()
                throw error
            }

        case .open:
            throw CircuitBreakerError.circuitOpen

        case .halfOpen:
            do {
                let result = try await operation()
                reset()
                return result
            } catch {
                state = .open
                throw error
            }
        }
    }

    private func onSuccess() {
        failureCount = 0
    }

    private func onFailure() {
        failureCount += 1
        if failureCount >= failureThreshold {
            state = .open
            scheduleReset()
        }
    }

    private func scheduleReset() {
        Task {
            try await Task.sleep(for: .seconds(resetTimeout))
            state = .halfOpen
        }
    }

    private func reset() {
        state = .closed
        failureCount = 0
    }
}
```

---

## 3. User-Facing Error Messages

### 3.1 Error Message Guidelines
- **Be Specific**: Explain what went wrong
- **Be Actionable**: Tell user what they can do
- **Be Concise**: Keep it short
- **Be Empathetic**: Acknowledge frustration

### 3.2 Error Message Mapping
```swift
extension TradingCockpitError {
    var userMessage: String {
        switch self {
        case .networkError:
            return "Connection lost. Please check your internet connection and try again."

        case .authenticationFailed:
            return "Unable to connect to your broker. Please check your credentials."

        case .orderRejected(let reason):
            return "Order rejected: \(reason). Please review and try again."

        case .insufficientFunds:
            return "Insufficient buying power. Your order exceeds available funds."

        case .tokenExpired:
            return "Your session has expired. Please sign in again."

        case .outOfMemory:
            return "App is using too much memory. Closing some windows may help."

        default:
            return "An unexpected error occurred. Please try again."
        }
    }

    var recoveryActions: [RecoveryAction] {
        switch self {
        case .networkError:
            return [.retry, .checkConnection]

        case .authenticationFailed:
            return [.reAuthenticate, .checkCredentials]

        case .orderRejected:
            return [.reviewOrder, .contactSupport]

        case .insufficientFunds:
            return [.reduceQuantity, .addFunds]

        default:
            return [.retry, .contactSupport]
        }
    }
}

enum RecoveryAction {
    case retry
    case checkConnection
    case reAuthenticate
    case checkCredentials
    case reviewOrder
    case contactSupport
    case reduceQuantity
    case addFunds
}
```

---

## 4. Edge Cases

### 4.1 Market Conditions

#### Extended Hours Trading
```swift
func validateMarketHours(order: Order) throws {
    let marketStatus = getMarketStatus(for: order.security.exchange)

    switch marketStatus {
    case .closed:
        throw TradingError.marketClosed

    case .premarket, .afterhours:
        // Warn user about extended hours
        if order.orderType == .market {
            throw TradingError.marketOrderNotAllowed(
                "Market orders not allowed during extended hours"
            )
        }

    case .open:
        break  // OK
    }
}
```

#### Circuit Breakers / Trading Halts
```swift
func checkTradingHalt(security: Security) throws {
    if security.isHalted {
        throw TradingError.tradingHalted(
            symbol: security.symbol,
            reason: security.haltReason ?? "Unknown"
        )
    }
}
```

#### Extreme Volatility
```swift
func checkVolatility(quote: Quote) -> VolatilityWarning? {
    let volatility = calculateVolatility(quote)

    if volatility > 0.10 {  // > 10%
        return VolatilityWarning(
            level: .extreme,
            message: "Extreme volatility detected. Prices may move rapidly."
        )
    }

    return nil
}
```

### 4.2 Data Issues

#### Stale Data
```swift
func validateDataFreshness(quote: Quote) throws {
    let age = Date().timeIntervalSince(quote.timestamp)

    if age > 60 {  // > 1 minute old
        throw DataError.staleData(age: age)
    }
}
```

#### Missing Data
```swift
func handleMissingQuote(symbol: String) -> Quote? {
    // Fallback strategies:
    // 1. Return cached quote
    if let cached = cache.get(symbol) {
        return cached
    }

    // 2. Fetch from alternative source
    if let alternative = try? fetchFromBackup(symbol) {
        return alternative
    }

    // 3. Return nil and show warning
    showWarning("Unable to retrieve price for \(symbol)")
    return nil
}
```

#### Data Corruption
```swift
func validateData(_ quote: Quote) throws {
    // Price validation
    guard quote.last > 0 else {
        throw DataError.invalidPrice
    }

    // Spread validation
    if let bid = quote.bid, let ask = quote.ask {
        guard ask >= bid else {
            throw DataError.invalidSpread
        }

        // Warn on wide spread
        let spreadPercent = ((ask - bid) / bid) * 100
        if spreadPercent > 5 {
            logWarning("Wide spread detected: \(spreadPercent)%")
        }
    }

    // Volume validation
    guard quote.volume >= 0 else {
        throw DataError.invalidVolume
    }
}
```

### 4.3 Order Edge Cases

#### Fractional Shares
```swift
func validateQuantity(order: Order) throws {
    // Some brokers don't support fractional shares
    if !broker.supportsFractionalShares {
        guard order.quantity == floor(Double(order.quantity)) else {
            throw OrderError.fractionalSharesNotSupported
        }
    }
}
```

#### Minimum Order Size
```swift
func checkMinimumOrderSize(order: Order) throws {
    let orderValue = Decimal(order.quantity) * order.estimatedPrice

    if orderValue < broker.minimumOrderValue {
        throw OrderError.belowMinimumOrderSize(
            minimum: broker.minimumOrderValue
        )
    }
}
```

#### Duplicate Orders
```swift
func checkDuplicateOrder(order: Order) throws {
    let recentOrders = getRecentOrders(within: .seconds(5))

    let duplicate = recentOrders.first { existing in
        existing.security.id == order.security.id &&
        existing.action == order.action &&
        existing.quantity == order.quantity
    }

    if duplicate != nil {
        throw OrderError.possibleDuplicate
    }
}
```

### 4.4 System Edge Cases

#### Low Memory
```swift
func handleMemoryPressure() {
    NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
    ) { _ in
        // Clear caches
        cache.clear()

        // Reduce rendering quality
        visualizationEngine.setLOD(.low)

        // Disconnect non-essential data feeds
        dataHub.disconnectLowPriority()

        // Alert user
        showWarning("Low memory. Some features temporarily reduced.")
    }
}
```

#### Device Disconnect
```swift
func handleDeviceDisconnect() {
    // Save state
    saveCurrentState()

    // Cancel pending orders
    cancelPendingOrders()

    // Show reconnection screen
    showReconnectionScreen()

    // Attempt reconnect
    Task {
        try await reconnectWithBackoff()
    }
}
```

#### Battery Low
```swift
func handleLowBattery() {
    let batteryLevel = UIDevice.current.batteryLevel

    if batteryLevel < 0.10 {
        // Reduce non-essential features
        disableBackgroundUpdates()
        reduceSpatialEffects()

        showWarning("Low battery. Some features disabled to conserve power.")
    }
}
```

---

## 5. Logging & Monitoring

### 5.1 Error Logging
```swift
class ErrorLogger {
    static func log(
        _ error: Error,
        severity: Severity,
        context: [String: Any] = [:]
    ) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            error: error,
            severity: severity,
            context: context,
            stackTrace: Thread.callStackSymbols
        )

        // Log locally
        writeToLog(entry)

        // Report critical errors
        if severity == .critical {
            reportToCrashlytics(entry)
        }
    }
}
```

### 5.2 Error Metrics
```swift
actor ErrorMetrics {
    private var errorCounts: [String: Int] = [:]
    private var errorRates: [String: Double] = [:]

    func recordError(_ error: Error) {
        let key = String(describing: type(of: error))
        errorCounts[key, default: 0] += 1

        // Calculate rate
        calculateErrorRate(for: key)

        // Alert if rate is high
        if errorRates[key] ?? 0 > 0.1 {  // > 10%
            alertHighErrorRate(error: key)
        }
    }

    private func calculateErrorRate(for key: String) {
        // Rate = errors / total operations
        let total = getTotalOperations()
        let errors = errorCounts[key] ?? 0
        errorRates[key] = Double(errors) / Double(total)
    }
}
```

---

## 6. Graceful Degradation

### 6.1 Feature Fallbacks
```swift
class FeatureFallbackManager {
    func handleFeatureFailure(_ feature: Feature) {
        switch feature {
        case .gesture Recognition:
            // Fall back to voice commands and tap
            enableVoiceCommandsOnly()
            showAlert("Gesture recognition unavailable. Use voice commands.")

        case .realtimeData:
            // Fall back to delayed data
            useDelayedDataFeed()
            showWarning("Real-time data unavailable. Using 15-minute delayed data.")

        case .visualization3D:
            // Fall back to 2D charts
            switch2DMode()
            showWarning("3D rendering unavailable. Using 2D charts.")

        case .newsIntegration:
            // Disable news features
            disableNewsFeed()
            // No alert needed, non-critical

        default:
            break
        }
    }
}
```

---

## 7. Recovery Procedures

### 7.1 Automatic Recovery
```swift
class AutoRecoveryManager {
    func attemptRecovery(from error: Error) async throws {
        switch error {
        case TradingCockpitError.networkError:
            try await reconnectNetwork()

        case TradingCockpitError.tokenExpired:
            try await refreshAuthToken()

        case TradingCockpitError.dataParsingFailed:
            try await resubscribeToData()

        default:
            // No automatic recovery available
            throw error
        }
    }

    private func reconnectNetwork() async throws {
        for attempt in 1...5 {
            try await Task.sleep(for: .seconds(Double(attempt)))

            if try await testConnection() {
                return
            }
        }

        throw TradingCockpitError.connectionTimeout
    }

    private func refreshAuthToken() async throws {
        let token = try await brokerAuthenticator.refreshToken()
        try KeychainManager.shared.store(token, for: currentBroker)
    }
}
```

---

## 8. Testing Edge Cases

### 8.1 Chaos Engineering
```swift
#if DEBUG
class ChaosEngineer {
    func injectRandomFailures() {
        // Randomly fail network calls
        if Double.random(in: 0...1) < 0.1 {
            throw TradingCockpitError.networkError(.timeout)
        }

        // Randomly corrupt data
        if Double.random(in: 0...1) < 0.05 {
            return corruptedData()
        }

        // Randomly delay responses
        if Double.random(in: 0...1) < 0.2 {
            Thread.sleep(forTimeInterval: Double.random(in: 1...5))
        }
    }
}
#endif
```

---

**Document Version History**:
- v1.0 (2025-11-24): Initial error handling and edge cases documentation
