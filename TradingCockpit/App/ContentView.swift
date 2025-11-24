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

// MARK: - Main View (Placeholder for Sprint 3)

struct MainView: View {
    let marketDataHub: MarketDataHub?
    @Environment(AppState.self) private var appState
    @State private var authService = AuthenticationService()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Text("🚀 Financial Trading Cockpit")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sprint 2: Market Data Pipeline Complete")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Spacer()

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
                    status: "Coming in Sprint 3",
                    icon: "cube.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)

            Spacer()

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
