//
//  Logger.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation
import os

/// Centralized logging system with severity levels and structured output
enum Logger {
    // MARK: - Log Levels

    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }

    // MARK: - Configuration

    private static var minimumLevel: Level = .info
    private static let osLog = os.Logger(subsystem: "com.tradingcockpit.app", category: "general")

    static func configure(level: Level) {
        minimumLevel = level
        info("📝 Logger configured with minimum level: \(level)")
    }

    // MARK: - Public Logging Methods

    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    static func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, file: file, function: function, line: line)
    }

    static func critical(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .critical, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private static func log(
        _ message: String,
        level: Level,
        file: String,
        function: String,
        line: Int
    ) {
        // Check minimum level
        guard level >= minimumLevel else { return }

        // Extract filename
        let filename = (file as NSString).lastPathComponent

        // Format message
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formattedMessage = "[\(timestamp)] \(level.emoji) [\(level)] \(filename):\(line) - \(message)"

        #if DEBUG
        // Print to console in debug mode
        print(formattedMessage)
        #endif

        // Log to unified logging system
        osLog.log(level: level.osLogType, "\(formattedMessage)")

        // Write to file for persistence
        writeToFile(formattedMessage)

        // Send critical errors to analytics
        if level >= .error {
            reportToAnalytics(message: message, level: level)
        }
    }

    private static func writeToFile(_ message: String) {
        // TODO: Implement file logging
        // For now, skip file logging in MVP
    }

    private static func reportToAnalytics(message: String, level: Level) {
        // TODO: Implement analytics reporting
        // For now, skip analytics in MVP
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log with structured metadata
    static func log(
        _ message: String,
        level: Level,
        metadata: [String: Any] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            fullMessage += " | Metadata: \(metadataString)"
        }
        log(fullMessage, level: level, file: file, function: function, line: line)
    }
}
