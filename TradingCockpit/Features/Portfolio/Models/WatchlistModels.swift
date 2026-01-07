//
//  WatchlistModels.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 5: Watchlist & Search
//

import Foundation

// MARK: - Watchlist

/// A watchlist containing multiple securities
struct Watchlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var symbols: [String]
    var createdAt: Date
    var updatedAt: Date
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        symbols: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbols = symbols
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDefault = isDefault
    }

    /// Number of symbols in watchlist
    var count: Int {
        symbols.count
    }

    /// Add a symbol to watchlist
    mutating func add(_ symbol: String) {
        if !symbols.contains(symbol) {
            symbols.append(symbol)
            updatedAt = Date()
        }
    }

    /// Remove a symbol from watchlist
    mutating func remove(_ symbol: String) {
        if let index = symbols.firstIndex(of: symbol) {
            symbols.remove(at: index)
            updatedAt = Date()
        }
    }

    /// Check if watchlist contains symbol
    func contains(_ symbol: String) -> Bool {
        symbols.contains(symbol)
    }
}

// MARK: - Symbol Search Result

/// Search result for symbol lookup
struct SymbolSearchResult: Identifiable {
    let id: String  // Symbol
    let symbol: String
    let name: String
    let type: SecurityType
    let exchange: String
    let currency: String

    var displayText: String {
        "\(symbol) - \(name)"
    }

    var exchangeInfo: String {
        "\(exchange) · \(currency)"
    }
}

// MARK: - Watchlist Item

/// Enriched watchlist item with current quote
struct WatchlistItem: Identifiable {
    let id: String  // Symbol
    let symbol: String
    let quote: Quote?
    let inWatchlist: Bool

    var displayName: String {
        symbol
    }

    var currentPrice: Decimal? {
        quote?.last
    }

    var priceChange: Decimal? {
        quote?.change
    }

    var priceChangePercent: Decimal? {
        quote?.changePercent
    }

    var isPositive: Bool {
        quote?.isPositive ?? false
    }

    var isNegative: Bool {
        quote?.isNegative ?? false
    }
}

// MARK: - Mock Data

extension Watchlist {
    /// Default watchlist with popular stocks
    static let `default` = Watchlist(
        name: "My Watchlist",
        symbols: ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX"],
        isDefault: true
    )

    /// Tech stocks watchlist
    static let tech = Watchlist(
        name: "Tech",
        symbols: ["AAPL", "GOOGL", "MSFT", "META", "NVDA", "AMD", "INTC", "CRM"]
    )

    /// Growth stocks watchlist
    static let growth = Watchlist(
        name: "Growth",
        symbols: ["TSLA", "NVDA", "AMD", "PLTR", "SNOW", "NET", "DDOG", "ZS"]
    )
}

extension SymbolSearchResult {
    /// Mock search results for testing
    static let mockResults: [SymbolSearchResult] = [
        SymbolSearchResult(
            id: "AAPL",
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "GOOGL",
            symbol: "GOOGL",
            name: "Alphabet Inc. Class A",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "MSFT",
            symbol: "MSFT",
            name: "Microsoft Corporation",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "AMZN",
            symbol: "AMZN",
            name: "Amazon.com Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "TSLA",
            symbol: "TSLA",
            name: "Tesla Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "NVDA",
            symbol: "NVDA",
            name: "NVIDIA Corporation",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "META",
            symbol: "META",
            name: "Meta Platforms Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "NFLX",
            symbol: "NFLX",
            name: "Netflix Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "AMD",
            symbol: "AMD",
            name: "Advanced Micro Devices Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "INTC",
            symbol: "INTC",
            name: "Intel Corporation",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "SPY",
            symbol: "SPY",
            name: "SPDR S&P 500 ETF Trust",
            type: .etf,
            exchange: "NYSE",
            currency: "USD"
        ),
        SymbolSearchResult(
            id: "QQQ",
            symbol: "QQQ",
            name: "Invesco QQQ Trust",
            type: .etf,
            exchange: "NASDAQ",
            currency: "USD"
        )
    ]
}
