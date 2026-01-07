//
//  MarketDataHub.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import Foundation
import Combine

/// Central hub for market data distribution
@Observable
class MarketDataHub {
    // MARK: - Properties

    private let polygonProvider: PolygonDataProvider
    private let quoteCache: QuoteCache
    private let prioritizer: UpdatePrioritizer

    // Publishers
    private let quoteSubject = PassthroughSubject<Quote, Never>()
    var quotePublisher: AnyPublisher<Quote, Never> {
        quoteSubject.eraseToAnyPublisher()
    }

    // AsyncStream
    private let quoteContinuation: AsyncStream<Quote>.Continuation
    let quotes: AsyncStream<Quote>

    // State
    var isConnected: Bool = false
    var subscribedSymbols: Set<String> = []
    private(set) var lastUpdate: Date?
    private(set) var updateCount: Int = 0

    // MARK: - Initialization

    init(polygonProvider: PolygonDataProvider) {
        self.polygonProvider = polygonProvider
        self.quoteCache = QuoteCache()
        self.prioritizer = UpdatePrioritizer()

        // Create quote stream
        var continuation: AsyncStream<Quote>.Continuation!
        self.quotes = AsyncStream { cont in
            continuation = cont
        }
        self.quoteContinuation = continuation

        Logger.info("📊 Market Data Hub initialized")
    }

    // MARK: - Connection Management

    func connect() async throws {
        guard !isConnected else {
            Logger.debug("Market Data Hub already connected")
            return
        }

        Logger.info("🔌 Connecting Market Data Hub")

        try await polygonProvider.connect()

        // Start processing quotes from provider
        Task {
            await processProviderQuotes()
        }

        isConnected = true
        Logger.info("✅ Market Data Hub connected")
    }

    func disconnect() async {
        guard isConnected else { return }

        Logger.info("🔌 Disconnecting Market Data Hub")

        await polygonProvider.disconnect()
        isConnected = false

        Logger.info("✅ Market Data Hub disconnected")
    }

    // MARK: - Subscription Management

    func subscribe(symbols: [String]) async throws {
        guard !symbols.isEmpty else { return }

        Logger.info("📡 Subscribing to \(symbols.count) symbols")

        // Add to our subscription set
        subscribedSymbols.formUnion(symbols)

        // Subscribe via provider
        try await polygonProvider.subscribe(symbols: symbols)
    }

    func unsubscribe(symbols: [String]) async throws {
        guard !symbols.isEmpty else { return }

        Logger.info("📡 Unsubscribing from \(symbols.count) symbols")

        // Remove from subscription set
        subscribedSymbols.subtract(symbols)

        // Unsubscribe via provider
        try await polygonProvider.unsubscribe(symbols: symbols)
    }

    func setVisibleSymbols(_ symbols: Set<String>) async {
        await prioritizer.setVisibleSymbols(symbols)
    }

    // MARK: - Quote Access

    func getQuote(for symbol: String) async -> Quote? {
        await quoteCache.get(symbol)
    }

    func getQuotes(for symbols: [String]) async -> [Quote] {
        await quoteCache.getMultiple(symbols)
    }

    func getAllQuotes() async -> [Quote] {
        await quoteCache.getAll()
    }

    // MARK: - Private Methods

    private func processProviderQuotes() async {
        for await quote in polygonProvider.quotes {
            await processQuote(quote)
        }
    }

    private func processQuote(_ quote: Quote) async {
        // Check if we should process this update
        guard await prioritizer.shouldProcess(quote: quote) else {
            return
        }

        // Update cache
        await quoteCache.set(quote)

        // Distribute to subscribers
        quoteSubject.send(quote)
        quoteContinuation.yield(quote)

        // Update stats
        lastUpdate = Date()
        updateCount += 1

        // Record update
        await prioritizer.recordUpdate(symbol: quote.symbol)

        if updateCount % 100 == 0 {
            Logger.debug("📊 Processed \(updateCount) quote updates")
        }
    }
}

// MARK: - Update Prioritizer

actor UpdatePrioritizer {
    private var visibleSymbols: Set<String> = []
    private var lastUpdateTime: [String: Date] = [:]
    private var updateCounts: [String: Int] = [:]

    func setVisibleSymbols(_ symbols: Set<String>) {
        self.visibleSymbols = symbols
        Logger.debug("👀 Visible symbols updated: \(symbols.count) symbols")
    }

    func shouldProcess(quote: Quote) -> Bool {
        let symbol = quote.symbol
        let currentTime = Date()

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

// MARK: - Quote Cache

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

        // Update access order
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

    func getMultiple(_ symbols: [String]) -> [Quote] {
        symbols.compactMap { quotes[$0] }
    }

    func getAll() -> [Quote] {
        Array(quotes.values)
    }

    func clear() {
        quotes.removeAll()
        accessOrder.removeAll()
    }

    func size() -> Int {
        quotes.count
    }
}

// MARK: - Factory

extension MarketDataHub {
    /// Create MarketDataHub with Polygon provider
    static func createWithPolygon(apiKey: String) -> MarketDataHub {
        let provider = PolygonDataProvider(apiKey: apiKey)
        return MarketDataHub(polygonProvider: provider)
    }

    /// Create for testing with demo provider
    static func createForTesting() -> MarketDataHub {
        let provider = PolygonDataProvider.createForTesting()
        return MarketDataHub(polygonProvider: provider)
    }
}
