# 3D Visualization Technical Specification
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Overview

This document provides detailed technical specifications for all 3D visualization components in the Financial Trading Cockpit. It covers terrain generation algorithms, options spiral geometry, risk barrier rendering, and performance optimization strategies.

### Visualization Components
1. Market Topography (3D terrain)
2. Options Chain Spirals
3. Risk Barriers
4. News Impact Ripples
5. Spatial UI Elements

---

## 2. Market Topography

### 2.1 Conceptual Design

Market topography renders financial markets as a 3D landscape where:
- **Height (Z-axis)**: Stock price
- **Position (X, Y)**: Sector grouping or custom arrangement
- **Color**: Price change percentage (red to green gradient)
- **Surface texture**: Volatility (smooth = low vol, rough = high vol)

### 2.2 Terrain Generation Algorithm

```swift
class TerrainGenerator {
    func generateTerrain(securities: [Security], quotes: [String: Quote]) -> TerrainMesh {
        // Step 1: Calculate positions for each security
        let positions = calculatePositions(securities)

        // Step 2: Generate height map
        let heightMap = generateHeightMap(securities, quotes, positions)

        // Step 3: Create mesh via Delaunay triangulation
        let vertices = createVertices(positions, heightMap)
        let indices = delaunayTriangulation(positions)

        // Step 4: Apply smoothing
        let smoothedVertices = applySmoothing(vertices, iterations: 3)

        // Step 5: Generate colors
        let colors = generateColors(securities, quotes)

        // Step 6: Generate normals for lighting
        let normals = calculateNormals(smoothedVertices, indices)

        // Step 7: Apply texture coordinates for volatility
        let texCoords = generateTextureCoordinates(securities, quotes)

        return TerrainMesh(
            vertices: smoothedVertices,
            indices: indices,
            normals: normals,
            colors: colors,
            textureCoordinates: texCoords
        )
    }
}
```

### 2.3 Position Calculation

#### 2.3.1 Sector-Based Layout
```swift
func calculatePositions(_ securities: [Security]) -> [SIMD3<Float>] {
    var positions: [SIMD3<Float>] = []

    // Group by sector
    let sectors = Dictionary(grouping: securities, by: { $0.sector })

    let sectorRadius: Float = 50.0  // Radius of each sector cluster
    let sectorSpacing: Float = 100.0

    for (sectorIndex, (sector, stocks)) in sectors.enumerated() {
        let sectorAngle = Float(sectorIndex) * (2 * .pi / Float(sectors.count))
        let sectorCenter = SIMD3<Float>(
            cos(sectorAngle) * sectorSpacing,
            0,
            sin(sectorAngle) * sectorSpacing
        )

        // Arrange stocks within sector using spiral pattern
        for (stockIndex, stock) in stocks.enumerated() {
            let spiralAngle = Float(stockIndex) * (2 * .pi / 5)
            let spiralRadius = sqrt(Float(stockIndex)) * 5
            let position = SIMD3<Float>(
                sectorCenter.x + cos(spiralAngle) * spiralRadius,
                0,  // Height will be set by price
                sectorCenter.z + sin(spiralAngle) * spiralRadius
            )
            positions.append(position)
        }
    }

    return positions
}
```

#### 2.3.2 Market Cap Based Layout
```swift
func calculateMarketCapPositions(_ securities: [Security]) -> [SIMD3<Float>] {
    // Larger companies closer to center
    securities.enumerated().map { index, security in
        let marketCap = security.marketCap ?? 0
        let distance = 100.0 / (1.0 + log10(Double(marketCap)))
        let angle = Float(index) * (2 * .pi / Float(securities.count))

        return SIMD3<Float>(
            Float(cos(angle) * distance),
            0,
            Float(sin(angle) * distance)
        )
    }
}
```

### 2.4 Height Mapping

```swift
func generateHeightMap(
    _ securities: [Security],
    _ quotes: [String: Quote],
    _ positions: [SIMD3<Float>]
) -> [Float] {
    securities.enumerated().map { index, security in
        guard let quote = quotes[security.symbol] else { return 0 }

        // Map price to height using log scale for better visual distribution
        let price = Float(truncating: quote.last as NSNumber)
        let height = log10(price + 1) * 10  // Scale factor of 10

        return height
    }
}
```

### 2.5 Delaunay Triangulation

```swift
func delaunayTriangulation(_ positions: [SIMD3<Float>]) -> [UInt32] {
    // Convert to 2D for triangulation (ignore Y)
    let points2D = positions.map { SIMD2<Float>($0.x, $0.z) }

    // Use sweep-line algorithm
    var triangles: [UInt32] = []

    // 1. Sort points by x-coordinate
    let sorted = points2D.enumerated().sorted { $0.element.x < $1.element.x }

    // 2. Sweep-line triangulation (simplified)
    var activeEdges: [(Int, Int)] = []

    for (index, point) in sorted {
        // Find edges that intersect vertical line through point
        let intersecting = findIntersectingEdges(point, activeEdges, points2D)

        // Create triangles with intersecting edges
        for edge in intersecting {
            triangles.append(contentsOf: [
                UInt32(edge.0), UInt32(edge.1), UInt32(index)
            ])
        }

        // Update active edges
        updateActiveEdges(&activeEdges, point, index)
    }

    return triangles
}
```

**Note**: For production, use a proven library like `Delaunay` or implement Bowyer-Watson algorithm.

### 2.6 Smoothing Algorithm

```swift
func applySmoothing(_ vertices: [SIMD3<Float>], iterations: Int) -> [SIMD3<Float>] {
    var smoothed = vertices

    for _ in 0..<iterations {
        smoothed = smoothed.enumerated().map { index, vertex in
            // Find neighboring vertices
            let neighbors = findNeighbors(index, smoothed)

            // Average position with neighbors (Laplacian smoothing)
            let neighborAvg = neighbors.reduce(SIMD3<Float>.zero, +) / Float(neighbors.count)

            // Blend with original (preserve some detail)
            return vertex * 0.5 + neighborAvg * 0.5
        }
    }

    return smoothed
}
```

### 2.7 Color Gradient

```swift
func generateColors(_ securities: [Security], _ quotes: [String: Quote]) -> [SIMD4<Float>] {
    securities.map { security in
        guard let quote = quotes[security.symbol] else {
            return SIMD4<Float>(0.5, 0.5, 0.5, 1)  // Gray for no data
        }

        let changePercent = Float(truncating: quote.changePercent as NSNumber)

        // Map -5% to +5% onto red-to-green gradient
        let normalized = (changePercent + 5) / 10  // 0 to 1
        let clamped = max(0, min(1, normalized))

        return colorGradient(at: clamped)
    }
}

func colorGradient(at t: Float) -> SIMD4<Float> {
    // Red (t=0) → White (t=0.5) → Green (t=1)
    if t < 0.5 {
        let normalized = t * 2
        return SIMD4<Float>(
            1.0,
            normalized,
            normalized,
            1.0
        )
    } else {
        let normalized = (t - 0.5) * 2
        return SIMD4<Float>(
            1.0 - normalized,
            1.0,
            1.0 - normalized,
            1.0
        )
    }
}
```

### 2.8 Volatility Texture

```swift
func generateTextureCoordinates(
    _ securities: [Security],
    _ quotes: [String: Quote]
) -> [SIMD2<Float>] {
    securities.map { security in
        guard let quote = quotes[security.symbol] else {
            return SIMD2<Float>(0, 0)
        }

        // Calculate volatility from high-low range
        let high = Float(truncating: quote.high as NSNumber)
        let low = Float(truncating: quote.low as NSNumber)
        let price = Float(truncating: quote.last as NSNumber)
        let volatility = (high - low) / price

        // Map volatility to texture coordinate
        // U = volatility (0 to 1), V = constant
        return SIMD2<Float>(
            min(1.0, volatility * 10),  // Scale up for visibility
            0.5
        )
    }
}
```

### 2.9 Metal Shader (Terrain Rendering)

```metal
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 texCoord [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float4 color;
    float2 texCoord;
};

vertex VertexOut terrain_vertex(
    VertexIn in [[stage_in]],
    constant float4x4 &modelMatrix [[buffer(1)]],
    constant float4x4 &viewMatrix [[buffer(2)]],
    constant float4x4 &projectionMatrix [[buffer(3)]]
) {
    VertexOut out;

    float4 worldPos = modelMatrix * float4(in.position, 1.0);
    out.worldPosition = worldPos.xyz;
    out.position = projectionMatrix * viewMatrix * worldPos;
    out.normal = normalize((modelMatrix * float4(in.normal, 0.0)).xyz);
    out.color = in.color;
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 terrain_fragment(
    VertexOut in [[stage_in]],
    constant float3 &lightPosition [[buffer(0)]],
    texture2d<float> volatilityTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    // Sample volatility texture
    float4 textureSample = volatilityTexture.sample(textureSampler, in.texCoord);
    float volatility = textureSample.r;

    // Lighting calculation
    float3 lightDir = normalize(lightPosition - in.worldPosition);
    float3 normal = normalize(in.normal);
    float diffuse = max(dot(normal, lightDir), 0.0);

    // Ambient + Diffuse
    float3 ambient = in.color.rgb * 0.3;
    float3 diffuseColor = in.color.rgb * diffuse * 0.7;

    // Add roughness based on volatility
    float roughness = volatility * 0.5;
    float3 finalColor = ambient + diffuseColor * (1.0 - roughness);

    return float4(finalColor, in.color.a);
}
```

### 2.10 Real-Time Updates

```swift
class TerrainUpdater {
    private var terrainEntity: ModelEntity?
    private let updateQueue = DispatchQueue(label: "terrain.update", qos: .userInteractive)

    func updateTerrainForQuote(_ quote: Quote) {
        updateQueue.async { [weak self] in
            guard let self = self,
                  let terrainEntity = self.terrainEntity else { return }

            // Find vertex index for this security
            guard let vertexIndex = self.securityToVertexIndex[quote.symbol] else { return }

            // Calculate new height
            let price = Float(truncating: quote.last as NSNumber)
            let newHeight = log10(price + 1) * 10

            // Update vertex position
            var mesh = terrainEntity.model!.mesh
            mesh.updateVertex(at: vertexIndex, position: SIMD3<Float>(
                mesh.positions[vertexIndex].x,
                newHeight,
                mesh.positions[vertexIndex].z
            ))

            // Update color
            let changePercent = Float(truncating: quote.changePercent as NSNumber)
            let color = self.colorForChange(changePercent)
            mesh.updateVertex(at: vertexIndex, color: color)

            // Recalculate normals for affected triangles
            self.updateNormals(mesh, aroundVertex: vertexIndex)

            // Apply changes on main thread
            Task { @MainActor in
                terrainEntity.model?.mesh = mesh
            }
        }
    }
}
```

### 2.11 Level of Detail (LOD)

```swift
enum LODLevel {
    case high       // < 2m: full detail
    case medium     // 2-5m: 50% vertices
    case low        // 5-10m: 25% vertices
    case billboard  // > 10m: 2D sprite

    func vertexReduction(originalCount: Int) -> Int {
        switch self {
        case .high: return originalCount
        case .medium: return originalCount / 2
        case .low: return originalCount / 4
        case .billboard: return 4  // Just a quad
        }
    }
}

class LODManager {
    func updateLOD(for entity: ModelEntity, cameraPosition: SIMD3<Float>) {
        let distance = length(entity.position - cameraPosition)

        let lodLevel: LODLevel
        if distance < 2.0 {
            lodLevel = .high
        } else if distance < 5.0 {
            lodLevel = .medium
        } else if distance < 10.0 {
            lodLevel = .low
        } else {
            lodLevel = .billboard
        }

        // Swap mesh based on LOD
        entity.model?.mesh = lodMeshes[lodLevel]
    }
}
```

---

## 3. Options Chain Spirals

### 3.1 Spiral Geometry

Options spiral around the underlying stock in 3D space:
- **Center**: Underlying stock position
- **Radius**: Expiration date (near = tight, far = wide)
- **Height**: Strike price (ascending)
- **Angle**: Sequential ordering
- **Left side**: Puts
- **Right side**: Calls

### 3.2 Spiral Generation Algorithm

```swift
class OptionsSpiralGenerator {
    func generateSpiral(
        chain: OptionsChain,
        underlyingPosition: SIMD3<Float>
    ) -> [OptionNode] {
        var nodes: [OptionNode] = []

        // Sort expirations by date
        let sortedExpirations = chain.expirations.sorted()

        for (expIndex, expiration) in sortedExpirations.enumerated() {
            let expRadius = Float(expIndex + 1) * 2.0  // Base radius

            // Get contracts for this expiration
            let calls = chain.contracts(expiration: expiration, type: .call)
            let puts = chain.contracts(expiration: expiration, type: .put)

            // Sort by strike
            let sortedCalls = calls.sorted { $0.strike < $1.strike }
            let sortedPuts = puts.sorted { $0.strike < $1.strike }

            // Generate call positions (right side)
            for (strikeIndex, call) in sortedCalls.enumerated() {
                let position = calculateOptionPosition(
                    underlying: underlyingPosition,
                    radius: expRadius,
                    strikeIndex: strikeIndex,
                    strike: call.strike,
                    side: .right
                )

                nodes.append(OptionNode(
                    contract: call,
                    position: position,
                    size: calculateSize(call),
                    color: calculateColor(call)
                ))
            }

            // Generate put positions (left side)
            for (strikeIndex, put) in sortedPuts.enumerated() {
                let position = calculateOptionPosition(
                    underlying: underlyingPosition,
                    radius: expRadius,
                    strikeIndex: strikeIndex,
                    strike: put.strike,
                    side: .left
                )

                nodes.append(OptionNode(
                    contract: put,
                    position: position,
                    size: calculateSize(put),
                    color: calculateColor(put)
                ))
            }
        }

        return nodes
    }

    private func calculateOptionPosition(
        underlying: SIMD3<Float>,
        radius: Float,
        strikeIndex: Int,
        strike: Decimal,
        side: OptionSide
    ) -> SIMD3<Float> {
        // Height based on strike price (log scale)
        let height = log10(Float(truncating: strike as NSNumber)) * 5

        // Angle based on strike index
        let anglePerStrike: Float = .pi / 20  // Small increments
        let baseAngle: Float = side == .right ? 0 : .pi
        let angle = baseAngle + Float(strikeIndex) * anglePerStrike

        // Calculate position
        let x = underlying.x + cos(angle) * radius
        let y = height
        let z = underlying.z + sin(angle) * radius

        return SIMD3<Float>(x, y, z)
    }

    private func calculateSize(_ contract: OptionContract) -> Float {
        // Size based on volume (scaled)
        let volume = Float(contract.volume)
        let size = log10(volume + 1) * 0.1
        return max(0.05, min(0.5, size))  // Clamp between 0.05 and 0.5
    }

    private func calculateColor(_ contract: OptionContract) -> SIMD4<Float> {
        if contract.inTheMoney {
            // Yellow glow for ITM
            return SIMD4<Float>(1.0, 1.0, 0.0, 1.0)
        } else {
            // Blue for OTM, intensity based on open interest
            let oi = Float(contract.openInterest)
            let intensity = log10(oi + 1) / 10
            return SIMD4<Float>(0.2, 0.5, 1.0, min(1.0, intensity))
        }
    }
}

enum OptionSide {
    case left   // Puts
    case right  // Calls
}

struct OptionNode {
    let contract: OptionContract
    let position: SIMD3<Float>
    let size: Float
    let color: SIMD4<Float>
}
```

### 3.3 Option Sphere Rendering

```swift
class OptionsSpiralRenderer {
    func createOptionEntity(node: OptionNode) -> ModelEntity {
        // Create sphere mesh
        let mesh = MeshResource.generateSphere(radius: node.size)

        // Create material with glow
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor(
            red: CGFloat(node.color.x),
            green: CGFloat(node.color.y),
            blue: CGFloat(node.color.z),
            alpha: CGFloat(node.color.w)
        ))

        // Add emission for glow effect
        if node.contract.inTheMoney {
            material.blending = .transparent(opacity: 0.8)
        }

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = node.position

        // Add hover interaction
        entity.components.set(HoverEffectComponent())
        entity.components.set(InputTargetComponent())

        // Store contract data in entity
        entity.name = node.contract.symbol

        return entity
    }
}
```

### 3.4 Greeks Visualization (On Hover)

```swift
class GreeksOverlay {
    func createGreeksLabel(for contract: OptionContract, at position: SIMD3<Float>) -> Entity {
        let text = """
        Strike: \(contract.strike)
        Delta: \(String(format: "%.3f", contract.delta ?? 0))
        Gamma: \(String(format: "%.3f", contract.gamma ?? 0))
        Theta: \(String(format: "%.3f", contract.theta ?? 0))
        Vega: \(String(format: "%.3f", contract.vega ?? 0))
        IV: \(String(format: "%.1f%%", (contract.impliedVolatility ?? 0) * 100))
        """

        // Create text entity
        let textEntity = ModelEntity(
            mesh: .generateText(
                text,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.05)
            )
        )

        // Position above option sphere
        textEntity.position = position + SIMD3<Float>(0, 0.2, 0)

        // Billboard effect (always face camera)
        textEntity.look(at: cameraPosition, from: textEntity.position, relativeTo: nil)

        return textEntity
    }
}
```

---

## 4. Risk Barriers

### 4.1 Barrier Types

```swift
enum BarrierShape {
    case wall           // Flat vertical wall
    case sphere         // Spherical boundary
    case cone           // Sector concentration cone
    case floor          // Drawdown floor
    case ceiling        // Leverage ceiling
}
```

### 4.2 Barrier Generation

```swift
class RiskBarrierGenerator {
    func generateBarrier(
        limit: RiskLimit,
        portfolio: Portfolio
    ) -> ModelEntity {
        let shape = shapeForLimitType(limit.type)
        let position = positionForLimitType(limit.type, portfolio)
        let size = sizeForLimitType(limit.type, limit.threshold)

        let mesh: MeshResource
        switch shape {
        case .wall:
            mesh = .generatePlane(width: size.x, depth: size.z)
        case .sphere:
            mesh = .generateSphere(radius: size.x)
        case .cone:
            mesh = .generateCone(height: size.y, radius: size.x)
        case .floor:
            mesh = .generatePlane(width: size.x, depth: size.z)
        case .ceiling:
            mesh = .generatePlane(width: size.x, depth: size.z)
        }

        // Material based on utilization
        let material = createBarrierMaterial(utilization: limit.utilization)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        entity.name = "RiskBarrier_\(limit.type.rawValue)"

        // Add collision component for order validation
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))

        return entity
    }

    private func createBarrierMaterial(utilization: Double) -> Material {
        var material = UnlitMaterial()

        // Color based on utilization
        let color: UIColor
        if utilization < 0.7 {
            color = UIColor.green.withAlphaComponent(0.2)
        } else if utilization < 0.9 {
            color = UIColor.yellow.withAlphaComponent(0.4)
        } else {
            color = UIColor.red.withAlphaComponent(0.6)
        }

        material.color = .init(tint: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.5))

        return material
    }
}
```

### 4.3 Collision Detection

```swift
class RiskCollisionDetector {
    func checkOrderCollision(
        order: Order,
        barriers: [ModelEntity]
    ) -> RiskLimit? {
        // Calculate where the order would place the portfolio
        let projectedPosition = calculateProjectedPosition(order)

        // Check against all barriers
        for barrier in barriers {
            if barrier.collision?.shapes.first?.isColliding(with: projectedPosition) == true {
                // Extract risk limit from barrier name
                let limitType = extractLimitType(from: barrier.name)
                return findRiskLimit(type: limitType)
            }
        }

        return nil
    }
}
```

---

## 5. News Impact Ripples

### 5.1 Ripple Effect

```swift
class NewsRippleGenerator {
    func createRipple(
        news: NewsItem,
        originPosition: SIMD3<Float>,
        affectedSecurities: [(Security, correlation: Float)]
    ) -> [ModelEntity] {
        var entities: [ModelEntity] = []

        // Create expanding rings
        for ringIndex in 0..<5 {
            let ring = createRing(
                center: originPosition,
                radius: Float(ringIndex + 1) * 2.0,
                color: colorForSentiment(news.sentiment),
                opacity: 1.0 - Float(ringIndex) / 5.0
            )

            entities.append(ring)

            // Animate expansion
            animateRingExpansion(ring, targetRadius: Float(ringIndex + 1) * 4.0, duration: 2.0)
        }

        // Create connecting lines to affected securities
        for (security, correlation) in affectedSecurities {
            guard let securityPosition = findSecurityPosition(security) else { continue }

            let line = createConnectionLine(
                from: originPosition,
                to: securityPosition,
                intensity: correlation
            )

            entities.append(line)
        }

        return entities
    }

    private func createRing(
        center: SIMD3<Float>,
        radius: Float,
        color: SIMD4<Float>,
        opacity: Float
    ) -> ModelEntity {
        let mesh = MeshResource.generateTorus(majorRadius: radius, minorRadius: 0.1)

        var material = UnlitMaterial()
        material.color = .init(tint: UIColor(
            red: CGFloat(color.x),
            green: CGFloat(color.y),
            blue: CGFloat(color.z),
            alpha: CGFloat(opacity)
        ))
        material.blending = .transparent(opacity: .init(floatLiteral: Double(opacity)))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = center

        return entity
    }

    private func animateRingExpansion(_ entity: ModelEntity, targetRadius: Float, duration: Double) {
        let animation = FromToByAnimation<Transform>(
            from: entity.transform,
            to: Transform(
                scale: SIMD3<Float>(repeating: targetRadius / entity.scale.x),
                rotation: entity.orientation,
                translation: entity.position
            ),
            duration: duration
        )

        entity.playAnimation(animation)
    }
}
```

---

## 6. Performance Optimization

### 6.1 Rendering Budget

```swift
struct RenderingBudget {
    static let maxDrawCallsPerFrame = 100
    static let maxVerticesPerFrame = 1_000_000
    static let maxTextureMemory: Int64 = 512 * 1024 * 1024  // 512 MB
    static let targetFrameTime: Double = 1.0 / 90.0  // 90 fps
}
```

### 6.2 Instancing

```swift
class InstancedRenderer {
    func renderOptions(nodes: [OptionNode]) {
        // Group by size (for instancing)
        let grouped = Dictionary(grouping: nodes, by: { $0.size })

        for (size, nodeGroup) in grouped {
            // Create instanced mesh
            let mesh = MeshResource.generateSphere(radius: size)

            // Create instance transforms
            let transforms = nodeGroup.map { node in
                Transform(
                    scale: SIMD3<Float>(repeating: 1.0),
                    rotation: simd_quatf(),
                    translation: node.position
                )
            }

            // Render all at once with GPU instancing
            renderInstanced(mesh: mesh, transforms: transforms)
        }
    }
}
```

### 6.3 Culling

```swift
class FrustumCuller {
    func cullEntities(_ entities: [ModelEntity], camera: Camera) -> [ModelEntity] {
        let frustum = camera.frustum

        return entities.filter { entity in
            let bounds = entity.visualBounds(relativeTo: nil)
            return frustum.intersects(bounds)
        }
    }
}
```

### 6.4 Update Throttling

```swift
class VisualizationThrottler {
    private var lastUpdateTime: [String: Date] = [:]

    func shouldUpdate(security: Security, currentTime: Date) -> Bool {
        guard let lastUpdate = lastUpdateTime[security.symbol] else {
            lastUpdateTime[security.symbol] = currentTime
            return true
        }

        // Different throttle rates based on visibility
        let throttleInterval: TimeInterval = isVisible(security) ? 0.1 : 1.0

        if currentTime.timeIntervalSince(lastUpdate) > throttleInterval {
            lastUpdateTime[security.symbol] = currentTime
            return true
        }

        return false
    }
}
```

---

## 7. Spatial UI Elements

### 7.1 Floating Labels

```swift
class FloatingLabelGenerator {
    func createLabel(
        text: String,
        position: SIMD3<Float>,
        fontSize: Float = 0.05
    ) -> ModelEntity {
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: CGFloat(fontSize))
        )

        var material = UnlitMaterial()
        material.color = .init(tint: .white)

        let entity = ModelEntity(mesh: textMesh, materials: [material])
        entity.position = position

        // Billboard behavior (always face camera)
        entity.components.set(BillboardComponent())

        return entity
    }
}
```

### 7.2 Interactive Buttons

```swift
class SpatialButtonGenerator {
    func createButton(
        title: String,
        position: SIMD3<Float>,
        action: @escaping () -> Void
    ) -> ModelEntity {
        // Create button mesh
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.2, 0.05, 0.01))

        // Create button material
        var material = SimpleMaterial()
        material.color = .init(tint: .systemBlue)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position

        // Add text label
        let label = createLabel(text: title, position: SIMD3<Float>(0, 0, 0.01))
        entity.addChild(label)

        // Add interaction
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())

        // Store action
        entity.components.set(ButtonActionComponent(action: action))

        return entity
    }
}
```

---

## 8. Testing & Validation

### 8.1 Visual Regression Tests

```swift
class VisualizationTests: XCTestCase {
    func testTerrainGeneration() throws {
        let securities = generateMockSecurities(count: 100)
        let quotes = generateMockQuotes(for: securities)

        let generator = TerrainGenerator()
        let mesh = generator.generateTerrain(securities: securities, quotes: quotes)

        // Validate mesh properties
        XCTAssertGreaterThan(mesh.vertices.count, 0)
        XCTAssertEqual(mesh.vertices.count, mesh.normals.count)
        XCTAssertEqual(mesh.vertices.count, mesh.colors.count)

        // Validate heights are within expected range
        for vertex in mesh.vertices {
            XCTAssertGreaterThanOrEqual(vertex.y, 0)
            XCTAssertLessThanOrEqual(vertex.y, 100)
        }
    }

    func testOptionsSpiral() throws {
        let chain = generateMockOptionsChain()
        let generator = OptionsSpiralGenerator()
        let nodes = generator.generateSpiral(
            chain: chain,
            underlyingPosition: SIMD3<Float>(0, 0, 0)
        )

        // Validate spiral properties
        XCTAssertEqual(nodes.count, chain.calls.count + chain.puts.count)

        // Verify calls are on right, puts on left
        for node in nodes {
            if node.contract.type == .call {
                XCTAssertGreaterThan(node.position.x, 0)
            } else {
                XCTAssertLessThan(node.position.x, 0)
            }
        }
    }
}
```

### 8.2 Performance Tests

```swift
class PerformanceTests: XCTestCase {
    func testTerrainUpdatePerformance() throws {
        let generator = TerrainGenerator()
        let securities = generateMockSecurities(count: 500)
        let quotes = generateMockQuotes(for: securities)

        measure {
            let _ = generator.generateTerrain(securities: securities, quotes: quotes)
        }

        // Should complete in < 16ms (60fps budget)
    }
}
```

---

## 9. Future Enhancements

### 9.1 Advanced Visualizations

- **Heat Map Overlay**: Temperature-style visualization of volume/liquidity
- **Flow Visualization**: Animated money flow between sectors
- **Correlation Web**: 3D graph showing security correlations
- **Time Machine**: Scrub through historical market states in 3D

### 9.2 Custom Shaders

- **Water Effect**: Rippling surface for high volatility
- **Fire Effect**: Burning visualization for extreme moves
- **Particle Systems**: Trade executions as particle bursts

---

## 10. References

- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit/)
- [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Delaunay Triangulation](https://en.wikipedia.org/wiki/Delaunay_triangulation)
- [Level of Detail Techniques](https://en.wikipedia.org/wiki/Level_of_detail_(computer_graphics))

---

**Document Version History**:
- v1.0 (2025-11-24): Initial 3D visualization specification
