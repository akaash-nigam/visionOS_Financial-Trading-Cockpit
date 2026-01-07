# ADR-002: Observable Macro for State Management

## Status

Accepted

**Date:** 2025-11-20

## Context

SwiftUI views need to observe and react to state changes in service layers (TradingService, WatchlistService, etc.). We need a state management pattern that:

1. Integrates seamlessly with SwiftUI
2. Provides fine-grained update notifications
3. Is type-safe and compile-time checked
4. Has minimal boilerplate
5. Works well with Swift 6.0+

Historically, SwiftUI used `ObservableObject` protocol with `@Published` properties, but Swift 5.9+ introduced the `@Observable` macro as a more modern approach.

## Decision

We will use the **`@Observable` macro** (introduced in Swift 5.9) for all service classes that need to be observed by SwiftUI views.

Services using `@Observable`:
- `TradingService`
- `WatchlistService`
- `AuthenticationService`
- View models (if needed)

This replaces the traditional `ObservableObject` + `@Published` pattern.

## Consequences

### Positive

- **Less boilerplate**: No need for `@Published` on every property
- **Better performance**: Fine-grained observation (only changed properties trigger updates)
- **Cleaner code**: Implicit observation tracking
- **Type safety**: Compiler-enforced observation
- **Modern Swift**: Uses Swift 5.9+ macros
- **SwiftUI integration**: Works seamlessly with `@State`, `@Bindable`

### Negative

- **Requires Swift 5.9+**: Not compatible with older Swift versions (not an issue for visionOS)
- **New pattern**: Developers need to learn the new approach
- **Debugging**: Macro expansion can be less transparent
- **Migration effort**: Existing `ObservableObject` code needs updates

### Neutral

- **Breaking change from SwiftUI 1.0 patterns**: But visionOS is new, so no legacy code
- **Observation framework**: Uses new Observation framework under the hood

## Implementation Notes

### Observable Service Example

```swift
import Observation

@Observable
class TradingService {
    // All properties are automatically observable
    var positions: [Position] = []
    var orders: [Order] = []
    var buyingPower: Decimal = 0

    // Private properties are NOT observable
    private var apiClient: AlpacaAPIClient

    func submitOrder(_ request: OrderRequest) async throws -> Order {
        // Implementation
    }
}
```

### SwiftUI View Usage

```swift
struct PortfolioView: View {
    @State private var tradingService: TradingService

    var body: some View {
        List(tradingService.positions) { position in
            PositionRow(position: position)
        }
        // View automatically updates when positions changes
    }
}
```

### Key Differences from ObservableObject

| Feature | ObservableObject + @Published | @Observable |
|---------|------------------------------|-------------|
| Property declaration | `@Published var value` | `var value` |
| View observation | `@StateObject`, `@ObservedObject` | `@State`, `@Bindable` |
| Granularity | All `@Published` properties | Only accessed properties |
| Boilerplate | High | Low |
| Performance | Good | Better (fine-grained) |

## Alternatives Considered

### 1. ObservableObject + @Published

**Pros:**
- Well-documented and understood
- Lots of existing examples
- Explicit property marking

**Cons:**
- More boilerplate
- Coarse-grained updates
- Older pattern
- More verbose

**Decision:** Rejected - `@Observable` is the modern approach

### 2. Combine Publishers (Manual)

**Pros:**
- Full control over updates
- Can compose complex streams

**Cons:**
- Very high complexity
- Lots of boilerplate
- Combine is being de-emphasized
- Harder to maintain

**Decision:** Rejected - Too complex for our needs

### 3. State Management Libraries (Redux-like)

**Pros:**
- Predictable state changes
- Time-travel debugging
- Centralized state

**Cons:**
- Heavy external dependency
- Overly complex for this app
- Not idiomatic SwiftUI
- Learning curve

**Decision:** Rejected - Overkill for our use case

### 4. Manual State Management (No Framework)

**Pros:**
- Complete control
- No dependencies

**Cons:**
- Reinventing the wheel
- Error-prone
- No compiler help
- High maintenance

**Decision:** Rejected - Built-in tools are better

## Migration Guide

### Before (ObservableObject)

```swift
class TradingService: ObservableObject {
    @Published var positions: [Position] = []
    @Published var orders: [Order] = []

    private var apiClient: AlpacaAPIClient
}

struct PortfolioView: View {
    @StateObject var tradingService = TradingService()
}
```

### After (@Observable)

```swift
@Observable
class TradingService {
    var positions: [Position] = []
    var orders: [Order] = []

    private var apiClient: AlpacaAPIClient
}

struct PortfolioView: View {
    @State var tradingService = TradingService()
}
```

## Related ADRs

- [ADR-001: Actor-Based Concurrency for Thread Safety](001-actor-based-concurrency.md)

## References

- [Observable Macro Documentation](https://developer.apple.com/documentation/observation/observable())
- [WWDC 2023: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [SE-0395: Observability](https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md)
- [Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

## Review History

- **2025-11-20**: Proposed by development team
- **2025-11-20**: Accepted after architecture review
