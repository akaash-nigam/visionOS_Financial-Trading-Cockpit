//
//  TerrainGenerator.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 3: 3D Visualization Engine
//

import Foundation
import RealityKit

/// Generates 3D terrain mesh from market data
actor TerrainGenerator {
    private let config: TerrainConfig
    private var currentPositions: [Position]
    private var currentQuotes: [String: Quote]

    init(config: TerrainConfig = .default) {
        self.config = config
        self.currentPositions = []
        self.currentQuotes = [:]
    }

    // MARK: - Public Methods

    /// Update positions and quotes for terrain generation
    func updateData(positions: [Position], quotes: [String: Quote]) {
        self.currentPositions = positions
        self.currentQuotes = quotes
    }

    /// Generate terrain mesh from current data
    func generateTerrain() async throws -> MeshResource {
        let points = await generateTerrainPoints()
        return try createMeshFromPoints(points)
    }

    /// Generate terrain points with positions and colors
    func generateTerrainPoints() async -> [TerrainPoint] {
        var points: [TerrainPoint] = []

        // Calculate grid dimensions
        let totalPositions = currentPositions.count
        guard totalPositions > 0 else {
            // Return flat grid if no positions
            return generateEmptyGrid()
        }

        // Create grid layout - arrange positions in a square grid
        let gridSize = Int(ceil(sqrt(Double(totalPositions))))
        let centerOffset = Float(gridSize - 1) * config.spacing / 2.0

        // Find min/max P&L for normalization
        let pnlValues = currentPositions.map { $0.unrealizedPnLPercent }
        let minPnL = pnlValues.min() ?? 0
        let maxPnL = pnlValues.max() ?? 0
        let pnlRange = max(abs(Double(minPnL)), abs(Double(maxPnL)), 0.001)  // Avoid division by zero

        // Generate points for each position
        for (index, position) in currentPositions.enumerated() {
            let gridX = index % gridSize
            let gridZ = index / gridSize

            // Calculate world position
            let x = Float(gridX) * config.spacing - centerOffset
            let z = Float(gridZ) * config.spacing - centerOffset

            // Calculate height based on P&L percentage
            let pnlPercent = Double(position.unrealizedPnLPercent)
            let normalizedPnL = Float(pnlPercent / pnlRange)  // -1 to 1
            let height = normalizedPnL * config.heightScale

            // Calculate color (0 = red, 0.5 = yellow, 1 = green)
            let colorValue = (normalizedPnL + 1) / 2.0  // Convert -1..1 to 0..1
            let color = config.colorGradient.color(for: colorValue)

            let point = TerrainPoint(
                x: x,
                y: height,
                z: z,
                color: color,
                value: colorValue,
                symbol: position.symbol
            )

            points.append(point)
        }

        return points
    }

    /// Generate security labels for the terrain
    func generateLabels() async -> [SecurityLabel] {
        var labels: [SecurityLabel] = []

        let totalPositions = currentPositions.count
        guard totalPositions > 0 else { return [] }

        let gridSize = Int(ceil(sqrt(Double(totalPositions))))
        let centerOffset = Float(gridSize - 1) * config.spacing / 2.0

        // Find min/max P&L for height calculation
        let pnlValues = currentPositions.map { $0.unrealizedPnLPercent }
        let minPnL = pnlValues.min() ?? 0
        let maxPnL = pnlValues.max() ?? 0
        let pnlRange = max(abs(Double(minPnL)), abs(Double(maxPnL)), 0.001)

        for (index, position) in currentPositions.enumerated() {
            let gridX = index % gridSize
            let gridZ = index / gridSize

            let x = Float(gridX) * config.spacing - centerOffset
            let z = Float(gridZ) * config.spacing - centerOffset

            let pnlPercent = Double(position.unrealizedPnLPercent)
            let normalizedPnL = Float(pnlPercent / pnlRange)
            let height = normalizedPnL * config.heightScale

            // Position label above the terrain point
            let labelPosition = SIMD3<Float>(x, height + 0.05, z)

            let label = SecurityLabel(
                symbol: position.symbol,
                position: labelPosition,
                value: position.currentPrice,
                changePercent: position.unrealizedPnLPercent
            )

            labels.append(label)
        }

        return labels
    }

    // MARK: - Private Methods

    /// Generate empty flat grid for initial state
    private func generateEmptyGrid() -> [TerrainPoint] {
        var points: [TerrainPoint] = []
        let gridSize = 5  // Small default grid
        let centerOffset = Float(gridSize - 1) * config.spacing / 2.0
        let neutralColor = config.colorGradient.color(for: 0.5)

        for gridZ in 0..<gridSize {
            for gridX in 0..<gridSize {
                let x = Float(gridX) * config.spacing - centerOffset
                let z = Float(gridZ) * config.spacing - centerOffset

                let point = TerrainPoint(
                    x: x,
                    y: 0,
                    z: z,
                    color: neutralColor,
                    value: 0.5,
                    symbol: nil
                )
                points.append(point)
            }
        }

        return points
    }

    /// Create RealityKit mesh from terrain points
    private func createMeshFromPoints(_ points: [TerrainPoint]) throws -> MeshResource {
        guard points.count > 0 else {
            throw TerrainGeneratorError.noPoints
        }

        // Calculate grid dimensions from points
        let gridSize = Int(ceil(sqrt(Double(points.count))))

        // Create vertex buffer
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        // Add vertices
        for point in points {
            positions.append(point.position)
            colors.append(point.color)
            normals.append(SIMD3<Float>(0, 1, 0))  // All normals point up initially
        }

        // Generate triangles for grid
        for z in 0..<(gridSize - 1) {
            for x in 0..<(gridSize - 1) {
                let topLeft = z * gridSize + x
                let topRight = topLeft + 1
                let bottomLeft = (z + 1) * gridSize + x
                let bottomRight = bottomLeft + 1

                // Skip if indices out of bounds
                guard bottomRight < points.count else { continue }

                // First triangle (top-left, bottom-left, top-right)
                indices.append(UInt32(topLeft))
                indices.append(UInt32(bottomLeft))
                indices.append(UInt32(topRight))

                // Second triangle (top-right, bottom-left, bottom-right)
                indices.append(UInt32(topRight))
                indices.append(UInt32(bottomLeft))
                indices.append(UInt32(bottomRight))
            }
        }

        // Calculate proper normals
        normals = calculateNormals(positions: positions, indices: indices)

        // Create mesh descriptor
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)

        // Create mesh resource
        return try MeshResource.generate(from: [descriptor])
    }

    /// Calculate vertex normals from triangle data
    private func calculateNormals(positions: [SIMD3<Float>], indices: [UInt32]) -> [SIMD3<Float>] {
        var normals = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: positions.count)

        // Calculate face normals and accumulate at vertices
        for i in stride(from: 0, to: indices.count, by: 3) {
            let i0 = Int(indices[i])
            let i1 = Int(indices[i + 1])
            let i2 = Int(indices[i + 2])

            let p0 = positions[i0]
            let p1 = positions[i1]
            let p2 = positions[i2]

            // Calculate triangle normal
            let edge1 = p1 - p0
            let edge2 = p2 - p0
            let normal = simd_normalize(simd_cross(edge1, edge2))

            // Accumulate at vertices
            normals[i0] += normal
            normals[i1] += normal
            normals[i2] += normal
        }

        // Normalize all vertex normals
        return normals.map { simd_normalize($0) }
    }
}

// MARK: - Errors

enum TerrainGeneratorError: Error, LocalizedError {
    case noPoints
    case invalidGridSize

    var errorDescription: String? {
        switch self {
        case .noPoints:
            return "No terrain points to generate mesh"
        case .invalidGridSize:
            return "Invalid grid size for terrain generation"
        }
    }
}
