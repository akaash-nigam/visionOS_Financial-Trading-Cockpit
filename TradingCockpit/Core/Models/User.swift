//
//  User.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation

/// Represents a user of the application
struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String
    var accounts: [Account]
    var preferences: UserPreferences
    let createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        name: String,
        accounts: [Account] = [],
        preferences: UserPreferences = UserPreferences(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.accounts = accounts
        self.preferences = preferences
        self.createdAt = createdAt
    }
}

/// User preferences and settings
struct UserPreferences: Codable {
    var defaultAccount: UUID?
    var theme: Theme
    var enableHaptics: Bool
    var enableSounds: Bool
    var orderConfirmation: OrderConfirmationPreference
    var defaultOrderType: OrderType
    var defaultTimeInForce: TimeInForce

    init(
        defaultAccount: UUID? = nil,
        theme: Theme = .dark,
        enableHaptics: Bool = true,
        enableSounds: Bool = true,
        orderConfirmation: OrderConfirmationPreference = .always,
        defaultOrderType: OrderType = .market,
        defaultTimeInForce: TimeInForce = .day
    ) {
        self.defaultAccount = defaultAccount
        self.theme = theme
        self.enableHaptics = enableHaptics
        self.enableSounds = enableSounds
        self.orderConfirmation = orderConfirmation
        self.defaultOrderType = defaultOrderType
        self.defaultTimeInForce = defaultTimeInForce
    }
}

enum Theme: String, Codable {
    case dark = "Dark"
    case light = "Light"
    case auto = "Auto"
}

enum OrderConfirmationPreference: String, Codable {
    case always = "Always"
    case marketOnly = "Market Orders Only"
    case never = "Never"
}
