# Contributing to Trading Cockpit

Thank you for your interest in contributing to Trading Cockpit! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

### Prerequisites

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.2+** with visionOS SDK
- **Apple Vision Pro** or visionOS Simulator
- **Swift 6.0+**
- **Git** for version control

### Initial Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/visionOS_Financial-Trading-Cockpit.git
   cd visionOS_Financial-Trading-Cockpit
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/visionOS_Financial-Trading-Cockpit.git
   ```

4. **Open in Xcode**:
   ```bash
   open TradingCockpit/TradingCockpit.xcodeproj
   ```

5. **Configure API credentials** (for testing):
   ```bash
   export ALPACA_API_KEY="your_paper_trading_key"
   export ALPACA_SECRET_KEY="your_paper_trading_secret"
   export POLYGON_API_KEY="your_polygon_key"
   ```

### Setting Up for Development

1. Review the [Getting Started Guide](docs/GETTING_STARTED.md)
2. Read the [System Architecture](docs/system-architecture.md)
3. Familiarize yourself with the [Development Standards](docs/development-standards.md)

## Development Process

### Branching Strategy

We use a feature branch workflow:

- **`main`** - Production-ready code
- **`develop`** - Integration branch for features
- **`feature/feature-name`** - New features
- **`fix/bug-name`** - Bug fixes
- **`docs/topic`** - Documentation updates
- **`test/scope`** - Test additions

### Creating a Feature Branch

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create a new feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. **Write code** following our [Coding Standards](#coding-standards)
2. **Add tests** for new functionality
3. **Update documentation** as needed
4. **Run tests** to ensure nothing breaks
5. **Commit changes** following [Commit Guidelines](#commit-guidelines)

## Coding Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

**Naming Conventions:**
```swift
// Types: UpperCamelCase
class TradingService { }
struct Quote { }
enum OrderType { }

// Functions and variables: lowerCamelCase
func calculateUnrealizedPnL() -> Decimal { }
var currentPrice: Decimal = 0.0

// Constants: lowerCamelCase
let maxPositionSize = 0.20
```

**Code Organization:**
```swift
// MARK: - Type Definition
class TradingService {

    // MARK: - Properties
    private let apiKey: String
    @Published var positions: [Position] = []

    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public Methods
    func submitOrder(_ request: OrderRequest) async throws -> Order {
        // Implementation
    }

    // MARK: - Private Methods
    private func validateOrder(_ request: OrderRequest) -> Bool {
        // Implementation
    }
}
```

**File Structure:**
- One type per file (unless tightly coupled)
- File name matches primary type name
- Organize by layer: Models, Services, Views, Integration

**Comments:**
- Use `///` for documentation comments
- Explain **why**, not **what**
- Document complex algorithms
- Add `// MARK:` for organization

**Error Handling:**
```swift
// Define specific error types
enum TradingError: Error {
    case insufficientFunds
    case invalidSymbol
    case marketClosed
}

// Use do-catch, not try?
do {
    let order = try await submitOrder(request)
} catch let error as TradingError {
    // Handle specific errors
} catch {
    // Handle unexpected errors
}
```

**Concurrency:**
```swift
// Use actor for mutable shared state
actor PortfolioManager {
    private var positions: [Position] = []

    func addPosition(_ position: Position) {
        positions.append(position)
    }
}

// Use async/await for asynchronous operations
func fetchQuote(symbol: String) async throws -> Quote {
    // Implementation
}

// Use @MainActor for UI updates
@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quote: Quote?
}
```

### SwiftUI Conventions

```swift
// Extract subviews for readability
struct OrderEntryView: View {
    var body: some View {
        VStack {
            headerView
            orderForm
            submitButton
        }
    }

    private var headerView: some View {
        // Header implementation
    }

    private var orderForm: some View {
        // Form implementation
    }

    private var submitButton: some View {
        // Button implementation
    }
}

// Use @State for local view state
@State private var quantity: Int = 1

// Use @StateObject for view-owned objects
@StateObject private var viewModel = QuoteViewModel()

// Use @ObservedObject for passed objects
@ObservedObject var tradingService: TradingService
```

## Commit Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Build process or tooling changes

### Examples

```bash
# Feature
git commit -m "feat(trading): Add limit order support"

# Bug fix
git commit -m "fix(portfolio): Correct P&L calculation for short positions"

# Documentation
git commit -m "docs(api): Add documentation for WatchlistService"

# Multi-line with body
git commit -m "feat(watchlist): Add symbol search functionality

Implement real-time symbol search with debouncing.
Search across symbol name and ticker.
Display results with exchange and security type.

Closes #42"
```

### Scope

Common scopes:
- `trading` - Trading execution
- `portfolio` - Portfolio management
- `watchlist` - Watchlist features
- `auth` - Authentication
- `api` - API integration
- `ui` - User interface
- `3d` - 3D visualization
- `data` - Data layer

## Pull Request Process

### Before Submitting

1. **Sync with upstream**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Run all tests**:
   ```bash
   # Unit tests
   swift test --filter UnitTests

   # Integration tests (requires API keys)
   swift test --filter IntegrationTests

   # UI tests (requires Xcode)
   xcodebuild test -scheme TradingCockpit \
     -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
   ```

3. **Verify code compiles**:
   ```bash
   swift build
   ```

4. **Update documentation** if needed

### Submitting a Pull Request

1. **Push to your fork**:
   ```bash
   git push origin your-feature-branch
   ```

2. **Open a Pull Request** on GitHub

3. **Fill out the PR template** completely

4. **Link related issues** (e.g., "Closes #42")

5. **Request review** from maintainers

### PR Requirements

- ✅ All tests pass
- ✅ Code follows style guidelines
- ✅ New code has tests (minimum 70% coverage)
- ✅ Documentation updated
- ✅ Commit messages follow conventions
- ✅ No merge conflicts
- ✅ PR description is clear and complete

### Review Process

1. **Automated checks** run (CI/CD)
2. **Maintainers review** code
3. **Feedback addressed** by contributor
4. **Approval** from at least one maintainer
5. **Merge** by maintainer

## Testing Requirements

### Test Coverage Goals

- **Models**: 90% coverage
- **Services**: 80% coverage
- **Views**: 70% coverage
- **Overall**: 80% coverage

### Writing Tests

```swift
import XCTest
@testable import TradingCockpit

final class QuoteTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    // MARK: - Tests

    func testChangePercentCalculation() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            last: 175.00,
            close: 170.00
        )

        // When
        let changePercent = quote.changePercent

        // Then
        XCTAssertEqual(
            Double(truncating: changePercent as NSNumber),
            2.94,
            accuracy: 0.01,
            "Change percent should be calculated correctly"
        )
    }

    // MARK: - Performance Tests

    func testPerformanceCalculation() {
        measure {
            // Code to benchmark
        }
    }
}
```

### Test Organization

```
TradingCockpit/Tests/
├── UnitTests/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── IntegrationTests/
│   └── BrokerIntegrationTests.swift
└── UITests/
    └── TradingFlowUITests.swift
```

### Running Tests

```bash
# All tests
swift test

# Specific test file
swift test --filter QuoteTests

# Specific test method
swift test --filter QuoteTests.testChangePercentCalculation

# With coverage
swift test --enable-code-coverage
```

## Documentation

### Code Documentation

Use Swift's documentation syntax:

```swift
/// Calculates the unrealized profit or loss for the position.
///
/// The unrealized P&L represents the difference between the current
/// market value and the cost basis of the position.
///
/// - Returns: The unrealized P&L as a Decimal value.
/// - Note: Positive values indicate profit, negative values indicate loss.
func calculateUnrealizedPnL() -> Decimal {
    return (currentPrice - averagePrice) * Decimal(quantity)
}
```

### Architecture Decision Records

For significant architectural changes, create an ADR in `docs/adr/`:

```markdown
# ADR-001: Use Actor-Based Concurrency

## Status
Accepted

## Context
Need thread-safe data access across multiple concurrent operations.

## Decision
Use Swift actors for managing shared mutable state.

## Consequences
- Thread safety guaranteed by compiler
- Easier to reason about concurrency
- Performance overhead for actor isolation
```

### Updating Documentation

When making changes, update relevant docs:

- **README.md** - If changing project overview
- **docs/api/** - If changing public APIs
- **docs/GETTING_STARTED.md** - If changing setup
- **CHANGELOG.md** - Add to "Unreleased" section

## Questions or Issues?

- **General questions**: Open a [Discussion](https://github.com/OWNER/REPO/discussions)
- **Bug reports**: Open an [Issue](https://github.com/OWNER/REPO/issues)
- **Security vulnerabilities**: Email security@tradingcockpit.com

## Recognition

Contributors will be recognized in:
- **README.md** Contributors section
- **CHANGELOG.md** Release notes
- GitHub Contributors page

Thank you for contributing to Trading Cockpit! 🚀

---

**Version**: 1.0.0
**Last Updated**: 2025-11-24
