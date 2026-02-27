//
//  FloatingPanel.swift
//  Hub
//

import SwiftUI
import AppKit
import QuartzCore

/// 自定义 NSPanel，实现无边框、置顶，透明背景
class FloatingPanel: NSPanel {
    
    /// 防止约束更新循环的标志
    private var isUpdatingFrame = false
    
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
        
        // 禁用自动约束系统，防止与 SwiftUI 冲突
        self.contentView?.translatesAutoresizingMaskIntoConstraints = true
        self.contentView?.autoresizingMask = [.width, .height]
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    /// 重写 setFrame - 禁用隐式动画避免 CATransaction 冲突
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        super.setFrame(frameRect, display: flag)
        CATransaction.commit()
    }
    
    /// 重写 setFrame 带动画版本
    override func setFrame(_ frameRect: NSRect, display flag: Bool, animate: Bool) {
        if animate {
            super.setFrame(frameRect, display: flag, animate: true)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            super.setFrame(frameRect, display: flag, animate: false)
            CATransaction.commit()
        }
    }
    
    /// 重写 contentView setter 确保禁用约束
    override var contentView: NSView? {
        get { super.contentView }
        set {
            super.contentView = newValue
            newValue?.translatesAutoresizingMaskIntoConstraints = true
            newValue?.autoresizingMask = [.width, .height]
        }
    }
    
}

/// 自定义 HostingView 以确保接受第一响应，并追踪鼠标进入/离开
class HubHostingView<Content: View>: NSHostingView<Content> {
    
    /// 鼠标进入回调
    var onMouseEntered: (() -> Void)?
    /// 鼠标离开回调
    var onMouseExited: (() -> Void)?
    
    private var trackingArea: NSTrackingArea?
    
    required init(rootView: Content) {
        super.init(rootView: rootView)
        // 禁用自动约束，防止与 SwiftUI 布局系统冲突
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.width, .height]
        setupTrackingArea()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.width, .height]
        setupTrackingArea()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    /// 重写 layout 方法，禁用约束更新
    override func layout() {
        super.layout()
        // 确保子视图不使用约束
        subviews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = true
        }
    }
    
    private func setupTrackingArea() {
        // 移除旧的追踪区域
        if let oldTrackingArea = trackingArea {
            removeTrackingArea(oldTrackingArea)
        }
        
        // 创建新的追踪区域
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]
        trackingArea = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        HubLogger.log("🖱️ HubHostingView mouseEntered")
        onMouseEntered?()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        HubLogger.log("🖱️ HubHostingView mouseExited")
        onMouseExited?()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hubClickOutside = Notification.Name("hubClickOutside")
    static let hubCloseSettings = Notification.Name("hubCloseSettings")
    static let hubApplySettings = Notification.Name("hubApplySettings")
    static let hubDragEntered = Notification.Name("hubDragEntered")
    static let hubDragExited = Notification.Name("hubDragExited")
    static let hubDragStateChanged = Notification.Name("hubDragStateChanged")
    static let hubShowDragOverlay = Notification.Name("hubShowDragOverlay")
    static let hubModeChanged = Notification.Name("hubModeChanged")
    static let hubPositionChanged = Notification.Name("hubPositionChanged")
    static let hubOrbTapped = Notification.Name("hubOrbTapped")
    static let hubExpandMenu = Notification.Name("hubExpandMenu")
    static let hubCollapseMenu = Notification.Name("hubCollapseMenu")
    static let hubMouseEntered = Notification.Name("hubMouseEntered")
    static let hubMouseExited = Notification.Name("hubMouseExited")
}

// MARK: - 刘海模式拖拽检测状态

/// 刘海模式拖拽检测状态管理类
private class DynamicIslandDragState {
    var mouseDownMonitor: Any?
    var mouseDraggedMonitor: Any?
    var mouseUpMonitor: Any?
    var pasteboardChangeCount: Int = -1
    var isDragging: Bool = false
    var isContentDragging: Bool = false
    let dragPasteboard = NSPasteboard(name: .drag)
    
    func cleanup() {
        [mouseDownMonitor, mouseDraggedMonitor, mouseUpMonitor].forEach { monitor in
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        mouseDownMonitor = nil
        mouseDraggedMonitor = nil
        mouseUpMonitor = nil
        isDragging = false
        isContentDragging = false
    }
    
    deinit {
        cleanup()
    }
}

/// 弱引用包装器 - 用于刘海模式拖拽检测
private class WeakIslandDragState {
    weak var value: DynamicIslandDragState?
    init(value: DynamicIslandDragState?) {
        self.value = value
    }
}

@MainActor
class WindowManager {
    static let shared = WindowManager()
    var panel: FloatingPanel?
    
    /// 刘海模式的全局拖拽检测状态
    private var dragDetectionState = DynamicIslandDragState()
    
    func setupWindow(view: some View) {
        NotificationCenter.default.removeObserver(self)
        
        let settings = HubSettings()
        let rect = calculateRect(for: settings)

        panel = FloatingPanel(contentRect: rect, backing: .buffered, defer: false)
        guard let panel = panel else { return }
        
        // 使用 CATransaction 禁用隐式动画，避免约束冲突
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let hostingView = HubHostingView(rootView: view.edgesIgnoringSafeArea(.all))
        hostingView.frame = NSRect(origin: .zero, size: rect.size)
        panel.contentView = hostingView
        
        CATransaction.commit()
        
        panel.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleModeChange(_:)), name: .hubModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePositionChange(_:)), name: .hubPositionChanged, object: nil)
        
        // 延迟启动全局拖拽检测（刘海模式）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startDragDetection()
        }
    }
    
    /// 关闭窗口
    func closeWindow() {
        // 停止全局拖拽检测
        stopDragDetection()
        
        panel?.close()
        panel = nil
        HubLogger.log("刘海模式窗口已关闭")
    }
    
    // MARK: - 刘海模式全局拖拽检测
    
    /// 开始检测文件拖拽（刘海模式）
    private func startDragDetection() {
        dragDetectionState.cleanup()
        
        HubLogger.log("🔵 刘海模式：开始监听文件拖拽（全局鼠标事件）")
        
        let weakDragState = WeakIslandDragState(value: dragDetectionState)
        
        // 鼠标按下 - 记录粘贴板状态
        dragDetectionState.mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { _ in
            guard let dragState = weakDragState.value else { return }
            dragState.pasteboardChangeCount = dragState.dragPasteboard.changeCount
            dragState.isDragging = true
            dragState.isContentDragging = false
        }
        
        // 鼠标移动 - 检测是否开始拖拽文件
        dragDetectionState.mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { _ in
            guard let dragState = weakDragState.value, dragState.isDragging else { return }
            
            // 检测粘贴板变化，确认是内容拖拽
            if !dragState.isContentDragging && dragState.dragPasteboard.changeCount != dragState.pasteboardChangeCount {
                let hasFileURL = dragState.dragPasteboard.types?.contains(.fileURL) == true
                if hasFileURL {
                    dragState.isContentDragging = true
                    HubLogger.log("🔵 刘海模式：检测到文件拖拽，通知展开 Hub")
                    
                    DispatchQueue.main.async {
                        // 通知 HubView 展开并显示拖拽效果
                        NotificationCenter.default.post(
                            name: .hubDragEntered,
                            object: nil
                        )
                    }
                }
            }
        }
        
        // 鼠标松开 - 拖拽结束
        dragDetectionState.mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { _ in
            guard let dragState = weakDragState.value else { return }
            if dragState.isContentDragging {
                HubLogger.log("🔵 刘海模式：文件拖拽结束")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .hubDragExited,
                        object: nil
                    )
                }
            }
            
            dragState.isDragging = false
            dragState.isContentDragging = false
            dragState.pasteboardChangeCount = -1
        }
    }
    
    /// 停止拖拽检测
    private func stopDragDetection() {
        dragDetectionState.cleanup()
        HubLogger.log("🔵 刘海模式：停止监听文件拖拽")
    }
    
    // MARK: - 悬浮球模式配置
    
    /// 悬浮球模式初始窗口大小（收起状态，只包裹悬浮球）
    private let floatingWindowSize: CGFloat = 84  // 52px球 + 16px*2边距
    
    private func calculateRect(for settings: HubSettings) -> NSRect {
        // 使用系统设置中配置的主显示屏（带菜单栏的屏幕）
        guard let screen = ScreenManager.shared.getMainScreen() else {
            return NSRect(x: 100, y: 100, width: floatingWindowSize, height: floatingWindowSize)
        }
        
        if settings.mode == .dynamicIsland {
            let hubSize = HubMetrics.windowSize
            let contentWidth = HubMetrics.openHubSize.width
            let x = screen.frame.origin.x + (screen.frame.width - contentWidth) / 2 - HubMetrics.sidePadding
            let y = screen.frame.maxY - hubSize.height
            return NSRect(x: x, y: y, width: hubSize.width, height: hubSize.height)
        } else {
            // 悬浮球模式：使用固定大窗口，只定位窗口位置
            let visibleFrame = screen.visibleFrame
            
            var x = settings.floatingX
            var y = settings.floatingY
            
            // 首次启动，默认右下角
            if x == 0 && y == 0 {
                // 窗口定位在右下角，悬浮球居中显示
                x = visibleFrame.maxX - floatingWindowSize - 20
                y = visibleFrame.minY + 20
                
                var s = settings
                s.floatingX = x
                s.floatingY = y
                s.save()
            }
            
            // 确保窗口在屏幕范围内
            x = max(visibleFrame.minX, min(x, visibleFrame.maxX - floatingWindowSize))
            y = max(visibleFrame.minY, min(y, visibleFrame.maxY - floatingWindowSize))
            
            return NSRect(x: x, y: y, width: floatingWindowSize, height: floatingWindowSize)
        }
    }
    
    /// 更新悬浮球位置（实时拖拽）
    func updateFloatingPosition(x: CGFloat, y: CGFloat) {
        guard HubSettings().mode == .floating,
              let panel = panel else { return }
        
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // 限制在屏幕范围内
        let newX = max(visibleFrame.minX, min(x, visibleFrame.maxX - floatingWindowSize))
        let newY = max(visibleFrame.minY, min(y, visibleFrame.maxY - floatingWindowSize))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
        CATransaction.commit()
    }
    
    @objc func handleModeChange(_ notification: Notification) {
        let settings = HubSettings()
        
        if settings.mode == .floating {
            // 悬浮球模式：保持当前窗口大小，只更新位置
            guard let panel = panel else { return }
            let newOrigin = calculateFloatingOrigin(for: settings)
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            panel.setFrameOrigin(newOrigin)
            CATransaction.commit()
        } else {
            // 刘海模式：重新计算整个窗口
            let newRect = calculateRect(for: settings)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            panel?.setFrame(newRect, display: true, animate: true)
            CATransaction.commit()
        }
    }
    
    @objc func handlePositionChange(_ notification: Notification) {
        let settings = HubSettings()
        
        if settings.mode == .floating {
            // 悬浮球模式：只更新位置
            let newOrigin = calculateFloatingOrigin(for: settings)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            panel?.setFrameOrigin(newOrigin)
            CATransaction.commit()
        } else {
            // 刘海模式
            let newRect = calculateRect(for: settings)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            panel?.setFrame(newRect, display: true)
            CATransaction.commit()
        }
    }
    
        /// 计算悬浮球模式的窗口原点
    
        private func calculateFloatingOrigin(for settings: HubSettings) -> NSPoint {
    
            guard let screen = NSScreen.main else { return NSPoint(x: settings.floatingX, y: settings.floatingY) }
    
            
    
            let visibleFrame = screen.visibleFrame
    
            var x = settings.floatingX
    
            var y = settings.floatingY
    
            
    
            // 首次启动，默认右下角
    
            if x == 0 && y == 0 {
    
                x = visibleFrame.maxX - floatingWindowSize - 20
    
                y = visibleFrame.minY + 20
    
            }
    
            
    
            // 宽松边界，允许部分超出
    
            let padding: CGFloat = 50
    
            x = max(visibleFrame.minX - padding, min(x, visibleFrame.maxX - floatingWindowSize + padding))
    
            y = max(visibleFrame.minY - padding, min(y, visibleFrame.maxY - floatingWindowSize + padding))
    
            
    
            return NSPoint(x: x, y: y)
    
        }
}
