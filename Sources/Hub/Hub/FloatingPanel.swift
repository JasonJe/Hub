//
//  FloatingPanel.swift
//  Hub
//
//  Created by 邱基盛 on 2026/2/13.
//

import SwiftUI
import AppKit

/// 自定义 NSPanel，实现无边框、置顶，透明背景
class FloatingPanel: NSPanel {
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((NSPoint) -> Void)?
    var onDragEntered: (() -> Void)?
    var onDragExited: (() -> Void)?
    
    private var initialMouseLocation: NSPoint = .zero
    private var initialWindowOrigin: NSPoint = .zero
    private var globalMonitor: Any?
    private var dragDetector: DragDetector?
    
    /// 缓存的设置实例
    private var cachedSettings: HubSettings?
    
    var settings: HubSettings {
        if cachedSettings == nil { cachedSettings = HubSettings() }
        return cachedSettings!
    }
    
    func refreshSettings() { cachedSettings = nil }
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless], backing: backing, defer: flag)
        
        self.isFloatingPanel = true
        self.level = .mainMenu + 3
        self.collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isMovable = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Global Click Monitor
    
    func startGlobalClickMonitor() {
        stopGlobalClickMonitor()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            if !self.frame.contains(NSEvent.mouseLocation) {
                NotificationCenter.default.post(name: .hubClickOutside, object: nil)
            }
        }
    }
    
    func stopGlobalClickMonitor() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }
    
    deinit {
        stopGlobalClickMonitor()
        stopDragDetector()
    }
    
    // MARK: - Drag Detection
    
    func startDragDetector() {
        stopDragDetector()
        dragDetector = DragDetector(hubRegion: calculateDragRegion())
        dragDetector?.onDragEntersHubRegion = { [weak self] in
            DispatchQueue.main.async { NotificationCenter.default.post(name: .hubDragEntered, object: nil) }
        }
        dragDetector?.onDragExitsHubRegion = { [weak self] in
            DispatchQueue.main.async { NotificationCenter.default.post(name: .hubDragExited, object: nil) }
        }
        dragDetector?.startMonitoring()
    }
    
    func stopDragDetector() {
        dragDetector?.stopMonitoring()
        dragDetector = nil
    }
    
    private func calculateDragRegion() -> CGRect {
        return CGRect(
            x: frame.origin.x,
            y: frame.origin.y - 100,
            width: frame.width,
            height: frame.height + 100
        )
    }

    func updateDragRegion() {
        dragDetector?.updateRegion(calculateDragRegion())
    }
    
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag)
        updateDragRegion()
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
        updateDragRegion()
    }

    // MARK: - Mouse Interaction
    
    override func mouseDown(with event: NSEvent) {
        if settings.mode == .floating {
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowOrigin = self.frame.origin
            onDragStarted?()
        }
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        if settings.mode == .floating {
            let currentMouseLocation = NSEvent.mouseLocation
            let deltaX = currentMouseLocation.x - initialMouseLocation.x
            let deltaY = currentMouseLocation.y - initialMouseLocation.y
            self.setFrameOrigin(NSPoint(x: initialWindowOrigin.x + deltaX, y: initialWindowOrigin.y + deltaY))
        }
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        if settings.mode == .floating { onDragEnded?(self.frame.origin) }
        super.mouseUp(with: event)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hubClickOutside = Notification.Name("hubClickOutside")
    static let hubCloseSettings = Notification.Name("hubCloseSettings")
    static let hubApplySettings = Notification.Name("hubApplySettings")
    static let hubDragEntered = Notification.Name("hubDragEntered")
    static let hubDragExited = Notification.Name("hubDragExited")
    static let hubModeChanged = Notification.Name("hubModeChanged")
    static let hubPositionChanged = Notification.Name("hubPositionChanged")
}

// MARK: - Window Manager

@MainActor
class WindowManager {
    static let shared = WindowManager()
    var panel: FloatingPanel?
    
    private init() {}
    
    func setupWindow(view: some View) {
        NotificationCenter.default.removeObserver(self)
        let settings = HubSettings()
        let rect = calculateRect(for: settings)

        panel = FloatingPanel(contentRect: rect, backing: .buffered, defer: false)
        guard let panel = panel else { return }
        
        panel.onDragEnded = { [weak self] origin in self?.saveFloatingPosition(origin) }
        
        // P0 修复：使用自定义 HostingView 处理 hitTest
        let hostingView = HubHostingView(rootView: view.edgesIgnoringSafeArea(.all))
        panel.contentView = hostingView
        
        panel.minSize = NSSize(width: HubMetrics.windowSize.width, height: HubMetrics.windowSize.height)
        panel.startGlobalClickMonitor()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { panel.startDragDetector() }
        panel.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleModeChange(_:)), name: .hubModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePositionChange(_:)), name: .hubPositionChanged, object: nil)
    }
    
    private func calculateRect(for settings: HubSettings) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 600, y: 900, width: HubMetrics.windowSize.width, height: HubMetrics.windowSize.height)
        }
        let screenFrame = screen.frame
        let fullWidth = HubMetrics.windowSize.width
        let fullHeight = HubMetrics.windowSize.height
        let contentWidth = HubMetrics.openHubSize.width
        
        switch settings.mode {
        case .dynamicIsland:
            let y = screenFrame.maxY - fullHeight
            let x = screenFrame.origin.x + (screenFrame.width - contentWidth) / 2 - HubMetrics.sidePadding
            return NSRect(x: x, y: y, width: fullWidth, height: fullHeight)
        case .floating:
            var x = settings.floatingX, y = settings.floatingY
            if x == 0 && y == 0 {
                x = screenFrame.origin.x + screenFrame.width - contentWidth - 100 - HubMetrics.sidePadding
                y = screenFrame.origin.y + screenFrame.height / 2
            }
            return NSRect(x: x, y: y, width: fullWidth, height: fullHeight)
        }
    }
    
    private func saveFloatingPosition(_ origin: NSPoint) {
        var settings = HubSettings()
        settings.floatingX = origin.x; settings.floatingY = origin.y; settings.save()
    }
    
    @objc func handleModeChange(_ notification: Notification) {
        guard let mode = notification.userInfo?["mode"] as? HubMode else { return }
        var settings = HubSettings(); settings.mode = mode; settings.save()
        panel?.setFrame(calculateRect(for: settings), display: true, animate: false)
        NotificationCenter.default.post(name: .hubApplySettings, object: nil, userInfo: ["mode": mode])
    }
    
    @objc func handlePositionChange(_ notification: Notification) {
        if HubSettings().mode == .floating {
            panel?.setFrame(calculateRect(for: HubSettings()), display: true)
        }
    }
}

/// P0 修复：自定义 HostingView，仅拦截内容区域的点击
class HubHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // 计算内容区域的有效 Rect
        let contentRect = NSRect(
            x: HubMetrics.sidePadding,
            y: HubMetrics.shadowPadding,
            width: HubMetrics.openHubSize.width,
            height: HubMetrics.openHubSize.height
        )
        // 只有在内容区域内的点击才由窗口处理
        return contentRect.contains(point) ? super.hitTest(point) : nil
    }
}
