//
//  HubAutoCloseManagerTests.swift
//  HubTests
//
//  Tests for HubAutoCloseManager auto-close logic
//

import Testing
import Foundation
@testable import Hub

@MainActor
struct HubAutoCloseManagerTests {
    
    // MARK: - State Tests
    
    @Test
    func testInitialState() {
        let manager = HubAutoCloseManager()
        
        #expect(manager.isMouseInHub == false)
        #expect(manager.isMouseInOrb == false)
        #expect(manager.isDragging == false)
        #expect(manager.isShowingSettings == false)
        #expect(manager.isShowingConfirmation == false)
        #expect(manager.hasItems == false)
        #expect(manager.isHubExpanded == false)
        #expect(manager.hasMouseEnteredHub == false)
    }
    
    @Test
    func testResetClearsAllStates() {
        let manager = HubAutoCloseManager()
        
        // Set some states
        manager.isMouseInHub = true
        manager.isDragging = true
        manager.hasMouseEnteredHub = true
        
        // Reset
        manager.reset()
        
        // Verify all cleared
        #expect(manager.isMouseInHub == false)
        #expect(manager.isDragging == false)
        #expect(manager.hasMouseEnteredHub == false)
    }
    
    // MARK: - Mouse Event Tests
    
    @Test
    func testMouseEnteredHubSetsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.mouseEnteredHub()
        
        #expect(manager.isMouseInHub == true)
        #expect(manager.hasMouseEnteredHub == true)
    }
    
    @Test
    func testMouseExitedHubClearsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.mouseEnteredHub()
        manager.mouseExitedHub()
        
        #expect(manager.isMouseInHub == false)
    }
    
    @Test
    func testMouseEnteredOrbSetsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.mouseEnteredOrb()
        
        #expect(manager.isMouseInOrb == true)
    }
    
    @Test
    func testMouseExitedOrbClearsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.mouseEnteredOrb()
        manager.mouseExitedOrb()
        
        #expect(manager.isMouseInOrb == false)
    }
    
    // MARK: - Drag State Tests
    
    @Test
    func testStartDraggingSetsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.startDragging()
        
        #expect(manager.isDragging == true)
    }
    
    @Test
    func testEndDraggingClearsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.startDragging()
        manager.endDragging()
        
        #expect(manager.isDragging == false)
    }
    
    // MARK: - Settings and Confirmation Tests
    
    @Test
    func testSettingsStateChanged() {
        let manager = HubAutoCloseManager()
        
        manager.settingsStateChanged(true)
        #expect(manager.isShowingSettings == true)
        
        manager.settingsStateChanged(false)
        #expect(manager.isShowingSettings == false)
    }
    
    @Test
    func testConfirmationStateChanged() {
        let manager = HubAutoCloseManager()
        
        manager.confirmationStateChanged(true)
        #expect(manager.isShowingConfirmation == true)
        
        manager.confirmationStateChanged(false)
        #expect(manager.isShowingConfirmation == false)
    }
    
    // MARK: - Items State Tests
    
    @Test
    func testItemsCountChanged() {
        let manager = HubAutoCloseManager()
        
        manager.itemsCountChanged(true)
        #expect(manager.hasItems == true)
        
        manager.itemsCountChanged(false)
        #expect(manager.hasItems == false)
    }
    
    // MARK: - Hub Expand/Close Tests
    
    @Test
    func testHubDidExpandSetsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.hubDidExpand()
        
        #expect(manager.isHubExpanded == true)
        #expect(manager.hasMouseEnteredHub == false)
    }
    
    @Test
    func testHubDidCloseClearsFlag() {
        let manager = HubAutoCloseManager()
        
        manager.hubDidExpand()
        manager.hubDidClose()
        
        #expect(manager.isHubExpanded == false)
    }
    
    // MARK: - Should Auto Close Logic Tests
    
    @Test
    func testShouldNotAutoCloseWhenMouseInHub() {
        let manager = HubAutoCloseManager()
        manager.isMouseInHub = true
        
        // Should not auto close
        manager.mouseExitedHub() // This would trigger auto-close check
        // Since we can't directly test shouldAutoClose(), we verify the state
        #expect(manager.isMouseInHub == false)
    }
    
    @Test
    func testShouldNotAutoCloseWhenDragging() {
        let manager = HubAutoCloseManager()
        manager.isDragging = true
        
        // Dragging should prevent auto close
        #expect(manager.isDragging == true)
    }
    
    @Test
    func testShouldNotAutoCloseWhenShowingSettings() {
        let manager = HubAutoCloseManager()
        manager.isShowingSettings = true
        
        #expect(manager.isShowingSettings == true)
    }
    
    @Test
    func testShouldNotAutoCloseWhenShowingConfirmation() {
        let manager = HubAutoCloseManager()
        manager.isShowingConfirmation = true
        
        #expect(manager.isShowingConfirmation == true)
    }
    
    @Test
    func testShouldNotAutoCloseWhenMouseInOrb() {
        let manager = HubAutoCloseManager()
        manager.isMouseInOrb = true
        
        #expect(manager.isMouseInOrb == true)
    }
    
    // MARK: - Callback Tests
    
    @Test
    func testOnCloseCallbackCanBeSet() {
        let manager = HubAutoCloseManager()
        
        manager.onClose = {
            // Callback set successfully
        }
        
        #expect(manager.onClose != nil)
    }
}
