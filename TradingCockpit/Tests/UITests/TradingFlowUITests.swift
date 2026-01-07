//
//  TradingFlowUITests.swift
//  TradingCockpit UI Tests
//
//  Created on 2025-11-24
//
//  NOTE: These tests require Xcode and visionOS Simulator
//

import XCTest

final class TradingFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Authentication Flow

    func testAuthenticationFlow() throws {
        // Given - App launches to authentication screen
        let apiKeyField = app.textFields["Enter your Alpaca API key"]
        let secretKeyField = app.secureTextFields["Enter your secret key"]
        let signInButton = app.buttons["Sign In with Alpaca"]

        // Then - Authentication elements should exist
        XCTAssertTrue(apiKeyField.exists)
        XCTAssertTrue(secretKeyField.exists)
        XCTAssertTrue(signInButton.exists)

        // When - Enter credentials
        apiKeyField.tap()
        apiKeyField.typeText("TEST_API_KEY")

        secretKeyField.tap()
        secretKeyField.typeText("TEST_SECRET_KEY")

        // Then - Sign in button should be enabled
        XCTAssertTrue(signInButton.isEnabled)
    }

    // MARK: - Main Navigation

    func testMainMenuNavigation() throws {
        // Given - User is authenticated (mock)
        // Note: In real test, would need to handle authentication first

        // Then - Main menu buttons should exist
        XCTAssertTrue(app.buttons["3D Visualization"].exists)
        XCTAssertTrue(app.buttons["Watchlist"].exists)
        XCTAssertTrue(app.buttons["Portfolio"].exists)
        XCTAssertTrue(app.buttons["Orders"].exists)
        XCTAssertTrue(app.buttons["Place Order"].exists)
    }

    // MARK: - Watchlist Flow

    func testWatchlistNavigation() throws {
        // When - Tap watchlist button
        app.buttons["Watchlist"].tap()

        // Then - Should navigate to watchlist view
        XCTAssertTrue(app.navigationBars["Watchlist"].exists)

        // Then - Watchlist tabs should exist
        XCTAssertTrue(app.staticTexts["My Watchlist"].exists)
    }

    func testAddSymbolToWatchlist() throws {
        // Given - Navigate to watchlist
        app.buttons["Watchlist"].tap()

        // When - Tap add button
        app.buttons["Add Symbol"].tap()

        // Then - Search view should appear
        XCTAssertTrue(app.navigationBars["Add Symbol"].exists)
        XCTAssertTrue(app.searchFields["Search symbols or companies"].exists)

        // When - Type in search
        let searchField = app.searchFields["Search symbols or companies"]
        searchField.tap()
        searchField.typeText("AAPL")

        // Then - Search results should appear
        XCTAssertTrue(app.staticTexts["Apple Inc."].exists)

        // When - Tap add button
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()

        // Then - Symbol should be added (checkmark appears)
        XCTAssertTrue(app.staticTexts["Added"].exists)
    }

    // MARK: - Order Entry Flow

    func testOrderEntryNavigation() throws {
        // When - Tap place order button
        app.buttons["Place Order"].tap()

        // Then - Order entry view should appear
        XCTAssertTrue(app.navigationBars["Place Order"].exists)

        // Then - Order entry elements should exist
        XCTAssertTrue(app.segmentedControls["Order Type"].exists)
        XCTAssertTrue(app.buttons["Buy"].exists)
        XCTAssertTrue(app.buttons["Sell"].exists)
        XCTAssertTrue(app.sliders.firstMatch.exists) // Quantity slider
    }

    func testOrderEntryValidation() throws {
        // Given - Navigate to order entry
        app.buttons["Place Order"].tap()

        // Then - Review button should be disabled initially (no quantity)
        let reviewButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Review'")).firstMatch
        XCTAssertFalse(reviewButton.isEnabled)

        // When - Set quantity
        let quantitySlider = app.sliders.firstMatch
        quantitySlider.adjust(toNormalizedSliderPosition: 0.5)

        // Then - Review button should be enabled
        XCTAssertTrue(reviewButton.isEnabled)
    }

    func testOrderConfirmationFlow() throws {
        // Given - Navigate to order entry and fill in details
        app.buttons["Place Order"].tap()

        let quantitySlider = app.sliders.firstMatch
        quantitySlider.adjust(toNormalizedSliderPosition: 0.1) // Set to 10%

        // When - Tap review button
        let reviewButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Review'")).firstMatch
        reviewButton.tap()

        // Then - Confirmation dialog should appear
        XCTAssertTrue(app.navigationBars["Confirm Order"].exists)
        XCTAssertTrue(app.staticTexts["Review Your Order"].exists)
        XCTAssertTrue(app.buttons["Confirm & Submit Order"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }

    // MARK: - Portfolio Flow

    func testPortfolioNavigation() throws {
        // When - Tap portfolio button
        app.buttons["Portfolio"].tap()

        // Then - Portfolio view should appear
        XCTAssertTrue(app.navigationBars["Portfolio"].exists)
        XCTAssertTrue(app.staticTexts["Account Value"].exists)
    }

    func testPortfolioPositionInteraction() throws {
        // Given - Navigate to portfolio
        app.buttons["Portfolio"].tap()

        // When - Tap on a position (if exists)
        let positions = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'position'"))
        if positions.count > 0 {
            positions.firstMatch.tap()

            // Then - Order entry should open for that symbol
            XCTAssertTrue(app.navigationBars["Place Order"].exists)
        }
    }

    // MARK: - Orders Flow

    func testOrdersNavigation() throws {
        // When - Tap orders button
        app.buttons["Orders"].tap()

        // Then - Orders view should appear
        XCTAssertTrue(app.navigationBars["Orders"].exists)

        // Then - Tab picker should exist
        XCTAssertTrue(app.buttons["Active"].exists)
        XCTAssertTrue(app.buttons["History"].exists)
    }

    func testOrdersTabSwitch() throws {
        // Given - Navigate to orders
        app.buttons["Orders"].tap()

        // When - Tap history tab
        app.buttons["History"].tap()

        // Then - Should show history view
        // Note: Content depends on order history
        XCTAssertTrue(app.navigationBars["Orders"].exists)
    }

    // MARK: - 3D Visualization Flow

    func testVisualizationNavigation() throws {
        // When - Tap 3D visualization button
        app.buttons["3D Visualization"].tap()

        // Then - Visualization view should appear
        XCTAssertTrue(app.navigationBars["Market Visualization"].exists)

        // Then - Control elements should exist
        XCTAssertTrue(app.buttons["Reset View"].exists)
        XCTAssertTrue(app.toggles["Labels"].exists)
        XCTAssertTrue(app.toggles["Grid"].exists)
    }

    // MARK: - Sign Out Flow

    func testSignOutFlow() throws {
        // When - Tap sign out button
        app.buttons["Sign Out"].tap()

        // Then - Should return to authentication screen
        XCTAssertTrue(app.textFields["Enter your Alpaca API key"].waitForExistence(timeout: 2))
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testNavigationPerformance() throws {
        measure {
            app.buttons["Watchlist"].tap()
            app.navigationBars.buttons.firstMatch.tap() // Back button

            app.buttons["Portfolio"].tap()
            app.navigationBars.buttons.firstMatch.tap()

            app.buttons["Orders"].tap()
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
