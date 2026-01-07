//
//  OrderTests.swift
//  TradingCockpit Unit Tests
//
//  Created on 2025-11-24
//

import XCTest
@testable import TradingCockpit

final class OrderRequestTests: XCTestCase {

    // MARK: - Estimated Value Tests

    func testEstimatedValueMarketOrder() {
        // Given
        let request = OrderRequest(
            symbol: "AAPL",
            side: .buy,
            quantity: 100,
            orderType: .market
        )
        let currentPrice: Decimal = 175.50

        // When
        let estimatedValue = request.estimatedValue(currentPrice: currentPrice)

        // Then
        XCTAssertEqual(estimatedValue, 17550.00, accuracy: 0.01)
    }

    func testEstimatedValueLimitOrder() {
        // Given
        let request = OrderRequest(
            symbol: "AAPL",
            side: .buy,
            quantity: 100,
            orderType: .limit,
            limitPrice: 170.00
        )
        let currentPrice: Decimal = 175.50

        // When
        let estimatedValue = request.estimatedValue(currentPrice: currentPrice)

        // Then
        XCTAssertEqual(estimatedValue, 17000.00, accuracy: 0.01)
    }

    func testEstimatedValueLimitOrderWithoutPrice() {
        // Given
        let request = OrderRequest(
            symbol: "AAPL",
            side: .buy,
            quantity: 100,
            orderType: .limit,
            limitPrice: nil
        )
        let currentPrice: Decimal = 175.50

        // When
        let estimatedValue = request.estimatedValue(currentPrice: currentPrice)

        // Then
        XCTAssertEqual(estimatedValue, 17550.00, accuracy: 0.01) // Falls back to current price
    }
}

final class OrderValidationTests: XCTestCase {

    // MARK: - Symbol Validation

    func testEmptySymbolInvalid() {
        // Given
        let errors: [OrderValidationError] = [.emptySymbol]
        let validation = OrderValidation(isValid: false, errors: errors, warnings: [])

        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.errors.count, 1)
        XCTAssertTrue(validation.errors.contains(where: {
            if case .emptySymbol = $0 { return true }
            return false
        }))
    }

    // MARK: - Quantity Validation

    func testInvalidQuantity() {
        // Given
        let errors: [OrderValidationError] = [.invalidQuantity]
        let validation = OrderValidation(isValid: false, errors: errors, warnings: [])

        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.errors.count, 1)
    }

    // MARK: - Buying Power Validation

    func testInsufficientBuyingPower() {
        // Given
        let errors: [OrderValidationError] = [
            .insufficientBuyingPower(required: 10000, available: 5000)
        ]
        let validation = OrderValidation(isValid: false, errors: errors, warnings: [])

        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.errors.count, 1)
    }

    // MARK: - Valid Order

    func testValidOrder() {
        // Given
        let validation = OrderValidation.valid

        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertTrue(validation.warnings.isEmpty)
    }

    // MARK: - Warnings

    func testValidWithWarnings() {
        // Given
        let validation = OrderValidation.validWithWarnings("Market is closed")

        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertEqual(validation.warnings.count, 1)
        XCTAssertEqual(validation.warnings.first, "Market is closed")
    }
}

final class PositionSizerTests: XCTestCase {

    // MARK: - Max Shares Calculation

    func testCalculateMaxSharesByDollarAmount() {
        // Given
        let sizer = PositionSizer(
            accountBalance: 100000,
            riskPercentage: 0.02,
            maxPositionSize: 0.20
        )
        let currentPrice: Decimal = 100.00

        // When
        let maxShares = sizer.calculateMaxShares(currentPrice: currentPrice)

        // Then
        // Max position = 100,000 * 0.20 = 20,000
        // Max shares = 20,000 / 100 = 200
        XCTAssertEqual(maxShares, 200)
    }

    func testCalculateMaxSharesWithStopLoss() {
        // Given
        let sizer = PositionSizer(
            accountBalance: 100000,
            riskPercentage: 0.02,
            maxPositionSize: 0.20
        )
        let currentPrice: Decimal = 100.00
        let stopLoss: Decimal = 95.00

        // When
        let maxShares = sizer.calculateMaxShares(currentPrice: currentPrice, stopLoss: stopLoss)

        // Then
        // Risk per share = 100 - 95 = 5
        // Max risk = 100,000 * 0.02 = 2,000
        // Max shares by risk = 2,000 / 5 = 400
        // Max shares by dollar = 200 (from previous test)
        // Should return min(400, 200) = 200
        XCTAssertEqual(maxShares, 200)
    }

    func testSuggestedPositions() {
        // Given
        let sizer = PositionSizer(
            accountBalance: 100000,
            riskPercentage: 0.02,
            maxPositionSize: 0.20
        )
        let currentPrice: Decimal = 100.00

        // When
        let suggestions = sizer.suggestedPositions(currentPrice: currentPrice)

        // Then
        // Max = 200 shares
        // Suggestions should be [50, 100, 150, 200]
        XCTAssertEqual(suggestions.count, 4)
        XCTAssertEqual(suggestions[0], 50)  // 25%
        XCTAssertEqual(suggestions[1], 100) // 50%
        XCTAssertEqual(suggestions[2], 150) // 75%
        XCTAssertEqual(suggestions[3], 200) // 100%
    }

    func testDefaultPositionSizer() {
        // Given
        let sizer = PositionSizer.default

        // Then
        XCTAssertEqual(sizer.accountBalance, 100000)
        XCTAssertEqual(sizer.riskPercentage, 0.02)
        XCTAssertEqual(sizer.maxPositionSize, 0.20)
    }
}

final class OrderStatusDisplayTests: XCTestCase {

    func testStatusText() {
        // Given
        let order = Order(
            id: UUID(),
            brokerOrderId: "123",
            symbol: "AAPL",
            side: .buy,
            orderType: .market,
            quantity: 100,
            filledQuantity: 0,
            limitPrice: nil,
            stopPrice: nil,
            averageFillPrice: nil,
            status: .new,
            timeInForce: .day,
            createdAt: Date(),
            updatedAt: Date()
        )
        let display = OrderStatusDisplay(order: order, currentPrice: nil, elapsedTime: 60)

        // When
        let statusText = display.statusText

        // Then
        XCTAssertEqual(statusText, "Submitted")
    }

    func testFilledPercentage() {
        // Given
        let order = Order(
            id: UUID(),
            brokerOrderId: "123",
            symbol: "AAPL",
            side: .buy,
            orderType: .market,
            quantity: 100,
            filledQuantity: 75,
            limitPrice: nil,
            stopPrice: nil,
            averageFillPrice: 175.00,
            status: .partiallyFilled,
            timeInForce: .day,
            createdAt: Date(),
            updatedAt: Date()
        )
        let display = OrderStatusDisplay(order: order, currentPrice: nil, elapsedTime: 60)

        // When
        let percentage = display.filledPercentage

        // Then
        XCTAssertEqual(percentage, 75)
    }

    func testIsActive() {
        // Given - New order
        let newOrder = Order(
            id: UUID(),
            brokerOrderId: "123",
            symbol: "AAPL",
            side: .buy,
            orderType: .market,
            quantity: 100,
            filledQuantity: 0,
            limitPrice: nil,
            stopPrice: nil,
            averageFillPrice: nil,
            status: .new,
            timeInForce: .day,
            createdAt: Date(),
            updatedAt: Date()
        )
        let newDisplay = OrderStatusDisplay(order: newOrder, currentPrice: nil, elapsedTime: 60)

        // Then
        XCTAssertTrue(newDisplay.isActive)
        XCTAssertTrue(newDisplay.canCancel)

        // Given - Filled order
        var filledOrder = newOrder
        filledOrder.status = .filled
        let filledDisplay = OrderStatusDisplay(order: filledOrder, currentPrice: nil, elapsedTime: 60)

        // Then
        XCTAssertFalse(filledDisplay.isActive)
        XCTAssertFalse(filledDisplay.canCancel)
    }
}
