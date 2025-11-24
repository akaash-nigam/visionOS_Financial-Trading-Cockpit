//
//  WatchlistService.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 5: Watchlist & Search
//

import Foundation
import Combine

/// Service for managing watchlists and symbol search
@Observable
class WatchlistService {
    // MARK: - Properties

    private let database: DatabaseManager
    private let marketDataHub: MarketDataHub?

    // Observable state
    var watchlists: [Watchlist] = []
    var currentWatchlist: Watchlist?
    var watchlistItems: [WatchlistItem] = []
    var isLoading: Bool = false
    var searchResults: [SymbolSearchResult] = []

    // MARK: - Initialization

    init(database: DatabaseManager = .shared, marketDataHub: MarketDataHub? = nil) {
        self.database = database
        self.marketDataHub = marketDataHub
        Logger.info("📋 Watchlist Service initialized")
    }

    // MARK: - Watchlist Management

    /// Load all watchlists
    func loadWatchlists() async {
        isLoading = true
        defer { isLoading = false }

        // For MVP, use in-memory watchlists
        // TODO: Load from database
        await MainActor.run {
            watchlists = [.default, .tech, .growth]
            currentWatchlist = watchlists.first
        }

        await loadWatchlistItems()
        Logger.debug("📋 Loaded \(watchlists.count) watchlists")
    }

    /// Create new watchlist
    func createWatchlist(name: String) async {
        let watchlist = Watchlist(name: name)

        await MainActor.run {
            watchlists.append(watchlist)
        }

        // TODO: Save to database
        Logger.info("✅ Created watchlist: \(name)")
    }

    /// Delete watchlist
    func deleteWatchlist(_ watchlist: Watchlist) async {
        guard !watchlist.isDefault else {
            Logger.warning("⚠️ Cannot delete default watchlist")
            return
        }

        await MainActor.run {
            watchlists.removeAll { $0.id == watchlist.id }
            if currentWatchlist?.id == watchlist.id {
                currentWatchlist = watchlists.first
            }
        }

        // TODO: Delete from database
        Logger.info("🗑️ Deleted watchlist: \(watchlist.name)")
    }

    /// Select watchlist
    func selectWatchlist(_ watchlist: Watchlist) async {
        await MainActor.run {
            currentWatchlist = watchlist
        }

        await loadWatchlistItems()
        Logger.debug("📋 Selected watchlist: \(watchlist.name)")
    }

    // MARK: - Symbol Management

    /// Add symbol to current watchlist
    func addSymbol(_ symbol: String) async {
        guard var watchlist = currentWatchlist else { return }

        watchlist.add(symbol)

        await MainActor.run {
            if let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) {
                watchlists[index] = watchlist
                currentWatchlist = watchlist
            }
        }

        await loadWatchlistItems()

        // TODO: Save to database
        Logger.info("✅ Added \(symbol) to watchlist")
    }

    /// Remove symbol from current watchlist
    func removeSymbol(_ symbol: String) async {
        guard var watchlist = currentWatchlist else { return }

        watchlist.remove(symbol)

        await MainActor.run {
            if let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) {
                watchlists[index] = watchlist
                currentWatchlist = watchlist
            }
        }

        await loadWatchlistItems()

        // TODO: Save to database
        Logger.info("🗑️ Removed \(symbol) from watchlist")
    }

    /// Check if symbol is in current watchlist
    func isInWatchlist(_ symbol: String) -> Bool {
        currentWatchlist?.contains(symbol) ?? false
    }

    // MARK: - Watchlist Items

    /// Load watchlist items with quotes
    func loadWatchlistItems() async {
        guard let watchlist = currentWatchlist else {
            await MainActor.run {
                watchlistItems = []
            }
            return
        }

        let items = watchlist.symbols.map { symbol in
            WatchlistItem(
                id: symbol,
                symbol: symbol,
                quote: generateMockQuote(for: symbol),
                inWatchlist: true
            )
        }

        await MainActor.run {
            watchlistItems = items
        }
    }

    /// Refresh quotes for watchlist items
    func refreshQuotes() async {
        await loadWatchlistItems()
        Logger.debug("🔄 Refreshed watchlist quotes")
    }

    // MARK: - Symbol Search

    /// Search for symbols
    func searchSymbols(_ query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }

        // Simulate search delay
        try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

        // For MVP, filter mock results
        let results = SymbolSearchResult.mockResults.filter { result in
            result.symbol.lowercased().contains(query.lowercased()) ||
            result.name.lowercased().contains(query.lowercased())
        }

        await MainActor.run {
            searchResults = results
        }

        Logger.debug("🔍 Found \(results.count) results for '\(query)'")
    }

    /// Clear search results
    func clearSearch() {
        searchResults = []
    }

    // MARK: - Private Helpers

    private func generateMockQuote(for symbol: String) -> Quote {
        // Use consistent mock data based on symbol
        return Quote.mock(symbol: symbol)
    }

    private func saveWatchlistToDatabase(_ watchlist: Watchlist) async throws {
        // TODO: Implement database save
        Logger.debug("💾 Saving watchlist to database: \(watchlist.name)")
    }

    private func loadWatchlistsFromDatabase() async throws -> [Watchlist] {
        // TODO: Implement database load
        Logger.debug("💾 Loading watchlists from database")
        return []
    }
}

// MARK: - Watchlist Statistics

extension WatchlistService {
    /// Get statistics for current watchlist
    func getWatchlistStatistics() -> WatchlistStatistics {
        guard !watchlistItems.isEmpty else {
            return .empty
        }

        let gainers = watchlistItems.filter { ($0.priceChange ?? 0) > 0 }.count
        let losers = watchlistItems.filter { ($0.priceChange ?? 0) < 0 }.count
        let unchanged = watchlistItems.filter { ($0.priceChange ?? 0) == 0 }.count

        let avgChange = watchlistItems.compactMap { $0.priceChangePercent }.reduce(0, +) / Decimal(watchlistItems.count)

        return WatchlistStatistics(
            totalSymbols: watchlistItems.count,
            gainers: gainers,
            losers: losers,
            unchanged: unchanged,
            avgChangePercent: avgChange
        )
    }
}

// MARK: - Watchlist Statistics

struct WatchlistStatistics {
    let totalSymbols: Int
    let gainers: Int
    let losers: Int
    let unchanged: Int
    let avgChangePercent: Decimal

    static let empty = WatchlistStatistics(
        totalSymbols: 0,
        gainers: 0,
        losers: 0,
        unchanged: 0,
        avgChangePercent: 0
    )

    var gainersPercent: Double {
        guard totalSymbols > 0 else { return 0 }
        return Double(gainers) / Double(totalSymbols) * 100
    }

    var losersPercent: Double {
        guard totalSymbols > 0 else { return 0 }
        return Double(losers) / Double(totalSymbols) * 100
    }
}
