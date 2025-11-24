//
//  VisualizationModels.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 3: 3D Visualization Engine
//

import Foundation
import RealityKit

// MARK: - Terrain Configuration

/// Configuration for terrain visualization
struct TerrainConfig {
    /// Grid dimensions
    let gridWidth: Int
    let gridHeight: Int

    /// Spacing between grid points (in meters for visionOS)
    let spacing: Float

    /// Height scale multiplier for P&L visualization
    let heightScale: Float

    /// Color gradient configuration
    let colorGradient: ColorGradient

    /// Animation duration for terrain updates
    let updateDuration: TimeInterval

    static let `default` = TerrainConfig(
        gridWidth: 20,
        gridHeight: 20,
        spacing: 0.05,  // 5cm spacing
        heightScale: 0.3,  // 30cm max height
        colorGradient: .profitLoss,
        updateDuration: 0.3
    )

    static let compact = TerrainConfig(
        gridWidth: 10,
        gridHeight: 10,
        spacing: 0.08,
        heightScale: 0.2,
        colorGradient: .profitLoss,
        updateDuration: 0.3
    )
}

// MARK: - Color Gradients

/// Color gradient for terrain visualization
struct ColorGradient {
    let colors: [Float: SIMD4<Float>]  // Value (0-1) to RGBA color

    /// Standard profit/loss gradient (red → yellow → green)
    static let profitLoss = ColorGradient(colors: [
        0.0: SIMD4<Float>(0.8, 0.0, 0.0, 1.0),   // Deep red (-100%)
        0.25: SIMD4<Float>(1.0, 0.3, 0.0, 1.0),  // Orange (-50%)
        0.5: SIMD4<Float>(1.0, 1.0, 0.0, 1.0),   // Yellow (0%)
        0.75: SIMD4<Float>(0.5, 1.0, 0.0, 1.0),  // Light green (+50%)
        1.0: SIMD4<Float>(0.0, 0.8, 0.0, 1.0)    // Deep green (+100%)
    ])

    /// Heat map gradient (blue → cyan → yellow → red)
    static let heatMap = ColorGradient(colors: [
        0.0: SIMD4<Float>(0.0, 0.0, 1.0, 1.0),   // Blue
        0.33: SIMD4<Float>(0.0, 1.0, 1.0, 1.0),  // Cyan
        0.67: SIMD4<Float>(1.0, 1.0, 0.0, 1.0),  // Yellow
        1.0: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)    // Red
    ])

    /// Get interpolated color for a value (0-1)
    func color(for value: Float) -> SIMD4<Float> {
        let clampedValue = max(0, min(1, value))
        let sortedKeys = colors.keys.sorted()

        // Find surrounding color stops
        var lowerKey: Float = 0
        var upperKey: Float = 1

        for key in sortedKeys {
            if key <= clampedValue {
                lowerKey = key
            }
            if key >= clampedValue {
                upperKey = key
                break
            }
        }

        // If exact match, return that color
        if lowerKey == upperKey {
            return colors[lowerKey]!
        }

        // Interpolate between colors
        let lowerColor = colors[lowerKey]!
        let upperColor = colors[upperKey]!
        let t = (clampedValue - lowerKey) / (upperKey - lowerKey)

        return simd_mix(lowerColor, upperColor, SIMD4<Float>(repeating: t))
    }
}

// MARK: - Terrain Point

/// Represents a single point in the terrain grid
struct TerrainPoint {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
    let value: Float  // Normalized value (0-1)
    let symbol: String?

    init(x: Float, y: Float, z: Float, color: SIMD4<Float>, value: Float, symbol: String? = nil) {
        self.position = SIMD3<Float>(x, y, z)
        self.color = color
        self.value = value
        self.symbol = symbol
    }
}

// MARK: - Security Label

/// 3D text label for security symbols
struct SecurityLabel {
    let symbol: String
    let position: SIMD3<Float>
    let value: Decimal
    let changePercent: Decimal

    var displayText: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(symbol)\n\(sign)\(String(format: "%.2f", NSDecimalNumber(decimal: changePercent).doubleValue))%"
    }

    var textColor: SIMD4<Float> {
        if changePercent > 0 {
            return SIMD4<Float>(0.0, 0.8, 0.0, 1.0)  // Green
        } else if changePercent < 0 {
            return SIMD4<Float>(0.8, 0.0, 0.0, 1.0)  // Red
        } else {
            return SIMD4<Float>(0.7, 0.7, 0.7, 1.0)  // Gray
        }
    }
}

// MARK: - Camera Configuration

/// Camera position and orientation
struct CameraState {
    var position: SIMD3<Float>
    var target: SIMD3<Float>  // Look-at target
    var distance: Float
    var rotation: SIMD2<Float>  // (pitch, yaw) in radians

    static let `default` = CameraState(
        position: SIMD3<Float>(0, 0.5, 1.0),
        target: SIMD3<Float>(0, 0, 0),
        distance: 1.5,
        rotation: SIMD2<Float>(Float.pi / 6, 0)  // 30° pitch
    )

    /// Update camera position based on rotation
    mutating func updatePosition() {
        let x = distance * cos(rotation.x) * sin(rotation.y)
        let y = distance * sin(rotation.x)
        let z = distance * cos(rotation.x) * cos(rotation.y)
        position = target + SIMD3<Float>(x, y, z)
    }
}

// MARK: - Visualization State

/// Current state of the visualization
@Observable
class VisualizationState {
    var isInitialized: Bool = false
    var isAnimating: Bool = false
    var currentConfig: TerrainConfig = .default
    var cameraState: CameraState = .default
    var visibleSymbols: Set<String> = []
    var selectedSymbol: String?
    var showLabels: Bool = true
    var showGrid: Bool = true

    // Performance metrics
    var frameRate: Double = 0
    var lastUpdateTime: Date = Date()
}
