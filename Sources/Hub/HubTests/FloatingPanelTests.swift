//
//  FloatingPanelTests.swift
//  HubTests
//
//  Tests for FloatingPanel window creation and behavior
//

import Testing
import AppKit
@testable import Hub

struct FloatingPanelTests {

    // MARK: - Panel Creation Tests
    
    @Test
    func testFloatingPanelCreation() {
        // Test that FloatingPanel can be created with correct configuration
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 200)
        
        let panel = FloatingPanel(
            contentRect: contentRect,
            backing: .buffered,
            defer: false
        )
        
        // Verify panel properties
        #expect(panel.isFloatingPanel == true)
        #expect(panel.level == .mainMenu + 3)  // 与 boring.notch 相同的层级
        #expect(panel.backgroundColor == .clear)
        #expect(panel.isOpaque == false)
        #expect(panel.titleVisibility == .hidden)
    }
    
    @Test
    func testFloatingPanelCollectionBehavior() {
        // Test that panel has correct collection behavior for multi-space support
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        let behaviors = panel.collectionBehavior
        #expect(behaviors.contains(.canJoinAllSpaces))
        #expect(behaviors.contains(.fullScreenAuxiliary))
        #expect(behaviors.contains(.stationary))
        #expect(behaviors.contains(.ignoresCycle))
    }
    
    // MARK: - Window Properties Tests
    
    @Test
    func testFloatingPanelFrame() {
        let contentRect = NSRect(x: 100, y: 100, width: 360, height: 240)
        let panel = FloatingPanel(
            contentRect: contentRect,
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.frame == contentRect)
    }
    
    @Test
    func testFloatingPanelIsKeyWindow() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.canBecomeKey == true)
    }
    
    @Test
    func testFloatingPanelCanBecomeMain() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.canBecomeMain == true)
    }
    
    @Test
    func testFloatingPanelIsNotMovable() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        // 禁止系统拖动，我们自己处理
        #expect(panel.isMovable == false)
    }
    
    @Test
    func testFloatingPanelHasNoShadow() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.hasShadow == false)
    }
    
    @Test
    func testFloatingPanelTitlebarAppearsTransparent() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.titlebarAppearsTransparent == true)
    }
    
    @Test
    func testFloatingPanelAcceptsMouseMovedEvents() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.acceptsMouseMovedEvents == true)
    }
    
    @Test
    func testFloatingPanelNotReleasedWhenClosed() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.isReleasedWhenClosed == false)
    }
    
    // MARK: - Style Mask Tests
    
    @Test
    func testFloatingPanelStyleMaskNonactivating() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.styleMask.contains(.nonactivatingPanel))
    }
    
    @Test
    func testFloatingPanelStyleMaskFullSizeContentView() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.styleMask.contains(.fullSizeContentView))
    }
    
    @Test
    func testFloatingPanelStyleMaskBorderless() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        #expect(panel.styleMask.contains(.borderless))
    }
    
    // MARK: - Callback Tests
    
    @Test
    func testOnDragStartedCallback() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        var callbackCalled = false
        panel.onDragStarted = {
            callbackCalled = true
        }
        
        #expect(panel.onDragStarted != nil)
    }
    
    @Test
    func testOnDragEndedCallback() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        var lastOrigin: NSPoint = .zero
        panel.onDragEnded = { origin in
            lastOrigin = origin
        }
        
        #expect(panel.onDragEnded != nil)
    }
    
    @Test
    func testOnDragEnteredCallback() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        var callbackCalled = false
        panel.onDragEntered = {
            callbackCalled = true
        }
        
        #expect(panel.onDragEntered != nil)
    }
    
    @Test
    func testOnDragExitedCallback() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        var callbackCalled = false
        panel.onDragExited = {
            callbackCalled = true
        }
        
        #expect(panel.onDragExited != nil)
    }
    
    // MARK: - Global Click Monitor Tests
    
    @Test
    func testStartGlobalClickMonitorDoesNotCrash() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        panel.startGlobalClickMonitor()
        panel.stopGlobalClickMonitor()
        
        #expect(true)
    }
    
    @Test
    func testStopGlobalClickMonitorDoesNotCrash() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        // 停止未启动的监控不应该崩溃
        panel.stopGlobalClickMonitor()
        
        #expect(true)
    }
    
    @Test
    func testStartStopGlobalClickMonitorCycle() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        panel.startGlobalClickMonitor()
        panel.stopGlobalClickMonitor()
        panel.startGlobalClickMonitor()
        panel.stopGlobalClickMonitor()
        
        #expect(true)
    }
    
    // MARK: - Drag Detector Tests
    
    @Test
    func testStartDragDetectorDoesNotCrash() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        panel.startDragDetector()
        panel.stopDragDetector()
        
        #expect(true)
    }
    
    @Test
    func testStopDragDetectorDoesNotCrash() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        // 停止未启动的检测器不应该崩溃
        panel.stopDragDetector()
        
        #expect(true)
    }
    
    @Test
    func testUpdateDragRegionDoesNotCrash() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        panel.startDragDetector()
        panel.updateDragRegion()
        panel.stopDragDetector()
        
        #expect(true)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testFullPanelLifecycle() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
            backing: .buffered,
            defer: false
        )
        
        // 设置回调
        panel.onDragStarted = { }
        panel.onDragEnded = { _ in }
        panel.onDragEntered = { }
        panel.onDragExited = { }
        
        // 启动监控
        panel.startGlobalClickMonitor()
        panel.startDragDetector()
        
        // 更新区域
        panel.updateDragRegion()
        
        // 停止监控
        panel.stopGlobalClickMonitor()
        panel.stopDragDetector()
        
        #expect(true)
    }
    
    // MARK: - Window Level Tests
    
    @Test
    func testFloatingPanelLevelIsAboveMainMenu() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        // panel.level = .mainMenu + 3
        #expect(panel.level.rawValue > NSWindow.Level.mainMenu.rawValue)
    }
}