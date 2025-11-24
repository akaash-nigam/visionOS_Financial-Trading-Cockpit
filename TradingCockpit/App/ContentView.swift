//
//  ContentView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainView()
            } else {
                AuthenticationView()
            }
        }
    }
}

// MARK: - Main View (Placeholder)

struct MainView: View {
    var body: some View {
        VStack {
            Text("🚀 Financial Trading Cockpit")
                .font(.largeTitle)
                .padding()

            Text("3D Market Visualization")
                .font(.title2)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Ready to trade!")
                .font(.headline)
                .foregroundStyle(.green)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Authentication View (Placeholder)

struct AuthenticationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Financial Trading Cockpit")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Connect your brokerage account to start trading")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                // TODO: Implement authentication
                Logger.info("🔐 Sign In button tapped")
                // For now, just set authenticated to true for testing
                appState.isAuthenticated = true
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Sign In with Alpaca")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }

            Text("Paper trading mode available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
