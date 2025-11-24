//
//  VisualizationEngine.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 3: 3D Visualization Engine
//

import Foundation
import RealityKit
import SwiftUI

/// Core 3D visualization engine for market terrain
@MainActor
class VisualizationEngine: ObservableObject {
    // MARK: - Properties

    @Published private(set) var state: VisualizationState
    private let terrainGenerator: TerrainGenerator
    private var rootEntity: Entity?
    private var terrainEntity: ModelEntity?
    private var labelEntities: [String: ModelEntity] = [:]

    // Performance tracking
    private var lastFrameTime: Date = Date()
    private var frameCount: Int = 0

    // MARK: - Initialization

    init(config: TerrainConfig = .default) {
        self.state = VisualizationState()
        self.state.currentConfig = config
        self.terrainGenerator = TerrainGenerator(config: config)
        Logger.info("🎨 Visualization Engine initialized")
    }

    // MARK: - Scene Setup

    /// Initialize RealityKit scene
    func initializeScene() async throws -> Entity {
        Logger.debug("🎨 Initializing RealityKit scene")

        // Create root entity
        let root = Entity()
        self.rootEntity = root

        // Add lighting
        await addLighting(to: root)

        // Add grid helper
        if state.showGrid {
            await addGridHelper(to: root)
        }

        // Create initial terrain (empty)
        try await updateTerrain(positions: [], quotes: [:])

        state.isInitialized = true
        Logger.info("✅ RealityKit scene initialized")

        return root
    }

    // MARK: - Data Updates

    /// Update visualization with new market data
    func updateVisualization(positions: [Position], quotes: [String: Quote]) async {
        guard state.isInitialized else {
            Logger.warning("⚠️ Scene not initialized, skipping update")
            return
        }

        state.isAnimating = true
        defer { state.isAnimating = false }

        // Update terrain
        do {
            try await updateTerrain(positions: positions, quotes: quotes)
            await updateLabels(positions: positions)
            state.lastUpdateTime = Date()
            Logger.debug("✅ Visualization updated with \(positions.count) positions")
        } catch {
            Logger.error("❌ Failed to update visualization", error: error)
        }
    }

    /// Update terrain mesh
    private func updateTerrain(positions: [Position], quotes: [String: Quote]) async throws {
        // Update generator data
        await terrainGenerator.updateData(positions: positions, quotes: quotes)

        // Generate new mesh
        let mesh = try await terrainGenerator.generateTerrain()

        // Create or update terrain entity
        if let existingTerrain = terrainEntity {
            // Update existing mesh
            existingTerrain.model?.mesh = mesh

            // Animate the update
            var transform = existingTerrain.transform
            transform.scale = SIMD3<Float>(repeating: 1.1)
            existingTerrain.move(
                to: transform,
                relativeTo: existingTerrain.parent,
                duration: state.currentConfig.updateDuration * 0.5
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + state.currentConfig.updateDuration * 0.5) {
                var resetTransform = existingTerrain.transform
                resetTransform.scale = SIMD3<Float>(repeating: 1.0)
                existingTerrain.move(
                    to: resetTransform,
                    relativeTo: existingTerrain.parent,
                    duration: self.state.currentConfig.updateDuration * 0.5
                )
            }
        } else {
            // Create new terrain entity
            let material = await createTerrainMaterial()
            let terrain = ModelEntity(mesh: mesh, materials: [material])
            terrain.name = "Terrain"

            rootEntity?.addChild(terrain)
            self.terrainEntity = terrain
        }
    }

    /// Update security labels
    private func updateLabels(positions: [Position]) async {
        guard state.showLabels else {
            // Remove all labels if disabled
            labelEntities.values.forEach { $0.removeFromParent() }
            labelEntities.removeAll()
            return
        }

        let labels = await terrainGenerator.generateLabels()

        // Remove labels for positions that no longer exist
        let currentSymbols = Set(positions.map { $0.symbol })
        for (symbol, entity) in labelEntities {
            if !currentSymbols.contains(symbol) {
                entity.removeFromParent()
                labelEntities.removeValue(forKey: symbol)
            }
        }

        // Update or create labels
        for label in labels {
            if let existingEntity = labelEntities[label.symbol] {
                // Update position
                var transform = existingEntity.transform
                transform.translation = label.position
                existingEntity.move(
                    to: transform,
                    relativeTo: existingEntity.parent,
                    duration: state.currentConfig.updateDuration
                )
            } else {
                // Create new label
                let labelEntity = await createLabelEntity(for: label)
                rootEntity?.addChild(labelEntity)
                labelEntities[label.symbol] = labelEntity
            }
        }
    }

    // MARK: - Camera Controls

    /// Update camera position
    func updateCamera(pitch: Float? = nil, yaw: Float? = nil, distance: Float? = nil) {
        if let pitch = pitch {
            state.cameraState.rotation.x = pitch
        }
        if let yaw = yaw {
            state.cameraState.rotation.y = yaw
        }
        if let distance = distance {
            state.cameraState.distance = distance
        }

        state.cameraState.updatePosition()
        Logger.debug("📷 Camera updated: pitch=\(state.cameraState.rotation.x), yaw=\(state.cameraState.rotation.y)")
    }

    /// Reset camera to default position
    func resetCamera() {
        state.cameraState = .default
        Logger.debug("📷 Camera reset to default")
    }

    // MARK: - Performance

    /// Update frame rate tracking
    func updateFrameRate() {
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFrameTime)

        if elapsed >= 1.0 {
            state.frameRate = Double(frameCount) / elapsed
            frameCount = 0
            lastFrameTime = now
        }
    }

    // MARK: - Private Helpers

    /// Create terrain material with vertex colors
    private func createTerrainMaterial() async -> Material {
        var material = SimpleMaterial()
        material.color = .init(tint: .white)
        material.metallic = .init(floatLiteral: 0.1)
        material.roughness = .init(floatLiteral: 0.8)
        return material
    }

    /// Create 3D text label entity
    private func createLabelEntity(for label: SecurityLabel) async -> ModelEntity {
        // Create text mesh (simplified - will use ModelEntity with basic shape for now)
        // In production, would use TextEntity or custom text mesh generation

        let mesh = MeshResource.generateBox(size: 0.02)
        var material = SimpleMaterial()
        material.color = .init(tint: .init(
            red: Double(label.textColor.x),
            green: Double(label.textColor.y),
            blue: Double(label.textColor.z),
            alpha: Double(label.textColor.w)
        ))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Label-\(label.symbol)"
        entity.position = label.position

        // Billboard behavior - always face camera (will be updated in animation loop)
        entity.look(at: state.cameraState.position, from: label.position, relativeTo: nil)

        return entity
    }

    /// Add lighting to scene
    private func addLighting(to parent: Entity) async {
        // Directional light (sun)
        let sunlight = DirectionalLight()
        sunlight.light.color = .white
        sunlight.light.intensity = 1000
        sunlight.shadow?.depthBias = 3.0
        sunlight.shadow?.maximumDistance = 5.0

        var sunTransform = Transform()
        sunTransform.rotation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0])
        sunlight.transform = sunTransform

        parent.addChild(sunlight)

        // Ambient light
        let ambient = PointLight()
        ambient.light.color = .white
        ambient.light.intensity = 300
        ambient.light.attenuationRadius = 10
        ambient.position = [0, 2, 0]

        parent.addChild(ambient)
    }

    /// Add grid helper for debugging
    private func addGridHelper(to parent: Entity) async {
        let gridSize: Float = 1.0
        let divisions: Int = 10
        let step = gridSize / Float(divisions)

        for i in 0...divisions {
            let offset = Float(i) * step - gridSize / 2

            // Horizontal lines
            let hLine = ModelEntity(
                mesh: .generateBox(width: gridSize, height: 0.001, depth: 0.001),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.3), isMetallic: false)]
            )
            hLine.position = [offset, 0, 0]
            parent.addChild(hLine)

            // Vertical lines
            let vLine = ModelEntity(
                mesh: .generateBox(width: 0.001, height: 0.001, depth: gridSize),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.3), isMetallic: false)]
            )
            vLine.position = [0, 0, offset]
            parent.addChild(vLine)
        }
    }
}
