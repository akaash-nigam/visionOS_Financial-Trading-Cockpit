//
//  WebSocketManager.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//  Sprint 2: Market Data Pipeline
//

import Foundation

/// Manages WebSocket connections with auto-reconnect and heartbeat monitoring
actor WebSocketManager {
    // MARK: - Properties

    private let endpoint: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private var isConnected = false
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 10
    private var heartbeatTask: Task<Void, Never>?

    // Message stream
    private let messagesContinuation: AsyncStream<Data>.Continuation
    let messages: AsyncStream<Data>

    // MARK: - Initialization

    init(endpoint: URL) {
        self.endpoint = endpoint

        // Configure URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)

        // Create message stream
        var continuation: AsyncStream<Data>.Continuation!
        self.messages = AsyncStream { cont in
            continuation = cont
        }
        self.messagesContinuation = continuation

        Logger.info("📡 WebSocket manager initialized for \(endpoint.absoluteString)")
    }

    // MARK: - Connection Management

    func connect() async throws {
        guard !isConnected else {
            Logger.debug("WebSocket already connected")
            return
        }

        Logger.info("🔌 Connecting to WebSocket: \(endpoint.absoluteString)")

        let task = urlSession.webSocketTask(with: endpoint)
        self.webSocketTask = task

        task.resume()
        isConnected = true
        reconnectAttempt = 0

        // Start receiving messages
        Task {
            await receiveMessages()
        }

        // Start heartbeat monitoring
        startHeartbeat()

        Logger.info("✅ WebSocket connected successfully")
    }

    func disconnect() {
        guard isConnected else { return }

        Logger.info("🔌 Disconnecting WebSocket")

        heartbeatTask?.cancel()
        heartbeatTask = nil

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        isConnected = false
        messagesContinuation.finish()

        Logger.info("✅ WebSocket disconnected")
    }

    func reconnect() async {
        guard reconnectAttempt < maxReconnectAttempts else {
            Logger.error("❌ Max reconnect attempts reached (\(maxReconnectAttempts))")
            return
        }

        reconnectAttempt += 1
        let delay = calculateBackoff(attempt: reconnectAttempt)

        Logger.warning("⚠️ Reconnecting in \(delay)s (attempt \(reconnectAttempt)/\(maxReconnectAttempts))")

        try? await Task.sleep(for: .seconds(delay))

        do {
            disconnect()
            try await connect()
            Logger.info("✅ Reconnection successful")
        } catch {
            Logger.error("❌ Reconnection failed", error: error)
            await reconnect()
        }
    }

    // MARK: - Message Handling

    func send(_ message: String) async throws {
        guard isConnected, let task = webSocketTask else {
            throw WebSocketError.notConnected
        }

        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        try await task.send(wsMessage)

        Logger.debug("📤 Sent WebSocket message: \(message)")
    }

    func send(_ data: Data) async throws {
        guard isConnected, let task = webSocketTask else {
            throw WebSocketError.notConnected
        }

        let wsMessage = URLSessionWebSocketTask.Message.data(data)
        try await task.send(wsMessage)

        Logger.debug("📤 Sent WebSocket data: \(data.count) bytes")
    }

    private func receiveMessages() async {
        while isConnected, let task = webSocketTask {
            do {
                let message = try await task.receive()

                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        messagesContinuation.yield(data)
                    }

                case .data(let data):
                    messagesContinuation.yield(data)

                @unknown default:
                    Logger.warning("⚠️ Unknown WebSocket message type")
                }

            } catch {
                Logger.error("❌ WebSocket receive error", error: error)
                isConnected = false
                await reconnect()
                break
            }
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTask?.cancel()

        heartbeatTask = Task {
            while !Task.isCancelled && isConnected {
                try? await Task.sleep(for: .seconds(30))

                guard !Task.isCancelled else { break }

                do {
                    try await sendHeartbeat()
                } catch {
                    Logger.warning("⚠️ Heartbeat failed, connection may be dead")
                    await reconnect()
                    break
                }
            }
        }
    }

    private func sendHeartbeat() async throws {
        // Send ping message
        guard let task = webSocketTask else {
            throw WebSocketError.notConnected
        }

        try await task.sendPing()
        Logger.debug("💓 Heartbeat sent")
    }

    // MARK: - Helper Methods

    private func calculateBackoff(attempt: Int) -> Double {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
        let maxDelay = 16.0
        let delay = min(pow(2.0, Double(attempt - 1)), maxDelay)
        return delay
    }

    // MARK: - Connection State

    var connectionState: ConnectionState {
        if isConnected {
            return .connected
        } else if reconnectAttempt > 0 {
            return .reconnecting(attempt: reconnectAttempt)
        } else {
            return .disconnected
        }
    }
}

// MARK: - Supporting Types

enum WebSocketError: Error, LocalizedError {
    case notConnected
    case connectionFailed(Error)
    case sendFailed(Error)
    case receiveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .receiveFailed(let error):
            return "Failed to receive message: \(error.localizedDescription)"
        }
    }
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
