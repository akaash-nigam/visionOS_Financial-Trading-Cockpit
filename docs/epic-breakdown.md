# Epic Breakdown & User Stories
## Financial Trading Cockpit MVP

**Version:** 1.0
**Last Updated:** 2025-11-24
**Sprint Duration:** 2 weeks
**MVP Timeline:** 10 weeks (5 sprints)

---

## Epic Overview

| Epic ID | Epic Name | Priority | Estimated Weeks | Dependencies |
|---------|-----------|----------|-----------------|--------------|
| **E1** | Foundation & Infrastructure | P0 | 2 weeks | None |
| **E2** | Market Data Pipeline | P0 | 2 weeks | E1 |
| **E3** | 3D Visualization Engine | P0 | 3 weeks | E2 |
| **E4** | Trading Execution | P0 | 2 weeks | E1, E2 |
| **E5** | Portfolio Management | P0 | 1 week | E4 |
| **E6** | Gesture Interface | P0 | 2 weeks | E3 |
| **E7** | Polish & Testing | P0 | 2 weeks | All |

**Total**: 14 weeks of work → 10 weeks with parallelization

---

## EPIC 1: Foundation & Infrastructure

**Goal**: Establish core technical foundation
**Duration**: 2 weeks (Sprint 1)
**Team**: 1 engineer
**Acceptance**: Authentication works, database operational, logging active

### User Stories

#### E1-US1: Project Setup
**As a** developer
**I want** a well-structured Xcode project
**So that** the team can work efficiently

**Acceptance Criteria**:
- [ ] Xcode project created for visionOS
- [ ] Folder structure matches architecture doc
- [ ] SwiftLint configured
- [ ] Git repo initialized
- [ ] README with setup instructions

**Effort**: 2 points
**Priority**: P0

---

#### E1-US2: Authentication System
**As a** user
**I want** to securely connect my brokerage account
**So that** I can trade through the app

**Acceptance Criteria**:
- [ ] OAuth 2.0 flow implemented for Alpaca
- [ ] Tokens stored securely in Keychain
- [ ] Token refresh logic working
- [ ] Error handling for failed auth
- [ ] UI for sign-in flow

**Effort**: 8 points
**Priority**: P0
**Technical Notes**:
```swift
// BrokerAuthenticator.swift
class AlpacaAuthenticator {
    func authenticate() async throws -> AuthToken
    func refreshToken() async throws -> AuthToken
}
```

---

#### E1-US3: Keychain Integration
**As a** developer
**I want** secure storage for sensitive data
**So that** user credentials are protected

**Acceptance Criteria**:
- [ ] KeychainManager implemented
- [ ] Store/retrieve/delete operations work
- [ ] Unit tests for Keychain operations
- [ ] Error handling for access failures

**Effort**: 3 points
**Priority**: P0

---

#### E1-US4: Database Setup
**As a** developer
**I want** a SQLite database
**So that** I can persist app data

**Acceptance Criteria**:
- [ ] SQLite wrapper created
- [ ] Core tables created (securities, orders, positions)
- [ ] Database migrations supported
- [ ] Unit tests for CRUD operations

**Effort**: 5 points
**Priority**: P0

---

#### E1-US5: Logging Framework
**As a** developer
**I want** structured logging
**So that** I can debug issues easily

**Acceptance Criteria**:
- [ ] Logger class with severity levels
- [ ] File logging configured
- [ ] Console logging in DEBUG mode
- [ ] Sensitive data redaction

**Effort**: 2 points
**Priority**: P0

---

## EPIC 2: Market Data Pipeline

**Goal**: Stream real-time market quotes
**Duration**: 2 weeks (Sprint 2)
**Team**: 1 engineer
**Acceptance**: Real-time quotes flowing from Polygon to UI

### User Stories

#### E2-US1: WebSocket Connection Manager
**As a** developer
**I want** reliable WebSocket connections
**So that** market data streams without interruption

**Acceptance Criteria**:
- [ ] WebSocketManager class implemented
- [ ] Auto-reconnect with exponential backoff
- [ ] Heartbeat monitoring
- [ ] Connection state observable
- [ ] Unit tests for reconnection logic

**Effort**: 8 points
**Priority**: P0

---

#### E2-US2: Polygon.io Integration
**As a** user
**I want** real-time stock quotes
**So that** I can see current market prices

**Acceptance Criteria**:
- [ ] Polygon WebSocket integration
- [ ] Subscribe/unsubscribe to symbols
- [ ] Parse incoming quote messages
- [ ] Handle connection errors gracefully

**Effort**: 5 points
**Priority**: P0
**API Endpoint**: `wss://socket.polygon.io/stocks`

---

#### E2-US3: Market Data Hub
**As a** developer
**I want** a centralized data distribution layer
**So that** multiple components can receive market data

**Acceptance Criteria**:
- [ ] MarketDataHub actor implemented
- [ ] AsyncStream for quote distribution
- [ ] Combine publishers for legacy support
- [ ] Thread-safe data access

**Effort**: 5 points
**Priority**: P0

---

#### E2-US4: Quote Caching
**As a** developer
**I want** an LRU cache for quotes
**So that** app remains performant

**Acceptance Criteria**:
- [ ] QuoteCache actor with LRU eviction
- [ ] Configurable cache size (1000 quotes)
- [ ] Cache hit/miss metrics
- [ ] Memory pressure handling

**Effort**: 3 points
**Priority**: P0

---

#### E2-US5: Data Throttling
**As a** developer
**I want** to throttle quote updates
**So that** UI doesn't overwhelm

**Acceptance Criteria**:
- [ ] Visible securities update every 100ms
- [ ] Background securities update every 1s
- [ ] Configurable throttle rates
- [ ] Performance tests pass

**Effort**: 3 points
**Priority**: P1

---

## EPIC 3: 3D Visualization Engine

**Goal**: Render market data as 3D terrain
**Duration**: 3 weeks (Sprint 2-3)
**Team**: 1 engineer
**Acceptance**: 50+ securities render at 60fps

### User Stories

#### E3-US1: RealityKit Scene Setup
**As a** developer
**I want** a RealityKit scene configured
**So that** I can render 3D content

**Acceptance Criteria**:
- [ ] RealityView integrated in SwiftUI
- [ ] Camera positioned correctly
- [ ] Lighting configured
- [ ] Basic interaction working

**Effort**: 5 points
**Priority**: P0

---

#### E3-US2: Terrain Generation (Simplified)
**As a** user
**I want** to see stocks as a 3D landscape
**So that** I can visualize the market spatially

**Acceptance Criteria**:
- [ ] Generate grid-based terrain for 50 securities
- [ ] Height maps to stock price
- [ ] Securities grouped by sector
- [ ] 60fps minimum with 50 securities

**Effort**: 13 points
**Priority**: P0
**Technical Approach**:
```swift
// Simplified approach for MVP:
// - Use grid layout (not Delaunay)
// - Use box geometries (not smooth terrain)
// - Defer LOD system
```

---

#### E3-US3: Color Gradients
**As a** user
**I want** stocks colored by performance
**So that** I can quickly identify winners/losers

**Acceptance Criteria**:
- [ ] Green for positive change
- [ ] Red for negative change
- [ ] White/gray for no change
- [ ] Smooth color transitions

**Effort**: 3 points
**Priority**: P0

---

#### E3-US4: Security Labels
**As a** user
**I want** to see stock symbols in 3D space
**So that** I know which stock I'm looking at

**Acceptance Criteria**:
- [ ] Text labels above each terrain element
- [ ] Labels face camera (billboard)
- [ ] Font size scales with distance
- [ ] Labels hide when too far

**Effort**: 5 points
**Priority**: P1

---

#### E3-US5: Camera Controls
**As a** user
**I want** to navigate the 3D scene
**So that** I can explore different stocks

**Acceptance Criteria**:
- [ ] Pan with gesture
- [ ] Zoom with pinch
- [ ] Rotate with two-finger drag
- [ ] Reset camera button

**Effort**: 5 points
**Priority**: P0

---

#### E3-US6: Real-time Updates
**As a** user
**I want** terrain to update with live prices
**So that** I see current market state

**Acceptance Criteria**:
- [ ] Terrain height updates on new quotes
- [ ] Color updates on price changes
- [ ] Smooth animations (not jarring)
- [ ] No frame drops during updates

**Effort**: 8 points
**Priority**: P0

---

## EPIC 4: Trading Execution

**Goal**: Execute market & limit orders
**Duration**: 2 weeks (Sprint 3-4)
**Team**: 1 engineer
**Acceptance**: Successfully execute test trades

### User Stories

#### E4-US1: Alpaca Broker Integration
**As a** developer
**I want** to integrate with Alpaca's API
**So that** orders can be submitted

**Acceptance Criteria**:
- [ ] AlpacaBrokerAdapter implemented
- [ ] Submit market orders
- [ ] Submit limit orders
- [ ] Cancel orders
- [ ] Get order status

**Effort**: 8 points
**Priority**: P0
**API Docs**: https://alpaca.markets/docs/

---

#### E4-US2: Order Entry UI
**As a** user
**I want** a form to enter trade details
**So that** I can place orders

**Acceptance Criteria**:
- [ ] Security selector
- [ ] Quantity input (slider + text)
- [ ] Order type picker (market/limit)
- [ ] Limit price input (for limit orders)
- [ ] Buy/Sell buttons
- [ ] Clear validation errors

**Effort**: 8 points
**Priority**: P0

---

#### E4-US3: Order Validation
**As a** user
**I want** orders validated before submission
**So that** I don't make mistakes

**Acceptance Criteria**:
- [ ] Check sufficient buying power
- [ ] Validate quantity > 0
- [ ] Validate limit price (if applicable)
- [ ] Check market hours
- [ ] Show clear error messages

**Effort**: 5 points
**Priority**: P0

---

#### E4-US4: Order Submission
**As a** user
**I want** to submit orders to my broker
**So that** I can execute trades

**Acceptance Criteria**:
- [ ] Submit button triggers order
- [ ] Loading state shown
- [ ] Success confirmation shown
- [ ] Error handling with user message
- [ ] Order saved to database

**Effort**: 8 points
**Priority**: P0

---

#### E4-US5: Order Confirmation Dialog
**As a** user
**I want** to review my order before submitting
**So that** I don't accidentally place wrong orders

**Acceptance Criteria**:
- [ ] Modal shows all order details
- [ ] Estimated cost displayed
- [ ] Confirm / Cancel buttons
- [ ] Can't dismiss by accident

**Effort**: 3 points
**Priority**: P0

---

#### E4-US6: Order Status Tracking
**As a** user
**I want** to see my order status
**So that** I know if it executed

**Acceptance Criteria**:
- [ ] Open orders list
- [ ] Status updates in real-time
- [ ] Fill notifications
- [ ] Rejection notifications

**Effort**: 5 points
**Priority**: P0

---

## EPIC 5: Portfolio Management

**Goal**: Display positions and P&L
**Duration**: 1 week (Sprint 4)
**Team**: 1 engineer
**Acceptance**: Accurate position and P&L display

### User Stories

#### E5-US1: Position Syncing
**As a** user
**I want** my positions synced from my broker
**So that** I see my current holdings

**Acceptance Criteria**:
- [ ] Fetch positions from Alpaca API
- [ ] Store positions in database
- [ ] Update positions on order fills
- [ ] Refresh positions periodically (30s)

**Effort**: 5 points
**Priority**: P0

---

#### E5-US2: P&L Calculation
**As a** developer
**I want** accurate P&L calculations
**So that** users trust the app

**Acceptance Criteria**:
- [ ] Calculate unrealized P&L
- [ ] Calculate realized P&L
- [ ] Calculate today's P&L
- [ ] Include commission costs
- [ ] Unit tests for edge cases

**Effort**: 5 points
**Priority**: P0

---

#### E5-US3: Portfolio Display
**As a** user
**I want** to see my positions and P&L
**So that** I can monitor my account

**Acceptance Criteria**:
- [ ] List of positions with key data
- [ ] Total portfolio value
- [ ] Total P&L
- [ ] Today's P&L
- [ ] Account balance

**Effort**: 5 points
**Priority**: P0

---

#### E5-US4: Position Detail View
**As a** user
**I want** detailed info on each position
**So that** I can make informed decisions

**Acceptance Criteria**:
- [ ] Security details
- [ ] Cost basis
- [ ] Current value
- [ ] P&L ($ and %)
- [ ] Quick close button

**Effort**: 3 points
**Priority**: P1

---

## EPIC 6: Gesture Interface

**Goal**: Trade using hand gestures
**Duration**: 2 weeks (Sprint 4-5)
**Team**: 1 engineer
**Acceptance**: Core gestures work reliably

### User Stories

#### E6-US1: Hand Tracking Setup
**As a** developer
**I want** hand tracking configured
**So that** I can detect gestures

**Acceptance Criteria**:
- [ ] ARKitSession initialized
- [ ] HandTrackingProvider configured
- [ ] Hand anchors tracked
- [ ] Joint positions accessible

**Effort**: 5 points
**Priority**: P0

---

#### E6-US2: Pinch to Select
**As a** user
**I want** to select stocks by pinching while looking
**So that** I can interact naturally

**Acceptance Criteria**:
- [ ] Detect pinch gesture
- [ ] Combine with eye tracking
- [ ] Select security in view
- [ ] Haptic feedback on select
- [ ] Visual highlight on selection

**Effort**: 8 points
**Priority**: P0

---

#### E6-US3: Drag to Adjust Quantity
**As a** user
**I want** to drag up/down to change quantity
**So that** order entry is faster

**Acceptance Criteria**:
- [ ] Detect drag gesture while pinching
- [ ] Map vertical distance to quantity
- [ ] Show quantity feedback in real-time
- [ ] Smooth value changes

**Effort**: 5 points
**Priority**: P1

---

#### E6-US4: Gesture Feedback
**As a** user
**I want** feedback when gestures are detected
**So that** I know the system recognized my input

**Acceptance Criteria**:
- [ ] Haptic feedback on gesture start
- [ ] Visual feedback (glow/highlight)
- [ ] Audio cue (optional)
- [ ] Feedback is immediate (< 50ms)

**Effort**: 3 points
**Priority**: P0

---

#### E6-US5: Fallback to Tap
**As a** user
**I want** to use tap as a fallback
**So that** I can still use the app if gestures fail

**Acceptance Criteria**:
- [ ] All gesture actions have tap equivalent
- [ ] Tap targets are appropriately sized
- [ ] Works with visionOS pointer

**Effort**: 3 points
**Priority**: P0

---

## EPIC 7: Polish & Testing

**Goal**: Make MVP production-ready
**Duration**: 2 weeks (Sprint 5)
**Team**: 2 engineers + 1 QA
**Acceptance**: All acceptance criteria met, zero P0 bugs

### User Stories

#### E7-US1: Performance Optimization
**As a** developer
**I want** the app to meet performance targets
**So that** user experience is smooth

**Acceptance Criteria**:
- [ ] 60fps sustained under normal load
- [ ] Memory usage < 2GB
- [ ] Order latency < 500ms
- [ ] App launch time < 3s
- [ ] No memory leaks detected

**Effort**: 8 points
**Priority**: P0

---

#### E7-US2: Error Handling Polish
**As a** user
**I want** clear error messages
**So that** I understand what went wrong

**Acceptance Criteria**:
- [ ] All error paths have user-friendly messages
- [ ] Network errors handled gracefully
- [ ] Broker API errors explained
- [ ] Recovery actions suggested

**Effort**: 5 points
**Priority**: P0

---

#### E7-US3: Onboarding Flow
**As a** new user
**I want** guidance on first launch
**So that** I can get started quickly

**Acceptance Criteria**:
- [ ] Welcome screen
- [ ] Brief tutorial on gestures
- [ ] Help overlay on 3D scene
- [ ] Can skip tutorial

**Effort**: 5 points
**Priority**: P1

---

#### E7-US4: Unit Test Coverage
**As a** developer
**I want** comprehensive test coverage
**So that** regressions are caught early

**Acceptance Criteria**:
- [ ] 80%+ code coverage
- [ ] 100% coverage for critical paths
- [ ] All validation logic tested
- [ ] All calculations tested

**Effort**: 13 points
**Priority**: P0

---

#### E7-US5: Integration Testing
**As a** QA engineer
**I want** end-to-end tests
**So that** critical flows are validated

**Acceptance Criteria**:
- [ ] Auth flow tested
- [ ] Market data flow tested
- [ ] Order submission tested
- [ ] Portfolio sync tested

**Effort**: 8 points
**Priority**: P0

---

#### E7-US6: Security Audit
**As a** developer
**I want** to ensure app is secure
**So that** user data is protected

**Acceptance Criteria**:
- [ ] No hardcoded secrets
- [ ] All API keys in Keychain
- [ ] HTTPS only
- [ ] Token refresh working
- [ ] Session timeout implemented

**Effort**: 5 points
**Priority**: P0

---

#### E7-US7: App Store Preparation
**As a** product owner
**I want** app ready for App Store
**So that** we can launch

**Acceptance Criteria**:
- [ ] Screenshots created
- [ ] App description written
- [ ] Privacy policy published
- [ ] App Store metadata complete
- [ ] TestFlight build uploaded

**Effort**: 5 points
**Priority**: P0

---

## Sprint Planning

### Sprint 1 (Week 1-2): Foundation
**Goal**: Infrastructure ready
**Epics**: E1
**Stories**: E1-US1 through E1-US5
**Team**: 1 engineer
**Total Points**: 20

**Sprint Goal Met When**:
- [x] Can authenticate with Alpaca
- [x] Database is operational
- [x] Logging is working

---

### Sprint 2 (Week 3-4): Data + Visualization Start
**Goal**: Market data flowing, RealityKit setup
**Epics**: E2, E3 (partial)
**Stories**: E2-US1 through E2-US5, E3-US1, E3-US2
**Team**: 1 engineer
**Total Points**: 42

**Sprint Goal Met When**:
- [x] Real-time quotes streaming
- [x] Basic 3D scene rendering
- [x] Quotes cached efficiently

---

### Sprint 3 (Week 5-6): Visualization + Trading Start
**Goal**: Complete visualization, start trading
**Epics**: E3 (completion), E4 (partial)
**Stories**: E3-US3 through E3-US6, E4-US1, E4-US2
**Team**: 1 engineer
**Total Points**: 37

**Sprint Goal Met When**:
- [x] Terrain renders with live updates
- [x] Order entry UI functional
- [x] Alpaca integration working

---

### Sprint 4 (Week 7-8): Trading + Portfolio + Gestures Start
**Goal**: Complete trading, add portfolio, start gestures
**Epics**: E4 (completion), E5, E6 (partial)
**Stories**: E4-US3 through E4-US6, E5-US1 through E5-US3, E6-US1, E6-US2
**Team**: 1 engineer
**Total Points**: 42

**Sprint Goal Met When**:
- [x] Can successfully place trades
- [x] Portfolio syncs correctly
- [x] Basic gestures working

---

### Sprint 5 (Week 9-10): Gestures + Polish + Testing
**Goal**: Complete gestures, polish, test
**Epics**: E6 (completion), E7
**Stories**: E6-US3 through E6-US5, E7-US1 through E7-US7
**Team**: 1-2 engineers + 1 QA
**Total Points**: 60

**Sprint Goal Met When**:
- [x] All gestures working reliably
- [x] Performance targets met
- [x] Ready for beta testing

---

## Definition of Done

### Story Level
- [ ] Code complete
- [ ] Unit tests written and passing
- [ ] Code reviewed
- [ ] Documented (if public API)
- [ ] No compiler warnings
- [ ] Meets acceptance criteria

### Epic Level
- [ ] All stories complete
- [ ] Integration tests passing
- [ ] Acceptance criteria validated
- [ ] No P0 bugs
- [ ] Documentation updated

### MVP Level
- [ ] All P0 epics complete
- [ ] End-to-end flow works
- [ ] Performance targets met
- [ ] Security audit passed
- [ ] Beta tested
- [ ] App Store ready

---

## Story Point Reference

| Points | Complexity | Time Estimate |
|--------|-----------|---------------|
| 1 | Trivial | < 2 hours |
| 2 | Simple | 2-4 hours |
| 3 | Moderate | 4-8 hours |
| 5 | Complex | 1-2 days |
| 8 | Very Complex | 2-3 days |
| 13 | Extremely Complex | 3-5 days |
| 21+ | Too Large | Break down |

---

## Risk Log

| Risk | Epic | Mitigation | Owner |
|------|------|-----------|-------|
| RealityKit performance on device | E3 | Early device testing, aggressive LOD | Engineering |
| Alpaca API rate limits | E4 | Implement backoff, consider caching | Engineering |
| Gesture recognition accuracy | E6 | Provide tap fallbacks | Engineering |
| Scope creep | All | Strict MVP discipline, weekly reviews | PM |

---

## Questions & Decisions

### Open Questions
1. Should we support paper trading mode for demo?
2. What's minimum iOS version to support?
3. Do we need landscape mode support?
4. Should watchlist be persisted locally or cloud?

### Decisions Made
- ✅ Use Alpaca (not IB) for MVP - simpler API
- ✅ Defer options trading to Wave 2
- ✅ Use grid layout for terrain (not Delaunay) - faster to implement
- ✅ Single broker for MVP

---

**Document Owner**: Product & Engineering
**Last Updated**: 2025-11-24
**Next Review**: Weekly during sprints

**Document Version History**:
- v1.0 (2025-11-24): Initial epic breakdown
