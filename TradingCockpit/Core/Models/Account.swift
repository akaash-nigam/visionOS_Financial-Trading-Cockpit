//
//  Account.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents a brokerage account
struct Account: Identifiable, Codable {
    let id: UUID
    let broker: Broker
    let accountNumber: String
    let accountType: AccountType
    var status: AccountStatus
    let capabilities: AccountCapabilities
    let connectedAt: Date

    init(
        id: UUID = UUID(),
        broker: Broker,
        accountNumber: String,
        accountType: AccountType,
        status: AccountStatus = .active,
        capabilities: AccountCapabilities,
        connectedAt: Date = Date()
    ) {
        self.id = id
        self.broker = broker
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.status = status
        self.capabilities = capabilities
        self.connectedAt = connectedAt
    }
}

enum AccountType: String, Codable {
    case cash = "Cash"
    case margin = "Margin"
    case portfolio = "Portfolio Margin"
}

enum AccountStatus: String, Codable {
    case active = "Active"
    case restricted = "Restricted"
    case closed = "Closed"
}

struct AccountCapabilities: Codable {
    let canTrade: Bool
    let canTradeOptions: Bool
    let canShortSell: Bool
    let canTradeFutures: Bool
    let canTradeCrypto: Bool
    let maxOptionsLevel: Int

    init(
        canTrade: Bool = true,
        canTradeOptions: Bool = false,
        canShortSell: Bool = false,
        canTradeFutures: Bool = false,
        canTradeCrypto: Bool = false,
        maxOptionsLevel: Int = 0
    ) {
        self.canTrade = canTrade
        self.canTradeOptions = canTradeOptions
        self.canShortSell = canShortSell
        self.canTradeFutures = canTradeFutures
        self.canTradeCrypto = canTradeCrypto
        self.maxOptionsLevel = maxOptionsLevel
    }
}

// MARK: - Account Balance

struct AccountBalance: Codable {
    let cash: Decimal
    let buyingPower: Decimal
    let equity: Decimal
    let portfolioValue: Decimal

    var marginUsed: Decimal {
        equity - cash
    }

    init(
        cash: Decimal,
        buyingPower: Decimal,
        equity: Decimal,
        portfolioValue: Decimal
    ) {
        self.cash = cash
        self.buyingPower = buyingPower
        self.equity = equity
        self.portfolioValue = portfolioValue
    }
}
