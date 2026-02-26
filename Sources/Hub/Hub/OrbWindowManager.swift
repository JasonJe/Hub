//
//  OrbWindowManager.swift
//  Hub
//
//  悬浮球窗口管理器 - 独立的悬浮球窗口
//

import SwiftUI
import AppKit
import QuartzCore
import Combine
import UniformTypeIdentifiers
import SwiftData

/// 悬浮球窗口管理器
@MainActor
class OrbWindowManager: ObservableObject {
    static let shared = OrbWindowManager()
    
    private var orbPanel: FloatingPanel?
    private var orbViewModel = OrbViewModel()
    
    // 悬浮球尺寸（50px = 30px球 + 10px*2边距，增大15%）
    private let orbSize: CGFloat = 30
    private let orbWindowSize: CGFloat = 50
    
    /// 当前角落位置
    @Published var currentCorner: ScreenCorner = .bottomRight
    
    private var modelContainer: ModelContainer?
    
    /// 初始化
    func setup(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        // 设置屏幕配置变化回调
        VisibleRegionManager.shared.onScreenConfigurationChanged = { [weak self] in
            HubLogger.log("🖥️ 屏幕配置变化，重新调整悬浮球位置")
            self?.snapToNearestCorner()
        }
        
        createOrbWindow()
    }
    
    /// 关闭悬浮球窗口
    func closeWindow() {
        // 清除回调
        VisibleRegionManager.shared.onScreenConfigurationChanged = nil
        
        orbPanel?.close()
        orbPanel = nil
        HubLogger.log("悬浮球窗口已关闭")
    }
    
    /// 创建悬浮球窗口
    private func createOrbWindow() {
        HubLogger.log("🟣 开始创建悬浮球窗口...")
        
        let settings = HubSettings()
        let rect = calculateOrbRect(for: settings)
        
        HubLogger.log("🟣 悬浮球窗口位置: \(rect)")
        
        orbPanel = FloatingPanel(contentRect: rect, backing: .buffered, defer: false)
        guard let panel = orbPanel else {
            HubLogger.log("🔴 悬浮球面板创建失败!")
            return
        }
        
        HubLogger.log("🟣 悬浮球面板已创建，frame: \(panel.frame)")
        
        // 悬浮球窗口层级更高
        panel.level = .mainMenu + 10
        
        // 使用 CATransaction 禁用隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let orbView = FloatingOrbButton(viewModel: orbViewModel)
        let hostingView = HubHostingView(rootView: orbView)
        hostingView.frame = NSRect(origin: .zero, size: rect.size)
        panel.contentView = hostingView
        
        CATransaction.commit()
        
        panel.makeKeyAndOrderFront(nil)
        
        HubLogger.log("🟢 悬浮球窗口已显示，当前 frame: \(panel.frame), isVisible: \(panel.isVisible)")
        
        // 监听显示/隐藏 Hub 窗口通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHubWindow),
            name: .hubOrbTapped,
            object: nil
        )
        
        // 监听悬停展开通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHubWindow),
            name: .hubOrbHoverExpand,
            object: nil
        )
        
        // 监听 Hub 窗口状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHubStateChanged(_:)),
            name: .hubWindowStateChanged,
            object: nil
        )
        
        // 监听拖拽通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDragUpdate),
            name: .orbDragUpdated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDragEnd),
            name: .orbDragEnded,
            object: nil
        )
    }
    
    @objc private func handleDragUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let x = userInfo["x"] as? CGFloat,
              let y = userInfo["y"] as? CGFloat else { return }
        
        updatePosition(x: x, y: y)
    }
    
    @objc private func handleDragEnd() {
        snapToNearestCorner()
    }
    
    @objc private func handleHubStateChanged(_ notification: Notification) {
        guard let isExpanded = notification.userInfo?["isExpanded"] as? Bool else { return }
        orbViewModel.isExpanded = isExpanded
    }
    

    
    /// 计算悬浮球窗口位置
    private func calculateOrbRect(for settings: HubSettings) -> NSRect {
        // 刷新可见区域
        VisibleRegionManager.shared.refresh()
        
        var x = settings.floatingX
        var y = settings.floatingY
        let rect = NSRect(x: x, y: y, width: orbWindowSize, height: orbWindowSize)
        
        // 检查球体是否大部分在可见区域内
        let isValidPosition = VisibleRegionManager.shared.mostlyContains(rect, threshold: 0.8)
        
        if (x == 0 && y == 0) || !isValidPosition {
            // 首次启动或位置无效，使用默认位置
            // 找到主屏幕的可见区域
            if let mainScreen = ScreenManager.shared.getMainScreen() {
                let visibleFrame = mainScreen.visibleFrame
                x = visibleFrame.maxX - orbWindowSize - 12
                y = visibleFrame.minY + 12
            } else {
                // 兜底：使用可见区域管理器的第一个区域
                let defaultRect = NSRect(x: 100, y: 100, width: orbWindowSize, height: orbWindowSize)
                let clampedOrigin = VisibleRegionManager.shared.clampRectToVisibleRegion(defaultRect)
                x = clampedOrigin.x
                y = clampedOrigin.y
            }

            // 保存默认位置
            var s = settings
            s.floatingX = x
            s.floatingY = y
            s.save()
            
            HubLogger.log("🔄 悬浮球位置重置到屏幕内: (\(x), \(y))")
        }

        // 计算当前角落
        if let screen = findScreenContaining(point: NSPoint(x: x, y: y)) {
            updateCurrentCorner(x: x, y: y, screen: screen)
        }

        return NSRect(x: x, y: y, width: orbWindowSize, height: orbWindowSize)
    }
    
    /// 更新当前角落
    private func updateCurrentCorner(x: CGFloat, y: CGFloat, screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        let centerX = x + orbWindowSize / 2
        let centerY = y + orbWindowSize / 2
        let midX = visibleFrame.midX
        let midY = visibleFrame.midY

        if centerX < midX && centerY > midY {
            currentCorner = .topLeft
        } else if centerX >= midX && centerY > midY {
            currentCorner = .topRight
        } else if centerX < midX && centerY <= midY {
            currentCorner = .bottomLeft
        } else {
            currentCorner = .bottomRight
        }
    }
    
    /// 更新悬浮球位置（拖拽时）
    func updatePosition(x: CGFloat, y: CGFloat) {
        guard let panel = orbPanel else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        CATransaction.commit()
        
        // 更新角落状态
        if let screen = ScreenManager.shared.getMainScreen() {
            updateCurrentCorner(x: x, y: y, screen: screen)
        }
    }
    
    /// 检查并调整悬浮球位置：确保球体完整在可见区域内
    /// 使用 VisibleRegionManager 统一处理多屏幕、Dock、菜单栏
    func snapToNearestCorner() {
        guard let panel = orbPanel else { return }
        
        // 刷新可见区域（屏幕配置可能已变化）
        VisibleRegionManager.shared.refresh()
        
        let currentRect = panel.frame
        let currentOrigin = currentRect.origin
        
        HubLogger.log("═══════════════════════════════════════")
        HubLogger.log("📍 悬浮球位置检查")
        HubLogger.log("  当前位置: (\(currentOrigin.x), \(currentOrigin.y))")
        
        // 检查球体是否大部分在可见区域内
        let isMostlyVisible = VisibleRegionManager.shared.mostlyContains(currentRect, threshold: 0.8)
        
        if isMostlyVisible {
            // 球体大部分在可见区域内，无需调整
            var settings = HubSettings()
            settings.floatingX = currentOrigin.x
            settings.floatingY = currentOrigin.y
            settings.save()
            HubLogger.log("✅ 悬浮球在可见区域内，无需调整")
        } else {
            // 球体不在可见区域内或可见部分不足 80%，需要调整
            let targetOrigin = VisibleRegionManager.shared.clampRectToVisibleRegion(currentRect)
            let targetFrame = NSRect(origin: targetOrigin, size: currentRect.size)
            
            // 执行动画移动
            panel.setFrame(targetFrame, display: true, animate: true)
            
            // 保存位置
            var settings = HubSettings()
            settings.floatingX = targetOrigin.x
            settings.floatingY = targetOrigin.y
            settings.save()
            
            // 更新角落状态
            if let screen = findScreenContaining(point: targetOrigin) {
                updateCurrentCorner(x: targetOrigin.x, y: targetOrigin.y, screen: screen)
            }
            
            HubLogger.log("🎯 悬浮球调整到可见区域: (\(currentOrigin.x), \(currentOrigin.y)) -> (\(targetOrigin.x), \(targetOrigin.y))")
        }
        HubLogger.log("═══════════════════════════════════════")
    }
    
    /// 找到包含指定点的屏幕
    private func findScreenContaining(point: NSPoint) -> NSScreen? {
        let allScreens = ScreenManager.shared.screenDetector.getAllScreens()
        for screen in allScreens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return allScreens.first
    }
    
    /// 显示 Hub 窗口
    @objc func showHubWindow() {
        HubLogger.log("🟣 OrbWindowManager.showHubWindow() 被调用")
        orbViewModel.isExpanded = true
        HubWindowManager.shared.show(
            from: currentCorner,
            orbFrame: orbPanel?.frame ?? .zero,
            modelContainer: modelContainer
        )
    }
    
    /// 获取当前窗口 frame
    var frame: NSRect {
        orbPanel?.frame ?? .zero
    }
}

/// 悬浮球专用 ViewModel
@MainActor
class OrbViewModel: ObservableObject {
    @Published var isDragging = false
    @Published var isHovering = false
    @Published var isExpanded = false  // 展开状态，用于图标切换
    @Published var isDropTarget = false  // 拖拽悬停状态
}

/// 拖拽检测状态管理类
private class DragDetectionState {
    var mouseDownMonitor: Any?
    var mouseDraggedMonitor: Any?
    var mouseUpMonitor: Any?
    var pasteboardChangeCount: Int = -1
    var isDragging: Bool = false
    var isContentDragging: Bool = false
    let dragPasteboard = NSPasteboard(name: .drag)
}

/// 悬浮球按钮视图 - 液态玻璃风格
struct FloatingOrbButton: View {
    @ObservedObject var viewModel: OrbViewModel
    @State private var lastMouseLocation: NSPoint?
    @State private var dragState = DragDetectionState()
    
    // 悬浮球尺寸（再增大10%）
    private let orbSize: CGFloat = 36
    private let windowSize: CGFloat = 61  // 36 + 12.5*2 ≈ 61
    
    /// 开始检测文件拖拽
    private func startDragDetection() {
        stopDragDetection()
        
        HubLogger.log("🟣 开始监听文件拖拽（全局鼠标事件）")
        
        // 鼠标按下 - 记录粘贴板状态
        dragState.mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [dragState] _ in
            dragState.pasteboardChangeCount = dragState.dragPasteboard.changeCount
            dragState.isDragging = true
            dragState.isContentDragging = false
            HubLogger.log("🟣 鼠标按下，准备检测拖拽")
        }
        
        // 鼠标移动 - 检测是否开始拖拽文件
        dragState.mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak viewModel, dragState] event in
            guard dragState.isDragging else { return }
            
            // 检测粘贴板变化，确认是内容拖拽
            if !dragState.isContentDragging && dragState.dragPasteboard.changeCount != dragState.pasteboardChangeCount {
                let hasFileURL = dragState.dragPasteboard.types?.contains(.fileURL) == true
                if hasFileURL {
                    dragState.isContentDragging = true
                    HubLogger.log("🟣 检测到文件拖拽，自动展开 Hub")
                    
                    DispatchQueue.main.async {
                        if let viewModel = viewModel, !viewModel.isExpanded {
                            viewModel.isExpanded = true
                            OrbWindowManager.shared.showHubWindow()
                            
                            // 通知 Hub 显示拖拽过渡效果
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: .hubShowDragOverlay,
                                    object: nil,
                                    userInfo: ["isDragging": true]
                                )
                            }
                        }
                    }
                }
            }
        }
        
        // 鼠标松开 - 拖拽结束
        dragState.mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [dragState] _ in
            if dragState.isContentDragging {
                HubLogger.log("🟣 文件拖拽结束")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .hubShowDragOverlay,
                        object: nil,
                        userInfo: ["isDragging": false]
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
        [dragState.mouseDownMonitor, dragState.mouseDraggedMonitor, dragState.mouseUpMonitor].forEach { monitor in
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        dragState.mouseDownMonitor = nil
        dragState.mouseDraggedMonitor = nil
        dragState.mouseUpMonitor = nil
        dragState.isDragging = false
        dragState.isContentDragging = false
    }
    
    var body: some View {
        ZStack {
            // 液态玻璃背景 - 多层材质叠加
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.08),
                            Color.cyan.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: orbSize, height: orbSize)
                .overlay(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                // 顶部液态高光
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .white.opacity(0.1), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: orbSize * 0.55)
                        .clipped(),
                    alignment: .top
                )
                // 底部折射效果
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .blue.opacity(0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                // 精致边框
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                // 双层阴影：外层柔和扩散 + 内层清晰投影
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                // 悬停动画
                .scaleEffect(viewModel.isHovering && !viewModel.isDragging ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.isHovering && !viewModel.isDragging)
            
            // 贴合 App 图标的堆叠图层设计
            ZStack {
                // 展开状态：关闭图标
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.95), .white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(viewModel.isExpanded ? 1 : 0)
                    .scaleEffect(viewModel.isExpanded ? 1 : 0.5)
                
                // 收起状态：堆叠图层图标（贴合 App 图标）
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.95), .cyan.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(viewModel.isExpanded ? 0 : 1)
                    .scaleEffect(viewModel.isExpanded ? 0.5 : 1)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.isExpanded)
        }
        .frame(width: windowSize, height: windowSize)
        .contentShape(Rectangle())
        .onAppear {
            // 延迟 2 秒后开始监听拖拽粘贴板，避免启动时误触发
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                HubLogger.log("🟣 延迟 2 秒后开始监听文件拖拽")
                startDragDetection()
            }
        }
        .onDisappear {
            // 停止监听
            stopDragDetection()
        }
        .onHover { hovering in
            viewModel.isHovering = hovering
            
            // 普通悬停时展开 Hub 窗口（非拖拽状态）
            if hovering && !viewModel.isDragging && !viewModel.isExpanded {
                HubLogger.log("🔵 鼠标悬停，准备展开 Hub")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if self.viewModel.isHovering && !self.viewModel.isDragging && !self.viewModel.isExpanded {
                        OrbWindowManager.shared.showHubWindow()
                    }
                }
            }
        }
        // 拖拽文件进入时展开 Hub 窗口
        .onDrop(of: [.fileURL, .url], isTargeted: $viewModel.isDropTarget) { providers in
            // 调试日志
            HubLogger.log("🔴 悬浮球接收到文件拖放，当前展开状态: \(self.viewModel.isExpanded)")
            
            // 重置悬停状态
            self.viewModel.isDropTarget = false
            
            // 如果 Hub 未展开，先展开并延迟传递文件
            if !self.viewModel.isExpanded {
                HubLogger.log("🔵 Hub 未展开，准备展开...")
                self.viewModel.isExpanded = true
                // 显示 Hub 窗口
                OrbWindowManager.shared.showHubWindow()
                // 延迟传递文件给 Hub 窗口
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    HubLogger.log("🟢 延迟传递文件给 Hub 窗口")
                    HubWindowManager.shared.handleDroppedFiles(providers)
                }
            } else {
                // Hub 已展开，直接传递文件
                HubLogger.log("🟡 Hub 已展开，直接传递文件")
                HubWindowManager.shared.handleDroppedFiles(providers)
            }
            return true
        }
        .onChange(of: viewModel.isDropTarget) { oldValue, newValue in
            if newValue && !viewModel.isExpanded {
                HubLogger.log("🟣 拖拽文件悬停在悬浮球上，展开 Hub")
                viewModel.isExpanded = true
                OrbWindowManager.shared.showHubWindow()
                // 通知 Hub 窗口显示拖拽过渡效果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: .hubShowDragOverlay,
                        object: nil,
                        userInfo: ["isDragging": true]
                    )
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    handleDragChanged()
                }
                .onEnded { _ in
                    handleDragEnd()
                }
        )
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleDragChanged() {
        // 首次拖拽
        if !viewModel.isDragging {
            viewModel.isDragging = true
            lastMouseLocation = NSEvent.mouseLocation
            
            // 关闭 Hub 窗口
            HubWindowManager.shared.hide()
            return
        }
        
        guard let lastMouse = lastMouseLocation else {
            lastMouseLocation = NSEvent.mouseLocation
            return
        }
        
        // 获取当前鼠标位置（屏幕坐标）
        let currentMouse = NSEvent.mouseLocation
        
        // 计算增量
        let deltaX = currentMouse.x - lastMouse.x
        let deltaY = currentMouse.y - lastMouse.y
        
        // 更新最后位置
        lastMouseLocation = currentMouse
        
        // 获取当前窗口位置
        let currentFrame = OrbWindowManager.shared.frame
        
        // 新位置 = 当前位置 + 增量
        let newX = currentFrame.origin.x + deltaX
        let newY = currentFrame.origin.y + deltaY
        
        // 发送位置更新
        NotificationCenter.default.post(
            name: .orbDragUpdated,
            object: nil,
            userInfo: ["x": newX, "y": newY]
        )
    }
    
    private func handleDragEnd() {
        guard viewModel.isDragging else { return }
        viewModel.isDragging = false
        lastMouseLocation = nil
        
        // 发送拖拽结束通知
        NotificationCenter.default.post(name: .orbDragEnded, object: nil)
        
        // 吸附到最近角落（带反弹效果）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            OrbWindowManager.shared.snapToNearestCorner()
        }
    }
    
    private func handleTap() {
        guard !viewModel.isDragging else { return }
        NotificationCenter.default.post(name: .hubOrbTapped, object: nil)
    }
}

// MARK: - 扩展通知

extension Notification.Name {
    static let orbDragStarted = Notification.Name("orbDragStarted")
    static let orbDragEnded = Notification.Name("orbDragEnded")
    static let orbDragUpdated = Notification.Name("orbDragUpdated")
    static let orbPositionChanged = Notification.Name("orbPositionChanged")
    static let hubOrbHoverExpand = Notification.Name("hubOrbHoverExpand")
    static let hubWindowStateChanged = Notification.Name("hubWindowStateChanged")
    static let hubFilesDropped = Notification.Name("hubFilesDropped")
    static let hubProcessDroppedFiles = Notification.Name("hubProcessDroppedFiles")
}
