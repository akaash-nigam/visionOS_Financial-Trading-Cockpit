# Trading Cockpit Test Guide

## Overview

This document describes all tests for the Financial Trading Cockpit application, including which tests can be run in which environments.

---

## Test Structure

```
Tests/
├── UnitTests/              # Fast, isolated unit tests
│   ├── Models/
│   │   ├── QuoteTests.swift
│   │   ├── PositionTests.swift
│   │   ├── OrderTests.swift
│   │   └── WatchlistTests.swift
│   ├── Services/
│   └── Utilities/
├── IntegrationTests/       # Tests requiring network/APIs
│   └── BrokerIntegrationTests.swift
└── UITests/                # UI automation tests
    └── TradingFlowUITests.swift
```

---

## Test Categories

### 1. Unit Tests (✅ Can run in CI/CD)

**Location**: `Tests/UnitTests/`

**Purpose**: Test individual components in isolation without external dependencies.

**Requirements**:
- No network access needed
- No Xcode required (can run via Swift Package Manager)
- Fast execution (< 1 second per test)

**Coverage**:

#### QuoteTests.swift (13 tests)
- ✅ Quote initialization
- ✅ Change calculation
- ✅ Change percent calculation
- ✅ Spread calculation
- ✅ Midpoint calculation
- ✅ Direction indicators (isPositive/isNegative)
- ✅ Mock data generation
- ✅ Codable serialization
- ✅ Performance benchmarks

#### PositionTests.swift (12 tests)
- ✅ Market value calculation
- ✅ Cost basis calculation
- ✅ Unrealized P&L calculation (profit & loss)
- ✅ P&L percentage calculation
- ✅ Position direction (long/short)
- ✅ Edge cases (zero cost basis, negative quantity)
- ✅ Portfolio aggregation
- ✅ Total portfolio P&L

#### OrderTests.swift (18 tests)
- ✅ Order request estimated value
- ✅ Order validation (symbol, quantity, buying power)
- ✅ Limit price validation
- ✅ Position sizing calculations
- ✅ Max shares calculation with stop loss
- ✅ Suggested position sizes
- ✅ Order status display
- ✅ Filled percentage calculation
- ✅ Active order detection

#### WatchlistTests.swift (20 tests)
- ✅ Watchlist initialization
- ✅ Add/remove symbols
- ✅ Duplicate symbol handling
- ✅ Contains checks
- ✅ Default watchlists
- ✅ Updated timestamps
- ✅ Watchlist item with/without quotes
- ✅ Symbol search results
- ✅ Watchlist statistics
- ✅ Codable serialization

**Total Unit Tests**: 63 tests

**To Run Unit Tests**:
```bash
# In Xcode
Cmd+U (run all tests)
Cmd+Ctrl+U (run current test)

# Via Command Line (Swift Package Manager)
swift test

# Run specific test
swift test --filter QuoteTests

# With coverage
swift test --enable-code-coverage
```

---

### 2. Integration Tests (⚠️ Requires API Credentials)

**Location**: `Tests/IntegrationTests/`

**Purpose**: Test integration with external services (Alpaca, Polygon.io).

**Requirements**:
- ✅ Xcode required
- ⚠️ Network access required
- ⚠️ API credentials required (set as environment variables)
- ⚠️ Paper trading account recommended
- Slower execution (1-5 seconds per test)

**Coverage**:

#### BrokerIntegrationTests.swift (10 tests)
- ⚠️ Get account info from Alpaca
- ⚠️ Get positions
- ⚠️ Submit market order (paper trading)
- ⚠️ Submit limit order
- ⚠️ Cancel order
- ⚠️ Invalid symbol error handling
- ⚠️ Invalid quantity error handling
- ⚠️ Get account performance benchmark
- ⚠️ Polygon WebSocket connection
- ⚠️ Real-time quote streaming

**Setup Required**:
```bash
# Set environment variables
export ALPACA_API_KEY="your_paper_trading_api_key"
export ALPACA_SECRET_KEY="your_paper_trading_secret"
export POLYGON_API_KEY="your_polygon_api_key"

# Then run in Xcode or via command line
swift test --filter IntegrationTests
```

**⚠️ Important Notes**:
- These tests use REAL APIs (paper trading mode)
- Orders are actually submitted (then cancelled)
- Rate limits may apply
- Tests may fail if markets are closed
- Requires active internet connection

---

### 3. UI Tests (❌ Requires Xcode + Simulator)

**Location**: `Tests/UITests/`

**Purpose**: Test user interface and user flows end-to-end.

**Requirements**:
- ❌ Xcode required
- ❌ visionOS Simulator required
- ❌ Cannot run in CI without macOS agents
- Very slow execution (5-30 seconds per test)

**Coverage**:

#### TradingFlowUITests.swift (15 tests)
- ❌ Authentication flow UI
- ❌ Main navigation menu
- ❌ Watchlist navigation
- ❌ Add symbol to watchlist flow
- ❌ Order entry navigation
- ❌ Order entry validation
- ❌ Order confirmation flow
- ❌ Portfolio navigation
- ❌ Portfolio position interaction
- ❌ Orders navigation
- ❌ Orders tab switching
- ❌ 3D visualization navigation
- ❌ Sign out flow
- ❌ Launch performance
- ❌ Navigation performance

**To Run UI Tests**:
```bash
# In Xcode
1. Select visionOS Simulator target
2. Product → Test (Cmd+U)
3. Or select specific UI test scheme

# Via Command Line
xcodebuild test \
  -scheme TradingCockpit \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  -only-testing:TradingCockpitUITests
```

**⚠️ Important Notes**:
- UI tests are brittle and may fail if UI changes
- Requires visionOS simulator (15+ GB disk space)
- Mock data should be used (not real API calls)
- Screenshots can be captured on failure

---

## Test Execution Summary

| Test Type | Count | Can Run in Terminal | Requires Xcode | Requires API Keys | Execution Time |
|-----------|-------|---------------------|----------------|-------------------|----------------|
| Unit Tests | 63 | ✅ Yes | Optional | ❌ No | < 5 seconds |
| Integration Tests | 10 | ⚠️ Yes* | ✅ Yes | ✅ Yes | 10-30 seconds |
| UI Tests | 15 | ❌ No | ✅ Yes | ❌ No | 1-5 minutes |
| **Total** | **88** | - | - | - | **1-6 minutes** |

\* Integration tests can run via `swift test` but require API credentials

---

## Running All Tests

### Quick Test (Unit Only)
```bash
# Fast, no external dependencies
swift test --filter UnitTests
```

### Full Test Suite (Requires Xcode)
```bash
# Run all tests including integration and UI
xcodebuild test \
  -scheme TradingCockpit \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

### CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Run Unit Tests
  run: swift test --filter UnitTests

# For full testing (requires macOS runner)
- name: Run All Tests
  run: |
    xcodebuild test \
      -scheme TradingCockpit \
      -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
      -enableCodeCoverage YES
```

---

## Test Coverage Goals

| Component | Target Coverage | Current Status |
|-----------|----------------|----------------|
| Models | 90% | ✅ ~85% |
| Services | 80% | ⚠️ ~60% (needs more tests) |
| Views | 70% | ⚠️ ~40% (UI tests cover some) |
| Utilities | 90% | ⏳ Not yet tested |
| **Overall** | **80%** | **~65%** |

---

## Writing New Tests

### Unit Test Template
```swift
import XCTest
@testable import TradingCockpit

final class MyFeatureTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    func testFeatureBehavior() {
        // Given
        let input = "test data"

        // When
        let result = myFunction(input)

        // Then
        XCTAssertEqual(result, "expected output")
    }

    func testPerformance() {
        measure {
            // Code to measure performance
        }
    }
}
```

### Integration Test Template
```swift
final class MyIntegrationTests: XCTestCase {

    func testAPICall() async throws {
        // Skip if credentials not available
        guard let apiKey = ProcessInfo.processInfo.environment["API_KEY"] else {
            throw XCTSkip("API key not available")
        }

        // Test actual API interaction
        let result = try await apiClient.fetchData()
        XCTAssertNotNil(result)
    }
}
```

### UI Test Template
```swift
final class MyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launch()
    }

    func testUserFlow() {
        // Test UI interactions
        app.buttons["MyButton"].tap()
        XCTAssertTrue(app.staticTexts["Result"].exists)
    }
}
```

---

## Test Maintenance

### Best Practices
1. **Keep tests independent** - Each test should be runnable in isolation
2. **Use descriptive names** - `testOrderValidationFailsWithInvalidQuantity` not `test1`
3. **Follow Arrange-Act-Assert** - Given, When, Then structure
4. **Mock external dependencies** - Don't rely on network in unit tests
5. **Test edge cases** - Zero, negative, nil, empty, etc.
6. **Measure performance** - Use `measure` blocks for critical paths

### When to Run Tests
- **Before commit** - Run unit tests (fast)
- **Before push** - Run all tests if possible
- **In CI/CD** - Always run unit tests, optionally integration tests
- **Before release** - Run full test suite including UI tests

---

## Troubleshooting

### Common Issues

**Issue**: Tests fail with "Module not found"
```bash
# Solution: Clean build folder
xcodebuild clean
swift package clean
swift build
```

**Issue**: Integration tests fail with API errors
```bash
# Solution: Check API credentials
echo $ALPACA_API_KEY
echo $ALPACA_SECRET_KEY

# Verify paper trading mode is enabled
# Check API rate limits
```

**Issue**: UI tests fail to find elements
```bash
# Solution: Update accessibility identifiers
# Add .accessibilityIdentifier("unique_id") to views
# Use app.buttons.matching(identifier: "id")
```

**Issue**: Tests are slow
```bash
# Solution: Run only changed tests
swift test --filter QuoteTests  # Specific test
swift test --skip IntegrationTests  # Skip slow tests

# Or use Xcode test plans to organize test suites
```

---

## Future Test Additions

### Needed Tests
- [ ] Service tests (TradingService, WatchlistService, AuthenticationService)
- [ ] Utility tests (Logger, KeychainManager, DatabaseManager)
- [ ] View model tests (if MVVM pattern is adopted)
- [ ] Snapshot tests (for UI regression testing)
- [ ] Accessibility tests
- [ ] Localization tests

### Performance Benchmarks
- [ ] Terrain generation (should be < 100ms for 100 securities)
- [ ] Order validation (should be < 10ms)
- [ ] Portfolio P&L calculation (should be < 50ms for 100 positions)
- [ ] Symbol search (should be < 200ms)

---

## Test Reports

### Generate Coverage Report
```bash
# In Xcode
1. Product → Test (Cmd+U)
2. View → Navigators → Show Report Navigator
3. Select latest test run
4. Click Coverage tab

# Via Command Line
xcodebuild test \
  -scheme TradingCockpit \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View results
xcrun xccov view --report TestResults.xcresult
```

### Export Test Results
```bash
# Generate JUnit XML for CI
xcodebuild test ... | xcpretty --report junit

# Generate HTML report
xcodebuild test ... | xcpretty --report html
```

---

## Contact

For questions about tests:
- Check existing test files for examples
- Review this guide for test requirements
- Add new tests following the templates above

**Remember**: Good tests are the foundation of reliable software! 🧪✅
