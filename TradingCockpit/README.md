# Trading Cockpit - Swift Project

**Version:** 0.3.0 (Sprint 3 - 3D Visualization)
**Platform:** visionOS 2.0+
**Language:** Swift 6.0+

---

## Project Structure

```
TradingCockpit/
├── App/
│   ├── TradingCockpitApp.swift      # Main app entry point
│   └── ContentView.swift             # Root view with auth routing
│
├── Core/
│   ├── Models/
│   │   ├── AppState.swift            # Global app state (@Observable)
│   │   ├── User.swift                # User & preferences models
│   │   ├── Account.swift             # Brokerage account models
│   │   ├── Security.swift            # Security (stocks, ETFs)
│   │   ├── Quote.swift               # Real-time market quotes
│   │   ├── Order.swift               # Trading order models
│   │   └── Position.swift            # Portfolio position models
│   │
│   ├── Services/
│   │   ├── WebSocketManager.swift     # WebSocket with auto-reconnect
│   │   ├── MarketDataHub.swift        # Quote distribution hub
│   │   └── AuthenticationService.swift # Broker authentication
│   │
│   └── Utilities/
│       ├── Logger.swift              # Structured logging system
│       ├── KeychainManager.swift    # Secure token storage
│       └── DatabaseManager.swift     # SQLite wrapper
│
├── Features/
│   ├── Trading/                      # Trading UI & logic
│   │   └── Views/
│   │       └── AuthenticationView.swift
│   ├── Visualization/                # 3D terrain rendering
│   │   ├── Views/
│   │   │   └── MarketVisualizationView.swift
│   │   ├── Engine/
│   │   │   ├── VisualizationEngine.swift
│   │   │   └── TerrainGenerator.swift
│   │   └── Models/
│   │       └── VisualizationModels.swift
│   ├── Gestures/                     # Hand tracking & gestures
│   └── Portfolio/                    # Portfolio views
│
├── Integration/
│   ├── Brokers/                      # Broker API adapters
│   ├── MarketData/                   # Market data providers
│   └── News/                         # News API adapters
│
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

## Sprint 1 Deliverables ✅

### Core Infrastructure
- [x] Project structure and organization
- [x] Logging framework with severity levels
- [x] Keychain manager for secure storage
- [x] SQLite database with core tables
- [x] Application state management

### Data Models
- [x] User & Account models
- [x] Security & Quote models
- [x] Order & Position models
- [x] Complete type system (enums, structs)

### Foundation Features
- [x] App initialization flow
- [x] Authentication routing (placeholder)
- [x] Database schema creation
- [x] Secure token storage

## Sprint 2 Deliverables ✅

### Market Data Pipeline
- [x] WebSocket connection manager with auto-reconnect
- [x] Exponential backoff for reconnections
- [x] Heartbeat monitoring (30s intervals)
- [x] Polygon.io WebSocket integration
- [x] Real-time quote streaming
- [x] Market data hub with quote distribution
- [x] LRU quote cache (1000 quotes max)
- [x] Update prioritization (visible vs background symbols)
- [x] AsyncStream + Combine publishers

### Authentication
- [x] Alpaca broker adapter
- [x] API key authentication
- [x] Account info fetching
- [x] Position syncing
- [x] Order submission (market & limit)
- [x] Authentication service
- [x] Keychain integration for credentials
- [x] Full authentication UI with form validation
- [x] Session restoration

### Integration
- [x] AlpacaBrokerAdapter with REST API
- [x] PolygonDataProvider with WebSocket
- [x] Paper trading support

## Sprint 3 Deliverables ✅

### 3D Visualization Engine
- [x] RealityKit scene foundation
- [x] Grid-based terrain generation
- [x] Color gradient system (P&L visualization)
- [x] Profit/loss color mapping (red → yellow → green)
- [x] Security label system with billboarding
- [x] Camera controls (pan, rotate, zoom)
- [x] Drag gesture for camera rotation
- [x] Pinch gesture for zoom
- [x] Real-time terrain updates
- [x] Performance monitoring (FPS counter)
- [x] Terrain animation on updates
- [x] Grid helper for debugging
- [x] Lighting system (directional + ambient)

### Visualization Features
- [x] MarketVisualizationView (main 3D view)
- [x] VisualizationEngine (core rendering)
- [x] TerrainGenerator (mesh generation)
- [x] Position-based terrain height mapping
- [x] Interactive position chips UI
- [x] Toggle controls (labels, grid)
- [x] Camera reset functionality
- [x] Mock data system for testing

---

## Key Classes & Protocols

### AppState
Global observable state for the application. Tracks authentication, selected securities, focus mode, and connection status.

### Logger
Centralized logging with levels: debug, info, warning, error, critical. Integrates with unified logging system.

### KeychainManager
Secure storage for authentication tokens and sensitive data. Uses iOS Keychain Services API.

### DatabaseManager
SQLite wrapper with core tables:
- `securities` - Security reference data
- `orders` - Order audit trail
- `positions` - Current positions
- `watchlists` - User watchlists

---

## Build Configuration

### Platform Requirements
- **visionOS**: 2.0+
- **Xcode**: 15.2+
- **Swift**: 6.0+

### Dependencies
- **Native Frameworks**:
  - SwiftUI (UI framework)
  - RealityKit (3D rendering) ✅
  - Combine (reactive streams) ✅
  - Security (Keychain) ✅
  - SQLite3 (database) ✅

### External Dependencies
- None for Sprint 1 (keeping it native)

---

## Next Steps (Sprint 4)

### Trading Execution
- [ ] Order entry UI (market, limit, stop)
- [ ] Order validation and preview
- [ ] One-click trading from visualization
- [ ] Position sizing calculator
- [ ] Risk management controls

### Enhanced Visualization
- [ ] Connect real market data to terrain
- [ ] Volume visualization (bar height/opacity)
- [ ] Sector grouping and clustering
- [ ] Historical P&L replay
- [ ] Performance improvements (LOD, culling)

---

## Running the Project

### Prerequisites
1. Xcode 15.2+ installed
2. Apple Vision Pro device or simulator
3. Apple Developer account

### Setup Steps
```bash
# 1. Clone the repository
git clone <repo-url>
cd visionOS_Financial-Trading-Cockpit

# 2. Open in Xcode
open TradingCockpit.xcodeproj  # (Will be created when building in Xcode)

# 3. Select target device
# - Apple Vision Pro (Device)
# - Apple Vision Pro (Simulator)

# 4. Build and run
# Cmd+R in Xcode
```

### API Keys (Coming in Sprint 2)
- Alpaca API Key (for paper trading)
- Polygon.io API Key (for market data)

---

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use `// MARK:` comments for organization
- Prefer structs over classes when possible
- Use `@Observable` for state management
- Use actors for thread-safe shared state

### Commit Messages
Follow Conventional Commits:
```
feat: add new feature
fix: bug fix
docs: documentation
refactor: code restructuring
test: adding tests
```

### Testing
- Minimum 80% code coverage
- Unit tests for all business logic
- Integration tests for API calls
- UI tests for critical flows

---

## Architecture Decisions

### Why `@Observable` instead of `@ObservableObject`?
Using Swift 5.9's new `@Observable` macro for cleaner, more performant state management.

### Why SQLite instead of Core Data?
Direct control over schema, better performance for financial data, simpler migration strategy.

### Why native frameworks only?
Minimizing dependencies keeps app lightweight, reduces security surface area, and improves App Store review chances.

---

## Security Notes

### Sensitive Data Handling
- ✅ Auth tokens stored in Keychain only
- ✅ No credentials in code or git
- ✅ Database is not encrypted (no sensitive data stored)
- ✅ Audit trail for all orders (SEC compliance)

### Best Practices
- Never log sensitive data
- Use HTTPS for all network calls
- Implement session timeout (15 minutes)
- Require re-auth for critical actions

---

## License

Copyright © 2025 Trading Cockpit. All rights reserved.

---

## Contact

For questions or issues, please refer to the project documentation in `/docs`.

**Status**: Sprint 3 Complete ✅
**Next Sprint**: Trading Execution & Enhanced Visualization
