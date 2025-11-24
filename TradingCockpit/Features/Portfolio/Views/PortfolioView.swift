//
//  PortfolioView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import SwiftUI

struct PortfolioView: View {
    @StateObject private var tradingService: TradingService
    @State private var showOrderEntry: Bool = false
    @State private var selectedSymbol: String = ""

    init(tradingService: TradingService) {
        _tradingService = StateObject(wrappedValue: tradingService)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Summary
                    accountSummary

                    // Positions List
                    if !tradingService.positions.isEmpty {
                        positionsList
                    } else {
                        emptyPortfolio
                    }
                }
                .padding()
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showOrderEntry) {
                OrderEntryView(symbol: selectedSymbol, tradingService: tradingService)
            }
            .task {
                await refreshData()
            }
        }
    }

    // MARK: - Account Summary

    private var accountSummary: some View {
        VStack(spacing: 16) {
            Text("Account Value")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let balance = tradingService.accountBalance {
                Text("$\(formatPrice(balance.equity))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                HStack(spacing: 24) {
                    StatBox(
                        label: "Cash",
                        value: "$\(formatPrice(balance.cash))",
                        color: .blue
                    )

                    StatBox(
                        label: "Portfolio",
                        value: "$\(formatPrice(balance.portfolioValue))",
                        color: .purple
                    )

                    StatBox(
                        label: "Buying Power",
                        value: "$\(formatPrice(balance.buyingPower))",
                        color: .green
                    )
                }

                // Total P&L
                let totalPnL = tradingService.positions.reduce(Decimal(0)) { $0 + $1.unrealizedPnL }
                let totalPnLPercent = tradingService.positions.reduce(Decimal(0)) { $0 + $1.unrealizedPnLPercent } / Decimal(max(tradingService.positions.count, 1))

                HStack(spacing: 8) {
                    Image(systemName: totalPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("$\(formatPrice(abs(totalPnL)))")
                    Text("(\(totalPnL >= 0 ? "+" : "")\(formatPercent(totalPnLPercent))%)")
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(totalPnL >= 0 ? .green : .red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }

    // MARK: - Positions List

    private var positionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Positions")
                .font(.headline)

            ForEach(tradingService.positions) { position in
                PositionRow(position: position) {
                    selectedSymbol = position.symbol
                    showOrderEntry = true
                }
            }
        }
    }

    // MARK: - Empty Portfolio

    private var emptyPortfolio: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Positions")
                .font(.headline)

            Text("Start trading to build your portfolio")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showOrderEntry = true
            } label: {
                Text("Place Order")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Methods

    private func refreshData() async {
        await tradingService.refreshAccount()
        await tradingService.refreshPositions()
    }

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatPercent(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }
}

// MARK: - Position Row

struct PositionRow: View {
    let position: Position
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Symbol and quantity
                    HStack(spacing: 8) {
                        Text(position.symbol)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("\(position.quantity) shares")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Price info
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("$\(formatPrice(position.currentPrice))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg Cost")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("$\(formatPrice(position.averagePrice))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Value")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("$\(formatPrice(position.marketValue))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Spacer()

                // P&L
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: position.unrealizedPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("$\(formatPrice(abs(position.unrealizedPnL)))")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(position.unrealizedPnL >= 0 ? .green : .red)

                    Text("\(position.unrealizedPnL >= 0 ? "+" : "")\(formatPercent(position.unrealizedPnLPercent))%")
                        .font(.caption)
                        .foregroundStyle(position.unrealizedPnL >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatPercent(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let service = TradingService()
    service.accountBalance = AccountBalance(
        cash: 50000,
        portfolioValue: 48000,
        buyingPower: 100000,
        equity: 98000
    )
    service.positions = [
        Position(
            symbol: "AAPL",
            quantity: 50,
            averagePrice: 150.00,
            currentPrice: 175.50
        ),
        Position(
            symbol: "GOOGL",
            quantity: 20,
            averagePrice: 140.00,
            currentPrice: 135.25
        )
    ]

    return PortfolioView(tradingService: service)
}
