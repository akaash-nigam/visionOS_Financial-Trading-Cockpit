//
//  TradingCockpitApp.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Copyright © 2025 Trading Cockpit. All rights reserved.
//

import SwiftUI

@main
struct TradingCockpitApp: App {
    // MARK: - Properties

    @State private var appState = AppState()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    await initializeApp()
                }
        }
        .windowStyle(.volumetric)
    }

    // MARK: - Private Methods

    private func initializeApp() async {
        Logger.info("🚀 Trading Cockpit launching...")

        // Initialize core services
        await setupLogging()
        await setupDatabase()
        await checkAuthentication()

        Logger.info("✅ Trading Cockpit initialized successfully")
    }

    private func setupLogging() async {
        Logger.configure(level: .info)
    }

    private func setupDatabase() async {
        do {
            try await DatabaseManager.shared.initialize()
            Logger.info("✅ Database initialized")
        } catch {
            Logger.error("❌ Failed to initialize database", error: error)
        }
    }

    private func checkAuthentication() async {
        // Check if user is already authenticated
        if let token = try? KeychainManager.shared.retrieveAuthToken(for: .alpaca) {
            Logger.info("✅ Found existing auth token")
            appState.isAuthenticated = true
        } else {
            Logger.info("ℹ️ No auth token found, user needs to sign in")
            appState.isAuthenticated = false
        }
    }
}
