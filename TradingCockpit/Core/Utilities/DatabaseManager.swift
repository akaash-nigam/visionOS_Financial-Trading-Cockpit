//
//  DatabaseManager.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation
import SQLite3

/// Manages SQLite database operations
actor DatabaseManager {
    // MARK: - Singleton

    static let shared = DatabaseManager()

    private init() {}

    // MARK: - Properties

    private var db: OpaquePointer?
    private var isInitialized = false

    // MARK: - Error Types

    enum DatabaseError: Error, LocalizedError {
        case connectionFailed(String)
        case executionFailed(String)
        case preparationFailed(String)
        case bindingFailed(String)
        case notInitialized

        var errorDescription: String? {
            switch self {
            case .connectionFailed(let message):
                return "Database connection failed: \(message)"
            case .executionFailed(let message):
                return "SQL execution failed: \(message)"
            case .preparationFailed(let message):
                return "Statement preparation failed: \(message)"
            case .bindingFailed(let message):
                return "Parameter binding failed: \(message)"
            case .notInitialized:
                return "Database not initialized"
            }
        }
    }

    // MARK: - Initialization

    func initialize() throws {
        guard !isInitialized else {
            Logger.info("ℹ️ Database already initialized")
            return
        }

        let fileURL = try getDatabaseURL()
        Logger.info("📁 Database location: \(fileURL.path)")

        // Open database
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(errorMessage)
        }

        // Enable foreign keys
        try execute("PRAGMA foreign_keys = ON;")

        // Create tables
        try createTables()

        isInitialized = true
        Logger.info("✅ Database initialized successfully")
    }

    func close() {
        guard isInitialized, db != nil else { return }

        if sqlite3_close(db) == SQLITE_OK {
            db = nil
            isInitialized = false
            Logger.info("🔒 Database closed")
        } else {
            Logger.error("❌ Failed to close database")
        }
    }

    // MARK: - Table Creation

    private func createTables() throws {
        // Securities table
        try execute("""
            CREATE TABLE IF NOT EXISTS securities (
                id TEXT PRIMARY KEY,
                symbol TEXT NOT NULL,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                exchange TEXT NOT NULL,
                currency TEXT NOT NULL,
                sector TEXT,
                industry TEXT,
                market_cap REAL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                UNIQUE(symbol, exchange)
            );
        """)

        // Create index on symbol
        try execute("CREATE INDEX IF NOT EXISTS idx_securities_symbol ON securities(symbol);")

        // Orders table (audit trail)
        try execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id TEXT PRIMARY KEY,
                client_order_id TEXT NOT NULL,
                broker_order_id TEXT,
                account_id TEXT NOT NULL,
                symbol TEXT NOT NULL,
                action TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                order_type TEXT NOT NULL,
                limit_price REAL,
                stop_price REAL,
                status TEXT NOT NULL,
                submitted_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                filled_quantity INTEGER DEFAULT 0,
                average_fill_price REAL,
                commission REAL,
                user_id TEXT NOT NULL
            );
        """)

        // Create indices on orders
        try execute("CREATE INDEX IF NOT EXISTS idx_orders_account ON orders(account_id, submitted_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_orders_symbol ON orders(symbol, submitted_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status, submitted_at DESC);")

        // Positions table
        try execute("""
            CREATE TABLE IF NOT EXISTS positions (
                id TEXT PRIMARY KEY,
                account_id TEXT NOT NULL,
                symbol TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                average_price REAL NOT NULL,
                current_price REAL NOT NULL,
                unrealized_pnl REAL NOT NULL,
                realized_pnl REAL NOT NULL,
                updated_at INTEGER NOT NULL,
                UNIQUE(account_id, symbol)
            );
        """)

        // Watchlists table
        try execute("""
            CREATE TABLE IF NOT EXISTS watchlists (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                symbols TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            );
        """)

        Logger.info("✅ Database tables created")
    }

    // MARK: - Query Execution

    func execute(_ sql: String) throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw DatabaseError.executionFailed(message)
        }
    }

    func query(_ sql: String) throws -> [[String: Any]] {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.preparationFailed(errorMessage)
        }

        defer {
            sqlite3_finalize(statement)
        }

        var results: [[String: Any]] = []
        let columnCount = sqlite3_column_count(statement)

        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]

            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)

                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    if let cString = sqlite3_column_text(statement, i) {
                        row[columnName] = String(cString: cString)
                    }
                case SQLITE_BLOB:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        row[columnName] = Data(bytes: blob, count: Int(size))
                    }
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    break
                }
            }

            results.append(row)
        }

        return results
    }

    // MARK: - Helper Methods

    private func getDatabaseURL() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentsURL.appendingPathComponent("TradingCockpit.sqlite")
    }
}

// MARK: - Convenience Methods

extension DatabaseManager {
    /// Insert a security
    func insertSecurity(_ symbol: String, name: String, type: String, exchange: String) async throws {
        let now = Int(Date().timeIntervalSince1970)
        let id = UUID().uuidString

        let sql = """
            INSERT OR REPLACE INTO securities
            (id, symbol, name, type, exchange, currency, created_at, updated_at)
            VALUES ('\(id)', '\(symbol)', '\(name)', '\(type)', '\(exchange)', 'USD', \(now), \(now));
        """

        try await execute(sql)
    }

    /// Get all securities
    func getSecurities() async throws -> [[String: Any]] {
        try await query("SELECT * FROM securities ORDER BY symbol;")
    }

    /// Insert an order
    func insertOrder(
        id: String,
        symbol: String,
        action: String,
        quantity: Int,
        orderType: String,
        status: String
    ) async throws {
        let now = Int(Date().timeIntervalSince1970)
        let clientOrderId = UUID().uuidString

        let sql = """
            INSERT INTO orders
            (id, client_order_id, account_id, symbol, action, quantity, order_type, status,
             submitted_at, updated_at, user_id)
            VALUES ('\(id)', '\(clientOrderId)', 'default', '\(symbol)', '\(action)', \(quantity),
                    '\(orderType)', '\(status)', \(now), \(now), 'default');
        """

        try await execute(sql)
    }

    /// Get recent orders
    func getRecentOrders(limit: Int = 50) async throws -> [[String: Any]] {
        try await query("SELECT * FROM orders ORDER BY submitted_at DESC LIMIT \(limit);")
    }
}
