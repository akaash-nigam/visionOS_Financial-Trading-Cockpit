//
//  OrderConfirmationView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import SwiftUI

struct OrderConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let confirmation: OrderConfirmation
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                header

                // Order Details
                orderDetails

                Spacer()

                // Action Buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Confirm Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(confirmation.request.side == .buy ? .green : .red)

            Text("Review Your Order")
                .font(.title2)
                .fontWeight(.bold)

            Text(confirmation.displaySummary)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Order Details

    private var orderDetails: some View {
        VStack(spacing: 0) {
            DetailRow(
                label: "Symbol",
                value: confirmation.request.symbol,
                icon: "chart.line.uptrend.xyaxis"
            )

            Divider()

            DetailRow(
                label: "Side",
                value: confirmation.request.side == .buy ? "Buy" : "Sell",
                icon: confirmation.request.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                valueColor: confirmation.request.side == .buy ? .green : .red
            )

            Divider()

            DetailRow(
                label: "Quantity",
                value: "\(confirmation.request.quantity) shares",
                icon: "number.circle.fill"
            )

            Divider()

            DetailRow(
                label: "Order Type",
                value: confirmation.request.orderType == .market ? "Market" : "Limit",
                icon: "doc.text.fill"
            )

            if confirmation.request.orderType == .limit, let limitPrice = confirmation.request.limitPrice {
                Divider()

                DetailRow(
                    label: "Limit Price",
                    value: "$\(formatPrice(limitPrice))",
                    icon: "dollarsign.circle.fill"
                )
            }

            Divider()

            DetailRow(
                label: "Current Price",
                value: "$\(formatPrice(confirmation.currentPrice))",
                icon: "tag.fill"
            )

            Divider()

            DetailRow(
                label: "Estimated Cost",
                value: "$\(formatPrice(confirmation.estimatedCost))",
                icon: "creditcard.fill",
                isHighlighted: true
            )

            Divider()

            DetailRow(
                label: "Commission",
                value: "$\(formatPrice(confirmation.estimatedCommission))",
                icon: "percent",
                valueColor: .green
            )

            Divider()

            DetailRow(
                label: "Total",
                value: "$\(formatPrice(confirmation.estimatedTotal))",
                icon: "sum",
                isHighlighted: true,
                isBold: true
            )

            Divider()

            DetailRow(
                label: "Buying Power After",
                value: "$\(formatPrice(confirmation.buyingPowerAfter))",
                icon: "dollarsign.square.fill",
                valueColor: confirmation.buyingPowerAfter >= 0 ? .primary : .red
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onConfirm()
                dismiss()
            } label: {
                Text("Confirm & Submit Order")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: confirmation.request.side == .buy ? [.green, .green.opacity(0.8)] : [.red, .red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }

            // Disclaimer
            Text("By confirming, you agree to submit this order to your broker.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    // MARK: - Formatting

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    var isHighlighted: Bool = false
    var isBold: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                Text(label)
                    .font(isBold ? .headline : .subheadline)
            }

            Spacer()

            Text(value)
                .font(isBold ? .headline : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundStyle(valueColor)
        }
        .padding()
        .background(isHighlighted ? Color(.systemGray5) : Color.clear)
    }
}

#Preview {
    let request = OrderRequest(
        symbol: "AAPL",
        side: .buy,
        quantity: 10,
        orderType: .market
    )

    let confirmation = OrderConfirmation(
        request: request,
        currentPrice: 175.50,
        estimatedCost: 1755.00,
        estimatedCommission: 0,
        estimatedTotal: 1755.00,
        buyingPowerAfter: 8245.00,
        marketStatus: .open
    )

    return OrderConfirmationView(confirmation: confirmation, onConfirm: {})
}
