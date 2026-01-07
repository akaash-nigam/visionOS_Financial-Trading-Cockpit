# Security & Compliance Architecture
## Financial Trading Cockpit for visionOS

**Version:** 1.0
**Last Updated:** 2025-11-24
**Status:** Design Phase

---

## 1. Security Overview

### 1.1 Security Principles
- **Defense in Depth**: Multiple layers of security
- **Least Privilege**: Minimal access rights
- **Data Minimization**: Collect only what's necessary
- **Privacy by Design**: Privacy built into architecture
- **Zero Trust**: Verify all requests

### 1.2 Threat Model

| Threat | Risk Level | Mitigation |
|--------|-----------|------------|
| Credential theft | High | Keychain storage, biometric auth |
| Man-in-the-middle | High | TLS 1.3, certificate pinning |
| Order tampering | Critical | Digital signatures, checksums |
| Session hijacking | High | Short-lived tokens, re-auth |
| Data exfiltration | Medium | Encryption at rest, no screenshots |
| Social engineering | Medium | User education, confirmation prompts |

---

## 2. Authentication & Authorization

### 2.1 OAuth 2.0 Flow

```swift
class BrokerAuthenticator {
    func authenticate(broker: Broker) async throws -> AuthToken {
        // Step 1: Request authorization
        let authURL = buildAuthorizationURL(broker: broker)
        let code = try await presentAuthenticationFlow(url: authURL)

        // Step 2: Exchange code for token
        let token = try await exchangeCodeForToken(
            code: code,
            broker: broker
        )

        // Step 3: Store securely in Keychain
        try await KeychainManager.shared.store(token, for: broker)

        // Step 4: Enable OpticID for future auth
        try await setupBiometricAuth(for: broker)

        return token
    }

    private func buildAuthorizationURL(broker: Broker) -> URL {
        var components = URLComponents(string: broker.authEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: broker.clientID),
            URLQueryItem(name: "redirect_uri", value: "tradingcockpit://oauth"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "trading account_info market_data"),
            URLQueryItem(name: "state", value: generateState())
        ]
        return components.url!
    }

    private func exchangeCodeForToken(code: String, broker: Broker) async throws -> AuthToken {
        var request = URLRequest(url: broker.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": broker.clientID,
            "client_secret": broker.clientSecret,
            "redirect_uri": "tradingcockpit://oauth"
        ]

        request.httpBody = body.percentEncoded()

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        return try JSONDecoder().decode(AuthToken.self, from: data)
    }
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let scope: String

    var isExpired: Bool {
        // Check expiration
        false  // TODO: Implement
    }
}
```

### 2.2 Biometric Authentication (OpticID)

```swift
class BiometricAuthManager {
    func setupBiometricAuth(for broker: Broker) async throws {
        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        // Enable OpticID for this broker
        let key = "biometric_enabled_\(broker.rawValue)"
        UserDefaults.standard.set(true, forKey: key)
    }

    func authenticateWithBiometrics(reason: String = "Authenticate to access trading") async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed
        }
    }
}
```

### 2.3 Keychain Management

```swift
class KeychainManager {
    static let shared = KeychainManager()

    func store(_ token: AuthToken, for broker: Broker) throws {
        let data = try JSONEncoder().encode(token)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.tradingcockpit.broker",
            kSecAttrAccount as String: broker.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    func retrieve(for broker: Broker) throws -> AuthToken {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.tradingcockpit.broker",
            kSecAttrAccount as String: broker.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }

        return try JSONDecoder().decode(AuthToken.self, from: data)
    }

    func delete(for broker: Broker) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.tradingcockpit.broker",
            kSecAttrAccount as String: broker.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
```

---

## 3. Network Security

### 3.1 TLS Configuration

```swift
class SecureNetworkManager {
    private let urlSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13

        self.urlSession = URLSession(
            configuration: configuration,
            delegate: CertificatePinningDelegate(),
            delegateQueue: nil
        )
    }
}
```

### 3.2 Certificate Pinning

```swift
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [String: SecCertificate] = [:]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate certificate
        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFArray)

        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Pin certificate (for production)
        if let pinnedCert = pinnedCertificates[challenge.protectionSpace.host] {
            guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0),
                  pinnedCert == serverCert else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
```

---

## 4. Data Security

### 4.1 Encryption at Rest

```swift
class EncryptedStorageManager {
    private let encryptionKey: SymmetricKey

    init() {
        // Generate or retrieve encryption key from Secure Enclave
        self.encryptionKey = try! retrieveOrGenerateKey()
    }

    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }

    private func retrieveOrGenerateKey() throws -> SymmetricKey {
        // Try to retrieve from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "encryption_key",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }

        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        // Store in Keychain
        let storeQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "encryption_key",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(storeQuery as CFDictionary, nil)

        return key
    }
}
```

### 4.2 Encrypted Database

```swift
class EncryptedDatabase {
    private let database: Database
    private let encryptionManager: EncryptedStorageManager

    func insert<T: Encodable>(_ object: T, table: String) throws {
        let data = try JSONEncoder().encode(object)
        let encrypted = try encryptionManager.encrypt(data)

        try database.execute(
            "INSERT INTO \(table) (data) VALUES (?)",
            parameters: [encrypted]
        )
    }

    func select<T: Decodable>(_ type: T.Type, from table: String) throws -> [T] {
        let rows = try database.query("SELECT data FROM \(table)")

        return try rows.compactMap { row in
            guard let encryptedData = row["data"] as? Data else { return nil }
            let decrypted = try encryptionManager.decrypt(encryptedData)
            return try JSONDecoder().decode(T.self, from: decrypted)
        }
    }
}
```

---

## 5. Compliance

### 5.1 SEC Rule 15c3-5 (Market Access Rule)

```swift
class PreTradeRiskCheck {
    func validate(order: Order, account: Account, portfolio: Portfolio) throws {
        // 1. Capital limits
        try checkCapitalLimits(order, account)

        // 2. Credit limits (for margin accounts)
        if account.accountType == .margin {
            try checkMarginRequirements(order, portfolio)
        }

        // 3. Position limits
        try checkPositionLimits(order, portfolio)

        // 4. Order size limits
        try checkOrderSizeLimits(order)

        // 5. Price collars
        try checkPriceReasonableness(order)

        // 6. Duplicate order prevention
        try checkDuplicateOrder(order)

        // Log compliance check
        logComplianceCheck(order)
    }

    private func checkCapitalLimits(_ order: Order, _ account: Account) throws {
        let estimatedCost = calculateCost(order)

        guard estimatedCost <= account.buyingPower else {
            throw ComplianceError.insufficientCapital
        }
    }

    private func checkPositionLimits(_ order: Order, _ portfolio: Portfolio) throws {
        let currentPosition = portfolio.positions.first { $0.security.id == order.security.id }
        let newQuantity = (currentPosition?.quantity ?? 0) + order.quantity

        // Example: Max position size = 10% of portfolio
        let maxPositionSize = portfolio.portfolioValue * 0.1
        let newPositionValue = Decimal(newQuantity) * order.estimatedPrice

        guard newPositionValue <= maxPositionSize else {
            throw ComplianceError.positionLimitExceeded
        }
    }

    private func checkOrderSizeLimits(_ order: Order) throws {
        // Prevent fat-finger errors
        let maxOrderQuantity = 10_000
        guard order.quantity <= maxOrderQuantity else {
            throw ComplianceError.orderTooLarge
        }
    }

    private func checkPriceReasonableness(_ order: Order) throws {
        guard let limitPrice = order.limitPrice else { return }

        // Get current market price
        let marketPrice = getMarketPrice(order.security)

        // Check if limit price is within 10% of market
        let deviation = abs((limitPrice - marketPrice) / marketPrice)
        guard deviation <= 0.10 else {
            throw ComplianceError.unreasonablePrice
        }
    }

    private func logComplianceCheck(_ order: Order) {
        // Log for audit trail
        ComplianceLogger.log(event: .preTradeCheck, order: order, result: .passed)
    }
}
```

### 5.2 Order Audit Trail

```swift
class OrderAuditTrail {
    func recordOrderEvent(_ event: OrderEvent) async {
        let record = AuditRecord(
            timestamp: Date(),
            event: event,
            userId: getCurrentUserId(),
            sessionId: getSessionId(),
            deviceId: getDeviceId()
        )

        // Store in encrypted database
        try? await database.insert(record, table: "order_audit")

        // Also log to persistent file
        await appendToAuditLog(record)
    }

    private func appendToAuditLog(_ record: AuditRecord) async {
        let logEntry = """
        [\(record.timestamp.ISO8601Format())] \
        USER:\(record.userId) \
        SESSION:\(record.sessionId) \
        EVENT:\(record.event.type) \
        DATA:\(record.event.data)
        """

        // Append to audit log file
        await FileLogger.append(logEntry, to: "order_audit.log")
    }
}

struct AuditRecord: Codable {
    let timestamp: Date
    let event: OrderEvent
    let userId: String
    let sessionId: String
    let deviceId: String
}

enum OrderEvent {
    case orderCreated(Order)
    case orderValidated(Order)
    case orderSubmitted(Order)
    case orderAccepted(Order)
    case orderRejected(Order, reason: String)
    case orderFilled(Order, execution: Execution)
    case orderCancelled(Order)
}
```

### 5.3 GDPR & CCPA Compliance

```swift
class PrivacyManager {
    // Data portability
    func exportUserData(userId: String) async throws -> Data {
        let userData = UserData(
            profile: try await fetchUserProfile(userId),
            orders: try await fetchOrders(userId),
            positions: try await fetchPositions(userId),
            preferences: try await fetchPreferences(userId)
        )

        return try JSONEncoder().encode(userData)
    }

    // Right to be forgotten
    func deleteUserData(userId: String) async throws {
        // Delete all user data
        try await database.execute("DELETE FROM users WHERE id = ?", parameters: [userId])
        try await database.execute("DELETE FROM orders WHERE user_id = ?", parameters: [userId])
        try await database.execute("DELETE FROM preferences WHERE user_id = ?", parameters: [userId])

        // Note: Order audit trail must be retained for 7 years per SEC requirements
        // Mark as anonymized instead
        try await database.execute(
            "UPDATE order_audit SET user_id = 'DELETED' WHERE user_id = ?",
            parameters: [userId]
        )
    }

    // Consent management
    func recordConsent(userId: String, consentType: ConsentType) async throws {
        let consent = Consent(
            userId: userId,
            type: consentType,
            granted: true,
            timestamp: Date()
        )

        try await database.insert(consent, table: "consents")
    }
}
```

---

## 6. Session Management

### 6.1 Session Timeout

```swift
actor SessionManager {
    private var lastActivityTime = Date()
    private let timeoutInterval: TimeInterval = 15 * 60  // 15 minutes
    private var timeoutTask: Task<Void, Never>?

    func recordActivity() {
        lastActivityTime = Date()
        resetTimeoutTimer()
    }

    private func resetTimeoutTimer() {
        timeoutTask?.cancel()

        timeoutTask = Task {
            try? await Task.sleep(for: .seconds(timeoutInterval))

            if Date().timeIntervalSince(lastActivityTime) >= timeoutInterval {
                await handleTimeout()
            }
        }
    }

    private func handleTimeout() async {
        // Lock session
        NotificationCenter.default.post(name: .sessionTimeout, object: nil)

        // Require re-authentication
        await requireReauth()
    }

    private func requireReauth() async {
        // Show authentication screen
        // User must re-enter credentials or use biometrics
    }
}
```

---

## 7. Security Monitoring

### 7.1 Anomaly Detection

```swift
class SecurityMonitor {
    func detectAnomalies(order: Order, userHistory: [Order]) -> [SecurityAnomaly] {
        var anomalies: [SecurityAnomaly] = []

        // Unusual order size
        let avgOrderSize = calculateAverageOrderSize(userHistory)
        if Double(order.quantity) > avgOrderSize * 10 {
            anomalies.append(.unusualOrderSize(order.quantity, average: Int(avgOrderSize)))
        }

        // Unusual trading hours
        if isOutsideNormalTradingHours(Date()) {
            anomalies.append(.unusualTradingHours(Date()))
        }

        // Rapid succession of orders
        if hasRapidOrders(userHistory, threshold: 10, within: 60) {
            anomalies.append(.rapidOrders)
        }

        return anomalies
    }

    private func calculateAverageOrderSize(_ orders: [Order]) -> Double {
        guard !orders.isEmpty else { return 0 }
        let total = orders.map { $0.quantity }.reduce(0, +)
        return Double(total) / Double(orders.count)
    }

    private func isOutsideNormalTradingHours(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour > 20  // 6 AM to 8 PM
    }

    private func hasRapidOrders(_ orders: [Order], threshold: Int, within seconds: TimeInterval) -> Bool {
        let recent = orders.filter {
            Date().timeIntervalSince($0.createdAt) < seconds
        }
        return recent.count >= threshold
    }
}

enum SecurityAnomaly {
    case unusualOrderSize(Int, average: Int)
    case unusualTradingHours(Date)
    case rapidOrders
    case suspiciousLocation
}
```

---

## 8. Incident Response

### 8.1 Security Incident Handler

```swift
class SecurityIncidentHandler {
    func handleIncident(_ incident: SecurityIncident) async {
        // Log incident
        await logIncident(incident)

        // Take immediate action
        switch incident.severity {
        case .critical:
            await lockAllSessions()
            await notifyAdministrator()
            await disableTradingTemporarily()

        case .high:
            await requireReauthentication()
            await notifyUser()

        case .medium:
            await alertUser()

        case .low:
            await logForReview()
        }

        // Trigger investigation
        await triggerInvestigation(incident)
    }

    private func logIncident(_ incident: SecurityIncident) async {
        let record = IncidentRecord(
            timestamp: Date(),
            type: incident.type,
            severity: incident.severity,
            details: incident.details
        )

        await IncidentLogger.log(record)
    }
}

struct SecurityIncident {
    let type: IncidentType
    let severity: Severity
    let details: String
}

enum IncidentType {
    case unauthorizedAccess
    case suspiciousActivity
    case dataBreachAttempt
    case authenticationFailure
}

enum Severity {
    case low
    case medium
    case high
    case critical
}
```

---

## 9. Security Testing

### 9.1 Penetration Testing Checklist

```markdown
- [ ] SQL injection attempts
- [ ] Cross-site scripting (if web component)
- [ ] Authentication bypass attempts
- [ ] Session hijacking
- [ ] Man-in-the-middle attacks
- [ ] Certificate validation
- [ ] API endpoint fuzzing
- [ ] Rate limiting bypass
- [ ] Privilege escalation
- [ ] Data exfiltration attempts
```

---

## 10. References

- [SEC Rule 15c3-5](https://www.sec.gov/rules/final/2010/34-63241.pdf)
- [GDPR Compliance](https://gdpr.eu/)
- [CCPA Guidelines](https://oag.ca.gov/privacy/ccpa)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Apple Security Guide](https://support.apple.com/guide/security/welcome/web)

---

**Document Version History**:
- v1.0 (2025-11-24): Initial security and compliance architecture
