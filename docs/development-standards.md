# Development Standards
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Code Style Guide

### 1.1 Swift Style
Follow [Swift.org API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

#### Naming Conventions
```swift
// ✅ Good
class MarketDataHub { }
func calculateTotalPnL() -> Decimal { }
var isAuthenticated: Bool = false
let maxRetryAttempts = 3

// ❌ Bad
class marketdatahub { }
func calc_pnl() -> Decimal { }
var authenticated: Bool = false
let MAX_RETRY = 3
```

#### File Organization
```swift
// MARK: - Type Definition
class OrderManager {

    // MARK: - Properties
    private let tradingEngine: TradingEngine
    private var pendingOrders: [Order] = []

    // MARK: - Initialization
    init(tradingEngine: TradingEngine) {
        self.tradingEngine = tradingEngine
    }

    // MARK: - Public Methods
    func submitOrder(_ order: Order) async throws {
        // Implementation
    }

    // MARK: - Private Methods
    private func validateOrder(_ order: Order) throws {
        // Implementation
    }
}
```

---

## 2. Project Structure

```
TradingCockpit/
├── App/
│   ├── TradingCockpitApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   │   ├── Security.swift
│   │   ├── Order.swift
│   │   ├── Portfolio.swift
│   │   └── Quote.swift
│   ├── Services/
│   │   ├── TradingEngine.swift
│   │   ├── MarketDataHub.swift
│   │   ├── RiskManager.swift
│   │   └── PortfolioManager.swift
│   └── Utilities/
│       ├── Logger.swift
│       ├── Extensions/
│       └── Constants.swift
├── Features/
│   ├── Trading/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── Visualization/
│   │   ├── TerrainGenerator.swift
│   │   ├── OptionsSpiral.swift
│   │   └── RiskBarriers.swift
│   └── Gestures/
│       ├── GestureRecognizer.swift
│       └── HandTrackingManager.swift
├── Integration/
│   ├── Brokers/
│   │   ├── BrokerAdapter.swift
│   │   ├── InteractiveBrokersAdapter.swift
│   │   └── TDAmeritadeAdapter.swift
│   ├── MarketData/
│   │   └── PolygonProvider.swift
│   └── News/
│       └── NewsProvider.swift
├── Resources/
│   ├── Assets.xcassets/
│   ├── Shaders/
│   └── Textures/
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

## 3. Git Workflow

### 3.1 Branch Naming
```
feature/    - New features
bugfix/     - Bug fixes
hotfix/     - Urgent fixes for production
release/    - Release preparation
docs/       - Documentation updates
refactor/   - Code refactoring

Examples:
feature/options-spiral-visualization
bugfix/order-validation-crash
hotfix/market-data-connection
```

### 3.2 Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/)

```
<type>(<scope>): <subject>

<body>

<footer>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Adding tests
- chore: Maintenance

Examples:
feat(trading): add options chain visualization
fix(auth): resolve token refresh issue
docs(api): update broker integration guide
refactor(data): optimize quote caching
test(orders): add validation tests
```

### 3.3 Pull Request Process

1. **Create branch** from `main`
2. **Implement** changes with tests
3. **Run** tests and linters locally
4. **Create PR** with descriptive title and description
5. **Request review** from at least 1 team member
6. **Address** review comments
7. **Merge** after approval (squash and merge)

#### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console warnings
- [ ] Tests passing
```

---

## 4. Code Review Guidelines

### 4.1 What to Look For
- **Correctness**: Does it work as intended?
- **Performance**: Are there performance issues?
- **Security**: Any security vulnerabilities?
- **Readability**: Is the code clear and maintainable?
- **Tests**: Are there adequate tests?
- **Documentation**: Are complex parts documented?

### 4.2 Review Checklist
```markdown
- [ ] Code compiles without warnings
- [ ] Tests pass
- [ ] No obvious bugs
- [ ] Error handling is appropriate
- [ ] No hardcoded values (use constants)
- [ ] No sensitive data in code
- [ ] Performance considerations addressed
- [ ] Follows project conventions
- [ ] Documentation updated if needed
```

---

## 5. Documentation Standards

### 5.1 Code Documentation
```swift
/// Calculates the total P&L for a portfolio including realized and unrealized gains.
///
/// This method aggregates P&L from all positions, accounting for:
/// - Realized gains/losses from closed positions
/// - Unrealized gains/losses from open positions
/// - Commission costs
///
/// - Parameter portfolio: The portfolio to calculate P&L for
/// - Returns: Total P&L as a Decimal value
/// - Throws: `PortfolioError.invalidData` if position data is corrupt
func calculateTotalPnL(portfolio: Portfolio) throws -> Decimal {
    // Implementation
}
```

### 5.2 README Standards
Every module should have a README with:
- **Purpose**: What does this module do?
- **Usage**: How to use it?
- **Dependencies**: What does it depend on?
- **Examples**: Code examples

---

## 6. Testing Standards

### 6.1 Test Coverage
- **Minimum**: 80% overall
- **Critical paths**: 100% (order validation, risk checks)
- **UI code**: 60% minimum

### 6.2 Test Naming
```swift
// Format: test_<methodName>_<scenario>_<expectedResult>

func test_validateOrder_insufficientFunds_throwsError() {
    // Test implementation
}

func test_calculatePnL_withMultiplePositions_returnsCorrectTotal() {
    // Test implementation
}

func test_submitOrder_validOrder_returnsConfirmation() async {
    // Test implementation
}
```

### 6.3 Test Structure (Arrange-Act-Assert)
```swift
func test_orderValidation_invalidQuantity_throwsError() {
    // Arrange
    let order = Order(
        security: mockSecurity,
        action: .buy,
        quantity: -10,  // Invalid
        orderType: .market
    )
    let validator = OrderValidator()

    // Act & Assert
    XCTAssertThrowsError(
        try validator.validate(order, account: mockAccount, portfolio: mockPortfolio)
    ) { error in
        XCTAssertEqual(error as? ValidationError, .invalidQuantity)
    }
}
```

---

## 7. Performance Standards

### 7.1 Performance Budgets
```swift
struct PerformanceBudgets {
    // Rendering
    static let minFrameRate: Double = 90  // fps
    static let maxFrameTime: TimeInterval = 1.0 / 90.0  // ~11ms

    // Data processing
    static let maxDataProcessingTime: TimeInterval = 0.005  // 5ms
    static let maxBatchProcessingTime: TimeInterval = 0.010  // 10ms

    // Network
    static let maxAPILatency: TimeInterval = 0.100  // 100ms
    static let maxWebSocketLatency: TimeInterval = 0.050  // 50ms

    // Memory
    static let maxMemoryUsage: Int64 = 3 * 1024 * 1024 * 1024  // 3GB
    static let maxCacheSize: Int64 = 500 * 1024 * 1024  // 500MB
}
```

### 7.2 Performance Testing
```swift
func testPerformance_terrainGeneration() {
    measure(metrics: [XCTClockMetric()]) {
        let generator = TerrainGenerator()
        let _ = generator.generateTerrain(securities: mockSecurities, quotes: mockQuotes)
    }
    // Must complete in < 16ms
}
```

---

## 8. Security Standards

### 8.1 Security Checklist
```markdown
- [ ] No hardcoded credentials
- [ ] All secrets in Keychain
- [ ] HTTPS only (TLS 1.3)
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention
- [ ] XSS prevention (if applicable)
- [ ] Sensitive data encrypted at rest
- [ ] Audit logging for all orders
- [ ] Session timeout implemented
- [ ] Biometric authentication supported
```

### 8.2 Sensitive Data Handling
```swift
// ❌ Bad
let apiKey = "sk_live_abc123xyz"

// ✅ Good
let apiKey = try KeychainManager.shared.retrieve(key: "api_key")
```

---

## 9. Dependency Management

### 9.1 Adding Dependencies
1. **Evaluate need**: Is it necessary?
2. **Check license**: Compatible with app?
3. **Check maintenance**: Actively maintained?
4. **Security audit**: Any known vulnerabilities?
5. **Size impact**: How big is it?

### 9.2 Dependency Updates
- Review release notes before updating
- Test thoroughly after updates
- Pin versions in production

---

## 10. Continuous Integration

### 10.1 CI Pipeline
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build
        run: xcodebuild build -scheme TradingCockpit

      - name: Run Tests
        run: xcodebuild test -scheme TradingCockpit

      - name: Lint
        run: swiftlint

      - name: Code Coverage
        run: xcov --scheme TradingCockpit --minimum_coverage_percentage 80
```

---

## 11. Release Process

### 11.1 Version Numbering
Follow [Semantic Versioning](https://semver.org/): MAJOR.MINOR.PATCH

```
1.0.0 - Initial release
1.1.0 - New features added
1.1.1 - Bug fixes
2.0.0 - Breaking changes
```

### 11.2 Release Checklist
```markdown
- [ ] All tests passing
- [ ] Code review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version number incremented
- [ ] Release notes drafted
- [ ] App Store screenshots updated
- [ ] Beta testing completed
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] App Store submission ready
```

---

## 12. Code Quality Tools

### 12.1 SwiftLint Configuration
```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - explicit_type_interface
  - closure_spacing

excluded:
  - Pods
  - Generated

line_length:
  warning: 120
  error: 200

function_body_length:
  warning: 50
  error: 100

type_body_length:
  warning: 300
  error: 500
```

### 12.2 Static Analysis
```bash
# Run SwiftLint
swiftlint

# Run SwiftFormat
swiftformat .

# Run Periphery (find unused code)
periphery scan
```

---

## 13. Accessibility Standards

### 13.1 Accessibility Checklist
```markdown
- [ ] All UI elements have accessibility labels
- [ ] Support for Dynamic Type
- [ ] VoiceOver tested
- [ ] Color contrast meets WCAG AA standards
- [ ] Alternative input methods available
- [ ] Haptic feedback provided
- [ ] Audio cues for important events
```

---

## 14. Monitoring & Analytics

### 14.1 Logging Levels
```swift
enum LogLevel {
    case debug      // Development only
    case info       // General information
    case warning    // Potential issues
    case error      // Errors that don't crash
    case critical   // Severe errors

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}

class Logger {
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line) {
        #if DEBUG
        print("\(level.emoji) [\(level)] \(file):\(line) - \(message)")
        #endif

        // Send to analytics in production
        if level >= .error {
            Analytics.track(event: "error", properties: ["message": message])
        }
    }
}
```

---

## 15. Development Environment Setup

### 15.1 Required Tools
```bash
# Install Xcode
xcode-select --install

# Install SwiftLint
brew install swiftlint

# Install SwiftFormat
brew install swiftformat

# Install xcov (coverage)
gem install xcov

# Install Periphery
brew install periphery
```

### 15.2 Pre-commit Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run SwiftLint
swiftlint
if [ $? -ne 0 ]; then
    echo "SwiftLint failed. Please fix warnings and errors."
    exit 1
fi

# Run tests
xcodebuild test -scheme TradingCockpit
if [ $? -ne 0 ]; then
    echo "Tests failed. Please fix failing tests."
    exit 1
fi
```

---

## 16. Best Practices

### 16.1 General Principles
1. **SOLID Principles**: Follow SOLID design principles
2. **DRY**: Don't Repeat Yourself
3. **KISS**: Keep It Simple, Stupid
4. **YAGNI**: You Aren't Gonna Need It
5. **Separation of Concerns**: Each module has one responsibility

### 16.2 Swift Best Practices
```swift
// Use Swift's type system
func fetchQuote(_ symbol: String) -> Quote? { }  // ✅
func fetchQuote(_ symbol: Any) -> Any { }        // ❌

// Use guard for early returns
guard let quote = getQuote(symbol) else { return }  // ✅
if let quote = getQuote(symbol) { /* ... */ }      // ❌ when early return is clearer

// Use map/filter/reduce
let symbols = securities.map { $0.symbol }  // ✅
var symbols: [String] = []                  // ❌
for security in securities {
    symbols.append(security.symbol)
}

// Use async/await
try await submitOrder(order)  // ✅
// Avoid completion handlers when possible
```

---

## 17. Resources

### 17.1 Official Documentation
- [Swift.org Documentation](https://www.swift.org/documentation/)
- [visionOS Developer](https://developer.apple.com/visionos/)
- [RealityKit](https://developer.apple.com/documentation/realitykit/)

### 17.2 Style Guides
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Google Swift Style Guide](https://google.github.io/swift/)
- [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)

---

**Document Version History**:
- v1.0 (2025-11-24): Initial development standards
