//
//  PolygonDataProvider.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import Foundation

/// Polygon.io WebSocket data provider for real-time market quotes
actor PolygonDataProvider {
    // MARK: - Properties

    private let apiKey: String
    private var webSocket: WebSocketManager?
    private var subscribedSymbols: Set<String> = []
    private let endpoint = URL(string: "wss://socket.polygon.io/stocks")!

    // Quote stream
    private let quoteContinuation: AsyncStream<Quote>.Continuation
    let quotes: AsyncStream<Quote>

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey

        // Create quote stream
        var continuation: AsyncStream<Quote>.Continuation!
        self.quotes = AsyncStream { cont in
            continuation = cont
        }
        self.quoteContinuation = continuation

        Logger.info("📊 Polygon.io data provider initialized")
    }

    // MARK: - Connection

    func connect() async throws {
        guard webSocket == nil else {
            Logger.debug("Already connected to Polygon.io")
            return
        }

        Logger.info("🔌 Connecting to Polygon.io WebSocket")

        let ws = WebSocketManager(endpoint: endpoint)
        self.webSocket = ws

        try await ws.connect()

        // Authenticate
        try await authenticate()

        // Start processing messages
        Task {
            await processMessages()
        }

        Logger.info("✅ Connected to Polygon.io")
    }

    func disconnect() {
        webSocket?.disconnect()
        webSocket = nil
        subscribedSymbols.removeAll()
        quoteContinuation.finish()

        Logger.info("🔌 Disconnected from Polygon.io")
    }

    // MARK: - Authentication

    private func authenticate() async throws {
        let authMessage = [
            "action": "auth",
            "params": apiKey
        ]

        let jsonData = try JSONEncoder().encode(authMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        try await webSocket?.send(jsonString)

        Logger.info("🔐 Sent authentication to Polygon.io")
    }

    // MARK: - Subscription Management

    func subscribe(symbols: [String]) async throws {
        guard !symbols.isEmpty else { return }

        // Add to subscribed set
        subscribedSymbols.formUnion(symbols)

        // Format symbols for Polygon (prefix with T.)
        let formattedSymbols = symbols.map { "T.\($0)" }

        let subscribeMessage: [String: Any] = [
            "action": "subscribe",
            "params": formattedSymbols.joined(separator: ",")
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: subscribeMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        try await webSocket?.send(jsonString)

        Logger.info("📡 Subscribed to \(symbols.count) symbols: \(symbols.joined(separator: ", "))")
    }

    func unsubscribe(symbols: [String]) async throws {
        guard !symbols.isEmpty else { return }

        // Remove from subscribed set
        subscribedSymbols.subtract(symbols)

        // Format symbols for Polygon (prefix with T.)
        let formattedSymbols = symbols.map { "T.\($0)" }

        let unsubscribeMessage: [String: Any] = [
            "action": "unsubscribe",
            "params": formattedSymbols.joined(separator: ",")
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: unsubscribeMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        try await webSocket?.send(jsonString)

        Logger.info("📡 Unsubscribed from \(symbols.count) symbols")
    }

    // MARK: - Message Processing

    private func processMessages() async {
        guard let webSocket = webSocket else { return }

        for await data in webSocket.messages {
            do {
                try parseMessage(data)
            } catch {
                Logger.error("❌ Failed to parse Polygon message", error: error)
            }
        }
    }

    private func parseMessage(_ data: Data) throws {
        // Parse JSON array
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }

        for message in jsonArray {
            guard let eventType = message["ev"] as? String else { continue }

            switch eventType {
            case "status":
                handleStatusMessage(message)

            case "T":
                // Trade message
                handleTradeMessage(message)

            case "Q":
                // Quote message (not used in MVP)
                break

            default:
                Logger.debug("Unknown message type: \(eventType)")
            }
        }
    }

    private func handleStatusMessage(_ message: [String: Any]) {
        if let status = message["status"] as? String,
           let statusMessage = message["message"] as? String {
            Logger.info("📊 Polygon status: \(status) - \(statusMessage)")
        }
    }

    private func handleTradeMessage(_ message: [String: Any]) {
        do {
            let quote = try parseTradeToQuote(message)
            quoteContinuation.yield(quote)
        } catch {
            Logger.error("❌ Failed to parse trade message", error: error)
        }
    }

    private func parseTradeToQuote(_ message: [String: Any]) throws -> Quote {
        // Extract fields from Polygon trade message
        guard let symbol = message["sym"] as? String,
              let price = message["p"] as? Double,
              let volume = message["s"] as? Int64 else {
            throw PolygonError.invalidMessageFormat
        }

        // Timestamp (milliseconds since epoch)
        let timestamp: Date
        if let timestampMs = message["t"] as? Int64 {
            timestamp = Date(timeIntervalSince1970: Double(timestampMs) / 1000.0)
        } else {
            timestamp = Date()
        }

        // Create quote (simplified - in production we'd aggregate trades)
        return Quote(
            symbol: symbol,
            timestamp: timestamp,
            bid: nil,  // Not available in trade message
            ask: nil,
            last: Decimal(price),
            open: Decimal(price),  // TODO: Track properly
            high: Decimal(price),
            low: Decimal(price),
            close: Decimal(price),  // TODO: Get from previous close
            volume: volume
        )
    }

    // MARK: - Helper Methods

    var isConnected: Bool {
        webSocket?.connectionState.isConnected ?? false
    }

    var subscribedSymbolsList: [String] {
        Array(subscribedSymbols)
    }
}

// MARK: - Error Types

enum PolygonError: Error, LocalizedError {
    case invalidMessageFormat
    case authenticationFailed
    case subscriptionFailed

    var errorDescription: String? {
        switch self {
        case .invalidMessageFormat:
            return "Invalid message format from Polygon.io"
        case .authenticationFailed:
            return "Failed to authenticate with Polygon.io"
        case .subscriptionFailed:
            return "Failed to subscribe to symbols"
        }
    }
}

// MARK: - Configuration

extension PolygonDataProvider {
    /// Get API key from environment or configuration
    static func createWithEnvironmentKey() -> PolygonDataProvider? {
        // In production, load from secure config
        // For now, this is a placeholder
        guard let apiKey = ProcessInfo.processInfo.environment["POLYGON_API_KEY"] else {
            Logger.warning("⚠️ POLYGON_API_KEY not set in environment")
            return nil
        }

        return PolygonDataProvider(apiKey: apiKey)
    }

    /// Create with mock/test API key
    static func createForTesting() -> PolygonDataProvider {
        // Use demo API key for testing (Polygon provides demo keys)
        return PolygonDataProvider(apiKey: "DEMO_KEY")
    }
}
