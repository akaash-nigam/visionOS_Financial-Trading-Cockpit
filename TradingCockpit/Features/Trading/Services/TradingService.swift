//
//  TradingService.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import Foundation
import Combine

/// Main trading service for order management
@Observable
class TradingService {
    // MARK: - Properties

    private let brokerAdapter: AlpacaBrokerAdapter?
    private let database: DatabaseManager
    private var cancellables = Set<AnyCancellable>()

    // Observable state
    var activeOrders: [Order] = []
    var orderHistory: [Order] = []
    var isSubmitting: Bool = false
    var lastError: Error?

    // Current account state
    var accountBalance: AccountBalance?
    var positions: [Position] = []

    // MARK: - Initialization

    init(brokerAdapter: AlpacaBrokerAdapter? = nil, database: DatabaseManager = .shared) {
        self.brokerAdapter = brokerAdapter
        self.database = database
        Logger.info("💼 Trading Service initialized")
    }

    // MARK: - Order Validation

    /// Validate an order request
    func validateOrder(_ request: OrderRequest, currentPrice: Decimal) async -> OrderValidation {
        var errors: [OrderValidationError] = []
        var warnings: [String] = []

        // Validate symbol
        if request.symbol.isEmpty {
            errors.append(.emptySymbol)
        }

        // Validate quantity
        if request.quantity <= 0 {
            errors.append(.invalidQuantity)
        }

        // Validate limit price for limit orders
        if request.orderType == .limit {
            if let limitPrice = request.limitPrice, limitPrice <= 0 {
                errors.append(.invalidLimitPrice)
            } else if request.limitPrice == nil {
                errors.append(.invalidLimitPrice)
            }
        }

        // Validate stop price for stop orders
        if request.orderType == .stopLoss || request.orderType == .stopLimit {
            if let stopPrice = request.stopPrice, stopPrice <= 0 {
                errors.append(.invalidStopPrice)
            } else if request.stopPrice == nil {
                errors.append(.invalidStopPrice)
            }
        }

        // Check buying power for buy orders
        if request.side == .buy, let balance = accountBalance {
            let estimatedCost = request.estimatedValue(currentPrice: currentPrice)
            if estimatedCost > balance.buyingPower {
                errors.append(.insufficientBuyingPower(
                    required: estimatedCost,
                    available: balance.buyingPower
                ))
            }
        }

        // Check position size limits
        if let balance = accountBalance {
            let estimatedValue = request.estimatedValue(currentPrice: currentPrice)
            let maxPositionValue = balance.equity * 0.20  // 20% max
            if estimatedValue > maxPositionValue {
                errors.append(.positionSizeTooLarge(maxSize: maxPositionValue))
            }
        }

        // Check for market hours
        let marketStatus = await checkMarketStatus()
        if marketStatus == .closed {
            warnings.append("Market is closed. Order will be queued for market open.")
        }

        // Check for duplicate orders
        let hasSimilarOrder = activeOrders.contains { order in
            order.symbol == request.symbol &&
            order.side == request.side &&
            order.status != .filled &&
            order.status != .cancelled
        }
        if hasSimilarOrder {
            warnings.append("You have a similar pending order for this security")
        }

        // Return validation result
        if !errors.isEmpty {
            return OrderValidation(isValid: false, errors: errors, warnings: warnings)
        } else if !warnings.isEmpty {
            return OrderValidation(isValid: true, errors: [], warnings: warnings)
        } else {
            return .valid
        }
    }

    // MARK: - Order Submission

    /// Submit an order to the broker
    func submitOrder(_ request: OrderRequest) async throws -> Order {
        isSubmitting = true
        defer { isSubmitting = false }

        Logger.info("📤 Submitting order: \(request.side) \(request.quantity) \(request.symbol)")

        guard let adapter = brokerAdapter else {
            throw TradingServiceError.noBrokerAdapter
        }

        do {
            // Create Alpaca order request
            let alpacaRequest = AlpacaOrderRequest(
                symbol: request.symbol,
                qty: request.quantity,
                side: request.side.rawValue,
                type: request.orderType.rawValue,
                timeInForce: request.timeInForce.rawValue,
                limitPrice: request.limitPrice,
                stopPrice: request.stopPrice,
                extendedHours: false,
                clientOrderId: UUID().uuidString
            )

            // Submit to broker
            let alpacaOrder = try await adapter.submitOrder(alpacaRequest)

            // Convert to local order model
            let order = Order(
                id: UUID(),
                brokerOrderId: alpacaOrder.id,
                symbol: request.symbol,
                side: request.side,
                orderType: request.orderType,
                quantity: request.quantity,
                filledQuantity: alpacaOrder.filledQty ?? 0,
                limitPrice: request.limitPrice,
                stopPrice: request.stopPrice,
                averageFillPrice: alpacaOrder.filledAvgPrice,
                status: OrderStatus(rawValue: alpacaOrder.status) ?? .pending,
                timeInForce: request.timeInForce,
                createdAt: alpacaOrder.createdAt ?? Date(),
                updatedAt: alpacaOrder.updatedAt ?? Date()
            )

            // Save to database
            try await saveOrder(order)

            // Update active orders
            await MainActor.run {
                activeOrders.append(order)
            }

            Logger.info("✅ Order submitted successfully: \(order.brokerOrderId ?? "unknown")")
            return order

        } catch {
            Logger.error("❌ Order submission failed", error: error)
            lastError = error
            throw error
        }
    }

    // MARK: - Order Management

    /// Cancel an active order
    func cancelOrder(_ order: Order) async throws {
        guard let brokerOrderId = order.brokerOrderId else {
            throw TradingServiceError.invalidOrderId
        }

        guard let adapter = brokerAdapter else {
            throw TradingServiceError.noBrokerAdapter
        }

        Logger.info("🚫 Cancelling order: \(brokerOrderId)")

        do {
            try await adapter.cancelOrder(orderId: brokerOrderId)

            // Update local order
            var updatedOrder = order
            updatedOrder.status = .cancelled
            updatedOrder.updatedAt = Date()

            try await updateOrder(updatedOrder)

            // Refresh orders
            await refreshOrders()

            Logger.info("✅ Order cancelled successfully")

        } catch {
            Logger.error("❌ Order cancellation failed", error: error)
            throw error
        }
    }

    /// Refresh orders from broker
    func refreshOrders() async {
        guard let adapter = brokerAdapter else { return }

        do {
            let alpacaOrders = try await adapter.getOrders()

            let orders = alpacaOrders.compactMap { alpacaOrder -> Order? in
                guard let side = OrderSide(rawValue: alpacaOrder.side),
                      let type = OrderType(rawValue: alpacaOrder.type),
                      let tif = TimeInForce(rawValue: alpacaOrder.timeInForce),
                      let status = OrderStatus(rawValue: alpacaOrder.status) else {
                    return nil
                }

                return Order(
                    id: UUID(),
                    brokerOrderId: alpacaOrder.id,
                    symbol: alpacaOrder.symbol,
                    side: side,
                    orderType: type,
                    quantity: alpacaOrder.qty,
                    filledQuantity: alpacaOrder.filledQty ?? 0,
                    limitPrice: alpacaOrder.limitPrice,
                    stopPrice: alpacaOrder.stopPrice,
                    averageFillPrice: alpacaOrder.filledAvgPrice,
                    status: status,
                    timeInForce: tif,
                    createdAt: alpacaOrder.createdAt ?? Date(),
                    updatedAt: alpacaOrder.updatedAt ?? Date()
                )
            }

            await MainActor.run {
                // Split into active and history
                activeOrders = orders.filter { $0.status == .new || $0.status == .partiallyFilled }
                orderHistory = orders.filter { $0.status == .filled || $0.status == .cancelled }
            }

            Logger.debug("📊 Refreshed orders: \(orders.count) total")

        } catch {
            Logger.error("❌ Failed to refresh orders", error: error)
        }
    }

    /// Refresh positions from broker
    func refreshPositions() async {
        guard let adapter = brokerAdapter else { return }

        do {
            let alpacaPositions = try await adapter.getPositions()

            let newPositions = alpacaPositions.map { alpacaPosition in
                Position(
                    symbol: alpacaPosition.symbol,
                    quantity: Int(alpacaPosition.qty) ?? 0,
                    averagePrice: alpacaPosition.avgEntryPrice,
                    currentPrice: alpacaPosition.currentPrice
                )
            }

            await MainActor.run {
                positions = newPositions
            }

            Logger.debug("📊 Refreshed positions: \(newPositions.count)")

        } catch {
            Logger.error("❌ Failed to refresh positions", error: error)
        }
    }

    /// Refresh account balance
    func refreshAccount() async {
        guard let adapter = brokerAdapter else { return }

        do {
            let account = try await adapter.getAccount()

            let balance = AccountBalance(
                cash: account.cash,
                portfolioValue: account.portfolioValue,
                buyingPower: account.buyingPower,
                equity: account.equity
            )

            await MainActor.run {
                accountBalance = balance
            }

            Logger.debug("💰 Account balance refreshed: $\(balance.equity)")

        } catch {
            Logger.error("❌ Failed to refresh account", error: error)
        }
    }

    // MARK: - Order Confirmation

    /// Generate order confirmation details
    func generateConfirmation(
        for request: OrderRequest,
        currentPrice: Decimal
    ) -> OrderConfirmation {
        let estimatedCost = request.estimatedValue(currentPrice: currentPrice)
        let commission = Decimal(0)  // Alpaca has no commissions
        let total = estimatedCost + commission

        let buyingPowerAfter: Decimal
        if request.side == .buy {
            buyingPowerAfter = (accountBalance?.buyingPower ?? 0) - total
        } else {
            buyingPowerAfter = (accountBalance?.buyingPower ?? 0) + estimatedCost
        }

        return OrderConfirmation(
            request: request,
            currentPrice: currentPrice,
            estimatedCost: estimatedCost,
            estimatedCommission: commission,
            estimatedTotal: total,
            buyingPowerAfter: buyingPowerAfter,
            marketStatus: .open  // Simplified for MVP
        )
    }

    // MARK: - Private Helpers

    private func checkMarketStatus() async -> MarketStatus {
        // Simplified market hours check (US Eastern Time)
        // TODO: Implement proper market calendar
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())

        // Weekend
        if weekday == 1 || weekday == 7 {
            return .closed
        }

        // Market hours: 9:30 AM - 4:00 PM ET (simplified to 9-16 for demo)
        if hour >= 9 && hour < 16 {
            return .open
        } else if hour >= 4 && hour < 9 {
            return .preMarket
        } else {
            return .afterHours
        }
    }

    private func saveOrder(_ order: Order) async throws {
        // Save to database (simplified)
        Logger.debug("💾 Saving order to database: \(order.symbol)")
        // TODO: Implement database save
    }

    private func updateOrder(_ order: Order) async throws {
        // Update in database (simplified)
        Logger.debug("💾 Updating order in database: \(order.symbol)")
        // TODO: Implement database update
    }
}

// MARK: - Errors

enum TradingServiceError: Error, LocalizedError {
    case noBrokerAdapter
    case invalidOrderId
    case orderNotFound

    var errorDescription: String? {
        switch self {
        case .noBrokerAdapter:
            return "No broker adapter configured"
        case .invalidOrderId:
            return "Invalid order ID"
        case .orderNotFound:
            return "Order not found"
        }
    }
}
