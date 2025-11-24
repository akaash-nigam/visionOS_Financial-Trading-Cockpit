//
//  OrderModels.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import Foundation

// MARK: - Order Request

/// User's order request before validation
struct OrderRequest {
    var symbol: String
    var side: OrderSide
    var quantity: Int
    var orderType: OrderType
    var limitPrice: Decimal?
    var stopPrice: Decimal?
    var timeInForce: TimeInForce

    init(
        symbol: String,
        side: OrderSide,
        quantity: Int = 0,
        orderType: OrderType = .market,
        limitPrice: Decimal? = nil,
        stopPrice: Decimal? = nil,
        timeInForce: TimeInForce = .day
    ) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.orderType = orderType
        self.limitPrice = limitPrice
        self.stopPrice = stopPrice
        self.timeInForce = timeInForce
    }

    /// Calculate estimated cost/proceeds
    func estimatedValue(currentPrice: Decimal) -> Decimal {
        let price = orderType == .limit ? (limitPrice ?? currentPrice) : currentPrice
        return price * Decimal(quantity)
    }
}

// MARK: - Order Validation

/// Order validation result
struct OrderValidation {
    let isValid: Bool
    let errors: [OrderValidationError]
    let warnings: [String]

    static let valid = OrderValidation(isValid: true, errors: [], warnings: [])

    static func invalid(_ errors: OrderValidationError...) -> OrderValidation {
        OrderValidation(isValid: false, errors: errors, warnings: [])
    }

    static func validWithWarnings(_ warnings: String...) -> OrderValidation {
        OrderValidation(isValid: true, errors: [], warnings: warnings)
    }
}

/// Order validation errors
enum OrderValidationError: Error, LocalizedError {
    case emptySymbol
    case invalidQuantity
    case insufficientBuyingPower(required: Decimal, available: Decimal)
    case invalidLimitPrice
    case invalidStopPrice
    case marketClosed
    case positionSizeTooLarge(maxSize: Decimal)
    case duplicateOrder

    var errorDescription: String? {
        switch self {
        case .emptySymbol:
            return "Please select a security"
        case .invalidQuantity:
            return "Quantity must be greater than 0"
        case .insufficientBuyingPower(let required, let available):
            return "Insufficient buying power. Required: $\(required), Available: $\(available)"
        case .invalidLimitPrice:
            return "Limit price must be greater than 0"
        case .invalidStopPrice:
            return "Stop price must be greater than 0"
        case .marketClosed:
            return "Market is currently closed. Order will be queued for market open."
        case .positionSizeTooLarge(let maxSize):
            return "Position size exceeds maximum allowed: $\(maxSize)"
        case .duplicateOrder:
            return "A similar order is already pending"
        }
    }
}

// MARK: - Order Confirmation

/// Order confirmation details shown to user before submission
struct OrderConfirmation {
    let request: OrderRequest
    let currentPrice: Decimal
    let estimatedCost: Decimal
    let estimatedCommission: Decimal
    let estimatedTotal: Decimal
    let buyingPowerAfter: Decimal
    let marketStatus: MarketStatus

    var displaySummary: String {
        let action = request.side == .buy ? "Buy" : "Sell"
        let type = request.orderType == .market ? "Market" : "Limit"
        return "\(action) \(request.quantity) shares of \(request.symbol) at \(type)"
    }
}

// MARK: - Market Status

enum MarketStatus {
    case open
    case closed
    case preMarket
    case afterHours

    var displayText: String {
        switch self {
        case .open: return "Market Open"
        case .closed: return "Market Closed"
        case .preMarket: return "Pre-Market"
        case .afterHours: return "After Hours"
        }
    }

    var color: String {
        switch self {
        case .open: return "green"
        case .closed: return "red"
        case .preMarket, .afterHours: return "orange"
        }
    }
}

// MARK: - Order Status

/// Extended order status for UI display
struct OrderStatusDisplay {
    let order: Order
    let currentPrice: Decimal?
    let elapsedTime: TimeInterval

    var statusText: String {
        switch order.status {
        case .pending: return "Pending Submission"
        case .new: return "Submitted"
        case .partiallyFilled: return "Partially Filled (\(filledPercentage)%)"
        case .filled: return "Filled"
        case .cancelled: return "Cancelled"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }

    var filledPercentage: Int {
        guard order.quantity > 0 else { return 0 }
        return Int((Double(order.filledQuantity) / Double(order.quantity)) * 100)
    }

    var isActive: Bool {
        order.status == .pending || order.status == .new || order.status == .partiallyFilled
    }

    var canCancel: Bool {
        order.status == .new || order.status == .partiallyFilled
    }

    var estimatedValue: Decimal? {
        guard let price = order.averageFillPrice ?? order.limitPrice ?? currentPrice else {
            return nil
        }
        return price * Decimal(order.filledQuantity > 0 ? order.filledQuantity : order.quantity)
    }
}

// MARK: - Position Sizing

/// Position sizing calculator
struct PositionSizer {
    let accountBalance: Decimal
    let riskPercentage: Decimal  // e.g., 0.02 for 2%
    let maxPositionSize: Decimal  // e.g., 0.20 for 20%

    static let `default` = PositionSizer(
        accountBalance: 100000,
        riskPercentage: 0.02,
        maxPositionSize: 0.20
    )

    /// Calculate maximum shares based on risk
    func calculateMaxShares(
        currentPrice: Decimal,
        stopLoss: Decimal? = nil
    ) -> Int {
        let maxDollarAmount = accountBalance * maxPositionSize
        let maxSharesByDollar = Int(maxDollarAmount / currentPrice)

        // If stop loss provided, calculate based on risk
        if let stopLoss = stopLoss {
            let riskPerShare = abs(currentPrice - stopLoss)
            let maxRiskDollars = accountBalance * riskPercentage
            let maxSharesByRisk = Int(maxRiskDollars / riskPerShare)
            return min(maxSharesByDollar, maxSharesByRisk)
        }

        return maxSharesByDollar
    }

    /// Calculate suggested position sizes
    func suggestedPositions(currentPrice: Decimal) -> [Int] {
        let max = calculateMaxShares(currentPrice: currentPrice)
        return [
            max / 4,      // 25% of max
            max / 2,      // 50% of max
            (max * 3) / 4,  // 75% of max
            max           // 100% of max
        ].filter { $0 > 0 }
    }
}

// MARK: - Order Book Entry

/// Simple order book entry for display
struct OrderBookEntry {
    let price: Decimal
    let size: Int
    let side: OrderSide
}

// MARK: - Trade Statistics

/// Statistics for a trading session
struct TradeStatistics {
    let totalOrders: Int
    let filledOrders: Int
    let cancelledOrders: Int
    let rejectedOrders: Int
    let totalVolume: Int
    let totalValue: Decimal
    let avgFillPrice: Decimal
    let successRate: Double

    static let empty = TradeStatistics(
        totalOrders: 0,
        filledOrders: 0,
        cancelledOrders: 0,
        rejectedOrders: 0,
        totalVolume: 0,
        totalValue: 0,
        avgFillPrice: 0,
        successRate: 0
    )

    var fillRate: Double {
        guard totalOrders > 0 else { return 0 }
        return Double(filledOrders) / Double(totalOrders)
    }
}
