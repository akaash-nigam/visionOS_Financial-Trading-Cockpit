//
//  AuthenticationService.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import Foundation

/// Manages user authentication with brokers
@Observable
class AuthenticationService {
    // MARK: - Properties

    private let keychainManager = KeychainManager.shared
    private var alpacaAdapter: AlpacaBrokerAdapter?

    var isAuthenticated: Bool = false
    var currentBroker: Broker?
    var currentAccount: Account?

    // MARK: - Authentication

    /// Authenticate with Alpaca using API keys
    func authenticateWithAlpaca(apiKey: String, secretKey: String, isPaperTrading: Bool = true) async throws {
        Logger.info("🔐 Authenticating with Alpaca (paper trading: \(isPaperTrading))")

        // Create adapter
        let adapter = AlpacaBrokerAdapter(apiKey: apiKey, secretKey: secretKey, isPaperTrading: isPaperTrading)

        // Validate credentials
        let isValid = try await adapter.validateCredentials()

        guard isValid else {
            throw AuthenticationError.invalidCredentials
        }

        // Fetch account info
        let alpacaAccount = try await adapter.getAccount()

        // Create auth token (for Alpaca, we store the API keys)
        let token = AuthToken(
            accessToken: apiKey,
            refreshToken: secretKey,  // Using secret key as "refresh token"
            expiresIn: 365 * 24 * 60 * 60,  // 1 year (API keys don't expire)
            tokenType: "API_KEY"
        )

        // Store in Keychain
        try keychainManager.storeAuthToken(token, for: .alpaca)

        // Create account object
        let account = Account(
            broker: .alpaca,
            accountNumber: alpacaAccount.accountNumber,
            accountType: isPaperTrading ? .cash : .margin,
            capabilities: AccountCapabilities(
                canTrade: !alpacaAccount.tradingBlocked,
                canTradeOptions: false,  // Alpaca doesn't support options
                canShortSell: true,
                canTradeFutures: false,
                canTradeCrypto: alpacaAccount.currency != "USD"  // Crypto if not USD
            )
        )

        // Update state
        self.alpacaAdapter = adapter
        self.currentBroker = .alpaca
        self.currentAccount = account
        self.isAuthenticated = true

        Logger.info("✅ Successfully authenticated with Alpaca")
    }

    /// Sign out and clear credentials
    func signOut() async throws {
        Logger.info("🔓 Signing out")

        if let broker = currentBroker {
            try keychainManager.deleteAuthToken(for: broker)
        }

        alpacaAdapter = nil
        currentBroker = nil
        currentAccount = nil
        isAuthenticated = false

        Logger.info("✅ Signed out successfully")
    }

    /// Check if user has valid stored credentials
    func checkStoredCredentials() async throws -> Bool {
        // Try to load Alpaca credentials from Keychain
        do {
            let token = try keychainManager.retrieveAuthToken(for: .alpaca)

            // Token represents API key/secret
            let apiKey = token.accessToken
            let secretKey = token.refreshToken ?? ""

            // Try to authenticate
            try await authenticateWithAlpaca(apiKey: apiKey, secretKey: secretKey)

            Logger.info("✅ Restored session from stored credentials")
            return true

        } catch KeychainManager.KeychainError.itemNotFound {
            Logger.debug("ℹ️ No stored credentials found")
            return false
        } catch {
            Logger.error("❌ Failed to restore session", error: error)
            throw error
        }
    }

    // MARK: - Broker Access

    func getAlpacaAdapter() -> AlpacaBrokerAdapter? {
        alpacaAdapter
    }
}

// MARK: - Error Types

enum AuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case authenticationFailed
    case tokenExpired
    case noStoredCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid API credentials"
        case .authenticationFailed:
            return "Authentication failed"
        case .tokenExpired:
            return "Authentication token expired"
        case .noStoredCredentials:
            return "No stored credentials found"
        }
    }
}
