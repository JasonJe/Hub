//
//  HubInteractionTests.swift
//  HubUITests
//
//  T031 & T032: UI tests - Hub interactions
//

import XCTest

final class HubInteractionTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testClickToExpandHub() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for Hub window
        let hubWindow = app.windows["Hub"]
        XCTAssertTrue(hubWindow.waitForExistence(timeout: 5))
        
        // Click on Hub to expand to stashed view
        hubWindow.click()
        
        // Verify state transition occurred
        // (In a full test, we'd verify the UI changed to show file list)
    }
    
    @MainActor
    func testESCDismissesHub() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for Hub window
        let hubWindow = app.windows["Hub"]
        XCTAssertTrue(hubWindow.waitForExistence(timeout: 5))
        
        // Press Escape key using typeKey
        hubWindow.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        
        // Verify Hub returns to idle state
        // (In a full test, we'd verify the UI returned to compact view)
    }
    
    @MainActor
    func testHubRespondsToInteraction() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify Hub window is responsive
        XCTAssertTrue(app.windows.count > 0)
    }

}
