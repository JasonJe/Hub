//
//  HubSettingsErrorTests.swift
//  HubTests
//
//  Tests for HubSettings error handling
//

import Testing
import Foundation
@testable import Hub

struct HubSettingsErrorTests {
    
    // MARK: - Error Type Tests
    
    @Test
    func testLaunchAtLoginRegistrationFailedError() {
        let error = HubSettingsError.launchAtLoginRegistrationFailed(underlyingError: nil)
        
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("注册") == true)
    }
    
    @Test
    func testLaunchAtLoginUnregistrationFailedError() {
        let error = HubSettingsError.launchAtLoginUnregistrationFailed(underlyingError: nil)
        
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("取消注册") == true)
    }
    
    @Test
    func testRequiresUserApprovalError() {
        let error = HubSettingsError.requiresUserApproval
        
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("批准") == true)
    }
    
    @Test
    func testErrorWithUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = HubSettingsError.launchAtLoginRegistrationFailed(underlyingError: underlyingError)
        
        #expect(error.errorDescription != nil)
    }
    
    // MARK: - Recovery Suggestion Tests
    
    @Test
    func testRegistrationFailedRecoverySuggestion() {
        let error = HubSettingsError.launchAtLoginRegistrationFailed(underlyingError: nil)
        
        #expect(error.recoverySuggestion != nil)
    }
    
    @Test
    func testRequiresApprovalRecoverySuggestion() {
        let error = HubSettingsError.requiresUserApproval
        
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("系统设置") == true)
    }
    
    // MARK: - Cache Tests
    
    @Test
    func testClearCache() {
        // Set some values
        var settings = HubSettings()
        settings.floatingX = 500
        settings.floatingY = 600
        
        // Clear cache
        HubSettings.clearCache()
        
        // After clearing cache, should still be able to read
        let newSettings = HubSettings()
        #expect(newSettings.floatingX == 500)
        #expect(newSettings.floatingY == 600)
    }
    
    // MARK: - Settings Persistence Tests
    
    @Test
    func testFloatingPositionPersistence() {
        var settings = HubSettings()
        settings.floatingX = 123.45
        settings.floatingY = 678.90
        settings.save()
        
        // Clear cache to force re-read
        HubSettings.clearCache()
        
        let loadedSettings = HubSettings()
        #expect(abs(loadedSettings.floatingX - 123.45) < 0.01)
        #expect(abs(loadedSettings.floatingY - 678.90) < 0.01)
    }
    
    @Test
    func testModePersistence() {
        var settings = HubSettings()
        settings.mode = .floating
        settings.save()
        
        HubSettings.clearCache()
        
        let loadedSettings = HubSettings()
        #expect(loadedSettings.mode == .floating)
        
        // Reset to default
        settings.mode = .dynamicIsland
        settings.save()
    }
    
    @Test
    func testSoundEnabledPersistence() {
        var settings = HubSettings()
        settings.soundEnabled = false
        settings.save()
        
        HubSettings.clearCache()
        
        let loadedSettings = HubSettings()
        #expect(loadedSettings.soundEnabled == false)
        
        // Reset to default
        settings.soundEnabled = true
        settings.save()
    }
    
    // MARK: - Default Values Tests
    
    @Test
    func testDefaultValues() {
        HubSettings.clearCache()
        
        let settings = HubSettings()
        #expect(settings.launchAtLogin == false)
        #expect(settings.soundEnabled == true)
        #expect(settings.mode == .dynamicIsland)
        #expect(settings.position == .right)
        #expect(settings.hasCompletedOnboarding == false)
    }
    
    // MARK: - HubMode Tests
    
    @Test
    func testHubModeRawValues() {
        #expect(HubMode.dynamicIsland.rawValue == "dynamicIsland")
        #expect(HubMode.floating.rawValue == "floating")
    }
    
    @Test
    func testHubModeDisplayNames() {
        #expect(HubMode.dynamicIsland.displayName == "灵动岛")
        #expect(HubMode.floating.displayName == "悬浮球")
    }
    
    // MARK: - HubPosition Tests
    
    @Test
    func testHubPositionRawValues() {
        #expect(HubPosition.left.rawValue == "left")
        #expect(HubPosition.right.rawValue == "right")
    }
    
    @Test
    func testHubPositionDisplayNames() {
        #expect(HubPosition.left.displayName == "左侧")
        #expect(HubPosition.right.displayName == "右侧")
    }
}
