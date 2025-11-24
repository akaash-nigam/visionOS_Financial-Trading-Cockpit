//
//  Position.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents an open position in a security
struct Position: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let quantity: Int
    let averagePrice: Decimal
    var currentPrice: Decimal
    var updatedAt: Date

    // Calculated fields
    var marketValue: Decimal {
        currentPrice * Decimal(quantity)
    }

    var costBasis: Decimal {
        averagePrice * Decimal(quantity)
    }

    var unrealizedPnL: Decimal {
        marketValue - costBasis
    }

    var unrealizedPnLPercent: Decimal {
        guard costBasis > 0 else { return 0 }
        return (unrealizedPnL / costBasis) * 100
    }

    var isLong: Bool { quantity > 0 }
    var isShort: Bool { quantity < 0 }

    init(
        id: UUID = UUID(),
        symbol: String,
        quantity: Int,
        averagePrice: Decimal,
        currentPrice: Decimal,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.currentPrice = currentPrice
        self.updatedAt = updatedAt
    }
}

/// Portfolio summary
struct Portfolio: Codable {
    let accountId: String
    var positions: [Position]
    let balance: AccountBalance

    // Calculated fields
    var totalValue: Decimal {
        balance.portfolioValue
    }

    var totalUnrealizedPnL: Decimal {
        positions.reduce(0) { $0 + $1.unrealizedPnL }
    }

    var positionCount: Int {
        positions.count
    }

    init(
        accountId: String,
        positions: [Position] = [],
        balance: AccountBalance
    ) {
        self.accountId = accountId
        self.positions = positions
        self.balance = balance
    }
}
