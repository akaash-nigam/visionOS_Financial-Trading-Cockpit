//
//  OrderEntryView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import SwiftUI

struct OrderEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tradingService: TradingService
    @State private var marketDataHub: MarketDataHub?

    // Order request state
    @State private var orderRequest: OrderRequest
    @State private var currentPrice: Decimal = 0
    @State private var quote: Quote?

    // UI state
    @State private var validation: OrderValidation = .valid
    @State private var showConfirmation: Bool = false
    @State private var isLoadingQuote: Bool = true

    // Initialization with symbol pre-selected
    init(symbol: String = "", tradingService: TradingService) {
        _tradingService = StateObject(wrappedValue: tradingService)
        _orderRequest = State(initialValue: OrderRequest(symbol: symbol, side: .buy))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Symbol Header
                    symbolHeader

                    // Order Type Selector
                    orderTypeSelector

                    // Side Selector (Buy/Sell)
                    sideSelector

                    // Quantity Input
                    quantityInput

                    // Limit Price (for limit orders)
                    if orderRequest.orderType == .limit {
                        limitPriceInput
                    }

                    // Order Summary
                    orderSummary

                    // Validation Errors
                    if !validation.isValid {
                        validationErrors
                    }

                    // Warnings
                    if !validation.warnings.isEmpty {
                        validationWarnings
                    }

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Place Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                OrderConfirmationView(
                    confirmation: tradingService.generateConfirmation(
                        for: orderRequest,
                        currentPrice: currentPrice
                    ),
                    onConfirm: {
                        Task {
                            await submitOrder()
                        }
                    }
                )
            }
            .task {
                await loadQuote()
                await tradingService.refreshAccount()
            }
            .onChange(of: orderRequest) { _, _ in
                Task {
                    await validateOrder()
                }
            }
        }
    }

    // MARK: - Symbol Header

    private var symbolHeader: some View {
        VStack(spacing: 8) {
            Text(orderRequest.symbol.isEmpty ? "Select Symbol" : orderRequest.symbol)
                .font(.system(size: 48, weight: .bold, design: .rounded))

            if let quote = quote {
                HStack(spacing: 12) {
                    Text("$\(formatPrice(quote.last))")
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Image(systemName: quote.isPositive ? "arrow.up.right" : "arrow.down.right")
                        Text("\(quote.changePercent >= 0 ? "+" : "")\(formatPercent(quote.changePercent))%")
                    }
                    .font(.subheadline)
                    .foregroundStyle(quote.isPositive ? .green : .red)
                }
            } else if isLoadingQuote {
                ProgressView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Order Type Selector

    private var orderTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Type")
                .font(.headline)

            Picker("Order Type", selection: $orderRequest.orderType) {
                Text("Market").tag(OrderType.market)
                Text("Limit").tag(OrderType.limit)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Side Selector

    private var sideSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    orderRequest.side = .buy
                } label: {
                    Text("Buy")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(orderRequest.side == .buy ? Color.green : Color.gray)
                        .cornerRadius(12)
                }

                Button {
                    orderRequest.side = .sell
                } label: {
                    Text("Sell")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(orderRequest.side == .sell ? Color.red : Color.gray)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Quantity Input

    private var quantityInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quantity")
                    .font(.headline)

                Spacer()

                Text("\(orderRequest.quantity) shares")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Slider
            Slider(
                value: Binding(
                    get: { Double(orderRequest.quantity) },
                    set: { orderRequest.quantity = Int($0) }
                ),
                in: 0...1000,
                step: 1
            )

            // Quick quantity buttons
            HStack(spacing: 8) {
                ForEach([1, 10, 50, 100], id: \.self) { qty in
                    Button {
                        orderRequest.quantity = qty
                    } label: {
                        Text("\(qty)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Limit Price Input

    private var limitPriceInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Limit Price")
                .font(.headline)

            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                TextField("0.00", value: $orderRequest.limitPrice, format: .number)
                    .font(.title3)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            Text("Current market price: $\(formatPrice(currentPrice))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Order Summary

    private var orderSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Estimated Value")
                    .font(.subheadline)
                Spacer()
                Text("$\(formatPrice(orderRequest.estimatedValue(currentPrice: currentPrice)))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Commission")
                    .font(.subheadline)
                Spacer()
                Text("$0.00")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("$\(formatPrice(orderRequest.estimatedValue(currentPrice: currentPrice)))")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            if let balance = tradingService.accountBalance {
                HStack {
                    Text("Buying Power")
                        .font(.caption)
                    Spacer()
                    Text("$\(formatPrice(balance.buyingPower))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Validation Errors

    private var validationErrors: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(validation.errors, id: \.localizedDescription) { error in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Validation Warnings

    private var validationWarnings: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(validation.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showConfirmation = true
            } label: {
                HStack {
                    if tradingService.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(orderRequest.side == .buy ? "Review Buy Order" : "Review Sell Order")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(validation.isValid ? (orderRequest.side == .buy ? Color.green : Color.red) : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!validation.isValid || tradingService.isSubmitting)
        }
    }

    // MARK: - Methods

    private func loadQuote() async {
        isLoadingQuote = true
        defer { isLoadingQuote = false }

        // Mock quote for demo
        quote = Quote.mock(symbol: orderRequest.symbol)
        currentPrice = quote?.last ?? 100

        await validateOrder()
    }

    private func validateOrder() async {
        validation = await tradingService.validateOrder(orderRequest, currentPrice: currentPrice)
    }

    private func submitOrder() async {
        do {
            _ = try await tradingService.submitOrder(orderRequest)
            Logger.info("✅ Order submitted successfully")
            dismiss()
        } catch {
            Logger.error("❌ Order submission failed", error: error)
        }
    }

    // MARK: - Formatting

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatPercent(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }
}

#Preview {
    OrderEntryView(symbol: "AAPL", tradingService: TradingService())
}
