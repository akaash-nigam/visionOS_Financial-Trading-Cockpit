# Testing Strategy
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Testing Pyramid

```
           ┌─────────────┐
           │   Manual    │  5%
           │  Testing    │
           ├─────────────┤
           │   E2E       │  15%
           │   Tests     │
           ├─────────────┤
           │Integration  │  30%
           │   Tests     │
           ├─────────────┤
           │    Unit     │  50%
           │   Tests     │
           └─────────────┘
```

---

## 2. Unit Testing

### 2.1 Testing Framework
- **XCTest** for all unit tests
- **Quick/Nimble** for BDD-style tests (optional)

### 2.2 Example Tests
```swift
class OrderValidatorTests: XCTestCase {
    var validator: OrderValidator!

    override func setUp() {
        super.setUp()
        validator = OrderValidator()
    }

    func testValidOrder() throws {
        let order = Order(
            security: mockSecurity,
            action: .buy,
            quantity: 100,
            orderType: .market
        )

        XCTAssertNoThrow(try validator.validate(order, account: mockAccount, portfolio: mockPortfolio))
    }

    func testInsufficientFunds() throws {
        let order = Order(
            security: mockSecurity,
            action: .buy,
            quantity: 1_000_000,  // Too large
            orderType: .market
        )

        XCTAssertThrowsError(try validator.validate(order, account: mockAccount, portfolio: mockPortfolio)) { error in
            XCTAssertEqual(error as? ValidationError, .insufficientFunds)
        }
    }

    func testInvalidQuantity() throws {
        let order = Order(
            security: mockSecurity,
            action: .buy,
            quantity: -10,  // Negative
            orderType: .market
        )

        XCTAssertThrowsError(try validator.validate(order, account: mockAccount, portfolio: mockPortfolio))
    }
}
```

### 2.3 Coverage Target
- **Minimum**: 80% code coverage
- **Critical Paths**: 100% (order validation, risk checks, calculations)

---

## 3. Integration Testing

### 3.1 API Integration Tests
```swift
class BrokerAPITests: XCTestCase {
    func testOrderSubmission() async throws {
        let adapter = InteractiveBrokersAdapter(environment: .paper)
        try await adapter.authenticate(credentials: testCredentials)

        let order = createTestOrder()
        let confirmation = try await adapter.submitOrder(order)

        XCTAssertNotNil(confirmation.orderId)
        XCTAssertEqual(confirmation.status, "SUBMITTED")
    }

    func testMarketDataStream() async throws {
        let provider = PolygonDataProvider(apiKey: testApiKey)

        var receivedQuotes = 0
        for await quote in provider.streamQuotes(symbols: ["AAPL"]).prefix(10) {
            XCTAssertEqual(quote.symbol, "AAPL")
            XCTAssertGreaterThan(quote.last, 0)
            receivedQuotes += 1
        }

        XCTAssertEqual(receivedQuotes, 10)
    }
}
```

### 3.2 Database Integration Tests
```swift
class DatabaseTests: XCTestCase {
    var database: Database!

    override func setUp() async throws {
        database = try await Database.createInMemory()
    }

    func testOrderPersistence() async throws {
        let order = createTestOrder()

        try await database.insert(order, table: "orders")
        let retrieved = try await database.select(Order.self, from: "orders").first

        XCTAssertEqual(retrieved?.id, order.id)
        XCTAssertEqual(retrieved?.symbol, order.security.symbol)
    }
}
```

---

## 4. End-to-End Testing

### 4.1 UI Tests
```swift
class TradingFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCompleteTradingFlow() throws {
        // 1. Launch app
        XCTAssertTrue(app.staticTexts["Welcome"].exists)

        // 2. Navigate to market view
        app.buttons["Market"].tap()

        // 3. Select security
        app.buttons["AAPL"].tap()

        // 4. Enter order
        app.buttons["Buy"].tap()
        app.sliders["Quantity"].adjust(toNormalizedSliderPosition: 0.5)

        // 5. Submit order
        app.buttons["Submit"].tap()

        // 6. Verify confirmation
        XCTAssertTrue(app.staticTexts["Order Submitted"].waitForExistence(timeout: 5))
    }
}
```

---

## 5. Performance Testing

### 5.1 Rendering Performance
```swift
class RenderingPerformanceTests: XCTestCase {
    func testTerrainGenerationPerformance() throws {
        let securities = generateMockSecurities(count: 500)
        let quotes = generateMockQuotes(for: securities)

        measure(metrics: [XCTClockMetric()]) {
            let generator = TerrainGenerator()
            let _ = generator.generateTerrain(securities: securities, quotes: quotes)
        }

        // Should complete in < 16ms (60fps)
    }

    func testDataProcessingThroughput() async throws {
        let hub = MarketDataHub()
        let updates = generateMockUpdates(count: 10_000)

        let start = Date()

        for update in updates {
            let data = try JSONEncoder().encode(update)
            await hub.processRawData(data, source: .interactiveBrokers)
        }

        let duration = Date().timeIntervalSince(start)
        let throughput = Double(updates.count) / duration

        XCTAssertGreaterThan(throughput, 1000)  // > 1000 updates/sec
    }
}
```

### 5.2 Memory Testing
```swift
class MemoryTests: XCTestCase {
    func testMemoryUsageUnderLoad() async throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate heavy load
            let hub = MarketDataHub()
            Task {
                for _ in 0..<10_000 {
                    let update = generateRandomUpdate()
                    let data = try! JSONEncoder().encode(update)
                    await hub.processRawData(data, source: .interactiveBrokers)
                }
            }
        }

        // Should stay under 500MB
    }
}
```

---

## 6. Security Testing

### 6.1 Authentication Tests
```swift
class SecurityTests: XCTestCase {
    func testKeychainEncryption() throws {
        let token = AuthToken(
            accessToken: "test_token",
            refreshToken: "refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "trading"
        )

        // Store
        try KeychainManager.shared.store(token, for: .interactiveBrokers)

        // Retrieve
        let retrieved = try KeychainManager.shared.retrieve(for: .interactiveBrokers)

        XCTAssertEqual(retrieved.accessToken, token.accessToken)
    }

    func testSessionTimeout() async throws {
        let sessionManager = SessionManager()

        // Simulate inactivity
        try await Task.sleep(for: .seconds(16 * 60))  // 16 minutes

        // Session should be locked
        let isLocked = await sessionManager.isLocked
        XCTAssertTrue(isLocked)
    }
}
```

---

## 7. Gesture Recognition Testing

### 7.1 Gesture Simulation Tests
```swift
class GestureTests: XCTestCase {
    func testPinchRecognition() {
        let recognizer = GestureRecognizer()
        let gesture = simulatePinch(hand: .right)

        let detected = recognizer.recognize(
            leftHand: nil,
            rightHand: createPinchingHand()
        )

        XCTAssertEqual(detected, .singlePinch(hand: .right))
    }

    func testDragRecognition() {
        let recognizer = GestureRecognizer()

        // Simulate drag up
        let frames = simulateDragUpGesture()

        let detected = recognizer.recognize(frames)
        XCTAssertNotNil(detected)

        if case .dragUp(let hand, let distance) = detected! {
            XCTAssertGreaterThan(distance, 0.1)
        } else {
            XCTFail("Expected dragUp gesture")
        }
    }
}
```

---

## 8. Mock Data & Test Utilities

### 8.1 Mock Generators
```swift
class MockDataGenerator {
    static func generateMockSecurity() -> Security {
        Security(
            id: UUID(),
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            exchange: .nasdaq,
            currency: .usd,
            sector: .technology
        )
    }

    static func generateMockQuote(symbol: String = "AAPL") -> Quote {
        Quote(
            id: UUID(),
            symbol: symbol,
            timestamp: Date(),
            bid: Decimal(Double.random(in: 150...170)),
            ask: Decimal(Double.random(in: 150...170)),
            last: Decimal(Double.random(in: 150...170)),
            open: 160,
            high: 170,
            low: 155,
            close: 165,
            volume: Int64.random(in: 1_000_000...10_000_000),
            marketStatus: .open
        )
    }

    static func generateMockPortfolio() -> Portfolio {
        Portfolio(
            id: UUID(),
            accountId: "TEST-ACCOUNT",
            positions: [],
            cash: 100_000,
            buyingPower: 200_000,
            equity: 100_000,
            portfolioValue: 100_000,
            totalUnrealizedPnL: 0,
            totalRealizedPnL: 0,
            totalPnL: 0,
            todayPnL: 0,
            totalRisk: mockPortfolioRisk(),
            riskLimits: [],
            updatedAt: Date()
        )
    }
}
```

---

## 9. CI/CD Pipeline

### 9.1 Automated Test Runs
```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Unit Tests
        run: xcodebuild test -scheme TradingCockpit -destination 'platform=visionOS Simulator,name=Apple Vision Pro'

      - name: Run Integration Tests
        run: xcodebuild test -scheme TradingCockpit-Integration

      - name: Code Coverage
        run: xcov --scheme TradingCockpit --minimum_coverage_percentage 80
```

---

## 10. Test Data Management

### 10.1 Test Fixtures
```swift
enum TestFixtures {
    static let testAccount = Account(
        id: UUID(),
        broker: .interactiveBrokers,
        accountNumber: "TEST123",
        accountType: .cash,
        status: .active,
        capabilities: AccountCapabilities(
            canTrade: true,
            canTradeOptions: true,
            canShortSell: false,
            canTradeFutures: false,
            canTradeCrypto: false,
            maxOptionsLevel: 2
        ),
        connectedAt: Date()
    )

    static let testSecurities = [
        Security(symbol: "AAPL", name: "Apple Inc.", ...),
        Security(symbol: "GOOGL", name: "Alphabet Inc.", ...),
        Security(symbol: "MSFT", name: "Microsoft Corporation", ...)
    ]
}
```

---

## 11. Regression Testing

### 11.1 Critical Path Tests
Run before every release:
- [ ] Login flow
- [ ] Market data streaming
- [ ] Order submission
- [ ] Order cancellation
- [ ] Portfolio updates
- [ ] Risk limit enforcement
- [ ] Gesture recognition
- [ ] 3D visualization rendering

---

## 12. Testing Checklist

### 12.1 Pre-Release Checklist
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Code coverage > 80%
- [ ] Performance benchmarks met
- [ ] Security tests passing
- [ ] UI tests passing
- [ ] Manual testing on device
- [ ] Beta testing feedback addressed

---

**Document Version History**:
- v1.0 (2025-11-24): Initial testing strategy
