# Real-Time Data Pipeline Design
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Overview

This document specifies the real-time data pipeline architecture for handling high-frequency market data, order updates, and news feeds with minimal latency while maintaining system performance.

### Performance Requirements
- **Market Data Latency**: < 50ms from source to UI
- **Order Updates**: < 100ms
- **Throughput**: 10,000+ updates/second
- **Simultaneous Subscriptions**: 1,000+ securities
- **Memory Efficiency**: < 500MB for data cache

---

## 2. Pipeline Architecture

```
┌──────────────────────────────────────────────────────────┐
│              External Data Sources                        │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐     │
│  │ Broker   │  │  Market   │  │   News APIs      │     │
│  │   APIs   │  │  Data     │  │                  │     │
│  └──────────┘  └───────────┘  └──────────────────┘     │
└────────┬─────────────┬───────────────┬──────────────────┘
         │             │               │
┌────────▼─────────────▼───────────────▼──────────────────┐
│              Connection Layer                             │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐     │
│  │WebSocket │  │ WebSocket │  │   HTTP REST      │     │
│  │ Manager  │  │ Manager   │  │   Client         │     │
│  └──────────┘  └───────────┘  └──────────────────┘     │
└────────┬─────────────┬───────────────┬──────────────────┘
         │             │               │
┌────────▼─────────────▼───────────────▼──────────────────┐
│           Data Normalization Layer                        │
│  - Parse different formats                                │
│  - Validate data integrity                                │
│  - Transform to common schema                             │
└────────┬──────────────────────────────────────────────────┘
         │
┌────────▼──────────────────────────────────────────────────┐
│              Priority Queue & Throttling                   │
│  - Prioritize visible securities                          │
│  - Batch similar updates                                  │
│  - Rate limit non-critical updates                        │
└────────┬──────────────────────────────────────────────────┘
         │
┌────────▼──────────────────────────────────────────────────┐
│                Cache Layer (Actor)                         │
│  - In-memory quote cache                                  │
│  - LRU eviction policy                                    │
│  - Thread-safe access                                     │
└────────┬──────────────────────────────────────────────────┘
         │
┌────────▼──────────────────────────────────────────────────┐
│            Distribution Layer                              │
│  - Combine publishers                                     │
│  - AsyncStream for Swift Concurrency                      │
│  - Multicast to subscribers                               │
└────────┬──────────────────────────────────────────────────┘
         │
┌────────▼──────────────────────────────────────────────────┐
│              Consumers                                     │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐     │
│  │  UI      │  │Portfolio  │  │  Risk Manager    │     │
│  │ Updates  │  │ Manager   │  │                  │     │
│  └──────────┘  └───────────┘  └──────────────────┘     │
└────────────────────────────────────────────────────────────┘
```

---

## 3. WebSocket Connection Management

### 3.1 WebSocket Manager

```swift
actor WebSocketManager {
    private var connections: [String: WebSocketConnection] = [:]
    private var subscriptions: [String: Set<String>] = [:]  // connectionId: symbols
    private var reconnectTasks: [String: Task<Void, Never>] = [:]

    func connect(to endpoint: URL, identifier: String) async throws {
        let connection = WebSocketConnection(endpoint: endpoint)
        connections[identifier] = connection

        // Start listening
        Task {
            await handleMessages(from: connection, identifier: identifier)
        }

        // Monitor connection health
        Task {
            await monitorConnection(connection, identifier: identifier)
        }

        try await connection.connect()
    }

    func subscribe(symbols: [String], on connectionId: String) async throws {
        guard let connection = connections[connectionId] else {
            throw DataPipelineError.connectionNotFound
        }

        // Add to subscription set
        var current = subscriptions[connectionId] ?? Set()
        current.formUnion(symbols)
        subscriptions[connectionId] = current

        // Send subscribe message
        let message = SubscribeMessage(symbols: symbols)
        try await connection.send(message)
    }

    private func handleMessages(from connection: WebSocketConnection, identifier: String) async {
        for await message in connection.messages {
            do {
                let data = try parseMessage(message)
                await processData(data)
            } catch {
                Logger.error("Failed to parse message", error: error)
            }
        }

        // Connection closed, attempt reconnect
        await reconnect(identifier: identifier)
    }

    private func reconnect(identifier: String, attempt: Int = 0) async {
        guard let connection = connections[identifier] else { return }

        let delay = calculateBackoff(attempt: attempt)
        Logger.info("Reconnecting in \(delay)s (attempt \(attempt + 1))")

        try? await Task.sleep(for: .seconds(delay))

        do {
            try await connection.reconnect()

            // Resubscribe to symbols
            if let symbols = subscriptions[identifier] {
                try await subscribe(symbols: Array(symbols), on: identifier)
            }
        } catch {
            // Retry with exponential backoff
            await reconnect(identifier: identifier, attempt: attempt + 1)
        }
    }

    private func calculateBackoff(attempt: Int) -> Double {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
        let maxDelay = 16.0
        let delay = min(pow(2.0, Double(attempt)), maxDelay)
        return delay
    }

    private func monitorConnection(_ connection: WebSocketConnection, identifier: String) async {
        while !Task.isCancelled {
            // Send heartbeat every 30 seconds
            try? await Task.sleep(for: .seconds(30))

            do {
                try await connection.sendHeartbeat()
            } catch {
                Logger.warning("Heartbeat failed, connection may be dead")
                await reconnect(identifier: identifier)
                break
            }
        }
    }
}
```

### 3.2 WebSocket Connection

```swift
class WebSocketConnection {
    private let endpoint: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession

    let messages: AsyncStream<Data>
    private let messagesContinuation: AsyncStream<Data>.Continuation

    init(endpoint: URL) {
        self.endpoint = endpoint

        // Create message stream
        (self.messages, self.messagesContinuation) = AsyncStream.makeStream()

        // Configure session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)
    }

    func connect() async throws {
        let task = urlSession.webSocketTask(with: endpoint)
        self.webSocketTask = task
        task.resume()

        // Start receiving messages
        Task {
            await receiveMessages()
        }
    }

    func reconnect() async throws {
        disconnect()
        try await connect()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func send(_ message: any Encodable) async throws {
        let data = try JSONEncoder().encode(message)
        let messageString = String(data: data, encoding: .utf8)!
        let wsMessage = URLSessionWebSocketTask.Message.string(messageString)

        try await webSocketTask?.send(wsMessage)
    }

    func sendHeartbeat() async throws {
        let heartbeat = HeartbeatMessage()
        try await send(heartbeat)
    }

    private func receiveMessages() async {
        while let task = webSocketTask {
            do {
                let message = try await task.receive()

                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        messagesContinuation.yield(data)
                    }
                case .data(let data):
                    messagesContinuation.yield(data)
                @unknown default:
                    break
                }
            } catch {
                Logger.error("WebSocket receive error", error: error)
                messagesContinuation.finish()
                break
            }
        }
    }
}
```

---

## 4. Data Normalization

### 4.1 Message Parser

```swift
class DataNormalizer {
    func normalize(_ data: Data, source: DataSource) throws -> MarketUpdate {
        switch source {
        case .interactiveBrokers:
            return try normalizeIBData(data)
        case .tdAmeritrade:
            return try normalizeTDAData(data)
        case .alpaca:
            return try normalizeAlpacaData(data)
        default:
            throw DataPipelineError.unsupportedSource
        }
    }

    private func normalizeIBData(_ data: Data) throws -> MarketUpdate {
        struct IBQuote: Decodable {
            let symbol: String
            let bid: Double
            let ask: Double
            let last: Double
            let volume: Int64
            let timestamp: Int64
        }

        let ibQuote = try JSONDecoder().decode(IBQuote.self, from: data)

        return MarketUpdate(
            symbol: ibQuote.symbol,
            bid: Decimal(ibQuote.bid),
            ask: Decimal(ibQuote.ask),
            last: Decimal(ibQuote.last),
            volume: ibQuote.volume,
            timestamp: Date(timeIntervalSince1970: Double(ibQuote.timestamp) / 1000.0),
            source: .interactiveBrokers
        )
    }

    // Similar methods for other data sources...
}

struct MarketUpdate {
    let symbol: String
    let bid: Decimal?
    let ask: Decimal?
    let last: Decimal
    let volume: Int64
    let timestamp: Date
    let source: DataSource
}

enum DataSource {
    case interactiveBrokers
    case tdAmeritrade
    case alpaca
    case polygon
    case alphaVantage
}
```

---

## 5. Priority Queue & Throttling

### 5.1 Update Prioritizer

```swift
actor UpdatePrioritizer {
    private var visibleSymbols: Set<String> = []
    private var updateCounts: [String: Int] = [:]
    private var lastUpdateTime: [String: Date] = [:]

    func setVisibleSymbols(_ symbols: Set<String>) {
        self.visibleSymbols = symbols
    }

    func shouldProcess(update: MarketUpdate, currentTime: Date = Date()) -> Bool {
        let symbol = update.symbol

        // Always process visible symbols
        if visibleSymbols.contains(symbol) {
            return shouldThrottle(symbol: symbol, currentTime: currentTime, interval: 0.1)
        }

        // Throttle non-visible symbols more aggressively
        return shouldThrottle(symbol: symbol, currentTime: currentTime, interval: 1.0)
    }

    private func shouldThrottle(symbol: String, currentTime: Date, interval: TimeInterval) -> Bool {
        guard let lastTime = lastUpdateTime[symbol] else {
            lastUpdateTime[symbol] = currentTime
            return true
        }

        if currentTime.timeIntervalSince(lastTime) >= interval {
            lastUpdateTime[symbol] = currentTime
            return true
        }

        return false
    }

    func recordUpdate(symbol: String) {
        updateCounts[symbol, default: 0] += 1
    }

    func getUpdateStats() -> [String: Int] {
        updateCounts
    }
}
```

### 5.2 Batch Processor

```swift
actor BatchProcessor {
    private var pendingUpdates: [MarketUpdate] = []
    private var batchTimer: Task<Void, Never>?
    private let maxBatchSize = 50
    private let maxBatchDelay: Duration = .milliseconds(10)

    private let onBatchReady: ([MarketUpdate]) async -> Void

    init(onBatchReady: @escaping ([MarketUpdate]) async -> Void) {
        self.onBatchReady = onBatchReady
    }

    func add(_ update: MarketUpdate) async {
        pendingUpdates.append(update)

        // Process immediately if batch is full
        if pendingUpdates.count >= maxBatchSize {
            await processBatch()
        } else if batchTimer == nil {
            // Start timer for partial batch
            batchTimer = Task {
                try? await Task.sleep(for: maxBatchDelay)
                await processBatch()
            }
        }
    }

    private func processBatch() async {
        guard !pendingUpdates.isEmpty else { return }

        let batch = pendingUpdates
        pendingUpdates.removeAll()
        batchTimer?.cancel()
        batchTimer = nil

        // Deduplicate by symbol (keep latest)
        var deduped: [String: MarketUpdate] = [:]
        for update in batch {
            deduped[update.symbol] = update
        }

        await onBatchReady(Array(deduped.values))
    }
}
```

---

## 6. Cache Layer

### 6.1 Quote Cache

```swift
actor QuoteCache {
    private var quotes: [String: Quote] = [:]
    private var accessOrder: [String] = []
    private let maxSize = 1000

    func set(_ quote: Quote) {
        // LRU eviction
        if quotes.count >= maxSize, let lru = accessOrder.first {
            quotes.removeValue(forKey: lru)
            accessOrder.removeFirst()
        }

        quotes[quote.symbol] = quote
        accessOrder.removeAll(where: { $0 == quote.symbol })
        accessOrder.append(quote.symbol)
    }

    func get(_ symbol: String) -> Quote? {
        guard let quote = quotes[symbol] else { return nil }

        // Update access order
        accessOrder.removeAll(where: { $0 == symbol })
        accessOrder.append(symbol)

        return quote
    }

    func getAll() -> [Quote] {
        Array(quotes.values)
    }

    func getMultiple(_ symbols: [String]) -> [Quote] {
        symbols.compactMap { quotes[$0] }
    }

    func clear() {
        quotes.removeAll()
        accessOrder.removeAll()
    }

    func size() -> Int {
        quotes.count
    }
}
```

---

## 7. Distribution Layer

### 7.1 Data Hub

```swift
@Observable
class MarketDataHub {
    private let quoteCache = QuoteCache()
    private let prioritizer = UpdatePrioritizer()
    private let batchProcessor: BatchProcessor
    private let normalizer = DataNormalizer()

    // Publishers
    private let quoteSubject = PassthroughSubject<Quote, Never>()
    var quotePublisher: AnyPublisher<Quote, Never> {
        quoteSubject.eraseToAnyPublisher()
    }

    // AsyncStream for Swift Concurrency
    private let (quoteStream, quoteContinuation) = AsyncStream<Quote>.makeStream()
    var quotes: AsyncStream<Quote> { quoteStream }

    init() {
        self.batchProcessor = BatchProcessor { [weak self] updates in
            await self?.processBatch(updates)
        }
    }

    func processRawData(_ data: Data, source: DataSource) async {
        do {
            let update = try normalizer.normalize(data, source: source)

            // Check priority
            if await prioritizer.shouldProcess(update: update) {
                await batchProcessor.add(update)
                await prioritizer.recordUpdate(symbol: update.symbol)
            }
        } catch {
            Logger.error("Failed to process data", error: error)
        }
    }

    private func processBatch(_ updates: [MarketUpdate]) async {
        for update in updates {
            let quote = convertToQuote(update)

            // Update cache
            await quoteCache.set(quote)

            // Notify subscribers
            quoteSubject.send(quote)
            quoteContinuation.yield(quote)
        }
    }

    func setVisibleSymbols(_ symbols: Set<String>) async {
        await prioritizer.setVisibleSymbols(symbols)
    }

    func getQuote(_ symbol: String) async -> Quote? {
        await quoteCache.get(symbol)
    }

    private func convertToQuote(_ update: MarketUpdate) -> Quote {
        Quote(
            id: UUID(),
            symbol: update.symbol,
            timestamp: update.timestamp,
            bid: update.bid,
            ask: update.ask,
            last: update.last,
            open: update.last,  // TODO: Track properly
            high: update.last,
            low: update.last,
            close: update.last,
            volume: update.volume,
            marketStatus: .open
        )
    }
}
```

---

## 8. Performance Monitoring

### 8.1 Latency Tracker

```swift
actor LatencyTracker {
    private var latencies: [String: [TimeInterval]] = [:]
    private let maxSamples = 100

    func record(operation: String, latency: TimeInterval) {
        var samples = latencies[operation] ?? []
        samples.append(latency)

        if samples.count > maxSamples {
            samples.removeFirst()
        }

        latencies[operation] = samples
    }

    func getStats(for operation: String) -> LatencyStats? {
        guard let samples = latencies[operation], !samples.empty else {
            return nil
        }

        let sorted = samples.sorted()
        return LatencyStats(
            mean: samples.reduce(0, +) / Double(samples.count),
            median: sorted[samples.count / 2],
            p95: sorted[Int(Double(samples.count) * 0.95)],
            p99: sorted[Int(Double(samples.count) * 0.99)],
            max: sorted.last!
        )
    }
}

struct LatencyStats {
    let mean: TimeInterval
    let median: TimeInterval
    let p95: TimeInterval
    let p99: TimeInterval
    let max: TimeInterval
}
```

### 8.2 Throughput Monitor

```swift
actor ThroughputMonitor {
    private var updateCounts: [Date: Int] = [:]
    private var windowSize: TimeInterval = 1.0

    func recordUpdate() {
        let now = Date()
        let key = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970 / windowSize) * windowSize)

        updateCounts[key, default: 0] += 1

        // Clean old entries
        let cutoff = now.addingTimeInterval(-60)
        updateCounts = updateCounts.filter { $0.key > cutoff }
    }

    func getUpdatesPerSecond() -> Double {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)

        let recentUpdates = updateCounts.filter { $0.key >= oneSecondAgo }
        let total = recentUpdates.values.reduce(0, +)

        return Double(total)
    }
}
```

---

## 9. Error Handling & Resilience

### 9.1 Circuit Breaker

```swift
actor CircuitBreaker {
    enum State {
        case closed         // Normal operation
        case open          // Too many failures, reject requests
        case halfOpen      // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?

    private let failureThreshold = 5
    private let timeout: TimeInterval = 30
    private let resetTimeout: TimeInterval = 60

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .closed:
            do {
                let result = try await operation()
                await onSuccess()
                return result
            } catch {
                await onFailure()
                throw error
            }

        case .open:
            // Check if we should try again
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > resetTimeout {
                state = .halfOpen
                return try await execute(operation)
            }
            throw CircuitBreakerError.circuitOpen

        case .halfOpen:
            do {
                let result = try await operation()
                await onSuccess()
                return result
            } catch {
                state = .open
                throw error
            }
        }
    }

    private func onSuccess() {
        failureCount = 0
        lastFailureTime = nil
        state = .closed
    }

    private func onFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= failureThreshold {
            state = .open
        }
    }
}
```

---

## 10. Testing

### 10.1 Mock Data Source

```swift
class MockDataSource {
    func streamQuotes() -> AsyncStream<MarketUpdate> {
        AsyncStream { continuation in
            Task {
                while true {
                    let update = generateRandomUpdate()
                    continuation.yield(update)
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        }
    }

    private func generateRandomUpdate() -> MarketUpdate {
        let symbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"]
        let symbol = symbols.randomElement()!

        return MarketUpdate(
            symbol: symbol,
            bid: Decimal(Double.random(in: 100...200)),
            ask: Decimal(Double.random(in: 100...200)),
            last: Decimal(Double.random(in: 100...200)),
            volume: Int64.random(in: 10000...1000000),
            timestamp: Date(),
            source: .interactiveBrokers
        )
    }
}
```

### 10.2 Performance Tests

```swift
class DataPipelineTests: XCTestCase {
    func testLatency() async throws {
        let hub = MarketDataHub()
        let source = MockDataSource()

        var latencies: [TimeInterval] = []

        for await update in source.streamQuotes().prefix(1000) {
            let start = Date()

            let data = try JSONEncoder().encode(update)
            await hub.processRawData(data, source: .interactiveBrokers)

            let latency = Date().timeIntervalSince(start)
            latencies.append(latency)
        }

        let avgLatency = latencies.reduce(0, +) / Double(latencies.count)
        XCTAssertLessThan(avgLatency, 0.005)  // < 5ms average
    }

    func testThroughput() async throws {
        let hub = MarketDataHub()
        let source = MockDataSource()

        let start = Date()
        var count = 0

        for await update in source.streamQuotes() {
            let data = try JSONEncoder().encode(update)
            await hub.processRawData(data, source: .interactiveBrokers)
            count += 1

            if Date().timeIntervalSince(start) > 1.0 {
                break
            }
        }

        XCTAssertGreaterThan(count, 1000)  // > 1000 updates/sec
    }
}
```

---

## 11. Deployment Configuration

### 11.1 Production Settings

```swift
struct DataPipelineConfiguration {
    // WebSocket settings
    let reconnectAttempts = 10
    let heartbeatInterval: TimeInterval = 30
    let connectionTimeout: TimeInterval = 30

    // Throttling
    let visibleSymbolThrottle: TimeInterval = 0.1      // 10 updates/sec
    let backgroundSymbolThrottle: TimeInterval = 1.0   // 1 update/sec

    // Batching
    let maxBatchSize = 50
    let maxBatchDelay: Duration = .milliseconds(10)

    // Cache
    let maxCacheSize = 1000
    let cacheEvictionPolicy: EvictionPolicy = .lru

    // Performance
    let maxConcurrentConnections = 5
    let maxSubscriptionsPerConnection = 200
}
```

---

## 12. References

- [URLSession WebSocket](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Combine Framework](https://developer.apple.com/documentation/combine)

---

**Document Version History**:
- v1.0 (2025-11-24): Initial real-time data pipeline design
