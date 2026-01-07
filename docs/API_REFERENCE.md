# API Reference

Complete reference documentation for Trading Cockpit's public APIs, services, and models.

## Table of Contents

- [Services](#services)
  - [AuthenticationService](#authenticationservice)
  - [TradingService](#tradingservice)
  - [MarketDataHub](#marketdatahub)
  - [WatchlistService](#watchlistservice)
- [Models](#models)
  - [Quote](#quote)
  - [Position](#position)
  - [Order](#order)
  - [Watchlist](#watchlist)
- [Integration](#integration)
  - [AlpacaAPIClient](#alpacaapiclient)
  - [PolygonWebSocket](#polygonwebsocket)
- [Utilities](#utilities)
  - [KeychainManager](#keychainmanager)
  - [Logger](#logger)

---

## Services

### AuthenticationService

Handles user authentication and account management with broker APIs.

#### Import

```swift
import TradingCockpit
```

#### Declaration

```swift
@Observable
class AuthenticationService {
    var isAuthenticated: Bool
    var accountInfo: AccountInfo?
    var error: Error?
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isAuthenticated` | `Bool` | Whether user is currently authenticated |
| `accountInfo` | `AccountInfo?` | Current account information |
| `error` | `Error?` | Last error encountered |

#### Methods

##### login(apiKey:secretKey:)

Authenticates user with Alpaca API credentials.

```swift
func login(apiKey: String, secretKey: String) async throws -> AccountInfo
```

**Parameters:**
- `apiKey`: Alpaca API key
- `secretKey`: Alpaca secret key

**Returns:** `AccountInfo` containing account details

**Throws:**
- `AuthenticationError.invalidCredentials` - Invalid API credentials
- `AuthenticationError.networkError` - Network connection failed
- `AuthenticationError.rateLimited` - Too many login attempts

**Example:**
```swift
let authService = AuthenticationService()

do {
    let account = try await authService.login(
        apiKey: "PKxxx",
        secretKey: "xxx"
    )
    print("Logged in: \(account.accountNumber)")
} catch AuthenticationError.invalidCredentials {
    print("Invalid credentials")
} catch {
    print("Login failed: \(error)")
}
```

##### logout()

Logs out the current user and clears stored credentials.

```swift
func logout() async
```

**Example:**
```swift
await authService.logout()
```

##### refreshAccount()

Refreshes current account information from the broker API.

```swift
func refreshAccount() async throws -> AccountInfo
```

**Returns:** Updated `AccountInfo`

---

### TradingService

Manages order execution, portfolio tracking, and position management.

#### Declaration

```swift
@Observable
class TradingService {
    var positions: [Position]
    var orders: [Order]
    var buyingPower: Decimal
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `positions` | `[Position]` | Current open positions |
| `orders` | `[Order]` | Order history |
| `buyingPower` | `Decimal` | Available buying power |
| `portfolio` | `Portfolio` | Portfolio summary |

#### Methods

##### submitOrder(_:)

Submits a new order to the broker.

```swift
func submitOrder(_ request: OrderRequest) async throws -> Order
```

**Parameters:**
- `request`: `OrderRequest` containing order details

**Returns:** Submitted `Order` with assigned ID

**Throws:**
- `TradingError.insufficientFunds` - Not enough buying power
- `TradingError.invalidSymbol` - Symbol not tradable
- `TradingError.marketClosed` - Market is closed
- `TradingError.invalidQuantity` - Invalid order quantity

**Example:**
```swift
let tradingService = TradingService()

let orderRequest = OrderRequest(
    symbol: "AAPL",
    quantity: 10,
    side: .buy,
    type: .market,
    timeInForce: .day
)

do {
    let order = try await tradingService.submitOrder(orderRequest)
    print("Order submitted: \(order.id)")
} catch TradingError.insufficientFunds {
    print("Not enough buying power")
} catch {
    print("Order failed: \(error)")
}
```

##### cancelOrder(orderId:)

Cancels an existing order.

```swift
func cancelOrder(orderId: String) async throws
```

**Parameters:**
- `orderId`: ID of order to cancel

**Throws:**
- `TradingError.orderNotFound` - Order ID not found
- `TradingError.orderNotCancellable` - Order already filled/cancelled

##### getPositions()

Fetches current positions from broker.

```swift
func getPositions() async throws -> [Position]
```

**Returns:** Array of current `Position` objects

##### closePosition(symbol:)

Closes an entire position for a given symbol.

```swift
func closePosition(symbol: String) async throws
```

**Parameters:**
- `symbol`: Symbol of position to close

---

### MarketDataHub

Manages real-time market data streaming and distribution.

#### Declaration

```swift
actor MarketDataHub {
    func subscribe(to symbols: [String]) -> AsyncStream<Quote>
    func unsubscribe(from symbols: [String]) async
}
```

#### Methods

##### subscribe(to:)

Subscribes to real-time quotes for specified symbols.

```swift
func subscribe(to symbols: [String]) -> AsyncStream<Quote>
```

**Parameters:**
- `symbols`: Array of symbols to subscribe to

**Returns:** `AsyncStream<Quote>` providing real-time quote updates

**Example:**
```swift
let hub = MarketDataHub()

Task {
    for await quote in hub.subscribe(to: ["AAPL", "GOOGL", "MSFT"]) {
        print("\(quote.symbol): $\(quote.last)")
    }
}
```

##### unsubscribe(from:)

Unsubscribes from quote updates for specified symbols.

```swift
func unsubscribe(from symbols: [String]) async
```

**Parameters:**
- `symbols`: Array of symbols to unsubscribe from

##### getQuote(symbol:)

Gets the most recent cached quote for a symbol.

```swift
func getQuote(symbol: String) async -> Quote?
```

**Parameters:**
- `symbol`: Symbol to get quote for

**Returns:** Latest `Quote` or `nil` if not available

---

### WatchlistService

Manages watchlists and symbol search functionality.

#### Declaration

```swift
@Observable
class WatchlistService {
    var watchlists: [Watchlist]
    var currentWatchlist: Watchlist?
    var searchResults: [SymbolSearchResult]
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `watchlists` | `[Watchlist]` | All user watchlists |
| `currentWatchlist` | `Watchlist?` | Currently selected watchlist |
| `watchlistItems` | `[WatchlistItem]` | Items in current watchlist |
| `searchResults` | `[SymbolSearchResult]` | Symbol search results |

#### Methods

##### createWatchlist(name:)

Creates a new watchlist.

```swift
func createWatchlist(name: String) -> Watchlist
```

**Parameters:**
- `name`: Name for the watchlist

**Returns:** Newly created `Watchlist`

**Example:**
```swift
let watchlistService = WatchlistService(marketDataHub: hub)

let techWatchlist = watchlistService.createWatchlist(name: "Tech Stocks")
```

##### addSymbol(_:to:)

Adds a symbol to a watchlist.

```swift
func addSymbol(_ symbol: String, to watchlistId: UUID) throws
```

**Parameters:**
- `symbol`: Symbol to add
- `watchlistId`: ID of target watchlist

**Throws:**
- `WatchlistError.watchlistNotFound`
- `WatchlistError.symbolAlreadyExists`

##### removeSymbol(_:from:)

Removes a symbol from a watchlist.

```swift
func removeSymbol(_ symbol: String, from watchlistId: UUID) throws
```

##### searchSymbols(_:)

Searches for symbols matching query.

```swift
func searchSymbols(_ query: String) async
```

**Parameters:**
- `query`: Search query string

**Side Effects:** Updates `searchResults` property

**Example:**
```swift
await watchlistService.searchSymbols("AAPL")
// searchResults now contains matching symbols
```

---

## Models

### Quote

Represents a real-time market quote for a security.

#### Declaration

```swift
struct Quote: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let last: Decimal
    let bid: Decimal
    let ask: Decimal
    let volume: Int64
    let timestamp: Date
    let close: Decimal?
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `symbol` | `String` | Security symbol |
| `last` | `Decimal` | Last traded price |
| `bid` | `Decimal` | Current bid price |
| `ask` | `Decimal` | Current ask price |
| `volume` | `Int64` | Trading volume |
| `timestamp` | `Date` | Quote timestamp |
| `close` | `Decimal?` | Previous closing price |

#### Computed Properties

##### change

Price change from previous close.

```swift
var change: Decimal { get }
```

**Returns:** Difference between `last` and `close`

##### changePercent

Percentage change from previous close.

```swift
var changePercent: Decimal { get }
```

**Returns:** Percentage change (e.g., 2.5 for +2.5%)

##### spread

Bid-ask spread.

```swift
var spread: Decimal { get }
```

**Returns:** Difference between `ask` and `bid`

##### direction

Price movement direction.

```swift
var direction: PriceDirection { get }
```

**Returns:** `.up`, `.down`, or `.flat`

#### Example

```swift
let quote = Quote(
    symbol: "AAPL",
    last: 175.50,
    bid: 175.48,
    ask: 175.52,
    volume: 50_000_000,
    close: 170.00
)

print("Price: $\(quote.last)")
print("Change: \(quote.change) (\(quote.changePercent)%)")
print("Spread: $\(quote.spread)")
print("Direction: \(quote.direction)")
```

---

### Position

Represents an open position in a portfolio.

#### Declaration

```swift
struct Position: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let quantity: Int
    let averagePrice: Decimal
    var currentPrice: Decimal
    let side: PositionSide
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `symbol` | `String` | Security symbol |
| `quantity` | `Int` | Number of shares |
| `averagePrice` | `Decimal` | Average entry price |
| `currentPrice` | `Decimal` | Current market price |
| `side` | `PositionSide` | `.long` or `.short` |

#### Computed Properties

##### marketValue

Current market value of position.

```swift
var marketValue: Decimal { get }
```

**Formula:** `quantity × currentPrice`

##### costBasis

Original cost of position.

```swift
var costBasis: Decimal { get }
```

**Formula:** `quantity × averagePrice`

##### unrealizedPnL

Unrealized profit or loss.

```swift
var unrealizedPnL: Decimal { get }
```

**Formula:** `marketValue - costBasis`

##### unrealizedPnLPercent

Unrealized P&L as percentage.

```swift
var unrealizedPnLPercent: Decimal { get }
```

**Formula:** `(unrealizedPnL / costBasis) × 100`

#### Example

```swift
let position = Position(
    symbol: "AAPL",
    quantity: 100,
    averagePrice: 150.00,
    currentPrice: 175.50,
    side: .long
)

print("Market Value: $\(position.marketValue)")
print("Cost Basis: $\(position.costBasis)")
print("P&L: $\(position.unrealizedPnL)")
print("P&L %: \(position.unrealizedPnLPercent)%")
```

---

### Order

Represents a trade order.

#### Declaration

```swift
struct Order: Codable, Identifiable {
    let id: String
    let symbol: String
    let quantity: Int
    let side: OrderSide
    let type: OrderType
    let status: OrderStatus
    let filledQuantity: Int
    let averageFillPrice: Decimal?
    let submittedAt: Date
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Broker-assigned order ID |
| `symbol` | `String` | Security symbol |
| `quantity` | `Int` | Order quantity |
| `side` | `OrderSide` | `.buy` or `.sell` |
| `type` | `OrderType` | Order type (market, limit, etc.) |
| `status` | `OrderStatus` | Current status |
| `filledQuantity` | `Int` | Shares filled |
| `averageFillPrice` | `Decimal?` | Average fill price |
| `submittedAt` | `Date` | Submission timestamp |

#### OrderStatus Enum

```swift
enum OrderStatus: String, Codable {
    case pending
    case submitted
    case partiallyFilled = "partially_filled"
    case filled
    case cancelled
    case rejected
}
```

#### OrderType Enum

```swift
enum OrderType: String, Codable {
    case market
    case limit
    case stop
    case stopLimit = "stop_limit"
}
```

---

### Watchlist

Represents a collection of symbols to monitor.

#### Declaration

```swift
struct Watchlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var symbols: [String]
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

#### Methods

##### add(_:)

Adds a symbol to the watchlist.

```swift
mutating func add(_ symbol: String)
```

##### remove(_:)

Removes a symbol from the watchlist.

```swift
mutating func remove(_ symbol: String)
```

##### contains(_:)

Checks if watchlist contains a symbol.

```swift
func contains(_ symbol: String) -> Bool
```

#### Example

```swift
var watchlist = Watchlist(
    name: "Tech Stocks",
    symbols: ["AAPL", "GOOGL"],
    isDefault: false
)

watchlist.add("MSFT")
print(watchlist.contains("MSFT"))  // true

watchlist.remove("GOOGL")
print(watchlist.symbols)  // ["AAPL", "MSFT"]
```

---

## Integration

### AlpacaAPIClient

HTTP client for Alpaca Markets API.

#### Methods

##### getAccount()

Retrieves account information.

```swift
func getAccount() async throws -> AccountInfo
```

##### submitOrder(_:)

Submits an order to Alpaca.

```swift
func submitOrder(_ request: AlpacaOrderRequest) async throws -> AlpacaOrder
```

##### getPositions()

Fetches all open positions.

```swift
func getPositions() async throws -> [AlpacaPosition]
```

---

### PolygonWebSocket

WebSocket client for Polygon.io market data.

#### Methods

##### connect()

Establishes WebSocket connection.

```swift
func connect() async throws
```

##### subscribe(symbols:)

Subscribes to real-time quotes.

```swift
func subscribe(symbols: [String]) async throws
```

##### disconnect()

Closes WebSocket connection.

```swift
func disconnect() async
```

---

## Utilities

### KeychainManager

Secure credential storage using iOS Keychain.

#### Methods

##### save(_:forKey:)

Saves a value to Keychain.

```swift
func save(_ value: String, forKey key: String) throws
```

##### get(_:)

Retrieves a value from Keychain.

```swift
func get(_ key: String) throws -> String?
```

##### delete(_:)

Deletes a value from Keychain.

```swift
func delete(_ key: String) throws
```

**Example:**
```swift
let keychain = KeychainManager()

try keychain.save("my_api_key", forKey: "alpaca.apiKey")
let apiKey = try keychain.get("alpaca.apiKey")
try keychain.delete("alpaca.apiKey")
```

---

### Logger

Structured logging utility.

#### Usage

```swift
Logger.info("User logged in")
Logger.warning("High latency detected: \(latency)ms")
Logger.error("Failed to submit order", error: error)
Logger.debug("Quote received: \(quote)")
```

#### Log Levels

- `debug` - Detailed diagnostic information
- `info` - General informational messages
- `warning` - Warning messages
- `error` - Error messages

---

## Error Handling

### Common Error Types

#### AuthenticationError

```swift
enum AuthenticationError: Error {
    case invalidCredentials
    case networkError
    case rateLimited
    case accountLocked
}
```

#### TradingError

```swift
enum TradingError: Error {
    case insufficientFunds
    case invalidSymbol
    case marketClosed
    case invalidQuantity
    case orderNotFound
    case orderNotCancellable
}
```

#### WatchlistError

```swift
enum WatchlistError: Error {
    case watchlistNotFound
    case symbolAlreadyExists
    case symbolNotFound
}
```

### Error Handling Example

```swift
do {
    let order = try await tradingService.submitOrder(request)
    print("Success: \(order.id)")
} catch TradingError.insufficientFunds {
    showAlert("Not enough buying power")
} catch TradingError.marketClosed {
    showAlert("Market is currently closed")
} catch {
    showAlert("Order failed: \(error.localizedDescription)")
}
```

---

## Version History

- **v0.6.0** - Added landing page and documentation
- **v0.5.0** - Added WatchlistService API
- **v0.4.0** - Added TradingService API
- **v0.3.0** - Added 3D visualization APIs
- **v0.2.0** - Added MarketDataHub API
- **v0.1.0** - Initial AuthenticationService API

---

**Last Updated:** 2025-11-24
**API Version:** 1.0
**Minimum visionOS:** 2.0
**License:** MIT
