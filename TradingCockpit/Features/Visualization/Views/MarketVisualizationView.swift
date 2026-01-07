//
//  MarketVisualizationView.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 3: 3D Visualization Engine
//

import SwiftUI
import RealityKit

struct MarketVisualizationView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var engine = VisualizationEngine()

    // Mock data for Sprint 3 (will be replaced with real data in Sprint 4)
    @State private var positions: [Position] = []
    @State private var quotes: [String: Quote] = [:]
    @State private var updateTimer: Timer?

    // Camera gesture state
    @State private var lastDragValue: DragGesture.Value?
    @State private var cameraRotation: SIMD2<Float> = SIMD2<Float>(Float.pi / 6, 0)
    @State private var cameraDistance: Float = 1.5

    var body: some View {
        ZStack {
            // RealityView for 3D scene
            RealityView { content in
                do {
                    let rootEntity = try await engine.initializeScene()
                    content.add(rootEntity)
                    Logger.info("✅ RealityView scene added")
                } catch {
                    Logger.error("❌ Failed to initialize scene", error: error)
                }
            } update: { content in
                // Update loop for continuous rendering
                engine.updateFrameRate()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleCameraDrag(value)
                    }
                    .onEnded { _ in
                        lastDragValue = nil
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        handleCameraZoom(value)
                    }
            )

            // Overlay UI
            VStack {
                // Top bar with stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Market Visualization")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(positions.count) positions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Performance indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(engine.state.frameRate)) FPS")
                            .font(.caption)
                            .foregroundStyle(engine.state.frameRate >= 50 ? .green : .orange)

                        if engine.state.isAnimating {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Updating")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()

                Spacer()

                // Bottom controls
                VStack(spacing: 12) {
                    // Camera controls
                    HStack(spacing: 16) {
                        Button {
                            engine.resetCamera()
                            cameraRotation = SIMD2<Float>(Float.pi / 6, 0)
                            cameraDistance = 1.5
                        } label: {
                            Label("Reset View", systemImage: "camera.fill")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                        }

                        Toggle("Labels", isOn: Binding(
                            get: { engine.state.showLabels },
                            set: { engine.state.showLabels = $0 }
                        ))
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                        Toggle("Grid", isOn: Binding(
                            get: { engine.state.showGrid },
                            set: { engine.state.showGrid = $0 }
                        ))
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }

                    // Position selector (placeholder)
                    if !positions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(positions) { position in
                                    PositionChip(position: position)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 60)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .task {
            await startVisualization()
        }
        .onDisappear {
            stopVisualization()
        }
    }

    // MARK: - Gesture Handlers

    private func handleCameraDrag(_ value: DragGesture.Value) {
        guard let lastValue = lastDragValue else {
            lastDragValue = value
            return
        }

        let deltaX = Float(value.translation.width - lastValue.translation.width)
        let deltaY = Float(value.translation.height - lastValue.translation.height)

        // Update rotation
        cameraRotation.y += deltaX * 0.01  // Yaw
        cameraRotation.x -= deltaY * 0.01  // Pitch

        // Clamp pitch to avoid flipping
        cameraRotation.x = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, cameraRotation.x))

        engine.updateCamera(pitch: cameraRotation.x, yaw: cameraRotation.y)
        lastDragValue = value
    }

    private func handleCameraZoom(_ scale: CGFloat) {
        cameraDistance = Float(1.5 / scale)
        cameraDistance = max(0.5, min(3.0, cameraDistance))  // Clamp distance
        engine.updateCamera(distance: cameraDistance)
    }

    // MARK: - Visualization Lifecycle

    private func startVisualization() async {
        Logger.info("🚀 Starting market visualization")

        // Generate mock positions for demo
        await generateMockData()

        // Update visualization with initial data
        await engine.updateVisualization(positions: positions, quotes: quotes)

        // Start update timer (simulate real-time updates)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await updateMockData()
                await engine.updateVisualization(positions: positions, quotes: quotes)
            }
        }
    }

    private func stopVisualization() {
        updateTimer?.invalidate()
        updateTimer = nil
        Logger.info("⏹️ Stopped market visualization")
    }

    // MARK: - Mock Data (Sprint 3 Demo)

    private func generateMockData() async {
        let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX", "AMD", "INTC"]

        positions = symbols.enumerated().map { index, symbol in
            let basePrice = Decimal(Double.random(in: 100...300))
            let quantity = Int.random(in: 10...100)
            let avgPrice = basePrice * Decimal(Double.random(in: 0.9...1.1))
            let currentPrice = basePrice

            return Position(
                symbol: symbol,
                quantity: quantity,
                averagePrice: avgPrice,
                currentPrice: currentPrice
            )
        }

        quotes = Dictionary(uniqueKeysWithValues: symbols.map { symbol in
            (symbol, Quote.mock(symbol: symbol))
        })

        Logger.info("📊 Generated mock data: \(positions.count) positions")
    }

    private func updateMockData() async {
        // Simulate price changes
        for i in 0..<positions.count {
            let priceChange = Decimal(Double.random(in: -5...5))
            positions[i].currentPrice += priceChange

            if let quote = quotes[positions[i].symbol] {
                let updatedQuote = Quote(
                    symbol: quote.symbol,
                    timestamp: Date(),
                    bid: quote.last - 0.05,
                    ask: quote.last + 0.05,
                    last: positions[i].currentPrice,
                    open: quote.open,
                    high: max(quote.high, positions[i].currentPrice),
                    low: min(quote.low, positions[i].currentPrice),
                    close: quote.close,
                    volume: quote.volume
                )
                quotes[positions[i].symbol] = updatedQuote
            }
        }
    }
}

// MARK: - Position Chip

struct PositionChip: View {
    let position: Position

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(position.symbol)
                .font(.caption)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: position.unrealizedPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text("\(position.unrealizedPnLPercent >= 0 ? "+" : "")\(String(format: "%.2f", NSDecimalNumber(decimal: position.unrealizedPnLPercent).doubleValue))%")
                    .font(.caption2)
            }
            .foregroundStyle(position.unrealizedPnL >= 0 ? .green : .red)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MarketVisualizationView()
        .environment(AppState())
}
