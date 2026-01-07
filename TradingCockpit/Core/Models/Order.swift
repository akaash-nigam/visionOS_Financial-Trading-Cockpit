//
//  Order.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents a trading order
struct Order: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let action: OrderAction
    let quantity: Int
    let orderType: OrderType
    let timeInForce: TimeInForce
    let limitPrice: Decimal?
    let stopPrice: Decimal?
    var status: OrderStatus
    let createdAt: Date
    var updatedAt: Date

    // Order IDs
    let clientOrderId: String
    var brokerOrderId: String?

    // Execution details
    var filledQuantity: Int
    var averageFillPrice: Decimal?
    var commission: Decimal?

    init(
        id: UUID = UUID(),
        symbol: String,
        action: OrderAction,
        quantity: Int,
        orderType: OrderType,
        timeInForce: TimeInForce = .day,
        limitPrice: Decimal? = nil,
        stopPrice: Decimal? = nil,
        status: OrderStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        clientOrderId: String = UUID().uuidString,
        brokerOrderId: String? = nil,
        filledQuantity: Int = 0,
        averageFillPrice: Decimal? = nil,
        commission: Decimal? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.action = action
        self.quantity = quantity
        self.orderType = orderType
        self.timeInForce = timeInForce
        self.limitPrice = limitPrice
        self.stopPrice = stopPrice
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.clientOrderId = clientOrderId
        self.brokerOrderId = brokerOrderId
        self.filledQuantity = filledQuantity
        self.averageFillPrice = averageFillPrice
        self.commission = commission
    }
}

enum OrderAction: String, Codable {
    case buy = "BUY"
    case sell = "SELL"
    case sellShort = "SELL_SHORT"
    case buyToCover = "BUY_TO_COVER"
}

enum OrderType: String, Codable {
    case market = "MARKET"
    case limit = "LIMIT"
    case stop = "STOP"
    case stopLimit = "STOP_LIMIT"
}

enum TimeInForce: String, Codable {
    case day = "DAY"
    case gtc = "GTC"  // Good 'til canceled
    case ioc = "IOC"  // Immediate or cancel
    case fok = "FOK"  // Fill or kill
}

enum OrderStatus: String, Codable {
    case pending = "PENDING"
    case submitted = "SUBMITTED"
    case accepted = "ACCEPTED"
    case partiallyFilled = "PARTIALLY_FILLED"
    case filled = "FILLED"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"

    var isActive: Bool {
        switch self {
        case .pending, .submitted, .accepted, .partiallyFilled:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        !isActive
    }
}
