# UI/UX Design System
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Design Principles

### 1.1 Core Principles
- **Clarity**: Trading decisions require clear information
- **Efficiency**: Minimize steps to execute trades
- **Safety**: Prevent accidental orders through confirmation
- **Spatial**: Leverage 3D space for organization
- **Accessible**: Support VoiceOver and alternative inputs

---

## 2. Color System

### 2.1 Trading Colors
```swift
struct TradingColors {
    static let bullGreen = Color(hex: "#00C853")
    static let bearRed = Color(hex: "#FF1744")
    static let neutral = Color(hex: "#607D8B")
    static let warning = Color(hex: "#FFC400")
    static let accent = Color(hex: "#2979FF")
}
```

### 2.2 Semantic Colors
- **Success**: Green for filled orders, profits
- **Error**: Red for rejections, losses
- **Warning**: Yellow for approaching limits
- **Info**: Blue for general information

---

## 3. Typography

### 3.1 Font Hierarchy
```swift
struct Typography {
    static let priceFont = Font.system(.title, design: .rounded).monospacedDigit()
    static let symbolFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let labelFont = Font.system(.caption, design: .default)
    static let bodyFont = Font.system(.body, design: .default)
}
```

### 3.2 Size Scale
- **Title**: 24pt - Primary prices
- **Headline**: 18pt - Symbols, headers
- **Body**: 14pt - General text
- **Caption**: 12pt - Labels, metadata

---

## 4. Spatial Layout

### 4.1 Default Workspace Layout
```
          [Market Indicators]
                  ↑
    [Watchlist] ← [3D Topography] → [Portfolio]
                  ↓
            [Order Entry]
```

### 4.2 Window Positioning
- **Center**: Primary focus (3D visualization)
- **Eye Level**: Frequently accessed panels
- **Periphery**: Monitoring windows (news, alerts)
- **Below**: Order entry (deliberate reach)

---

## 5. Components

### 5.1 Order Entry Panel
```swift
struct OrderEntryView: View {
    @State private var quantity: Int = 100
    @State private var orderType: OrderType = .market

    var body: some View {
        VStack {
            // Security info
            SecurityHeaderView(security: security)

            // Quantity slider
            QuantitySlider(quantity: $quantity)

            // Order type picker
            OrderTypePicker(type: $orderType)

            // Action buttons
            HStack {
                Button("Buy", action: submitBuyOrder)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                Button("Sell", action: submitSellOrder)
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
```

### 5.2 Position Card
```swift
struct PositionCard: View {
    let position: Position

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(position.security.symbol)
                    .font(.headline)

                Spacer()

                PnLLabel(pnl: position.totalPnL)
            }

            HStack {
                VStack(alignment: .leading) {
                    Label("Qty", value: "\(position.quantity)")
                    Label("Avg", value: position.averagePrice.formatted(.currency(code: "USD")))
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Label("Last", value: position.currentPrice.formatted(.currency(code: "USD")))
                    Label("Value", value: position.marketValue.formatted(.currency(code: "USD")))
                }
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
```

---

## 6. Animations

### 6.1 Price Changes
```swift
extension View {
    func animatePriceChange(from old: Decimal, to new: Decimal) -> some View {
        self.modifier(PriceChangeAnimation(oldPrice: old, newPrice: new))
    }
}

struct PriceChangeAnimation: ViewModifier {
    let oldPrice: Decimal
    let newPrice: Decimal

    func body(content: Content) -> some View {
        content
            .foregroundColor(newPrice > oldPrice ? .green : .red)
            .animation(.easeInOut(duration: 0.3), value: newPrice)
    }
}
```

### 6.2 Order Confirmation
```swift
func showOrderConfirmation() {
    // Brief flash + haptic
    withAnimation(.spring(response: 0.3)) {
        showCheckmark = true
    }

    HapticManager.shared.playSuccess()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        withAnimation {
            showCheckmark = false
        }
    }
}
```

---

## 7. Accessibility

### 7.1 VoiceOver Support
```swift
.accessibilityLabel("Apple stock price: \(price)")
.accessibilityValue("Up \(changePercent)%")
.accessibilityHint("Double tap to view details")
```

### 7.2 Dynamic Type Support
```swift
Text(security.symbol)
    .font(.headline)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

---

## 8. Dark Mode

All components support both light and dark modes with semantic colors:
```swift
Color.primary  // Adapts to environment
Color.secondary
.background(.thinMaterial)  // Adaptive glass effect
```

---

**Document Version History**:
- v1.0 (2025-11-24): Initial UI/UX design system
