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
    
    /// 缓存的设置实例，避免每次鼠标事件都创建新实例
    private var cachedSettings: HubSettings?
    
    /// 获取设置（优先使用缓存）
    var settings: HubSettings {
        if cachedSettings == nil {
            cachedSettings = HubSettings()
        }
        return cachedSettings!
    }
    
    /// 刷新缓存的设置（当设置变化时调用）
    func refreshSettings() {
        cachedSettings = nil
    }
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless], backing: backing, defer: flag)
        
        // 关键属性配置 - 参考 boring.notch
        self.isFloatingPanel = true
        self.level = .mainMenu + 3  // 使用与 boring.notch 相同的层级
        self.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        
        // 外观配置
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isMovable = false  // 禁止窗口拖动，我们自己处理
        
        // 隐藏标题栏和标准按钮
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // 确保能接收鼠标移动事件
        self.acceptsMouseMovedEvents = true
        
        // 不在关闭时释放
        self.isReleasedWhenClosed = false
    }
    
    // 允许 Panel 接收点击
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // 监听全局点击
    func startGlobalClickMonitor() {
        // 移除旧的监听
        stopGlobalClickMonitor()
        
        // 添加全局点击监听
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            // 检查点击是否在窗口内
            let clickLocation = event.locationInWindow
            let windowFrame = self.frame
            
            // 如果点击在窗口外，发送通知
            if !windowFrame.contains(clickLocation) {
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
    
    /// 启动拖拽检测
    func startDragDetector() {
        stopDragDetector()
        
        // 创建拖拽区域（窗口大小）
        let dragRegion = CGRect(
            x: frame.origin.x,
            y: frame.origin.y - 100, // 稍微扩展上方区域以便更容易触发
            width: frame.width,
            height: frame.height + 100
        )
        
        dragDetector = DragDetector(hubRegion: dragRegion)
        
        dragDetector?.onDragEntersHubRegion = { [weak self] in
            DispatchQueue.main.async {
                self?.onDragEntered?()
                NotificationCenter.default.post(name: .hubDragEntered, object: nil)
            }
        }
        
        dragDetector?.onDragExitsHubRegion = { [weak self] in
            DispatchQueue.main.async {
                self?.onDragExited?()
                NotificationCenter.default.post(name: .hubDragExited, object: nil)
            }
        }
        
        dragDetector?.startMonitoring()
    }
    
    /// 停止拖拽检测
    func stopDragDetector() {
        dragDetector?.stopMonitoring()
        dragDetector = nil
    }
    
    /// 更新拖拽区域
    func updateDragRegion() {
        let dragRegion = CGRect(
            x: frame.origin.x,
            y: frame.origin.y - 100,
            width: frame.width,
            height: frame.height + 100
        )
        dragDetector?.updateRegion(dragRegion)
    }
    

    
    // 启用拖动
    override func mouseDown(with event: NSEvent) {
        // 只有在悬浮模式下才能拖动
        if settings.mode == .floating {
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowOrigin = self.frame.origin
            onDragStarted?()
        }
        
        // 检查点击是否在内容视图范围外
        let locationInWindow = event.locationInWindow
        let contentViewFrame = self.contentView?.frame ?? .zero
        if !contentViewFrame.contains(locationInWindow) && settings.mode == .dynamicIsland {
            NotificationCenter.default.post(name: .hubClickOutside, object: nil)
        }
        
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        if settings.mode == .floating {
            let currentMouseLocation = NSEvent.mouseLocation
            let deltaX = currentMouseLocation.x - initialMouseLocation.x
            let deltaY = currentMouseLocation.y - initialMouseLocation.y
            
            let newOrigin = NSPoint(
                x: initialWindowOrigin.x + deltaX,
                y: initialWindowOrigin.y + deltaY
            )
            self.setFrameOrigin(newOrigin)
        }
        
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        if settings.mode == .floating {
            onDragEnded?(self.frame.origin)
        }
        
        super.mouseUp(with: event)
    }
}

// T037 & T048: 扩展 Notification.Name - 集中管理所有通知名称
extension Notification.Name {
    // 用户交互相关
    static let hubClickOutside = Notification.Name("hubClickOutside")
    static let hubCloseSettings = Notification.Name("hubCloseSettings")
    static let hubApplySettings = Notification.Name("hubApplySettings")

    // 拖拽相关
    static let hubDragEntered = Notification.Name("hubDragEntered")
    static let hubDragExited = Notification.Name("hubDragExited")
    static let hubPerformDrag = Notification.Name("hubPerformDrag")

    // 设置相关
    static let hubModeChanged = Notification.Name("hubModeChanged")
    static let hubPositionChanged = Notification.Name("hubPositionChanged")

    // 错误相关
    static let hubError = Notification.Name("hubError")
}

/// 窗口管理器单例
@MainActor
class WindowManager {
    static let shared = WindowManager()
    var panel: FloatingPanel?
    
    private init() {}
    
    func setupWindow(view: some View) {
        // 先移除旧的观察者，防止重复添加
        NotificationCenter.default.removeObserver(self)

        let settings = HubSettings()
        let rect = calculateRect(for: settings)

        HubLogger.window("Creating panel at \(rect), mode: \(settings.mode)")
        
        panel = FloatingPanel(contentRect: rect, backing: .buffered, defer: false)
        
        guard let panel = panel else {
            HubLogger.error("Failed to create panel")
            return
        }
        
        // 设置拖动回调
        panel.onDragEnded = { [weak self] origin in
            self?.saveFloatingPosition(origin)
        }
        
        let hostingView = NSHostingView(rootView: view.edgesIgnoringSafeArea(.all))
        panel.contentView = hostingView
        
        // 设置最小尺寸为窗口尺寸（窗口保持固定大小）
        panel.minSize = NSSize(width: windowSize.width, height: windowSize.height)
        
        // 启动全局点击监听
        panel.startGlobalClickMonitor()
        
        // 延迟启动拖拽检测（确保窗口位置确定后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            panel.startDragDetector()
        }
        
        // 显示窗口
        panel.orderFront(nil)
        panel.makeKeyAndOrderFront(nil)
        
        DispatchQueue.main.async {
            panel.makeKeyAndOrderFront(nil)
            HubLogger.window("Panel is now visible at \(panel.frame)")
        }
        
        // 监听设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModeChange(_:)),
            name: .hubModeChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePositionChange(_:)),
            name: .hubPositionChanged,
            object: nil
        )
    }
    
    // 计算窗口位置 - 窗口始终使用固定大小 windowSize
    private func calculateRect(for settings: HubSettings) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 600, y: 900, width: windowSize.width, height: windowSize.height)
        }
        
        let screenFrame = screen.frame
        let width = windowSize.width
        let height = windowSize.height
        
        switch settings.mode {
        case .dynamicIsland:
            // 动态岛模式：窗口顶部紧贴屏幕顶部，水平居中
            let y = screenFrame.maxY - height
            let x = screenFrame.origin.x + (screenFrame.width - width) / 2
            
            HubLogger.window("Dynamic Island position - screen: \(screenFrame), window: x=\(x), y=\(y), w=\(width), h=\(height)")
            
            return NSRect(x: x, y: y, width: width, height: height)
            
        case .floating:
            // 悬浮模式：使用保存的位置或默认位置
            var x = settings.floatingX
            var y = settings.floatingY
            
            // 如果没有保存的位置，使用默认右侧位置
            if x == 0 && y == 0 {
                let margin: CGFloat = 100
                x = screenFrame.origin.x + screenFrame.width - width - margin
                y = screenFrame.origin.y + screenFrame.height / 2
            }
            
            return NSRect(x: x, y: y, width: width, height: height)
        }
    }
    
    // 保存悬浮模式下的位置
    private func saveFloatingPosition(_ origin: NSPoint) {
        var settings = HubSettings()
        settings.floatingX = origin.x
        settings.floatingY = origin.y
        settings.save()
    }
    
    // 处理模式变化
    @objc func handleModeChange(_ notification: Notification) {
        guard let mode = notification.userInfo?["mode"] as? HubMode else { return }
        
        HubLogger.window("handleModeChange - mode = \(mode)")
        
        // 更新设置
        var settings = HubSettings()
        settings.mode = mode
        settings.save()
        
        // 重新计算位置
        let rect = calculateRect(for: settings)
        
        // 移动窗口到新位置（立即生效）
        panel?.setFrame(rect, display: true, animate: false)
        
        // 通知 UI 更新
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .hubApplySettings, object: nil, userInfo: ["mode": mode])
            HubLogger.window("Posted hubApplySettings notification")
        }
    }
    
    // 更新窗口大小 - 现在窗口固定大小，此方法仅用于兼容
    func updateSize(width: CGFloat, height: CGFloat) {
        // 窗口大小固定，不随内容变化
    }
    
    // 处理位置变化（悬浮模式下）
    @objc func handlePositionChange(_ notification: Notification) {
        let settings = HubSettings()
        if settings.mode == .floating {
            let rect = calculateRect(for: settings)
            panel?.setFrame(rect, display: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

}