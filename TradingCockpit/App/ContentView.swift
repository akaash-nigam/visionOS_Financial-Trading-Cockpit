//
//  ContentView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var marketDataHub: MarketDataHub?

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainView(marketDataHub: marketDataHub)
            } else {
                AuthenticationView()
            }
        }
        .task {
            await setupMarketData()
        }
    }

    private func setupMarketData() async {
        // Initialize market data hub (will be used in Sprint 3)
        // For now, create with test provider
        marketDataHub = MarketDataHub.createForTesting()
        Logger.debug("📊 Market Data Hub created")
    }
}

// MARK: - Main View

struct MainView: View {
    let marketDataHub: MarketDataHub?
    @Environment(AppState.self) private var appState
    @State private var authService = AuthenticationService()
    @State private var tradingService: TradingService?
    @State private var watchlistService: WatchlistService?
    @State private var showOrderEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Text("🚀 Financial Trading Cockpit")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sprint 5: Watchlist & Search Complete")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    // Status Cards
                    VStack(spacing: 16) {
                        StatusCard(
                            title: "Authentication",
                            status: "Connected",
                            icon: "checkmark.shield.fill",
                            color: .green
                        )

                        StatusCard(
                            title: "Market Data",
                            status: "Ready",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )

                        StatusCard(
                            title: "3D Visualization",
                            status: "Ready",
                            icon: "cube.fill",
                            color: .green
                        )

                        StatusCard(
                            title: "Trading",
                            status: "Ready",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Main Actions
                    VStack(spacing: 12) {
                        // Visualization Button
                        NavigationLink(destination: MarketVisualizationView()) {
                            ActionButton(
                                title: "3D Visualization",
                                icon: "cube.fill",
                                gradient: [.blue, .purple]
                            )
                        }

                        // Watchlist Button
                        if let watchlist = watchlistService, let trading = tradingService {
                            NavigationLink(destination: WatchlistView(watchlistService: watchlist, tradingService: trading)) {
                                ActionButton(
                                    title: "Watchlist",
                                    icon: "star.fill",
                                    gradient: [.yellow, .orange]
                                )
                            }
                        }

                        // Portfolio Button
                        if let service = tradingService {
                            NavigationLink(destination: PortfolioView(tradingService: service)) {
                                ActionButton(
                                    title: "Portfolio",
                                    icon: "chart.pie.fill",
                                    gradient: [.purple, .pink]
                                )
                            }

                            // Orders Button
                            NavigationLink(destination: OrderStatusView(tradingService: service)) {
                                ActionButton(
                                    title: "Orders",
                                    icon: "list.bullet.rectangle.fill",
                                    gradient: [.orange, .red]
                                )
                            }

                            // Quick Trade Button
                            Button {
                                showOrderEntry = true
                            } label: {
                                ActionButton(
                                    title: "Place Order",
                                    icon: "plus.circle.fill",
                                    gradient: [.green, .cyan]
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Sign Out Button
                    Button {
                        Task {
                            try? await authService.signOut()
                            appState.isAuthenticated = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .sheet(isPresented: $showOrderEntry) {
            if let service = tradingService {
                OrderEntryView(symbol: "AAPL", tradingService: service)
            }
        }
        .task {
            await initializeTradingService()
        }
    }

    private func initializeTradingService() async {
        // In production, get broker adapter from auth service
        // For now, create without adapter for UI testing
        tradingService = TradingService()
        watchlistService = WatchlistService(marketDataHub: marketDataHub)
        Logger.info("💼 Trading service initialized")
        Logger.info("📋 Watchlist service initialized")
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let status: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
