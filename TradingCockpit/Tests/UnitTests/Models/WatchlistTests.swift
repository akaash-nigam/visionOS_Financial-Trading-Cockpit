//
//  WatchlistTests.swift
//  TradingCockpit Unit Tests
//
//  Created on 2025-11-24
//

import XCTest
@testable import TradingCockpit

final class WatchlistTests: XCTestCase {

    // MARK: - Initialization

    func testWatchlistInitialization() {
        // Given
        let name = "Tech Stocks"
        let symbols = ["AAPL", "GOOGL", "MSFT"]

        // When
        let watchlist = Watchlist(name: name, symbols: symbols)

        // Then
        XCTAssertEqual(watchlist.name, name)
        XCTAssertEqual(watchlist.symbols, symbols)
        XCTAssertEqual(watchlist.count, 3)
        XCTAssertFalse(watchlist.isDefault)
        XCTAssertNotNil(watchlist.id)
    }

    // MARK: - Add Symbol

    func testAddSymbol() {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL"])

        // When
        watchlist.add("GOOGL")

        // Then
        XCTAssertEqual(watchlist.count, 2)
        XCTAssertTrue(watchlist.contains("GOOGL"))
    }

    func testAddDuplicateSymbol() {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL"])
        let originalCount = watchlist.count

        // When
        watchlist.add("AAPL")

        // Then
        XCTAssertEqual(watchlist.count, originalCount) // No change
        XCTAssertEqual(watchlist.symbols.count, 1)
    }

    // MARK: - Remove Symbol

    func testRemoveSymbol() {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL", "GOOGL", "MSFT"])

        // When
        watchlist.remove("GOOGL")

        // Then
        XCTAssertEqual(watchlist.count, 2)
        XCTAssertFalse(watchlist.contains("GOOGL"))
        XCTAssertTrue(watchlist.contains("AAPL"))
        XCTAssertTrue(watchlist.contains("MSFT"))
    }

    func testRemoveNonExistentSymbol() {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL"])
        let originalCount = watchlist.count

        // When
        watchlist.remove("TSLA")

        // Then
        XCTAssertEqual(watchlist.count, originalCount) // No change
    }

    // MARK: - Contains

    func testContains() {
        // Given
        let watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL", "GOOGL"])

        // Then
        XCTAssertTrue(watchlist.contains("AAPL"))
        XCTAssertTrue(watchlist.contains("GOOGL"))
        XCTAssertFalse(watchlist.contains("MSFT"))
    }

    // MARK: - Default Watchlists

    func testDefaultWatchlist() {
        // When
        let watchlist = Watchlist.default

        // Then
        XCTAssertTrue(watchlist.isDefault)
        XCTAssertEqual(watchlist.name, "My Watchlist")
        XCTAssertGreaterThan(watchlist.count, 0)
    }

    func testTechWatchlist() {
        // When
        let watchlist = Watchlist.tech

        // Then
        XCTAssertFalse(watchlist.isDefault)
        XCTAssertEqual(watchlist.name, "Tech")
        XCTAssertTrue(watchlist.contains("AAPL"))
        XCTAssertTrue(watchlist.contains("GOOGL"))
        XCTAssertTrue(watchlist.contains("MSFT"))
    }

    // MARK: - Updated Timestamp

    func testUpdatedTimestampOnAdd() throws {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL"])
        let originalTimestamp = watchlist.updatedAt

        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // When
        watchlist.add("GOOGL")

        // Then
        XCTAssertGreaterThan(watchlist.updatedAt, originalTimestamp)
    }

    func testUpdatedTimestampOnRemove() throws {
        // Given
        var watchlist = Watchlist(name: "My Watchlist", symbols: ["AAPL", "GOOGL"])
        let originalTimestamp = watchlist.updatedAt

        // Wait a bit
        Thread.sleep(forTimeInterval: 0.01)

        // When
        watchlist.remove("GOOGL")

        // Then
        XCTAssertGreaterThan(watchlist.updatedAt, originalTimestamp)
    }

    // MARK: - Codable

    func testWatchlistCodable() throws {
        // Given
        let original = Watchlist(
            name: "Test Watchlist",
            symbols: ["AAPL", "GOOGL", "MSFT"]
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Watchlist.self, from: data)

        // Then
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.symbols, original.symbols)
        XCTAssertEqual(decoded.count, original.count)
    }
}

final class WatchlistItemTests: XCTestCase {

    func testWatchlistItemWithQuote() {
        // Given
        let quote = Quote.mock(symbol: "AAPL")
        let item = WatchlistItem(
            id: "AAPL",
            symbol: "AAPL",
            quote: quote,
            inWatchlist: true
        )

        // Then
        XCTAssertEqual(item.symbol, "AAPL")
        XCTAssertNotNil(item.currentPrice)
        XCTAssertNotNil(item.priceChange)
        XCTAssertNotNil(item.priceChangePercent)
        XCTAssertTrue(item.inWatchlist)
    }

    func testWatchlistItemWithoutQuote() {
        // Given
        let item = WatchlistItem(
            id: "AAPL",
            symbol: "AAPL",
            quote: nil,
            inWatchlist: false
        )

        // Then
        XCTAssertEqual(item.symbol, "AAPL")
        XCTAssertNil(item.currentPrice)
        XCTAssertNil(item.priceChange)
        XCTAssertNil(item.priceChangePercent)
        XCTAssertFalse(item.inWatchlist)
    }

    func testIsPositive() {
        // Given
        let positiveQuote = Quote(
            symbol: "AAPL",
            last: 175.00,
            open: 170.00,
            high: 176.00,
            low: 170.00,
            close: 170.00,
            volume: 1_000_000
        )
        let item = WatchlistItem(
            id: "AAPL",
            symbol: "AAPL",
            quote: positiveQuote,
            inWatchlist: true
        )

        // Then
        XCTAssertTrue(item.isPositive)
        XCTAssertFalse(item.isNegative)
    }
}

final class SymbolSearchResultTests: XCTestCase {

    func testSearchResultDisplayText() {
        // Given
        let result = SymbolSearchResult(
            id: "AAPL",
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        )

        // When
        let displayText = result.displayText

        // Then
        XCTAssertEqual(displayText, "AAPL - Apple Inc.")
    }

    func testSearchResultExchangeInfo() {
        // Given
        let result = SymbolSearchResult(
            id: "AAPL",
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            exchange: "NASDAQ",
            currency: "USD"
        )

        // When
        let exchangeInfo = result.exchangeInfo

        // Then
        XCTAssertEqual(exchangeInfo, "NASDAQ · USD")
    }

    func testMockSearchResults() {
        // When
        let results = SymbolSearchResult.mockResults

        // Then
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.contains(where: { $0.symbol == "AAPL" }))
        XCTAssertTrue(results.contains(where: { $0.symbol == "GOOGL" }))
        XCTAssertTrue(results.contains(where: { $0.type == .stock }))
        XCTAssertTrue(results.contains(where: { $0.type == .etf }))
    }
}

final class WatchlistStatisticsTests: XCTestCase {

    func testGainersPercent() {
        // Given
        let stats = WatchlistStatistics(
            totalSymbols: 100,
            gainers: 60,
            losers: 30,
            unchanged: 10,
            avgChangePercent: 1.5
        )

        // When
        let gainersPercent = stats.gainersPercent

        // Then
        XCTAssertEqual(gainersPercent, 60.0, accuracy: 0.1)
    }

    func testLosersPercent() {
        // Given
        let stats = WatchlistStatistics(
            totalSymbols: 100,
            gainers: 60,
            losers: 30,
            unchanged: 10,
            avgChangePercent: 1.5
        )

        // When
        let losersPercent = stats.losersPercent

        // Then
        XCTAssertEqual(losersPercent, 30.0, accuracy: 0.1)
    }

    func testEmptyStatistics() {
        // When
        let stats = WatchlistStatistics.empty

        // Then
        XCTAssertEqual(stats.totalSymbols, 0)
        XCTAssertEqual(stats.gainers, 0)
        XCTAssertEqual(stats.losers, 0)
        XCTAssertEqual(stats.gainersPercent, 0)
        XCTAssertEqual(stats.losersPercent, 0)
    }
}
