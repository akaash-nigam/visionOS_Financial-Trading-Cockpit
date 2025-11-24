//
//  AlpacaBrokerAdapter.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import Foundation

/// Alpaca broker API adapter for paper and live trading
class AlpacaBrokerAdapter {
    // MARK: - Properties

    private let baseURL: URL
    private let apiKey: String
    private let secretKey: String
    private let session: URLSession

    // MARK: - Initialization

    init(apiKey: String, secretKey: String, isPaperTrading: Bool = true) {
        self.apiKey = apiKey
        self.secretKey = secretKey

        // Use paper trading endpoint by default for safety
        if isPaperTrading {
            self.baseURL = URL(string: "https://paper-api.alpaca.markets")!
        } else {
            self.baseURL = URL(string: "https://api.alpaca.markets")!
        }

        // Configure session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)

        Logger.info("🏦 Alpaca broker adapter initialized (paper trading: \(isPaperTrading))")
    }

    // MARK: - Authentication

    func validateCredentials() async throws -> Bool {
        // Test credentials by fetching account info
        do {
            let _ = try await getAccount()
            Logger.info("✅ Alpaca credentials validated successfully")
            return true
        } catch {
            Logger.error("❌ Alpaca credentials validation failed", error: error)
            throw error
        }
    }

    // MARK: - Account Information

    func getAccount() async throws -> AlpacaAccount {
        let endpoint = baseURL.appendingPathComponent("/v2/account")

        var request = URLRequest(url: endpoint)
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        Logger.debug("✅ Fetched Alpaca account info")

        return account
    }

    func getPositions() async throws -> [AlpacaPosition] {
        let endpoint = baseURL.appendingPathComponent("/v2/positions")

        var request = URLRequest(url: endpoint)
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        let positions = try JSONDecoder().decode([AlpacaPosition].self, from: data)
        Logger.debug("✅ Fetched \(positions.count) positions from Alpaca")

        return positions
    }

    // MARK: - Order Management

    func submitOrder(_ orderRequest: AlpacaOrderRequest) async throws -> AlpacaOrder {
        let endpoint = baseURL.appendingPathComponent("/v2/orders")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(orderRequest)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(AlpacaErrorResponse.self, from: data) {
                throw AlpacaError.orderRejected(errorResponse.message)
            }
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let order = try decoder.decode(AlpacaOrder.self, from: data)

        Logger.info("✅ Order submitted successfully: \(order.id)")

        return order
    }

    func cancelOrder(orderId: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/v2/orders/\(orderId)")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 204 else {
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        Logger.info("✅ Order cancelled: \(orderId)")
    }

    func getOrder(orderId: String) async throws -> AlpacaOrder {
        let endpoint = baseURL.appendingPathComponent("/v2/orders/\(orderId)")

        var request = URLRequest(url: endpoint)
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let order = try decoder.decode(AlpacaOrder.self, from: data)

        return order
    }

    func getOpenOrders() async throws -> [AlpacaOrder] {
        let endpoint = baseURL.appendingPathComponent("/v2/orders")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "status", value: "open")]

        var request = URLRequest(url: components.url!)
        request.addAuthHeaders(apiKey: apiKey, secretKey: secretKey)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AlpacaError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let orders = try decoder.decode([AlpacaOrder].self, from: data)

        Logger.debug("✅ Fetched \(orders.count) open orders")

        return orders
    }
}

// MARK: - Alpaca Models

struct AlpacaAccount: Codable {
    let id: String
    let accountNumber: String
    let status: String
    let currency: String
    let cash: String
    let buyingPower: String
    let portfolioValue: String
    let equity: String
    let lastEquity: String
    let daytradeCount: Int
    let tradingBlocked: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case accountNumber = "account_number"
        case status
        case currency
        case cash
        case buyingPower = "buying_power"
        case portfolioValue = "portfolio_value"
        case equity
        case lastEquity = "last_equity"
        case daytradeCount = "daytrade_count"
        case tradingBlocked = "trading_blocked"
    }
}

struct AlpacaPosition: Codable {
    let symbol: String
    let qty: String
    let avgEntryPrice: String
    let currentPrice: String
    let marketValue: String
    let costBasis: String
    let unrealizedPl: String
    let unrealizedPlpc: String
    let side: String

    private enum CodingKeys: String, CodingKey {
        case symbol
        case qty
        case avgEntryPrice = "avg_entry_price"
        case currentPrice = "current_price"
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case unrealizedPl = "unrealized_pl"
        case unrealizedPlpc = "unrealized_plpc"
        case side
    }
}

struct AlpacaOrderRequest: Codable {
    let symbol: String
    let qty: Int
    let side: String  // "buy" or "sell"
    let type: String  // "market", "limit", etc.
    let timeInForce: String  // "day", "gtc", etc.
    let limitPrice: String?  // Required for limit orders
    let stopPrice: String?   // Required for stop orders
    let clientOrderId: String?

    init(
        symbol: String,
        qty: Int,
        side: String,
        type: String,
        timeInForce: String = "day",
        limitPrice: String? = nil,
        stopPrice: String? = nil,
        clientOrderId: String? = nil
    ) {
        self.symbol = symbol
        self.qty = qty
        self.side = side
        self.type = type
        self.timeInForce = timeInForce
        self.limitPrice = limitPrice
        self.stopPrice = stopPrice
        self.clientOrderId = clientOrderId
    }
}

struct AlpacaOrder: Codable {
    let id: String
    let clientOrderId: String
    let symbol: String
    let qty: String
    let side: String
    let type: String
    let timeInForce: String
    let limitPrice: String?
    let stopPrice: String?
    let status: String
    let filledQty: String
    let filledAvgPrice: String?
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case qty
        case side
        case type
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case status
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AlpacaErrorResponse: Codable {
    let code: Int
    let message: String
}

// MARK: - Error Types

enum AlpacaError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case orderRejected(String)
    case invalidCredentials
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Alpaca API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .orderRejected(let message):
            return "Order rejected: \(message)"
        case .invalidCredentials:
            return "Invalid Alpaca API credentials"
        case .rateLimited:
            return "Alpaca API rate limit exceeded"
        }
    }
}

// MARK: - URLRequest Extension

extension URLRequest {
    mutating func addAuthHeaders(apiKey: String, secretKey: String) {
        addValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        addValue(secretKey, forHTTPHeaderField: "APCA-API-SECRET-KEY")
    }
}

// MARK: - Factory

extension AlpacaBrokerAdapter {
    /// Create adapter with credentials from environment
    static func createWithEnvironmentKeys() -> AlpacaBrokerAdapter? {
        guard let apiKey = ProcessInfo.processInfo.environment["ALPACA_API_KEY"],
              let secretKey = ProcessInfo.processInfo.environment["ALPACA_SECRET_KEY"] else {
            Logger.warning("⚠️ Alpaca credentials not found in environment")
            return nil
        }

        return AlpacaBrokerAdapter(apiKey: apiKey, secretKey: secretKey, isPaperTrading: true)
    }
}
