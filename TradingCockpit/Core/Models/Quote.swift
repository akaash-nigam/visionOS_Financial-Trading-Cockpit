//
//  Quote.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents a real-time market quote
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
    let close: Decimal  // Previous close
    let volume: Int64

    // Calculated fields
    var change: Decimal {
        last - close
    }

    var changePercent: Decimal {
        guard close > 0 else { return 0 }
        return (change / close) * 100
    }

    var spread: Decimal? {
        guard let bid = bid, let ask = ask else { return nil }
        return ask - bid
    }

    var midpoint: Decimal? {
        guard let bid = bid, let ask = ask else { return nil }
        return (bid + ask) / 2
    }

    var isPositive: Bool {
        change > 0
    }

    var isNegative: Bool {
        change < 0
    }

    init(
        id: UUID = UUID(),
        symbol: String,
        timestamp: Date = Date(),
        bid: Decimal? = nil,
        ask: Decimal? = nil,
        last: Decimal,
        open: Decimal,
        high: Decimal,
        low: Decimal,
        close: Decimal,
        volume: Int64
    ) {
        self.id = id
        self.symbol = symbol
        self.timestamp = timestamp
        self.bid = bid
        self.ask = ask
        self.last = last
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

// MARK: - Mock Data

extension Quote {
    /// Generate mock quote for testing
    static func mock(symbol: String = "AAPL") -> Quote {
        let basePrice = Decimal(Double.random(in: 150...200))
        let previousClose = basePrice
        let change = Decimal(Double.random(in: -5...5))
        let last = previousClose + change

        return Quote(
            symbol: symbol,
            bid: last - 0.05,
            ask: last + 0.05,
            last: last,
            open: previousClose,
            high: last + Decimal(Double.random(in: 0...3)),
            low: last - Decimal(Double.random(in: 0...3)),
            close: previousClose,
            volume: Int64.random(in: 1_000_000...50_000_000)
        )
    }
}
