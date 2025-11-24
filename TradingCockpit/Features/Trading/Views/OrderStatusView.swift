//
//  OrderStatusView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 4: Trading Execution
//

import SwiftUI

struct OrderStatusView: View {
    @StateObject private var tradingService: TradingService
    @State private var selectedTab: OrderTab = .active
    @State private var showCancelAlert: Bool = false
    @State private var orderToCancel: Order?

    enum OrderTab: String, CaseIterable {
        case active = "Active"
        case history = "History"
    }

    init(tradingService: TradingService) {
        _tradingService = StateObject(wrappedValue: tradingService)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Order Type", selection: $selectedTab) {
                    ForEach(OrderTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Order List
                if selectedTab == .active {
                    activeOrdersList
                } else {
                    orderHistoryList
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await tradingService.refreshOrders()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Cancel Order", isPresented: $showCancelAlert) {
                Button("Cancel Order", role: .destructive) {
                    if let order = orderToCancel {
                        Task {
                            try? await tradingService.cancelOrder(order)
                        }
                    }
                }
                Button("Keep Order", role: .cancel) {}
            } message: {
                if let order = orderToCancel {
                    Text("Are you sure you want to cancel the order for \(order.quantity) shares of \(order.symbol)?")
                }
            }
            .task {
                await tradingService.refreshOrders()
            }
        }
    }

    // MARK: - Active Orders List

    private var activeOrdersList: some View {
        Group {
            if tradingService.activeOrders.isEmpty {
                emptyState(message: "No active orders")
            } else {
                List {
                    ForEach(tradingService.activeOrders) { order in
                        OrderRow(order: order, showActions: true) {
                            orderToCancel = order
                            showCancelAlert = true
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Order History List

    private var orderHistoryList: some View {
        Group {
            if tradingService.orderHistory.isEmpty {
                emptyState(message: "No order history")
            } else {
                List {
                    ForEach(tradingService.orderHistory) { order in
                        OrderRow(order: order, showActions: false)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private func emptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Order Row

struct OrderRow: View {
    let order: Order
    let showActions: Bool
    var onCancel: (() -> Void)?

    private var statusDisplay: OrderStatusDisplay {
        OrderStatusDisplay(
            order: order,
            currentPrice: nil,
            elapsedTime: Date().timeIntervalSince(order.createdAt)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Symbol and side
                HStack(spacing: 8) {
                    Image(systemName: order.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(order.side == .buy ? .green : .red)

                    Text(order.symbol)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(order.side == .buy ? "BUY" : "SELL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(order.side == .buy ? Color.green : Color.red)
                        .cornerRadius(4)
                }

                Spacer()

                // Status badge
                Text(statusDisplay.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
            }

            // Details
            HStack(spacing: 16) {
                DetailPill(label: "Qty", value: "\(order.quantity)")

                DetailPill(label: "Type", value: order.orderType.rawValue.capitalized)

                if let price = order.limitPrice ?? order.averageFillPrice {
                    DetailPill(label: "Price", value: "$\(formatPrice(price))")
                }

                if order.status == .partiallyFilled {
                    DetailPill(label: "Filled", value: "\(statusDisplay.filledPercentage)%")
                }
            }

            // Timestamp
            Text(formatDate(order.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)

            // Cancel button for active orders
            if showActions, statusDisplay.canCancel {
                Button(role: .destructive) {
                    onCancel?()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Order")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch order.status {
        case .pending, .new:
            return .blue
        case .partiallyFilled:
            return .orange
        case .filled:
            return .green
        case .cancelled:
            return .gray
        case .rejected:
            return .red
        case .expired:
            return .purple
        }
    }

    private func formatPrice(_ value: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Pill

struct DetailPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

#Preview {
    let service = TradingService()
    service.activeOrders = [
        Order(
            id: UUID(),
            brokerOrderId: "123",
            symbol: "AAPL",
            side: .buy,
            orderType: .market,
            quantity: 10,
            filledQuantity: 0,
            limitPrice: nil,
            stopPrice: nil,
            averageFillPrice: nil,
            status: .new,
            timeInForce: .day,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Order(
            id: UUID(),
            brokerOrderId: "124",
            symbol: "GOOGL",
            side: .sell,
            orderType: .limit,
            quantity: 5,
            filledQuantity: 3,
            limitPrice: 150.00,
            stopPrice: nil,
            averageFillPrice: 149.95,
            status: .partiallyFilled,
            timeInForce: .day,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date()
        )
    ]

    return OrderStatusView(tradingService: service)
}
