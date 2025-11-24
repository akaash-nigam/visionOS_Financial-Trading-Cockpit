//
//  AppState.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation
import Observation

/// Global application state
@Observable
class AppState {
    // MARK: - Authentication

    var isAuthenticated: Bool = false
    var currentBroker: Broker = .alpaca

    // MARK: - User Session

    var currentUser: User?
    var selectedAccount: Account?

    // MARK: - UI State

    var selectedSecurities: Set<String> = []
    var activeFocusMode: FocusMode = .overview
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Market Data

    var isMarketDataConnected: Bool = false
    var lastDataUpdate: Date?

    // MARK: - Methods

    func reset() {
        isAuthenticated = false
        currentUser = nil
        selectedAccount = nil
        selectedSecurities.removeAll()
        activeFocusMode = .overview
        isLoading = false
        errorMessage = nil
        isMarketDataConnected = false
        lastDataUpdate = nil
    }
}

// MARK: - Supporting Types

enum FocusMode: String {
    case overview = "Overview"
    case trading = "Trading"
    case portfolio = "Portfolio"
}

enum Broker: String, Codable {
    case alpaca = "Alpaca"
    case interactiveBrokers = "Interactive Brokers"
    case tdAmeritrade = "TD Ameritrade"
    case etrade = "E*TRADE"
}
