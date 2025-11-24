# Data Models & Schema Design
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Overview

This document defines all data models, database schemas, and data structures for the Financial Trading Cockpit application. It covers in-memory models, persistent storage schemas, and API contracts.

---

## 2. Core Domain Models

### 2.1 Security

```swift
struct Security: Identifiable, Codable, Hashable {
    let id: UUID
    let symbol: String                  // e.g., "AAPL"
    let name: String                    // e.g., "Apple Inc."
    let type: SecurityType
    let exchange: Exchange
    let currency: Currency
    let sector: Sector?
    let industry: String?
    let marketCap: Decimal?
    let primaryKey: String              // Broker-specific identifier

    // Computed properties
    var displaySymbol: String { "\(exchange.rawValue):\(symbol)" }
}

enum SecurityType: String, Codable {
    case stock = "STK"
    case option = "OPT"
    case future = "FUT"
    case forex = "FX"
    case crypto = "CRYPTO"
    case etf = "ETF"
    case index = "IND"
}

enum Exchange: String, Codable {
    case nasdaq = "NASDAQ"
    case nyse = "NYSE"
    case amex = "AMEX"
    case cboe = "CBOE"          // Options
    case cme = "CME"            // Futures
    case binance = "BINANCE"    // Crypto
    case forex = "FOREX"
}

enum Currency: String, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case btc = "BTC"
    case eth = "ETH"
}

enum Sector: String, Codable {
    case technology = "Technology"
    case healthcare = "Healthcare"
    case financial = "Financial"
    case consumer = "Consumer"
    case industrial = "Industrial"
    case energy = "Energy"
    case utilities = "Utilities"
    case realestate = "Real Estate"
    case materials = "Materials"
    case communication = "Communication"
}
```

### 2.2 Quote (Real-Time Market Data)

```swift
struct Quote: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let timestamp: Date

    // Price data
    let bid: Decimal?
    let ask: Decimal?
    let last: Decimal
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal              // Previous close
    let volume: Int64

    // Derived fields
    var change: Decimal { last - close }
    var changePercent: Decimal { (change / close) * 100 }
    var spread: Decimal? {
        guard let bid = bid, let ask = ask else { return nil }
        return ask - bid
    }
    var midpoint: Decimal? {
        guard let bid = bid, let ask = ask else { return nil }
        return (bid + ask) / 2
    }

    // Market status
    let marketStatus: MarketStatus

    // Extended data (optional)
    let bidSize: Int?
    let askSize: Int?
    let averageVolume: Int64?
    let weekHigh52: Decimal?
    let weekLow52: Decimal?
}

enum MarketStatus: String, Codable {
    case premarket = "PREMARKET"
    case open = "OPEN"
    case closed = "CLOSED"
    case afterhours = "AFTERHOURS"
}
```

### 2.3 Option Contract

```swift
struct OptionContract: Identifiable, Codable {
    let id: UUID
    let underlying: String              // Underlying symbol
    let strike: Decimal
    let expiration: Date
    let type: OptionType
    let symbol: String                  // OCC symbol (e.g., "AAPL230616C00150000")

    // Pricing
    let bid: Decimal?
    let ask: Decimal?
    let last: Decimal
    let volume: Int
    let openInterest: Int
    let impliedVolatility: Double?

    // Greeks
    let delta: Double?
    let gamma: Double?
    let theta: Double?
    let vega: Double?
    let rho: Double?

    // Status
    let inTheMoney: Bool
    let intrinsicValue: Decimal

    // Timestamp
    let timestamp: Date
}

enum OptionType: String, Codable {
    case call = "C"
    case put = "P"
}

// Options Chain - collection of all options for an underlying
struct OptionsChain: Identifiable, Codable {
    let id: UUID
    let underlying: String
    let expirations: [Date]
    let strikes: [Decimal]
    let calls: [OptionContract]
    let puts: [OptionContract]
    let timestamp: Date

    // Helper methods
    func contracts(expiration: Date, type: OptionType) -> [OptionContract] {
        let filtered = type == .call ? calls : puts
        return filtered.filter { $0.expiration == expiration }
    }

    func contract(strike: Decimal, expiration: Date, type: OptionType) -> OptionContract? {
        contracts(expiration: expiration, type: type)
            .first { $0.strike == strike }
    }
}
```

### 2.4 Order

```swift
struct Order: Identifiable, Codable {
    let id: UUID
    let security: Security
    let action: OrderAction
    let quantity: Int
    let orderType: OrderType
    let timeInForce: TimeInForce
    let limitPrice: Decimal?
    let stopPrice: Decimal?
    let status: OrderStatus
    let createdAt: Date
    let updatedAt: Date
    let submittedBy: String             // User ID

    // Order IDs
    let clientOrderId: String           // Our internal ID
    let brokerOrderId: String?          // Broker's ID

    // Execution details
    let filledQuantity: Int
    let averageFillPrice: Decimal?
    let commission: Decimal?
    let executions: [Execution]

    // Risk fields
    let estimatedCost: Decimal
    let riskImpact: RiskImpact?

    // Multi-leg (for options spreads)
    let legs: [OrderLeg]?
    let strategyType: OptionStrategyType?
}

enum OrderAction: String, Codable {
    case buy = "BUY"
    case sell = "SELL"
    case sellShort = "SSHORT"
    case buyToCover = "BTC"
}

enum OrderType: String, Codable {
    case market = "MKT"
    case limit = "LMT"
    case stop = "STP"
    case stopLimit = "STP_LMT"
    case trailingStop = "TRAIL"
    case marketOnClose = "MOC"
    case limitOnClose = "LOC"
}

enum TimeInForce: String, Codable {
    case day = "DAY"
    case gtc = "GTC"                    // Good 'til canceled
    case ioc = "IOC"                    // Immediate or cancel
    case fok = "FOK"                    // Fill or kill
    case gtd = "GTD"                    // Good 'til date
}

enum OrderStatus: String, Codable {
    case pending = "PENDING"
    case submitted = "SUBMITTED"
    case accepted = "ACCEPTED"
    case partiallyFilled = "PARTIALLY_FILLED"
    case filled = "FILLED"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"

    var isActive: Bool {
        switch self {
        case .pending, .submitted, .accepted, .partiallyFilled:
            return true
        default:
            return false
        }
    }
}

struct OrderLeg: Codable {
    let security: Security
    let action: OrderAction
    let quantity: Int
    let ratio: Int                      // For spreads (e.g., 1:2 ratio)
}

enum OptionStrategyType: String, Codable {
    case spread = "SPREAD"
    case ironCondor = "IRON_CONDOR"
    case butterfly = "BUTTERFLY"
    case straddle = "STRADDLE"
    case strangle = "STRANGLE"
    case collar = "COLLAR"
    case calendarSpread = "CALENDAR_SPREAD"
}
```

### 2.5 Execution

```swift
struct Execution: Identifiable, Codable {
    let id: UUID
    let orderId: UUID
    let executionId: String             // Broker execution ID
    let symbol: String
    let side: OrderAction
    let quantity: Int
    let price: Decimal
    let commission: Decimal
    let timestamp: Date
    let exchange: Exchange
    let liquidityFlag: LiquidityFlag?   // For rebates/fees
}

enum LiquidityFlag: String, Codable {
    case added = "ADDED"                // Maker
    case removed = "REMOVED"            // Taker
}
```

### 2.6 Position

```swift
struct Position: Identifiable, Codable {
    let id: UUID
    let security: Security
    let quantity: Int                   // Can be negative (short)
    let averagePrice: Decimal           // Cost basis
    let currentPrice: Decimal
    let marketValue: Decimal
    let costBasis: Decimal
    let unrealizedPnL: Decimal
    let realizedPnL: Decimal
    let totalPnL: Decimal

    // For options
    let greeks: Greeks?

    // Risk metrics
    let betaWeightedDelta: Double?
    let portfolioWeight: Double?

    // Timestamps
    let openedAt: Date
    let updatedAt: Date

    // Tax lots (for detailed tracking)
    let taxLots: [TaxLot]

    // Computed properties
    var isLong: Bool { quantity > 0 }
    var isShort: Bool { quantity < 0 }
    var pnlPercent: Decimal { (totalPnL / costBasis) * 100 }
}

struct TaxLot: Identifiable, Codable {
    let id: UUID
    let quantity: Int
    let price: Decimal
    let acquiredDate: Date
    let costBasis: Decimal
    let term: TaxTerm

    var isLongTerm: Bool { term == .longTerm }
}

enum TaxTerm: String, Codable {
    case shortTerm = "SHORT_TERM"       // < 1 year
    case longTerm = "LONG_TERM"         // >= 1 year
}

struct Greeks: Codable {
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let rho: Double
}
```

### 2.7 Portfolio

```swift
struct Portfolio: Identifiable, Codable {
    let id: UUID
    let accountId: String
    let positions: [Position]
    let cash: Decimal
    let buyingPower: Decimal
    let equity: Decimal                 // Cash + market value of positions
    let portfolioValue: Decimal

    // P&L
    let totalUnrealizedPnL: Decimal
    let totalRealizedPnL: Decimal
    let totalPnL: Decimal
    let todayPnL: Decimal

    // Risk metrics
    let totalRisk: PortfolioRisk
    let riskLimits: [RiskLimit]

    // Greeks (for options)
    let portfolioGreeks: Greeks?

    // Timestamp
    let updatedAt: Date

    // Computed properties
    var marginUsed: Decimal { buyingPower - cash }
    var leverage: Double { Double(truncating: portfolioValue / equity as NSNumber) }
}

struct PortfolioRisk: Codable {
    let valueAtRisk: Decimal            // VaR (95% confidence, 1-day)
    let conditionalVaR: Decimal         // CVaR
    let maxDrawdown: Decimal
    let sharpeRatio: Double?
    let beta: Double
    let betaWeightedDelta: Double

    // Concentration risks
    let sectorExposure: [Sector: Decimal]
    let largestPosition: Decimal
    let top10Concentration: Double      // % of portfolio in top 10 positions
}
```

### 2.8 Risk Limit

```swift
struct RiskLimit: Identifiable, Codable {
    let id: UUID
    let type: RiskLimitType
    let threshold: Decimal
    let currentValue: Decimal
    let utilization: Double             // 0.0 to 1.0
    let status: RiskLimitStatus
    let enforcementLevel: EnforcementLevel

    var isBreached: Bool { utilization >= 1.0 }
    var isWarning: Bool { utilization >= 0.7 && utilization < 0.9 }
    var isCritical: Bool { utilization >= 0.9 }
}

enum RiskLimitType: String, Codable {
    case positionSize = "POSITION_SIZE"
    case portfolioValue = "PORTFOLIO_VALUE"
    case dailyLoss = "DAILY_LOSS"
    case sectorExposure = "SECTOR_EXPOSURE"
    case leverage = "LEVERAGE"
    case betaWeightedDelta = "BETA_WEIGHTED_DELTA"
    case valueAtRisk = "VAR"
    case optionsNotional = "OPTIONS_NOTIONAL"
}

enum RiskLimitStatus: String, Codable {
    case ok = "OK"                      // < 70%
    case warning = "WARNING"            // 70-90%
    case critical = "CRITICAL"          // 90-100%
    case breached = "BREACHED"          // >= 100%
}

enum EnforcementLevel: String, Codable {
    case advisory = "ADVISORY"          // Show warning only
    case soft = "SOFT"                  // Require confirmation
    case hard = "HARD"                  // Prevent order
}
```

### 2.9 News Item

```swift
struct NewsItem: Identifiable, Codable {
    let id: UUID
    let headline: String
    let summary: String?
    let source: String                  // "Bloomberg", "Reuters", etc.
    let url: URL?
    let publishedAt: Date
    let symbols: [String]               // Affected symbols
    let sentiment: Sentiment
    let impactScore: Double             // 0.0 to 1.0
    let priority: NewsPriority
    let category: NewsCategory
}

enum Sentiment: String, Codable {
    case positive = "POSITIVE"
    case neutral = "NEUTRAL"
    case negative = "NEGATIVE"

    var color: String {
        switch self {
        case .positive: return "green"
        case .neutral: return "gray"
        case .negative: return "red"
        }
    }
}

enum NewsPriority: String, Codable {
    case critical = "CRITICAL"          // Fed, earnings surprises
    case high = "HIGH"                  // Analyst upgrades, M&A
    case medium = "MEDIUM"              // SEC filings
    case low = "LOW"                    // General news
}

enum NewsCategory: String, Codable {
    case earnings = "EARNINGS"
    case guidance = "GUIDANCE"
    case analyst = "ANALYST"
    case economic = "ECONOMIC"
    case political = "POLITICAL"
    case regulatory = "REGULATORY"
    case merger = "MERGER"
    case general = "GENERAL"
}
```

### 2.10 Account & User

```swift
struct Account: Identifiable, Codable {
    let id: UUID
    let broker: Broker
    let accountNumber: String
    let accountType: AccountType
    let status: AccountStatus
    let capabilities: AccountCapabilities
    let connectedAt: Date
}

enum Broker: String, Codable {
    case interactiveBrokers = "IB"
    case tdAmeritrade = "TDA"
    case etrade = "ETRADE"
    case alpaca = "ALPACA"
    case robinhood = "ROBINHOOD"
}

enum AccountType: String, Codable {
    case cash = "CASH"
    case margin = "MARGIN"
    case portfolio = "PORTFOLIO"        // Portfolio margin
}

enum AccountStatus: String, Codable {
    case active = "ACTIVE"
    case restricted = "RESTRICTED"
    case closed = "CLOSED"
}

struct AccountCapabilities: Codable {
    let canTrade: Bool
    let canTradeOptions: Bool
    let canShortSell: Bool
    let canTradeFutures: Bool
    let canTradeCrypto: Bool
    let maxOptionsLevel: Int            // 0-5
}

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String
    let accounts: [Account]
    let preferences: UserPreferences
    let subscription: Subscription
    let createdAt: Date
}

struct UserPreferences: Codable {
    var defaultAccount: UUID?
    var theme: Theme
    var enableHaptics: Bool
    var enableSounds: Bool
    var orderConfirmation: OrderConfirmationPreference
    var defaultOrderType: OrderType
    var defaultTimeInForce: TimeInForce
    var riskLimits: [RiskLimit]
}

enum Theme: String, Codable {
    case dark = "DARK"
    case light = "LIGHT"
    case auto = "AUTO"
}

enum OrderConfirmationPreference: String, Codable {
    case always = "ALWAYS"
    case marketOnly = "MARKET_ONLY"
    case never = "NEVER"
}

struct Subscription: Codable {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let startDate: Date
    let renewalDate: Date?
    let cancelDate: Date?
}

enum SubscriptionTier: String, Codable {
    case free = "FREE"
    case basic = "BASIC"
    case professional = "PROFESSIONAL"
    case institutional = "INSTITUTIONAL"
}

enum SubscriptionStatus: String, Codable {
    case active = "ACTIVE"
    case trial = "TRIAL"
    case cancelled = "CANCELLED"
    case expired = "EXPIRED"
}
```

### 2.11 Workspace

```swift
struct Workspace: Identifiable, Codable {
    let id: UUID
    let name: String
    let windows: [SpatialWindow]
    let focusMode: FocusMode
    let securities: [Security]          // Tracked securities
    let layout: WorkspaceLayout
    let createdAt: Date
    let updatedAt: Date
    let isDefault: Bool
}

struct SpatialWindow: Identifiable, Codable {
    let id: UUID
    let type: WindowType
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let scale: Float
    let configuration: WindowConfiguration
}

enum WindowType: String, Codable {
    case chart = "CHART"
    case watchlist = "WATCHLIST"
    case orderEntry = "ORDER_ENTRY"
    case newsFeed = "NEWS_FEED"
    case portfolio = "PORTFOLIO"
    case optionsChain = "OPTIONS_CHAIN"
    case orderBook = "ORDER_BOOK"
    case analytics = "ANALYTICS"
}

enum FocusMode: String, Codable {
    case overview = "OVERVIEW"
    case options = "OPTIONS"
    case risk = "RISK"
    case news = "NEWS"
}

struct WorkspaceLayout: Codable {
    let name: String
    let description: String?
    let template: WorkspaceTemplate
}

enum WorkspaceTemplate: String, Codable {
    case dayTrader = "DAY_TRADER"
    case optionsTrader = "OPTIONS_TRADER"
    case longTerm = "LONG_TERM"
    case analyst = "ANALYST"
    case custom = "CUSTOM"
}
```

### 2.12 Watchlist

```swift
struct Watchlist: Identifiable, Codable {
    let id: UUID
    let name: String
    let securities: [Security]
    let alerts: [PriceAlert]
    let createdAt: Date
    let updatedAt: Date
    let sortOrder: WatchlistSortOrder
}

enum WatchlistSortOrder: String, Codable {
    case alphabetical = "ALPHABETICAL"
    case changePercent = "CHANGE_PERCENT"
    case volume = "VOLUME"
    case custom = "CUSTOM"
}

struct PriceAlert: Identifiable, Codable {
    let id: UUID
    let security: Security
    let condition: AlertCondition
    let threshold: Decimal
    let isActive: Bool
    let createdAt: Date
    let triggeredAt: Date?
}

enum AlertCondition: String, Codable {
    case above = "ABOVE"
    case below = "BELOW"
    case percentChange = "PERCENT_CHANGE"
    case volume = "VOLUME"
}
```

---

## 3. Database Schemas

### 3.1 SQLite Schema (Historical Data)

```sql
-- Securities reference data
CREATE TABLE securities (
    id TEXT PRIMARY KEY,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    exchange TEXT NOT NULL,
    currency TEXT NOT NULL,
    sector TEXT,
    industry TEXT,
    market_cap REAL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(symbol, exchange)
);

CREATE INDEX idx_securities_symbol ON securities(symbol);
CREATE INDEX idx_securities_sector ON securities(sector);

-- Historical OHLCV data
CREATE TABLE price_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    security_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    timeframe TEXT NOT NULL,  -- '1m', '5m', '1h', '1d'
    open REAL NOT NULL,
    high REAL NOT NULL,
    low REAL NOT NULL,
    close REAL NOT NULL,
    volume INTEGER NOT NULL,
    FOREIGN KEY (security_id) REFERENCES securities(id),
    UNIQUE(security_id, timestamp, timeframe)
);

CREATE INDEX idx_price_history_security_time ON price_history(security_id, timestamp DESC);
CREATE INDEX idx_price_history_timeframe ON price_history(timeframe, timestamp DESC);

-- Order audit trail (SEC compliance)
CREATE TABLE order_audit (
    id TEXT PRIMARY KEY,
    client_order_id TEXT NOT NULL,
    broker_order_id TEXT,
    account_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    action TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    order_type TEXT NOT NULL,
    limit_price REAL,
    stop_price REAL,
    status TEXT NOT NULL,
    submitted_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    filled_quantity INTEGER DEFAULT 0,
    average_fill_price REAL,
    commission REAL,
    user_id TEXT NOT NULL
);

CREATE INDEX idx_order_audit_account ON order_audit(account_id, submitted_at DESC);
CREATE INDEX idx_order_audit_symbol ON order_audit(symbol, submitted_at DESC);
CREATE INDEX idx_order_audit_status ON order_audit(status, submitted_at DESC);

-- Executions
CREATE TABLE executions (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL,
    execution_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price REAL NOT NULL,
    commission REAL NOT NULL,
    timestamp INTEGER NOT NULL,
    exchange TEXT NOT NULL,
    liquidity_flag TEXT,
    FOREIGN KEY (order_id) REFERENCES order_audit(id)
);

CREATE INDEX idx_executions_order ON executions(order_id, timestamp);
CREATE INDEX idx_executions_symbol ON executions(symbol, timestamp DESC);

-- News archive
CREATE TABLE news_archive (
    id TEXT PRIMARY KEY,
    headline TEXT NOT NULL,
    summary TEXT,
    source TEXT NOT NULL,
    url TEXT,
    published_at INTEGER NOT NULL,
    symbols TEXT NOT NULL,  -- JSON array
    sentiment TEXT NOT NULL,
    impact_score REAL NOT NULL,
    priority TEXT NOT NULL,
    category TEXT NOT NULL
);

CREATE INDEX idx_news_published ON news_archive(published_at DESC);
CREATE INDEX idx_news_priority ON news_archive(priority, published_at DESC);

-- Full-text search for news
CREATE VIRTUAL TABLE news_fts USING fts5(
    headline,
    summary,
    content='news_archive',
    content_rowid='id'
);
```

### 3.2 Core Data Schema (User Data)

```swift
// Workspace entity
@objc(WorkspaceEntity)
class WorkspaceEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var windowsData: Data          // JSON encoded [SpatialWindow]
    @NSManaged var focusMode: String
    @NSManaged var securitiesData: Data       // JSON encoded [Security]
    @NSManaged var layoutData: Data           // JSON encoded WorkspaceLayout
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var isDefault: Bool
}

// Watchlist entity
@objc(WatchlistEntity)
class WatchlistEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var securitiesData: Data       // JSON encoded [Security]
    @NSManaged var alertsData: Data           // JSON encoded [PriceAlert]
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var sortOrder: String
}
```

### 3.3 UserDefaults / CloudKit (Preferences)

```swift
struct StorageKeys {
    static let userPreferences = "user_preferences"
    static let defaultWorkspace = "default_workspace_id"
    static let lastSelectedAccount = "last_selected_account"
    static let onboardingCompleted = "onboarding_completed"
    static let appVersion = "app_version"
}

// CloudKit container: iCloud.com.example.TradingCockpit
// Record types:
// - Workspace (synced)
// - UserPreferences (synced)
// - Watchlist (synced)
```

---

## 4. API Contracts

### 4.1 WebSocket Message Formats

#### Quote Update
```json
{
    "type": "quote",
    "symbol": "AAPL",
    "timestamp": 1700000000000,
    "bid": 175.25,
    "ask": 175.27,
    "last": 175.26,
    "volume": 45123456,
    "change": 2.15,
    "changePercent": 1.24
}
```

#### Order Update
```json
{
    "type": "order_update",
    "orderId": "ORD-12345",
    "status": "FILLED",
    "filledQuantity": 100,
    "averageFillPrice": 175.26,
    "timestamp": 1700000000000
}
```

#### Execution Report
```json
{
    "type": "execution",
    "orderId": "ORD-12345",
    "executionId": "EXEC-67890",
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    "price": 175.26,
    "commission": 1.50,
    "timestamp": 1700000000000
}
```

### 4.2 REST API Endpoints (Broker Adapter)

```swift
protocol BrokerAPI {
    // Authentication
    func authenticate(credentials: Credentials) async throws -> AuthResponse
    func refreshToken() async throws -> AuthResponse

    // Account
    func getAccount() async throws -> AccountResponse
    func getPositions() async throws -> [PositionResponse]
    func getOrders() async throws -> [OrderResponse]

    // Trading
    func submitOrder(request: OrderRequest) async throws -> OrderResponse
    func cancelOrder(orderId: String) async throws -> CancelResponse
    func modifyOrder(orderId: String, request: ModifyOrderRequest) async throws -> OrderResponse

    // Market data
    func getQuote(symbol: String) async throws -> QuoteResponse
    func getOptionsChain(symbol: String, expiration: Date?) async throws -> OptionsChainResponse
    func getHistoricalData(symbol: String, range: DateInterval) async throws -> [OHLCVResponse]
}

struct OrderRequest: Codable {
    let symbol: String
    let action: String
    let quantity: Int
    let orderType: String
    let timeInForce: String
    let limitPrice: Decimal?
    let stopPrice: Decimal?
}

struct OrderResponse: Codable {
    let orderId: String
    let status: String
    let message: String?
}
```

---

## 5. In-Memory Data Structures

### 5.1 Quote Cache (Actor for Thread Safety)

```swift
actor QuoteCache {
    private var quotes: [String: Quote] = [:]
    private let maxSize = 1000
    private var accessOrder: [String] = []  // LRU tracking

    func set(quote: Quote) {
        if quotes.count >= maxSize {
            // Evict least recently used
            if let lru = accessOrder.first {
                quotes.removeValue(forKey: lru)
                accessOrder.removeFirst()
            }
        }

        quotes[quote.symbol] = quote
        accessOrder.append(quote.symbol)
    }

    func get(symbol: String) -> Quote? {
        guard let quote = quotes[symbol] else { return nil }

        // Update access order
        if let index = accessOrder.firstIndex(of: symbol) {
            accessOrder.remove(at: index)
            accessOrder.append(symbol)
        }

        return quote
    }

    func getAll() -> [Quote] {
        Array(quotes.values)
    }
}
```

### 5.2 Order Book (Level 2 Data)

```swift
struct OrderBook {
    let symbol: String
    var bids: [PriceLevel]          // Sorted descending by price
    var asks: [PriceLevel]          // Sorted ascending by price
    var timestamp: Date

    struct PriceLevel {
        let price: Decimal
        let size: Int
        let orderCount: Int
    }

    var spread: Decimal? {
        guard let bestBid = bids.first?.price,
              let bestAsk = asks.first?.price else {
            return nil
        }
        return bestAsk - bestBid
    }

    var midpoint: Decimal? {
        guard let bestBid = bids.first?.price,
              let bestAsk = asks.first?.price else {
            return nil
        }
        return (bestBid + bestAsk) / 2
    }
}
```

---

## 6. Validation Rules

### 6.1 Order Validation

```swift
enum ValidationError: Error {
    case insufficientFunds
    case invalidQuantity
    case invalidPrice
    case symbolNotFound
    case accountNotAuthorized
    case riskLimitExceeded(limit: RiskLimit)
    case marketClosed
    case duplicateOrder
}

struct OrderValidator {
    func validate(order: Order, account: Account, portfolio: Portfolio) throws {
        // Quantity validation
        guard order.quantity > 0 else {
            throw ValidationError.invalidQuantity
        }

        // Price validation
        if let limitPrice = order.limitPrice, limitPrice <= 0 {
            throw ValidationError.invalidPrice
        }

        // Funds check
        let estimatedCost = calculateEstimatedCost(order)
        guard portfolio.buyingPower >= estimatedCost else {
            throw ValidationError.insufficientFunds
        }

        // Risk limits check
        let riskImpact = calculateRiskImpact(order, portfolio)
        if let exceededLimit = checkRiskLimits(riskImpact, portfolio.riskLimits) {
            throw ValidationError.riskLimitExceeded(limit: exceededLimit)
        }

        // Market hours check (if required)
        if order.orderType == .market && !isMarketOpen(order.security.exchange) {
            throw ValidationError.marketClosed
        }
    }
}
```

### 6.2 Data Validation

```swift
extension Quote {
    func validate() throws {
        guard last > 0 else {
            throw DataError.invalidPrice
        }

        guard volume >= 0 else {
            throw DataError.invalidVolume
        }

        if let bid = bid, let ask = ask {
            guard ask >= bid else {
                throw DataError.invalidSpread
            }
        }
    }
}
```

---

## 7. Data Migration Strategy

### 7.1 Version Management

```swift
enum SchemaVersion: Int {
    case v1_0 = 1
    case v1_1 = 2
    case v2_0 = 3

    static var current: SchemaVersion { .v2_0 }
}

protocol Migration {
    var fromVersion: SchemaVersion { get }
    var toVersion: SchemaVersion { get }
    func migrate(database: Database) throws
}
```

### 7.2 Example Migration

```swift
struct Migration_v1_to_v2: Migration {
    let fromVersion: SchemaVersion = .v1_0
    let toVersion: SchemaVersion = .v1_1

    func migrate(database: Database) throws {
        // Add new columns
        try database.execute("""
            ALTER TABLE securities
            ADD COLUMN market_cap REAL;
        """)

        // Add new table
        try database.execute("""
            CREATE TABLE news_archive (
                id TEXT PRIMARY KEY,
                headline TEXT NOT NULL,
                -- ... rest of schema
            );
        """)
    }
}
```

---

## 8. Data Lifecycle

### 8.1 Cache TTL

| Data Type | TTL | Eviction Policy |
|-----------|-----|----------------|
| Real-time quotes | 5 seconds | Time-based |
| Historical prices | 24 hours | LRU |
| Options chains | 1 minute | Time-based |
| News items | 1 hour | LRU |
| Account positions | 30 seconds | Time-based |
| Workspace layouts | Indefinite | Manual |

### 8.2 Data Cleanup

```swift
class DataCleanupService {
    func cleanupOldData() async {
        // Delete price history older than 90 days
        await deleteOldPriceHistory(olderThan: .days(90))

        // Delete order audit older than 7 years (SEC requirement)
        await deleteOldOrderAudit(olderThan: .days(7 * 365))

        // Delete news older than 30 days
        await deleteOldNews(olderThan: .days(30))

        // Vacuum database
        await vacuumDatabase()
    }
}
```

---

## 9. References

- [Swift Codable Documentation](https://developer.apple.com/documentation/swift/codable)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [SQLite Documentation](https://www.sqlite.org/docs.html)

---

**Document Version History**:
- v1.0 (2025-11-24): Initial data models design
