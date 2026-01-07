//
//  AuthenticationView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(AppState.self) private var appState
    @State private var authService = AuthenticationService()

    @State private var apiKey: String = ""
    @State private var secretKey: String = ""
    @State private var isPaperTrading: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Financial Trading Cockpit")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Connect your Alpaca account to start trading")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)

            // API Key Form
            VStack(alignment: .leading, spacing: 16) {
                // API Key
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)

                    TextField("Enter your Alpaca API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                // Secret Key
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secret Key")
                        .font(.headline)

                    SecureField("Enter your secret key", text: $secretKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }

                // Paper Trading Toggle
                Toggle("Paper Trading (Recommended)", isOn: $isPaperTrading)
                    .font(.subheadline)
                    .tint(.blue)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 500)

            // Sign In Button
            Button {
                Task {
                    await signIn()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.shield")
                        Text("Sign In with Alpaca")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 400)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || isLoading)

            // Help Text
            VStack(spacing: 8) {
                Text("Don't have an Alpaca account?")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("Create free paper trading account →", destination: URL(string: "https://alpaca.markets/")!)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(.top, 10)

            // Security Note
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("Your credentials are stored securely in Keychain")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("We never store or transmit your credentials")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 20)
        }
        .padding()
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .task {
            await checkStoredCredentials()
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !apiKey.isEmpty && !secretKey.isEmpty
    }

    // MARK: - Methods

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.authenticateWithAlpaca(
                apiKey: apiKey.trimmingCharacters(in: .whitespaces),
                secretKey: secretKey.trimmingCharacters(in: .whitespaces),
                isPaperTrading: isPaperTrading
            )

            // Update app state
            await MainActor.run {
                appState.isAuthenticated = true
                appState.currentBroker = .alpaca
                Logger.info("✅ User authenticated successfully")
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
            Logger.error("❌ Authentication failed", error: error)
        }
    }

    private func checkStoredCredentials() async {
        do {
            let hasCredentials = try await authService.checkStoredCredentials()

            if hasCredentials {
                await MainActor.run {
                    appState.isAuthenticated = true
                    appState.currentBroker = .alpaca
                    Logger.info("✅ Restored previous session")
                }
            }
        } catch {
            Logger.debug("ℹ️ No stored credentials or validation failed")
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AppState())
}
