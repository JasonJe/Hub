//
//  FloatingPanelTests.swift
//  HubTests
//
//  Tests for FloatingPanel window creation and behavior
//

import Testing
import SwiftUI
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
    
    // MARK: - HubHostingView Tests
    
    @MainActor
    @Test
    func testHubHostingViewCreation() {
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 200)
        let panel = FloatingPanel(
            contentRect: contentRect,
            backing: .buffered,
            defer: false
        )
        
        let hostingView = HubHostingView(rootView: Text("Test"))
        hostingView.frame = NSRect(origin: .zero, size: contentRect.size)
        panel.contentView = hostingView
        
        #expect(panel.contentView === hostingView)
    }
    
    @MainActor
    @Test
    func testHubHostingViewMouseCallbacks() {
        let hostingView = HubHostingView(rootView: Text("Test"))
        
        var enteredCalled = false
        var exitedCalled = false
        
        hostingView.onMouseEntered = {
            enteredCalled = true
        }
        hostingView.onMouseExited = {
            exitedCalled = true
        }
        
        #expect(hostingView.onMouseEntered != nil)
        #expect(hostingView.onMouseExited != nil)
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
    
    // MARK: - Frame Animation Tests
    
    @MainActor
    @Test
    func testSetFrameWithAnimation() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        let newFrame = NSRect(x: 100, y: 100, width: 400, height: 300)
        
        // setFrame with animate should not crash
        panel.setFrame(newFrame, display: true, animate: true)
        
        // Frame should be updated
        #expect(panel.frame == newFrame)
    }
    
    @MainActor
    @Test
    func testSetFrameWithoutAnimation() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        let newFrame = NSRect(x: 50, y: 50, width: 350, height: 250)
        
        // setFrame without animate should not crash
        panel.setFrame(newFrame, display: true, animate: false)
        
        // Frame should be updated
        #expect(panel.frame == newFrame)
    }
    
    // MARK: - Content View Autoresizing Tests
    
    @MainActor
    @Test
    func testContentViewAutoresizingMask() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            backing: .buffered,
            defer: false
        )
        
        let hostingView = HubHostingView(rootView: Text("Test"))
        panel.contentView = hostingView
        
        // Content view should have autoresizing mask
        #expect(hostingView.autoresizingMask.contains(.width))
        #expect(hostingView.autoresizingMask.contains(.height))
        #expect(hostingView.translatesAutoresizingMaskIntoConstraints == true)
    }
}
