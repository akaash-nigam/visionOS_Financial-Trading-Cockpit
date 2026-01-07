# System Architecture Document
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Executive Summary

This document defines the system architecture for Financial Trading Cockpit, a spatial computing trading platform for Apple Vision Pro. The architecture is designed to handle real-time financial data streams, render complex 3D visualizations at 90fps, and execute trades with sub-100ms latency.

### Key Architectural Goals
- **Performance**: 90fps rendering with 1,000+ securities
- **Reliability**: 99.9% uptime for trading hours
- **Scalability**: Support multiple brokers and data sources
- **Security**: Bank-grade security for financial transactions
- **Maintainability**: Modular design for easy updates

---

## 2. System Overview

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌────────────┐  ┌────────────┐  ┌─────────────────────┐   │
│  │  SwiftUI   │  │ RealityKit │  │  Gesture/Eye Track  │   │
│  │  Windows   │  │   Scene    │  │     Recognition     │   │
│  └────────────┘  └────────────┘  └─────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                    Application Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Trading    │  │ Visualization│  │  Risk Manager    │  │
│  │  Engine     │  │   Engine     │  │                  │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Portfolio  │  │   Workspace  │  │  News Service    │  │
│  │  Manager    │  │   Manager    │  │                  │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                      Data Layer                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Market     │  │    Cache     │  │   Persistence    │  │
│  │  Data Hub   │  │   Manager    │  │     Layer        │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                  Integration Layer                           │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Broker     │  │  Market Data │  │   News API       │  │
│  │  Adapters   │  │  Adapters    │  │   Adapters       │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │   External    │
                    │   Services    │
                    └───────────────┘
```

### 2.2 Component Responsibilities

| Layer | Components | Responsibilities |
|-------|-----------|------------------|
| **Presentation** | SwiftUI Windows | 2D UI panels, forms, settings |
| | RealityKit Scene | 3D market visualization, spatial UI |
| | Gesture Recognition | Hand tracking, eye tracking, voice |
| **Application** | Trading Engine | Order creation, validation, execution |
| | Visualization Engine | Terrain generation, options spirals |
| | Risk Manager | Risk calculations, limit enforcement |
| | Portfolio Manager | Position tracking, P&L calculation |
| | Workspace Manager | Layout persistence, state management |
| | News Service | News fetching, sentiment analysis |
| **Data** | Market Data Hub | WebSocket management, data normalization |
| | Cache Manager | In-memory caching, update throttling |
| | Persistence Layer | SQLite, Core Data, UserDefaults |
| **Integration** | Broker Adapters | API abstraction for each broker |
| | Market Data Adapters | Data feed abstraction |
| | News API Adapters | News source abstraction |

---

## 3. Component Details

### 3.1 Presentation Layer

#### 3.1.1 SwiftUI Windows
- **Purpose**: Traditional 2D UI for forms, settings, detailed data
- **Technology**: SwiftUI on visionOS
- **Responsibilities**:
  - Order entry forms
  - Settings and preferences
  - Account management
  - Detailed analytics tables

#### 3.1.2 RealityKit Scene
- **Purpose**: 3D spatial visualization and interaction
- **Technology**: RealityKit + Metal shaders
- **Responsibilities**:
  - Market topography rendering
  - Options chain spirals
  - Risk barriers visualization
  - News ripple effects
  - Spatial UI elements (floating buttons, labels)

#### 3.1.3 Gesture Recognition System
- **Purpose**: Natural interaction through gestures and eye tracking
- **Technology**: ARKit hand tracking, eye tracking, Speech framework
- **Responsibilities**:
  - Gesture detection and classification
  - Eye tracking for target selection
  - Voice command recognition
  - Haptic feedback coordination

### 3.2 Application Layer

#### 3.2.1 Trading Engine
```swift
class TradingEngine {
    // Order lifecycle management
    func createOrder(security: Security, action: OrderAction, quantity: Int) -> Order
    func validateOrder(order: Order) -> ValidationResult
    func submitOrder(order: Order) -> Result<OrderConfirmation, TradingError>
    func cancelOrder(orderId: String) -> Result<Void, TradingError>
    func modifyOrder(orderId: String, changes: OrderModification) -> Result<Void, TradingError>

    // Order monitoring
    func observeOrderStatus(orderId: String) -> AsyncStream<OrderStatus>
    func observeExecutions() -> AsyncStream<Execution>
}
```

**Key Features**:
- Order validation (funds, position limits, risk checks)
- Multi-broker order routing
- Order status tracking
- Execution reporting
- FIX protocol support

#### 3.2.2 Visualization Engine
```swift
class VisualizationEngine {
    // Terrain generation
    func generateMarketTerrain(securities: [Security]) -> TerrainMesh
    func updateTerrainForPrice(security: Security, newPrice: Decimal)

    // Options visualization
    func generateOptionsSpiral(chain: OptionsChain) -> SpiralGeometry
    func updateOptionsSpiral(contract: OptionContract, volume: Int)

    // Risk barriers
    func generateRiskBarriers(limits: [RiskLimit]) -> [BarrierEntity]
    func updateBarrierStatus(limit: RiskLimit, utilization: Double)

    // News ripples
    func createNewsRipple(news: NewsItem, origin: Security) -> RippleEffect
}
```

**Key Features**:
- Dynamic mesh generation and updates
- LOD (Level of Detail) management
- Material and shader management
- Performance optimization (culling, instancing)

#### 3.2.3 Risk Manager
```swift
class RiskManager {
    // Risk calculations
    func calculatePortfolioRisk() -> PortfolioRisk
    func calculatePositionRisk(security: Security) -> PositionRisk
    func calculateOrderImpact(order: Order) -> RiskImpact

    // Risk limits
    func checkRiskLimits(order: Order) -> RiskCheckResult
    func getRiskLimits(for user: User) -> [RiskLimit]
    func updateRiskLimit(limit: RiskLimit)

    // Risk metrics
    func calculateVaR(confidence: Double, horizon: Days) -> Decimal
    func calculateBetaWeightedDelta() -> Decimal
    func calculatePortfolioGreeks() -> Greeks
}
```

**Key Features**:
- Real-time risk calculations
- Pre-trade risk checks (SEC 15c3-5 compliance)
- Position limit enforcement
- VaR, CVaR, Greeks calculations
- Sector concentration monitoring

#### 3.2.4 Portfolio Manager
```swift
class PortfolioManager {
    // Position tracking
    func getPositions() -> [Position]
    func getPosition(security: Security) -> Position?
    func observePositionUpdates() -> AsyncStream<Position>

    // P&L calculations
    func calculatePnL() -> PnL
    func calculateRealizedPnL(period: DateInterval) -> Decimal
    func calculateUnrealizedPnL() -> Decimal

    // Portfolio analytics
    func getPortfolioComposition() -> [SectorAllocation]
    func getPortfolioPerformance(period: DateInterval) -> Performance
}
```

#### 3.2.5 Workspace Manager
```swift
class WorkspaceManager {
    // Workspace persistence
    func saveWorkspace(workspace: Workspace)
    func loadWorkspace(id: UUID) -> Workspace?
    func syncToCloud(workspace: Workspace)

    // Layout management
    func addWindow(type: WindowType, position: SIMD3<Float>)
    func removeWindow(id: UUID)
    func updateWindowPosition(id: UUID, position: SIMD3<Float>)
}
```

#### 3.2.6 News Service
```swift
class NewsService {
    // News fetching
    func streamNews(filter: NewsFilter) -> AsyncStream<NewsItem>
    func getHeadlines(for security: Security) -> [NewsItem]

    // Sentiment analysis
    func analyzeSentiment(news: NewsItem) -> Sentiment
    func calculateImpactScore(news: NewsItem) -> ImpactScore

    // News alerts
    func createAlert(filter: NewsFilter) -> NewsAlert
    func observeAlerts() -> AsyncStream<NewsAlert>
}
```

### 3.3 Data Layer

#### 3.3.1 Market Data Hub
```swift
class MarketDataHub {
    // Real-time data streams
    func subscribeToQuotes(securities: [Security]) -> AsyncStream<Quote>
    func subscribeToLevel2(security: Security) -> AsyncStream<OrderBook>
    func subscribeToTrades(security: Security) -> AsyncStream<Trade>

    // Data management
    func setUpdateThrottle(interval: TimeInterval)
    func setPriority(securities: [Security], priority: Priority)
}
```

**Key Features**:
- WebSocket connection management
- Automatic reconnection with exponential backoff
- Heartbeat monitoring
- Data normalization across providers
- Update throttling and batching
- Priority queue for visible securities

#### 3.3.2 Cache Manager
```swift
class CacheManager {
    // In-memory caching
    func cache<T>(key: String, value: T, ttl: TimeInterval)
    func get<T>(key: String) -> T?
    func invalidate(key: String)

    // Cache strategies
    func setMaxSize(bytes: Int)
    func setEvictionPolicy(policy: EvictionPolicy)
}
```

**Key Features**:
- LRU eviction for quotes
- TTL-based expiration
- Memory pressure handling
- Cache warming for workspace securities

#### 3.3.3 Persistence Layer
```swift
class PersistenceLayer {
    // Historical data (SQLite)
    func saveHistoricalPrices(security: Security, prices: [OHLCV])
    func getHistoricalPrices(security: Security, range: DateInterval) -> [OHLCV]

    // User data (Core Data)
    func saveWorkspace(workspace: Workspace)
    func saveWatchlist(watchlist: Watchlist)

    // Preferences (UserDefaults + CloudKit)
    func savePreferences(preferences: UserPreferences)
    func syncToCloud()
}
```

### 3.4 Integration Layer

#### 3.4.1 Broker Adapter Protocol
```swift
protocol BrokerAdapter {
    // Authentication
    func authenticate(credentials: BrokerCredentials) async throws -> AuthToken
    func refreshToken(token: AuthToken) async throws -> AuthToken

    // Account info
    func getAccountInfo() async throws -> AccountInfo
    func getPositions() async throws -> [Position]

    // Trading
    func submitOrder(order: Order) async throws -> OrderConfirmation
    func cancelOrder(orderId: String) async throws
    func observeOrderUpdates() -> AsyncStream<OrderUpdate>

    // Market data
    func subscribeToQuotes(symbols: [String]) -> AsyncStream<Quote>
}
```

**Implementations**:
- `InteractiveBrokersAdapter`
- `TDAmeritradAdapter`
- `ETradeAdapter`
- `AlpacaAdapter`

---

## 4. Data Flow

### 4.1 Market Data Flow
```
External Feed → WebSocket → Market Data Hub → Cache Manager → Visualization Engine
                                           ↓
                                    Portfolio Manager
                                           ↓
                                      RealityKit Scene
```

**Timing Budget**:
- WebSocket receive to Cache: < 5ms
- Cache to Visualization Engine: < 10ms
- Visualization to RealityKit: < 20ms
- **Total**: < 35ms (leaves 55ms for rendering at 90fps)

### 4.2 Order Execution Flow
```
User Gesture → Gesture Recognition → Trading Engine → Broker Adapter → External Broker
                                           ↓
                                    Risk Manager (validation)
                                           ↓
                                    Portfolio Manager (update)
```

**Timing Budget**:
- Gesture to Order Creation: < 50ms
- Risk Validation: < 20ms
- Broker Submission: < 100ms
- **Total**: < 170ms target

### 4.3 News Impact Flow
```
News API → News Service → Sentiment Analysis → Market Data Hub (correlation)
                                           ↓
                              Visualization Engine (ripple effect)
```

---

## 5. Threading Model

### 5.1 Thread Architecture

| Thread/Queue | Purpose | Components |
|--------------|---------|------------|
| **Main Thread** | UI updates, RealityKit | SwiftUI, RealityKit Scene |
| **High Priority** | Market data processing | Market Data Hub, Cache Manager |
| **Default** | Business logic | Trading Engine, Portfolio Manager |
| **Background** | Heavy computation | Terrain generation, Greeks calculation |
| **Utility** | News, analytics | News Service, sentiment analysis |

### 5.2 Concurrency Strategy

```swift
// Swift Concurrency (async/await + actors)

actor MarketDataHub {
    // Thread-safe market data management
}

actor CacheManager {
    // Thread-safe cache access
}

@MainActor
class VisualizationEngine {
    // Always on main thread for RealityKit
}

class TradingEngine {
    // Uses async/await for broker communication
    func submitOrder(order: Order) async throws -> OrderConfirmation
}
```

**Key Principles**:
- Use `@MainActor` for all RealityKit operations
- Use `actor` for shared mutable state
- Use `async/await` for asynchronous operations
- Avoid locks; prefer actor isolation

---

## 6. State Management

### 6.1 State Architecture

```swift
// Global App State (Observable)
@Observable
class AppState {
    var currentWorkspace: Workspace
    var selectedSecurities: [Security]
    var activeFocusMode: FocusMode
    var connectionStatus: ConnectionStatus
}

// Domain State (Actors)
actor TradingState {
    var pendingOrders: [Order]
    var executedOrders: [Order]
}

actor PortfolioState {
    var positions: [Position]
    var pnl: PnL
}

actor MarketDataState {
    var quotes: [String: Quote]
    var orderBooks: [String: OrderBook]
}
```

### 6.2 State Synchronization

- **Local State**: Immediate updates for UI responsiveness
- **Broker State**: Periodic sync (every 5s) + real-time order updates
- **Cloud State**: Workspace sync on change (debounced 30s)

---

## 7. Performance Optimization

### 7.1 Rendering Optimization

**Level of Detail (LOD)**:
```swift
enum LODLevel {
    case high      // < 2m distance: full detail
    case medium    // 2-5m: reduced polygons
    case low       // 5-10m: billboard sprites
    case culled    // > 10m or out of view: not rendered
}
```

**Instancing**:
- Reuse meshes for similar securities
- GPU instancing for options spheres

**Frustum Culling**:
- Only render securities in view
- Update culling every frame

**Metal Shaders**:
- GPU-accelerated terrain coloring
- Vertex shaders for height animation

### 7.2 Data Optimization

**Throttling**:
```swift
// Update visible securities every 100ms
// Update off-screen securities every 1s
// Update very distant securities every 5s
```

**Batching**:
```swift
// Batch WebSocket messages
// Process 50 updates per frame max
// Defer non-critical updates
```

**Caching**:
```swift
// Cache last 1000 quotes in memory
// Cache 30 days of OHLC in SQLite
// Cache workspace in memory + disk
```

### 7.3 Memory Management

**Target Memory Budget**:
- RealityKit assets: < 1GB
- Market data cache: < 500MB
- Historical data: < 1GB
- SwiftUI windows: < 500MB
- **Total**: < 3GB (leaves 1GB buffer)

**Memory Pressure Handling**:
```swift
// Level 1 (Warning): Clear unused caches
// Level 2 (Critical): Reduce LOD, clear distant meshes
// Level 3 (Emergency): Disconnect non-critical data feeds
```

---

## 8. Security Architecture

### 8.1 Authentication Flow

```
App Launch → Check Keychain → Token Valid?
                                    ├── Yes → Continue
                                    └── No → Prompt for credentials
                                                 ↓
                                         OAuth 2.0 Flow
                                                 ↓
                                          Store in Keychain
                                                 ↓
                                         Enable OpticID
```

### 8.2 Security Layers

| Layer | Security Measure |
|-------|-----------------|
| **Transport** | TLS 1.3 for all connections |
| **Authentication** | OAuth 2.0 + 2FA + OpticID |
| **Storage** | Keychain for tokens, encrypted SQLite |
| **Memory** | Secure enclaves for sensitive data |
| **Session** | 15-minute timeout, require re-auth |

### 8.3 Compliance

- **Order Audit Trail**: Every order logged to encrypted SQLite
- **Pre-Trade Checks**: SEC 15c3-5 compliance in Risk Manager
- **Data Residency**: Trading data stays on device
- **Privacy**: Eye tracking data never recorded

---

## 9. Error Handling

### 9.1 Error Categories

```swift
enum TradingCockpitError: Error {
    case network(NetworkError)
    case broker(BrokerError)
    case validation(ValidationError)
    case rendering(RenderingError)
    case authentication(AuthError)
}

enum Severity {
    case info       // Informational, no action needed
    case warning    // Issue but recoverable
    case error      // Operation failed, user action needed
    case critical   // System instability, force restart
}
```

### 9.2 Recovery Strategies

| Error Type | Recovery Strategy |
|------------|------------------|
| **WebSocket disconnect** | Exponential backoff reconnect (1s, 2s, 4s, 8s) |
| **Order rejection** | Display reason, allow modification |
| **Broker API rate limit** | Queue orders, retry with backoff |
| **Out of memory** | Clear caches, reduce LOD, alert user |
| **Gesture recognition failure** | Fallback to voice commands |

---

## 10. Deployment Architecture

### 10.1 Development Environments

| Environment | Purpose | Configuration |
|-------------|---------|--------------|
| **Development** | Local testing | Mock brokers, sample data |
| **Staging** | Pre-release testing | Broker paper trading APIs |
| **Production** | Live trading | Real broker APIs, live data |

### 10.2 Configuration Management

```swift
enum Environment {
    case development
    case staging
    case production

    var brokerEndpoint: URL {
        switch self {
        case .development: return URL(string: "https://mock.broker.com")!
        case .staging: return URL(string: "https://paper.broker.com")!
        case .production: return URL(string: "https://api.broker.com")!
        }
    }
}
```

---

## 11. Monitoring & Observability

### 11.1 Metrics to Track

**Performance Metrics**:
- Frame rate (target: 90fps)
- Market data latency (target: < 50ms)
- Order execution time (target: < 100ms)
- Memory usage (target: < 3GB)
- Network bandwidth (track per connection)

**Business Metrics**:
- Orders per session
- Order success rate
- Feature usage (topography, options, gestures)
- Session duration
- Crash rate (target: < 0.1%)

### 11.2 Logging Strategy

```swift
enum LogLevel {
    case debug      // Development only
    case info       // General information
    case warning    // Potential issues
    case error      // Operation failures
    case critical   // System failures
}

// Structured logging
Logger.info("Order submitted", metadata: [
    "orderId": orderId,
    "symbol": symbol,
    "quantity": quantity,
    "type": orderType
])
```

### 11.3 Error Reporting

- **Crashes**: Automatic crash reports (TestFlight, App Store)
- **API Errors**: Log to file, optionally upload
- **User Feedback**: In-app feedback form
- **Performance Issues**: FPS drops, latency spikes

---

## 12. Technology Stack Summary

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Platform** | visionOS | 2.0+ | Operating system |
| **Language** | Swift | 6.0+ | Primary language |
| **UI** | SwiftUI | Latest | 2D UI framework |
| **3D** | RealityKit | Latest | 3D rendering |
| **GPU** | Metal | Latest | Shader programming |
| **Concurrency** | Swift Concurrency | Latest | async/await, actors |
| **Reactive** | Combine | Latest | Reactive streams |
| **Networking** | URLSession | Latest | HTTP/WebSocket |
| **Storage** | SQLite, Core Data | Latest | Persistence |
| **Cloud** | CloudKit | Latest | Workspace sync |
| **ML** | Core ML | Latest | Sentiment analysis |

---

## 13. Module Dependencies

```
┌──────────────┐
│  Presentation│
└──────┬───────┘
       │
┌──────▼───────┐
│  Application │
└──────┬───────┘
       │
┌──────▼───────┐
│     Data     │
└──────┬───────┘
       │
┌──────▼───────┐
│  Integration │
└──────────────┘
```

**Dependency Rules**:
- Layers only depend on layers below
- No circular dependencies
- Integration layer has no dependencies (only Swift stdlib)
- Application layer depends on Data + Integration
- Presentation layer depends on Application

---

## 14. Testing Strategy Overview

| Component | Testing Approach |
|-----------|-----------------|
| **Broker Adapters** | Mock APIs, integration tests |
| **Trading Engine** | Unit tests, order simulation |
| **Risk Manager** | Unit tests with edge cases |
| **Visualization Engine** | Visual regression tests |
| **Gesture Recognition** | Recorded gesture playback |
| **End-to-End** | Automated UI tests |

---

## 15. Future Extensibility

### 15.1 Plugin Architecture (Post-V1)

```swift
protocol TradingStrategy {
    func analyze(market: MarketData) -> [Signal]
    func generateOrders(signals: [Signal]) -> [Order]
}

protocol Indicator {
    func calculate(prices: [Decimal]) -> [Decimal]
}
```

### 15.2 API for Third-Party Integration (Post-V1)

```swift
// Allow users to build custom visualizations
protocol CustomVisualization {
    func render(data: MarketData, scene: RealityKit.Scene)
}
```

---

## 16. Open Architecture Questions

1. **WebSocket Library**: Use URLSession or third-party (Starscream)?
2. **FIX Protocol**: Build custom or use library (FIXparser)?
3. **Greeks Calculation**: Core ML model or traditional Black-Scholes?
4. **Mesh Generation**: Custom algorithm or third-party (Delaunay triangulation library)?
5. **State Management**: SwiftUI @Observable or custom state container?

**Decisions Required Before Implementation**

---

## 17. References

- [visionOS Documentation](https://developer.apple.com/visionos/)
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [FIX Protocol Specification](https://www.fixtrading.org/)
- [SEC Rule 15c3-5](https://www.sec.gov/rules/final/2010/34-63241.pdf)

---

**Document Version History**:
- v1.0 (2025-11-24): Initial architecture design
