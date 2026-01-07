//
//  WatchlistView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 5: Watchlist & Search
//

import SwiftUI

struct WatchlistView: View {
    @StateObject private var watchlistService: WatchlistService
    @StateObject private var tradingService: TradingService
    @State private var showAddSymbol: Bool = false
    @State private var showManageWatchlists: Bool = false
    @State private var selectedSymbol: String?
    @State private var showOrderEntry: Bool = false

    init(watchlistService: WatchlistService, tradingService: TradingService) {
        _watchlistService = StateObject(wrappedValue: watchlistService)
        _tradingService = StateObject(wrappedValue: tradingService)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Watchlist selector
                watchlistSelector

                // Statistics bar
                if let stats = watchlistService.currentWatchlist {
                    statisticsBar
                }

                // Symbol list
                symbolList
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddSymbol = true
                        } label: {
                            Label("Add Symbol", systemImage: "plus")
                        }

                        Button {
                            showManageWatchlists = true
                        } label: {
                            Label("Manage Watchlists", systemImage: "folder")
                        }

                        Button {
                            Task {
                                await watchlistService.refreshQuotes()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddSymbol) {
                SymbolSearchView(watchlistService: watchlistService)
            }
            .sheet(isPresented: $showManageWatchlists) {
                WatchlistManagerView(watchlistService: watchlistService)
            }
            .sheet(isPresented: $showOrderEntry) {
                if let symbol = selectedSymbol {
                    OrderEntryView(symbol: symbol, tradingService: tradingService)
                }
            }
            .task {
                await watchlistService.loadWatchlists()
            }
        }
    }

    // MARK: - Watchlist Selector

    private var watchlistSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(watchlistService.watchlists) { watchlist in
                    WatchlistTab(
                        watchlist: watchlist,
                        isSelected: watchlist.id == watchlistService.currentWatchlist?.id
                    ) {
                        Task {
                            await watchlistService.selectWatchlist(watchlist)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }

    // MARK: - Statistics Bar

    private var statisticsBar: some View {
        let stats = watchlistService.getWatchlistStatistics()

        return HStack(spacing: 20) {
            StatItem(label: "Symbols", value: "\(stats.totalSymbols)", color: .blue)
            StatItem(label: "Gainers", value: "\(stats.gainers)", color: .green)
            StatItem(label: "Losers", value: "\(stats.losers)", color: .red)
            StatItem(
                label: "Avg Change",
                value: "\(stats.avgChangePercent >= 0 ? "+" : "")\(formatPercent(stats.avgChangePercent))%",
                color: stats.avgChangePercent >= 0 ? .green : .red
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }

    // MARK: - Symbol List

    private var symbolList: some View {
        Group {
            if watchlistService.watchlistItems.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(watchlistService.watchlistItems) { item in
                        WatchlistItemRow(item: item) {
                            selectedSymbol = item.symbol
                            showOrderEntry = true
                        } onRemove: {
                            Task {
                                await watchlistService.removeSymbol(item.symbol)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Symbols in Watchlist")
                .font(.headline)

            Text("Add symbols to track their performance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showAddSymbol = true
            } label: {
                Text("Add Symbols")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatPercent(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }
}

// MARK: - Watchlist Tab

struct WatchlistTab: View {
    let watchlist: Watchlist
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(watchlist.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)

                Text("\(watchlist.count) symbols")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Watchlist Item Row

struct WatchlistItemRow: View {
    let item: WatchlistItem
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Symbol
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.symbol)
                        .font(.headline)
                        .fontWeight(.bold)

                    if let quote = item.quote {
                        Text("Vol: \(formatVolume(quote.volume))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Price info
                if let quote = item.quote {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(formatPrice(quote.last))")
                            .font(.headline)

                        HStack(spacing: 4) {
                            Image(systemName: item.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text("\(item.isPositive ? "+" : "")\(formatPercent(quote.changePercent))%")
                                .font(.caption)
                        }
                        .foregroundStyle(item.isPositive ? .green : .red)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatPercent(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatVolume(_ value: Int64) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }
}

#Preview {
    let watchlistService = WatchlistService()
    let tradingService = TradingService()

    return WatchlistView(watchlistService: watchlistService, tradingService: tradingService)
}
