//
//  PositionTests.swift
//  TradingCockpit Unit Tests
//
//  Created on 2025-11-24
//

import XCTest
@testable import TradingCockpit

final class PositionTests: XCTestCase {

    // MARK: - P&L Calculation Tests

    func testMarketValue() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 175.50
        )

        // When
        let marketValue = position.marketValue

        // Then
        XCTAssertEqual(marketValue, 17550.00, accuracy: 0.01)
    }

    func testCostBasis() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 175.50
        )

        // When
        let costBasis = position.costBasis

        // Then
        XCTAssertEqual(costBasis, 15000.00, accuracy: 0.01)
    }

    func testUnrealizedPnL_Profit() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 175.50
        )

        // When
        let pnl = position.unrealizedPnL

        // Then
        XCTAssertEqual(pnl, 2550.00, accuracy: 0.01)
    }

    func testUnrealizedPnL_Loss() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 140.00
        )

        // When
        let pnl = position.unrealizedPnL

        // Then
        XCTAssertEqual(pnl, -1000.00, accuracy: 0.01)
    }

    func testUnrealizedPnLPercent_Profit() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 165.00
        )

        // When
        let pnlPercent = position.unrealizedPnLPercent

        // Then
        // (165 - 150) / 150 * 100 = 10%
        XCTAssertEqual(Double(truncating: pnlPercent as NSNumber), 10.0, accuracy: 0.01)
    }

    func testUnrealizedPnLPercent_Loss() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 135.00
        )

        // When
        let pnlPercent = position.unrealizedPnLPercent

        // Then
        // (135 - 150) / 150 * 100 = -10%
        XCTAssertEqual(Double(truncating: pnlPercent as NSNumber), -10.0, accuracy: 0.01)
    }

    // MARK: - Position Direction Tests

    func testIsLong() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 150.00,
            currentPrice: 175.50
        )

        // Then
        XCTAssertTrue(position.isLong)
        XCTAssertFalse(position.isShort)
    }

    func testIsShort() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: -100,
            averagePrice: 150.00,
            currentPrice: 175.50
        )

        // Then
        XCTAssertTrue(position.isShort)
        XCTAssertFalse(position.isLong)
    }

    // MARK: - Edge Cases

    func testZeroCostBasisPnLPercent() {
        // Given
        let position = Position(
            symbol: "AAPL",
            quantity: 100,
            averagePrice: 0.00,
            currentPrice: 175.50
        )

        // When
        let pnlPercent = position.unrealizedPnLPercent

        // Then
        XCTAssertEqual(pnlPercent, 0)
    }

    func testNegativeQuantityCalculations() {
        // Given (short position)
        let position = Position(
            symbol: "AAPL",
            quantity: -100,
            averagePrice: 150.00,
            currentPrice: 140.00
        )

        // When
        let marketValue = position.marketValue
        let costBasis = position.costBasis
        let pnl = position.unrealizedPnL

        // Then
        XCTAssertEqual(marketValue, -14000.00, accuracy: 0.01)
        XCTAssertEqual(costBasis, -15000.00, accuracy: 0.01)
        XCTAssertEqual(pnl, 1000.00, accuracy: 0.01) // Profit on short
    }
}

// MARK: - Portfolio Tests

final class PortfolioTests: XCTestCase {

    func testTotalValue() {
        // Given
        let balance = AccountBalance(
            cash: 10000,
            portfolioValue: 50000,
            buyingPower: 20000,
            equity: 60000
        )
        let portfolio = Portfolio(
            accountId: "test-account",
            positions: [],
            balance: balance
        )

        // When
        let totalValue = portfolio.totalValue

        // Then
        XCTAssertEqual(totalValue, 60000, accuracy: 0.01)
    }

    func testTotalUnrealizedPnL() {
        // Given
        let positions = [
            Position(symbol: "AAPL", quantity: 100, averagePrice: 150.00, currentPrice: 175.00),
            Position(symbol: "GOOGL", quantity: 50, averagePrice: 140.00, currentPrice: 135.00),
            Position(symbol: "MSFT", quantity: 75, averagePrice: 300.00, currentPrice: 350.00)
        ]
        let balance = AccountBalance(cash: 10000, portfolioValue: 50000, buyingPower: 20000, equity: 60000)
        let portfolio = Portfolio(accountId: "test-account", positions: positions, balance: balance)

        // When
        let totalPnL = portfolio.totalUnrealizedPnL

        // Then
        // AAPL: (175 - 150) * 100 = 2,500
        // GOOGL: (135 - 140) * 50 = -250
        // MSFT: (350 - 300) * 75 = 3,750
        // Total: 6,000
        XCTAssertEqual(totalPnL, 6000, accuracy: 0.01)
    }

    func testPositionCount() {
        // Given
        let positions = [
            Position(symbol: "AAPL", quantity: 100, averagePrice: 150.00, currentPrice: 175.00),
            Position(symbol: "GOOGL", quantity: 50, averagePrice: 140.00, currentPrice: 135.00)
        ]
        let balance = AccountBalance(cash: 10000, portfolioValue: 50000, buyingPower: 20000, equity: 60000)
        let portfolio = Portfolio(accountId: "test-account", positions: positions, balance: balance)

        // Then
        XCTAssertEqual(portfolio.positionCount, 2)
    }
}
