//
//  Security.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents a tradable security (stock, ETF, etc.)
struct Security: Identifiable, Codable, Hashable {
    let id: UUID
    let symbol: String
    let name: String
    let type: SecurityType
    let exchange: Exchange
    let currency: Currency
    let sector: Sector?
    let industry: String?

    var displaySymbol: String {
        "\(exchange.rawValue):\(symbol)"
    }

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        type: SecurityType,
        exchange: Exchange,
        currency: Currency = .usd,
        sector: Sector? = nil,
        industry: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.type = type
        self.exchange = exchange
        self.currency = currency
        self.sector = sector
        self.industry = industry
    }
}

enum SecurityType: String, Codable {
    case stock = "Stock"
    case etf = "ETF"
    case index = "Index"
}

enum Exchange: String, Codable {
    case nasdaq = "NASDAQ"
    case nyse = "NYSE"
    case amex = "AMEX"
}

enum Currency: String, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
}

enum Sector: String, Codable, CaseIterable {
    case technology = "Technology"
    case healthcare = "Healthcare"
    case financial = "Financial"
    case consumer = "Consumer"
    case industrial = "Industrial"
    case energy = "Energy"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case materials = "Materials"
    case communication = "Communication"
}
