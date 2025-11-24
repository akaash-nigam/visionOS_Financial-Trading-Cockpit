# Gesture Recognition System Design
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Overview

This document specifies the gesture recognition system for natural trading interactions using hand tracking, eye tracking, and voice commands on Apple Vision Pro.

### Recognition Requirements
- **Accuracy**: > 95% gesture recognition
- **Latency**: < 50ms from gesture to action
- **Concurrent Gestures**: Support 2-hand gestures
- **Fallback**: Voice commands when gestures fail

---

## 2. Gesture Taxonomy

### 2.1 Primary Trading Gestures

| Gesture | Action | Hand | Trigger |
|---------|--------|------|---------|
| **Single Pinch** | Select security | Either | Look + pinch index/thumb |
| **Double Pinch** | Quick buy (market) | Either | Two rapid pinches |
| **Drag Up** | Increase quantity | Either | Pinch + move up |
| **Drag Down** | Decrease quantity / Close | Either | Pinch + move down |
| **Spread Fingers** | Cancel order | Either | Open hand from fist |
| **Circle Motion** | Set stop loss | Either | Trace circle in air |
| **Two-Hand Pinch** | Multi-leg option strategy | Both | Simultaneous pinches |
| **Push Away** | Reject/Close | Either | Push palm forward |
| **Pull Toward** | Accept/Confirm | Either | Pull fist toward body |

### 2.2 Navigation Gestures

| Gesture | Action | Description |
|---------|--------|-------------|
| **Pinch + Drag** | Pan view | Move viewpoint |
| **Two-finger pinch** | Zoom | Scale view |
| **Rotate** | Rotate scene | Two-hand rotation |
| **Tap** | Select window | Air tap on window |

---

## 3. Hand Tracking Architecture

### 3.1 Hand Tracking Manager

```swift
@MainActor
class HandTrackingManager: ObservableObject {
    @Published var leftHand: HandState?
    @Published var rightHand: HandState?
    @Published var detectedGesture: TradingGesture?

    private var arSession: ARKitSession?
    private var handTracking: HandTrackingProvider?
    private var gestureRecognizer: GestureRecognizer

    init() {
        self.gestureRecognizer = GestureRecognizer()
        setupHandTracking()
    }

    private func setupHandTracking() {
        Task {
            arSession = ARKitSession()
            handTracking = HandTrackingProvider()

            do {
                try await arSession?.run([handTracking!])
                await processHandUpdates()
            } catch {
                Logger.error("Failed to start hand tracking", error: error)
            }
        }
    }

    private func processHandUpdates() async {
        guard let handTracking = handTracking else { return }

        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .added, .updated:
                if let anchor = update.anchor as? HandAnchor {
                    updateHandState(anchor)
                    detectGestures(anchor)
                }
            case .removed:
                if let anchor = update.anchor as? HandAnchor {
                    removeHandState(anchor)
                }
            }
        }
    }

    private func updateHandState(_ anchor: HandAnchor) {
        let state = HandState(
            chirality: anchor.chirality,
            joints: extractJoints(anchor),
            isTracked: anchor.isTracked
        )

        if anchor.chirality == .left {
            leftHand = state
        } else {
            rightHand = state
        }
    }

    private func detectGestures(_ anchor: HandAnchor) {
        let gesture = gestureRecognizer.recognize(
            leftHand: leftHand,
            rightHand: rightHand
        )

        if let gesture = gesture {
            detectedGesture = gesture
            handleGesture(gesture)
        }
    }

    private func handleGesture(_ gesture: TradingGesture) {
        NotificationCenter.default.post(
            name: .gestureDetected,
            object: gesture
        )
    }

    private func extractJoints(_ anchor: HandAnchor) -> [HandJoint] {
        HandSkeleton.JointName.allCases.compactMap { jointName in
            guard let joint = anchor.handSkeleton?.joint(jointName) else { return nil }
            return HandJoint(
                name: jointName,
                position: SIMD3<Float>(joint.anchorFromJointTransform.columns.3),
                isTracked: joint.isTracked
            )
        }
    }
}

struct HandState {
    let chirality: HandAnchor.Chirality
    let joints: [HandJoint]
    let isTracked: Bool

    var indexTip: HandJoint? {
        joints.first { $0.name == .indexFingerTip }
    }

    var thumbTip: HandJoint? {
        joints.first { $0.name == .thumbTip }
    }

    var isPinching: Bool {
        guard let index = indexTip, let thumb = thumbTip else { return false }
        let distance = simd_distance(index.position, thumb.position)
        return distance < 0.02  // 2cm threshold
    }
}

struct HandJoint {
    let name: HandSkeleton.JointName
    let position: SIMD3<Float>
    let isTracked: Bool
}
```

---

## 4. Gesture Recognition

### 4.1 Gesture Recognizer

```swift
class GestureRecognizer {
    private var gestureHistory: [GestureFrame] = []
    private let historySize = 30  // 0.5 seconds at 60fps

    func recognize(leftHand: HandState?, rightHand: HandState?) -> TradingGesture? {
        let frame = GestureFrame(
            timestamp: Date(),
            leftHand: leftHand,
            rightHand: rightHand
        )

        gestureHistory.append(frame)
        if gestureHistory.count > historySize {
            gestureHistory.removeFirst()
        }

        // Try to recognize gestures in priority order
        if let gesture = recognizePinch(frame) { return gesture }
        if let gesture = recognizeDrag(gestureHistory) { return gesture }
        if let gesture = recognizeSpread(frame) { return gesture }
        if let gesture = recognizeCircle(gestureHistory) { return gesture }
        if let gesture = recognizeTwoHandGesture(frame) { return gesture }

        return nil
    }

    private func recognizePinch(_ frame: GestureFrame) -> TradingGesture? {
        // Check right hand
        if let rightHand = frame.rightHand, rightHand.isPinching {
            // Check for double pinch
            if isDoublePinch(hand: .right) {
                return .doublePinch(hand: .right)
            }
            return .singlePinch(hand: .right)
        }

        // Check left hand
        if let leftHand = frame.leftHand, leftHand.isPinching {
            if isDoublePinch(hand: .left) {
                return .doublePinch(hand: .left)
            }
            return .singlePinch(hand: .left)
        }

        return nil
    }

    private func isDoublePinch(hand: Hand) -> Bool {
        // Look for two pinches within 500ms
        let recentFrames = gestureHistory.suffix(30)
        let pinches = recentFrames.filter { frame in
            let handState = hand == .right ? frame.rightHand : frame.leftHand
            return handState?.isPinching ?? false
        }

        // Count distinct pinch events
        var pinchEvents = 0
        var wasPinching = false

        for frame in recentFrames {
            let handState = hand == .right ? frame.rightHand : frame.leftHand
            let isPinching = handState?.isPinching ?? false

            if isPinching && !wasPinching {
                pinchEvents += 1
            }

            wasPinching = isPinching
        }

        return pinchEvents >= 2
    }

    private func recognizeDrag(_ history: [GestureFrame]) -> TradingGesture? {
        guard history.count >= 10 else { return nil }

        let recent = Array(history.suffix(10))
        guard let first = recent.first, let last = recent.last else { return nil }

        // Check if hand is pinching throughout drag
        let rightPinching = recent.allSatisfy { $0.rightHand?.isPinching ?? false }
        let leftPinching = recent.allSatisfy { $0.leftHand?.isPinching ?? false }

        if rightPinching {
            let displacement = calculateDisplacement(from: first, to: last, hand: .right)
            return classifyDrag(displacement: displacement, hand: .right)
        }

        if leftPinching {
            let displacement = calculateDisplacement(from: first, to: last, hand: .left)
            return classifyDrag(displacement: displacement, hand: .left)
        }

        return nil
    }

    private func calculateDisplacement(
        from start: GestureFrame,
        to end: GestureFrame,
        hand: Hand
    ) -> SIMD3<Float> {
        let startPos = hand == .right ?
            start.rightHand?.indexTip?.position :
            start.leftHand?.indexTip?.position

        let endPos = hand == .right ?
            end.rightHand?.indexTip?.position :
            end.leftHand?.indexTip?.position

        guard let start = startPos, let end = endPos else {
            return SIMD3<Float>.zero
        }

        return end - start
    }

    private func classifyDrag(displacement: SIMD3<Float>, hand: Hand) -> TradingGesture? {
        let threshold: Float = 0.1  // 10cm

        if displacement.y > threshold {
            return .dragUp(hand: hand, distance: displacement.y)
        } else if displacement.y < -threshold {
            return .dragDown(hand: hand, distance: abs(displacement.y))
        }

        return nil
    }

    private func recognizeSpread(_ frame: GestureFrame) -> TradingGesture? {
        // Check if fingers are spread (all fingertips far from palm)
        func isSpread(_ hand: HandState) -> Bool {
            guard let wrist = hand.joints.first(where: { $0.name == .wrist }),
                  let index = hand.indexTip,
                  let middle = hand.joints.first(where: { $0.name == .middleFingerTip }),
                  let ring = hand.joints.first(where: { $0.name == .ringFingerTip }),
                  let pinky = hand.joints.first(where: { $0.name == .littleFingerTip }) else {
                return false
            }

            let avgDistance = (
                simd_distance(wrist.position, index.position) +
                simd_distance(wrist.position, middle.position) +
                simd_distance(wrist.position, ring.position) +
                simd_distance(wrist.position, pinky.position)
            ) / 4.0

            return avgDistance > 0.15  // 15cm threshold
        }

        if let rightHand = frame.rightHand, isSpread(rightHand) {
            return .spread(hand: .right)
        }

        if let leftHand = frame.leftHand, isSpread(leftHand) {
            return .spread(hand: .left)
        }

        return nil
    }

    private func recognizeCircle(_ history: [GestureFrame]) -> TradingGesture? {
        guard history.count >= 30 else { return nil }  // Need full history

        // Extract trajectory of index finger
        let rightTrajectory = history.compactMap { $0.rightHand?.indexTip?.position }
        let leftTrajectory = history.compactMap { $0.leftHand?.indexTip?.position }

        if rightTrajectory.count >= 20 && isCircularMotion(rightTrajectory) {
            return .circle(hand: .right)
        }

        if leftTrajectory.count >= 20 && isCircularMotion(leftTrajectory) {
            return .circle(hand: .left)
        }

        return nil
    }

    private func isCircularMotion(_ trajectory: [SIMD3<Float>]) -> Bool {
        guard trajectory.count >= 20 else { return false }

        // Calculate center point
        let center = trajectory.reduce(SIMD3<Float>.zero, +) / Float(trajectory.count)

        // Calculate average radius
        let radii = trajectory.map { simd_distance($0, center) }
        let avgRadius = radii.reduce(0, +) / Float(radii.count)

        // Check variance in radius (should be small for circle)
        let variance = radii.map { pow($0 - avgRadius, 2) }.reduce(0, +) / Float(radii.count)
        let stdDev = sqrt(variance)

        // Check if points roughly form a circle
        return stdDev < avgRadius * 0.3  // 30% tolerance
    }

    private func recognizeTwoHandGesture(_ frame: GestureFrame) -> TradingGesture? {
        guard let leftHand = frame.leftHand,
              let rightHand = frame.rightHand,
              leftHand.isPinching,
              rightHand.isPinching else {
            return nil
        }

        return .twoHandPinch
    }
}

struct GestureFrame {
    let timestamp: Date
    let leftHand: HandState?
    let rightHand: HandState?
}

enum TradingGesture {
    case singlePinch(hand: Hand)
    case doublePinch(hand: Hand)
    case dragUp(hand: Hand, distance: Float)
    case dragDown(hand: Hand, distance: Float)
    case spread(hand: Hand)
    case circle(hand: Hand)
    case twoHandPinch
    case pushAway(hand: Hand)
    case pullToward(hand: Hand)
}

enum Hand {
    case left
    case right
}
```

---

## 5. Eye Tracking Integration

### 5.1 Eye Tracking Manager

```swift
@MainActor
class EyeTrackingManager: ObservableObject {
    @Published var gazeTarget: Entity?
    @Published var gazePosition: SIMD3<Float>?

    private var arSession: ARKitSession?
    private var worldTracking: WorldTrackingProvider?

    func startTracking() {
        Task {
            arSession = ARKitSession()
            worldTracking = WorldTrackingProvider()

            do {
                try await arSession?.run([worldTracking!])
                await processEyeTracking()
            } catch {
                Logger.error("Failed to start eye tracking", error: error)
            }
        }
    }

    private func processEyeTracking() async {
        // Note: Eye tracking in visionOS is privacy-preserving
        // We only get target entities, not raw gaze direction

        // Use hit testing with user's gaze
        // Implementation depends on visionOS API
    }

    func getGazedEntity(in scene: RealityKit.Scene) -> Entity? {
        // Return entity user is looking at
        // This is used for "look + pinch" gesture
        return gazeTarget
    }
}
```

---

## 6. Voice Command System

### 6.1 Voice Command Recognizer

```swift
class VoiceCommandRecognizer: ObservableObject {
    @Published var lastCommand: VoiceCommand?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startListening() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceError.recognizerNotAvailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.cannotCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let command = self?.parseCommand(result.bestTranscription.formattedString)
                self?.lastCommand = command
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    private func parseCommand(_ text: String) -> VoiceCommand? {
        let lowercased = text.lowercased()

        // Buy commands
        if lowercased.contains("buy") {
            let quantity = extractQuantity(from: lowercased)
            let symbol = extractSymbol(from: lowercased)
            return .buy(symbol: symbol, quantity: quantity, type: .market)
        }

        // Sell commands
        if lowercased.contains("sell") {
            let quantity = extractQuantity(from: lowercased)
            let symbol = extractSymbol(from: lowercased)
            return .sell(symbol: symbol, quantity: quantity)
        }

        // Stop loss
        if lowercased.contains("stop loss") || lowercased.contains("stop at") {
            let price = extractPrice(from: lowercased)
            return .setStopLoss(price: price)
        }

        // Cancel
        if lowercased.contains("cancel") {
            return .cancel
        }

        return nil
    }

    private func extractQuantity(from text: String) -> Int? {
        // Extract number followed by "shares" or before "shares"
        let pattern = #"(\d+)\s*shares"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let quantityStr = String(text[match]).components(separatedBy: " ").first
            return Int(quantityStr ?? "")
        }
        return nil
    }

    private func extractSymbol(from text: String) -> String? {
        // Extract uppercase ticker symbols (e.g., "AAPL", "GOOGL")
        let pattern = #"\b[A-Z]{1,5}\b"#
        if let match = text.uppercased().range(of: pattern, options: .regularExpression) {
            return String(text.uppercased()[match])
        }
        return nil
    }

    private func extractPrice(from text: String) -> Decimal? {
        // Extract price (e.g., "150", "150.50")
        let pattern = #"\d+\.?\d*"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            return Decimal(string: String(text[match]))
        }
        return nil
    }
}

enum VoiceCommand {
    case buy(symbol: String?, quantity: Int?, type: OrderType)
    case sell(symbol: String?, quantity: Int?)
    case setStopLoss(price: Decimal?)
    case cancel
    case confirm
}
```

---

## 7. Gesture-to-Action Mapping

### 7.1 Action Handler

```swift
@MainActor
class GestureActionHandler: ObservableObject {
    private let tradingEngine: TradingEngine
    private let eyeTracking: EyeTrackingManager
    private weak var selectedSecurity: Security?

    init(tradingEngine: TradingEngine, eyeTracking: EyeTrackingManager) {
        self.tradingEngine = tradingEngine
        self.eyeTracking = eyeTracking
    }

    func handleGesture(_ gesture: TradingGesture) {
        switch gesture {
        case .singlePinch(let hand):
            handleSinglePinch()

        case .doublePinch(let hand):
            handleDoublePinch()

        case .dragUp(let hand, let distance):
            handleDragUp(distance: distance)

        case .dragDown(let hand, let distance):
            handleDragDown(distance: distance)

        case .spread(let hand):
            handleSpread()

        case .circle(let hand):
            handleCircle()

        case .twoHandPinch:
            handleTwoHandPinch()

        default:
            break
        }
    }

    private func handleSinglePinch() {
        // Select security user is looking at
        if let entity = eyeTracking.gazeTarget,
           let security = extractSecurity(from: entity) {
            selectedSecurity = security
            showOrderEntry(for: security)
        }
    }

    private func handleDoublePinch() {
        // Quick market buy
        guard let security = selectedSecurity else {
            showAlert("No security selected")
            return
        }

        Task {
            do {
                let order = Order(
                    security: security,
                    action: .buy,
                    quantity: 100,  // Default quantity
                    orderType: .market
                )

                try await tradingEngine.submitOrder(order)
                showConfirmation("Market buy order submitted")
            } catch {
                showAlert("Order failed: \(error)")
            }
        }
    }

    private func handleDragUp(distance: Float) {
        // Increase quantity based on drag distance
        let quantity = Int(distance * 100)  // 10cm = 10 shares
        updateOrderQuantity(quantity)
    }

    private func handleDragDown(distance: Float) {
        // Decrease quantity or close position
        let quantity = Int(distance * 100)
        updateOrderQuantity(-quantity)
    }

    private func handleSpread() {
        // Cancel current order
        cancelCurrentOrder()
    }

    private func handleCircle() {
        // Show stop loss entry
        showStopLossEntry()
    }

    private func handleTwoHandPinch() {
        // Start multi-leg option strategy builder
        showOptionsStrategyBuilder()
    }

    // Helper methods
    private func extractSecurity(from entity: Entity) -> Security? {
        // Extract security from entity metadata
        nil  // TODO: Implement
    }

    private func showOrderEntry(for security: Security) {
        // Show order entry UI
    }

    private func updateOrderQuantity(_ delta: Int) {
        // Update pending order quantity
    }

    private func cancelCurrentOrder() {
        // Cancel order in progress
    }

    private func showStopLossEntry() {
        // Show stop loss UI
    }

    private func showOptionsStrategyBuilder() {
        // Show multi-leg strategy builder
    }

    private func showAlert(_ message: String) {
        // Show alert to user
    }

    private func showConfirmation(_ message: String) {
        // Show confirmation message
    }
}
```

---

## 8. Haptic Feedback

### 8.1 Haptic Manager

```swift
class HapticManager {
    func playFeedback(for gesture: TradingGesture) {
        switch gesture {
        case .singlePinch:
            playSelection()

        case .doublePinch:
            playSuccess()

        case .dragUp, .dragDown:
            playContinuous()

        case .spread:
            playWarning()

        case .circle:
            playNotification()

        default:
            playSelection()
        }
    }

    private func playSelection() {
        // Light tap
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func playSuccess() {
        // Success notification
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func playContinuous() {
        // Continuous feedback during drag
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    private func playWarning() {
        // Warning haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    private func playNotification() {
        // General notification
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
```

---

## 9. Testing

### 9.1 Gesture Simulation

```swift
class GestureSimulator {
    func simulatePinch(hand: Hand) -> TradingGesture {
        .singlePinch(hand: hand)
    }

    func simulateDrag(hand: Hand, direction: DragDirection, distance: Float) -> TradingGesture {
        switch direction {
        case .up:
            return .dragUp(hand: hand, distance: distance)
        case .down:
            return .dragDown(hand: hand, distance: distance)
        }
    }
}

enum DragDirection {
    case up
    case down
}
```

---

## 10. Accessibility

### 10.1 Alternative Input Methods

```swift
class AccessibilityInputManager {
    // Fallback to standard visionOS interactions
    func enableAlternativeInputs() {
        // Eye tracking + dwell
        // Voice commands only
        // External keyboard shortcuts
        // VoiceOver support
    }
}
```

---

**Document Version History**:
- v1.0 (2025-11-24): Initial gesture recognition design
