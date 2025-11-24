//
//  SymbolSearchView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 5: Watchlist & Search
//

import SwiftUI

struct SymbolSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchlistService: WatchlistService
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false

    init(watchlistService: WatchlistService) {
        _watchlistService = StateObject(wrappedValue: watchlistService)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Search results
                if isSearching {
                    searchingIndicator
                } else if searchQuery.isEmpty {
                    searchPrompt
                } else if watchlistService.searchResults.isEmpty {
                    noResults
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Add Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                Task {
                    await performSearch(newValue)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search symbols or companies", text: $searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    watchlistService.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }

    // MARK: - Search States

    private var searchingIndicator: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Search for Symbols")
                .font(.headline)

            Text("Enter a stock symbol or company name")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Popular symbols
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA"], id: \.self) { symbol in
                            Button {
                                searchQuery = symbol
                            } label: {
                                Text(symbol)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var noResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Results Found")
                .font(.headline)

            Text("Try searching for a different symbol or company name")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        List {
            ForEach(watchlistService.searchResults) { result in
                SearchResultRow(
                    result: result,
                    inWatchlist: watchlistService.isInWatchlist(result.symbol)
                ) {
                    Task {
                        await addToWatchlist(result.symbol)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Methods

    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            isSearching = false
            return
        }

        isSearching = true
        await watchlistService.searchSymbols(query)
        isSearching = false
    }

    private func addToWatchlist(_ symbol: String) async {
        await watchlistService.addSymbol(symbol)
        // Optionally dismiss after adding
        // dismiss()
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SymbolSearchResult
    let inWatchlist: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(result.symbol)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(result.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(result.exchangeInfo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if inWatchlist {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Added")
                }
                .font(.caption)
                .foregroundStyle(.green)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Watchlist Manager View

struct WatchlistManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchlistService: WatchlistService
    @State private var showCreateWatchlist: Bool = false
    @State private var newWatchlistName: String = ""

    init(watchlistService: WatchlistService) {
        _watchlistService = StateObject(wrappedValue: watchlistService)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(watchlistService.watchlists) { watchlist in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(watchlist.name)
                                .font(.headline)

                            Text("\(watchlist.count) symbols")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if watchlist.isDefault {
                            Text("Default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let watchlist = watchlistService.watchlists[index]
                        Task {
                            await watchlistService.deleteWatchlist(watchlist)
                        }
                    }
                }
            }
            .navigationTitle("Manage Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateWatchlist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Watchlist", isPresented: $showCreateWatchlist) {
                TextField("Name", text: $newWatchlistName)
                Button("Cancel", role: .cancel) {
                    newWatchlistName = ""
                }
                Button("Create") {
                    Task {
                        await watchlistService.createWatchlist(name: newWatchlistName)
                        newWatchlistName = ""
                    }
                }
            } message: {
                Text("Enter a name for your new watchlist")
            }
        }
    }
}

#Preview {
    let watchlistService = WatchlistService()
    return SymbolSearchView(watchlistService: watchlistService)
}
