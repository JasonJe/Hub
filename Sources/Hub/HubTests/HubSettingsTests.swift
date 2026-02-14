//
//  HubSettingsTests.swift
//  HubTests
//
//  T039: Tests for HubSettings persistence
//

import Testing
@testable import Hub

struct HubSettingsTests {

    @Test
    func testDefaultSettings() {
        let settings = HubSettings()
        
        #expect(settings.launchAtLogin == false)
        #expect(settings.soundEnabled == true)
        #expect(settings.mode == .dynamicIsland)
        #expect(settings.position == .right)
    }
    
    @Test
    func testSettingsPersistence() {
        // Save settings
        var settings = HubSettings()
        settings.launchAtLogin = true
        settings.soundEnabled = false
        settings.position = .left
        settings.mode = .floating
        settings.save()
        
        // Load settings
        let loadedSettings = HubSettings()
        
        #expect(loadedSettings.launchAtLogin == true)
        #expect(loadedSettings.soundEnabled == false)
        #expect(loadedSettings.position == .left)
        #expect(loadedSettings.mode == .floating)
        
        // Clean up
        settings.launchAtLogin = false
        settings.soundEnabled = true
        settings.position = .right
        settings.mode = .dynamicIsland
        settings.save()
    }
    
    @Test
    func testHubPositionValues() {
        #expect(HubPosition.left.rawValue == "left")
        #expect(HubPosition.right.rawValue == "right")
    }
    
    @Test
    func testHubModeValues() {
        #expect(HubMode.dynamicIsland.rawValue == "dynamicIsland")
        #expect(HubMode.floating.rawValue == "floating")
    }

}
