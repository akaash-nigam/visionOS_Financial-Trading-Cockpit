//
//  QuoteTests.swift
//  TradingCockpit Unit Tests
//
//  Created on 2025-11-24
//

import XCTest
@testable import TradingCockpit

final class QuoteTests: XCTestCase {

    // MARK: - Test Setup

    override func setUpWithError() throws {
        // Put setup code here
    }

    override func tearDownWithError() throws {
        // Put teardown code here
    }

    // MARK: - Initialization Tests

    func testQuoteInitialization() {
        // Given
        let symbol = "AAPL"
        let last: Decimal = 175.50
        let close: Decimal = 170.00
        let volume: Int64 = 50_000_000

        // When
        let quote = Quote(
            symbol: symbol,
            bid: 175.45,
            ask: 175.55,
            last: last,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: close,
            volume: volume
        )

        // Then
        XCTAssertEqual(quote.symbol, symbol)
        XCTAssertEqual(quote.last, last)
        XCTAssertEqual(quote.close, close)
        XCTAssertEqual(quote.volume, volume)
        XCTAssertNotNil(quote.id)
        XCTAssertNotNil(quote.timestamp)
    }

    // MARK: - Calculated Field Tests

    func testChangeCalculation() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let change = quote.change

        // Then
        XCTAssertEqual(change, 5.50, accuracy: 0.01)
    }

    func testChangePercentCalculation() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            last: 175.00,
            open: 171.00,
            high: 176.00,
            low: 170.00,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let changePercent = quote.changePercent

        // Then
        // (175 - 170) / 170 * 100 = 2.94%
        XCTAssertEqual(Double(truncating: changePercent as NSNumber), 2.94, accuracy: 0.01)
    }

    func testSpreadCalculation() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            bid: 175.45,
            ask: 175.55,
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let spread = quote.spread

        // Then
        XCTAssertEqual(spread, 0.10, accuracy: 0.001)
    }

    func testMidpointCalculation() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            bid: 175.40,
            ask: 175.60,
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let midpoint = quote.midpoint

        // Then
        XCTAssertEqual(midpoint, 175.50, accuracy: 0.01)
    }

    func testSpreadNilWithoutBidAsk() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            bid: nil,
            ask: nil,
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let spread = quote.spread

        // Then
        XCTAssertNil(spread)
    }

    // MARK: - Direction Tests

    func testIsPositive() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // Then
        XCTAssertTrue(quote.isPositive)
        XCTAssertFalse(quote.isNegative)
    }

    func testIsNegative() {
        // Given
        let quote = Quote(
            symbol: "AAPL",
            last: 165.50,
            open: 171.00,
            high: 172.00,
            low: 165.00,
            close: 170.00,
            volume: 50_000_000
        )

        // Then
        XCTAssertTrue(quote.isNegative)
        XCTAssertFalse(quote.isPositive)
    }

    // MARK: - Mock Data Tests

    func testMockQuoteGeneration() {
        // When
        let mockQuote = Quote.mock(symbol: "TSLA")

        // Then
        XCTAssertEqual(mockQuote.symbol, "TSLA")
        XCTAssertGreaterThan(mockQuote.last, 0)
        XCTAssertGreaterThan(mockQuote.volume, 0)
        XCTAssertNotNil(mockQuote.bid)
        XCTAssertNotNil(mockQuote.ask)
    }

    // MARK: - Codable Tests

    func testQuoteCodable() throws {
        // Given
        let original = Quote(
            symbol: "AAPL",
            bid: 175.45,
            ask: 175.55,
            last: 175.50,
            open: 171.00,
            high: 176.00,
            low: 170.50,
            close: 170.00,
            volume: 50_000_000
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Quote.self, from: data)

        // Then
        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.last, original.last)
        XCTAssertEqual(decoded.close, original.close)
        XCTAssertEqual(decoded.volume, original.volume)
    }

    // MARK: - Performance Tests

    func testQuoteCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Quote.mock(symbol: "AAPL")
            }
        }
    }
}
