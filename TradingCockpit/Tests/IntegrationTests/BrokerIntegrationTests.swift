//
//  BrokerIntegrationTests.swift
//  TradingCockpit Integration Tests
//
//  Created on 2025-11-24
//
//  NOTE: These tests require actual API credentials and network access.
//  They should be run separately from unit tests.
//

import XCTest
@testable import TradingCockpit

final class AlpacaBrokerIntegrationTests: XCTestCase {

    var broker: AlpacaBrokerAdapter!

    override func setUpWithError() throws {
        // Skip if no API credentials available
        guard let apiKey = ProcessInfo.processInfo.environment["ALPACA_API_KEY"],
              let secretKey = ProcessInfo.processInfo.environment["ALPACA_SECRET_KEY"] else {
            throw XCTSkip("Alpaca API credentials not available")
        }

        broker = AlpacaBrokerAdapter(
            apiKey: apiKey,
            secretKey: secretKey,
            isPaperTrading: true
        )
    }

    override func tearDownWithError() throws {
        broker = nil
    }

    // MARK: - Account Tests

    func testGetAccount() async throws {
        // When
        let account = try await broker.getAccount()

        // Then
        XCTAssertGreaterThan(account.equity, 0)
        XCTAssertGreaterThanOrEqual(account.buyingPower, 0)
        XCTAssertNotNil(account.accountNumber)
    }

    // MARK: - Position Tests

    func testGetPositions() async throws {
        // When
        let positions = try await broker.getPositions()

        // Then
        XCTAssertNotNil(positions)
        // Note: May be empty if no positions
    }

    // MARK: - Order Tests (Paper Trading Only)

    func testSubmitAndCancelMarketOrder() async throws {
        // Given
        let orderRequest = AlpacaOrderRequest(
            symbol: "AAPL",
            qty: 1,
            side: "buy",
            type: "market",
            timeInForce: "day",
            limitPrice: nil,
            stopPrice: nil,
            extendedHours: false,
            clientOrderId: "test-\(UUID().uuidString)"
        )

        // When - Submit order
        let submittedOrder = try await broker.submitOrder(orderRequest)

        // Then
        XCTAssertNotNil(submittedOrder.id)
        XCTAssertEqual(submittedOrder.symbol, "AAPL")
        XCTAssertEqual(submittedOrder.qty, 1)

        // Wait a moment for order to be processed
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // When - Cancel order
        try await broker.cancelOrder(orderId: submittedOrder.id)

        // Then - Get orders to verify cancellation
        let orders = try await broker.getOrders()
        if let cancelledOrder = orders.first(where: { $0.id == submittedOrder.id }) {
            XCTAssertTrue(["cancelled", "canceled"].contains(cancelledOrder.status))
        }
    }

    func testSubmitLimitOrder() async throws {
        // Given - Use a limit price far from current to avoid immediate fill
        let orderRequest = AlpacaOrderRequest(
            symbol: "AAPL",
            qty: 1,
            side: "buy",
            type: "limit",
            timeInForce: "day",
            limitPrice: 1.00, // Intentionally low to avoid fill
            stopPrice: nil,
            extendedHours: false,
            clientOrderId: "test-\(UUID().uuidString)"
        )

        // When
        let submittedOrder = try await broker.submitOrder(orderRequest)

        // Then
        XCTAssertNotNil(submittedOrder.id)
        XCTAssertEqual(submittedOrder.type, "limit")
        XCTAssertEqual(submittedOrder.limitPrice, 1.00)

        // Cleanup - Cancel order
        try? await broker.cancelOrder(orderId: submittedOrder.id)
    }

    // MARK: - Error Handling Tests

    func testInvalidSymbolError() async {
        // Given
        let orderRequest = AlpacaOrderRequest(
            symbol: "INVALID_SYMBOL_THAT_DOESNT_EXIST",
            qty: 1,
            side: "buy",
            type: "market",
            timeInForce: "day",
            limitPrice: nil,
            stopPrice: nil,
            extendedHours: false,
            clientOrderId: "test-\(UUID().uuidString)"
        )

        // When/Then
        do {
            _ = try await broker.submitOrder(orderRequest)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    func testInvalidOrderQuantityError() async {
        // Given
        let orderRequest = AlpacaOrderRequest(
            symbol: "AAPL",
            qty: 0, // Invalid quantity
            side: "buy",
            type: "market",
            timeInForce: "day",
            limitPrice: nil,
            stopPrice: nil,
            extendedHours: false,
            clientOrderId: "test-\(UUID().uuidString)"
        )

        // When/Then
        do {
            _ = try await broker.submitOrder(orderRequest)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Performance Tests

    func testGetAccountPerformance() {
        measure {
            let expectation = self.expectation(description: "Get account")

            Task {
                do {
                    _ = try await broker.getAccount()
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to get account: \(error)")
                }
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }
}

final class MarketDataIntegrationTests: XCTestCase {

    // NOTE: These tests require Polygon.io API key and network access

    func testPolygonWebSocketConnection() async throws {
        // Skip if no API key
        guard let apiKey = ProcessInfo.processInfo.environment["POLYGON_API_KEY"] else {
            throw XCTSkip("Polygon API key not available")
        }

        // Given
        let provider = PolygonDataProvider(apiKey: apiKey)

        // When
        try await provider.connect()

        // Wait for connection
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Then - Should be connected without errors
        // Note: Actual quote verification would require monitoring the AsyncStream
    }
}
