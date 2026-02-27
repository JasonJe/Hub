//
//  HubWindowManager.swift
//  Hub
//
//  Hub 主窗口管理器 - 独立的 Hub 窗口
//

import SwiftUI
import AppKit
import QuartzCore
import Combine
import SwiftData
import UniformTypeIdentifiers

/// Hub 窗口管理器
@MainActor
class HubWindowManager: ObservableObject {
    static let shared = HubWindowManager()
    
    private var hubPanel: FloatingPanel?
    private let autoCloseManager = HubAutoCloseManager.shared
    
    // Hub 窗口尺寸 - 根据图标尺寸动态计算
    // 4列图标(52*4) + 3个间距(12*3) + 2个padding(16*2) = 208 + 36 + 32 = 276，取整为 280
    private let hubWidth: CGFloat = 280
    private let hubHeight: CGFloat = 320
    
    /// 显示 Hub 窗口
    func show(from corner: ScreenCorner, orbFrame: NSRect, modelContainer: ModelContainer?) {
        HubLogger.log("🟢 HubWindowManager.show() 被调用，corner: \(corner)")
        
        // 如果窗口已存在，则关闭
        if hubPanel != nil {
            HubLogger.log("🟡 Hub 窗口已存在，先关闭")
            hide()
            return
        }
        
        // 重置自动收起管理器
        autoCloseManager.reset()
        autoCloseManager.onClose = { [weak self] in
            self?.hide()
        }
        
        // 发送展开状态通知
        NotificationCenter.default.post(
            name: .hubWindowStateChanged,
            object: nil,
            userInfo: ["isExpanded": true]
        )
        
        // 计算 Hub 窗口位置
        let rect = calculateHubRect(from: corner, orbFrame: orbFrame)
        
        hubPanel = FloatingPanel(contentRect: rect, backing: .buffered, defer: false)
        guard let panel = hubPanel else { return }
        
        // Hub 窗口层级略低于悬浮球
        panel.level = .mainMenu + 5
        
        // 使用 CATransaction 禁用隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 创建 Hub 内容视图
        let hubContent = HubContentView(
            onClose: { [weak self] in
                self?.hide()
            },
            corner: corner
        )
        
        // 注入 modelContainer
        let wrappedContent: AnyView
        if let container = modelContainer {
            wrappedContent = AnyView(hubContent.modelContainer(container))
            HubLogger.log("✅ modelContainer 已注入到 HubContentView")
        } else {
            wrappedContent = AnyView(hubContent)
            HubLogger.log("⚠️ modelContainer 为 nil")
        }
        
        let hostingView = HubHostingView(rootView: wrappedContent)
        hostingView.frame = NSRect(origin: .zero, size: rect.size)
        
        panel.contentView = hostingView
        
        CATransaction.commit()
        
        // 显示窗口
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        
        // 展开动画完成后通知自动收起管理器
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.autoCloseManager.hubDidExpand()
                
                // 延迟设置鼠标回调
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
                guard let self = self, let hostingView = self.hubPanel?.contentView as? HubHostingView<AnyView> else { return }
                HubLogger.log("🖱️ 设置鼠标追踪回调")
                hostingView.onMouseEntered = {
                    Task { @MainActor in
                        self.autoCloseManager.mouseEnteredHub()
                    }
                }
                hostingView.onMouseExited = {
                    Task { @MainActor in
                        self.autoCloseManager.mouseExitedHub()
                    }
                }
                hostingView.updateTrackingAreas()
            }
        }
    }

    /// 隐藏 Hub 窗口
    func hide() {
        HubLogger.log("🔴 HubWindowManager.hide() 被调用")
        guard let panel = hubPanel else { return }
        
        autoCloseManager.hubDidClose()
        
        // 发送收起状态通知
        NotificationCenter.default.post(
            name: .hubWindowStateChanged,
            object: nil,
            userInfo: ["isExpanded": false]
        )
        
        // 收起动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            panel.close()
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.hubPanel = nil
            }
        }
    }

    /// 处理拖放的文件（公共方法，供悬浮球调用）
    func handleDroppedFiles(_ providers: [NSItemProvider]) {
        HubLogger.log("📦 handleDroppedFiles 被调用，providers 数量: \(providers.count)")
        // 发送通知给 HubContentView 处理文件
        NotificationCenter.default.post(
            name: .hubProcessDroppedFiles,
            object: nil,
            userInfo: ["providers": providers]
        )
    }
    
    /// 计算 Hub 窗口位置（悬浮球外接 Hub 的角落）
    private func calculateHubRect(from corner: ScreenCorner, orbFrame: NSRect) -> NSRect {
        // 找到悬浮球所在的屏幕（使用悬浮球中心点判断）
        guard let screen = findScreenForOrb(orbFrame: orbFrame) ?? ScreenManager.shared.getMainScreen() else {
            return NSRect(x: 100, y: 100, width: hubWidth, height: hubHeight)
        }
        
        let visibleFrame = screen.visibleFrame
        
        HubLogger.log("🔵 悬浮球 frame: \(orbFrame)")
        HubLogger.log("🔵 悬浮球中心: (\(orbFrame.midX), \(orbFrame.midY))")
        HubLogger.log("🔵 屏幕可见区域: \(visibleFrame)")
        
        // 悬浮球窗口中心位置
        let orbCenterX = orbFrame.midX
        let orbCenterY = orbFrame.midY
        
        // 悬浮球视觉半径（球体本身的半径）
        let orbVisualRadius: CGFloat = HubMetrics.orbVisualRadius  // 18
        // 间隙：悬浮球边缘到 Hub 边缘的距离
        let gap: CGFloat = 4
        
        var x: CGFloat
        var y: CGFloat
        
        // 根据传入的 corner 参数决定展开方向
        // 悬浮球在 Hub 的对应角落外侧，紧贴 Hub
        switch corner {
        case .topLeft:
            // 悬浮球在 Hub 左上角外侧
            // Hub 左边缘 = 悬浮球右边缘 + 间隙
            x = orbCenterX + orbVisualRadius + gap
            // Hub 上边缘 = 悬浮球下边缘 + 间隙
            y = orbCenterY - orbVisualRadius - gap - hubHeight
        case .topRight:
            // 悬浮球在 Hub 右上角外侧
            // Hub 右边缘 = 悬浮球左边缘 - 间隙
            x = orbCenterX - orbVisualRadius - gap - hubWidth
            // Hub 上边缘 = 悬浮球下边缘 + 间隙
            y = orbCenterY - orbVisualRadius - gap - hubHeight
        case .bottomLeft:
            // 悬浮球在 Hub 左下角外侧
            // Hub 左边缘 = 悬浮球右边缘 + 间隙
            x = orbCenterX + orbVisualRadius + gap
            // Hub 下边缘 = 悬浮球上边缘 - 间隙
            y = orbCenterY + orbVisualRadius + gap
        case .bottomRight:
            // 悬浮球在 Hub 右下角外侧
            // Hub 右边缘 = 悬浮球左边缘 - 间隙
            x = orbCenterX - orbVisualRadius - gap - hubWidth
            // Hub 下边缘 = 悬浮球上边缘 - 间隙
            y = orbCenterY + orbVisualRadius + gap
        }
        
        HubLogger.log("🔵 使用 corner: \(corner)")
        HubLogger.log("🔵 Hub 目标位置: (\(x), \(y))")
        
        // 确保不超出该屏幕的可见区域边界（留出边距）
        let clampedX = max(visibleFrame.minX + 10, min(x, visibleFrame.maxX - hubWidth - 10))
        let clampedY = max(visibleFrame.minY + 10, min(y, visibleFrame.maxY - hubHeight - 10))
        
        if clampedX != x || clampedY != y {
            HubLogger.log("⚠️ Hub 位置被边界调整: (\(x), \(y)) -> (\(clampedX), \(clampedY))")
        }
        
        HubLogger.log("📺 Hub 最终位置: (\(clampedX), \(clampedY))")
        
        return NSRect(x: clampedX, y: clampedY, width: hubWidth, height: hubHeight)
    }
    
    /// 找到包含指定点的屏幕（使用悬浮球中心点判断）
    private func findScreenContaining(point: NSPoint) -> NSScreen? {
        let allScreens = ScreenManager.shared.screenDetector.getAllScreens()
        
        // 使用悬浮球 frame 的中心点来判断所在屏幕
        for screen in allScreens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return nil
    }
    
    /// 找到悬浮球所在的屏幕
    private func findScreenForOrb(orbFrame: NSRect) -> NSScreen? {
        let allScreens = ScreenManager.shared.screenDetector.getAllScreens()
        
        // 使用悬浮球中心点来判断所在屏幕
        let center = NSPoint(x: orbFrame.midX, y: orbFrame.midY)
        HubLogger.log("🔍 查找悬浮球所在屏幕，中心点: \(center)")
        
        for (index, screen) in allScreens.enumerated() {
            let frame = screen.frame
            HubLogger.log("  屏幕[\(index)]: \(frame), 包含中心点: \(frame.contains(center))")
            if frame.contains(center) {
                return screen
            }
        }
        return allScreens.first
    }
    
    /// 更新位置（跟随悬浮球移动）
    func updatePosition(from corner: ScreenCorner, orbFrame: NSRect) {
        guard let panel = hubPanel else { return }
        
        let newRect = calculateHubRect(from: corner, orbFrame: orbFrame)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        panel.setFrame(newRect, display: true)
        CATransaction.commit()
    }
    
    /// 处理来自悬浮球的文件拖放
    @objc private func handleFilesFromOrb(_ notification: Notification) {
        guard let providers = notification.userInfo?["providers"] as? [NSItemProvider] else { return }
        // 转发给 HubContentView 处理
        NotificationCenter.default.post(
            name: .hubProcessDroppedFiles,
            object: nil,
            userInfo: ["providers": providers]
        )
    }
}

/// Hub 内容视图
struct HubContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StashedItem.dateAdded, order: .reverse) private var queryItems: [StashedItem]
    
    let onClose: () -> Void
    let corner: ScreenCorner
    
    @State private var items: [StashedItem] = []
    @State private var showSettings = false
    @State private var showConfirmation = false
    @State private var confirmationTitle = ""
    @State private var confirmationMessage = ""
    @State private var confirmationAction: (() -> Void)?
    
    // 鼠标悬停状态
    @State private var isHovering = false
    @State private var closeWorkItem: DispatchWorkItem?
    
    // 拖拽状态
    @State private var isDragging = false
    @State private var pulseOpacity: CGFloat = 0.3
    @State private var dragScale: CGFloat = 1.0
    @State private var dragOpacity: CGFloat = 1.0
    
    // 悬浮球区域大小
    private let orbAreaSize: CGFloat = 84
    
    // Shimmer 动画状态
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var isWindowVisible: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. 拖放接收区 (全透明)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL, .url], isTargeted: Binding(
                    get: { isDragging },
                    set: { newValue in
                        if isDragging != newValue {
                            HubLogger.log("🎯 isTargeted changed: \(isDragging) -> \(newValue)")
                            isDragging = newValue
                        }
                    }
                )) { providers in
                    HubLogger.log("🎯 onDrop handle: \(providers.count) providers")
                    self.handleDrop(providers: providers)
                    return true
                }
            
            // 2. 主内容层 - 与刘海模式结构完全一致
            ZStack(alignment: .top) {
                // 玻璃容器主体 - 液态玻璃效果应用在这一层
                hubContentView
                    .frame(width: 280, height: 320, alignment: .top)
                    .background(
                        // 使用 GeometryReader 确保背景填满
                        GeometryReader { geometry in
                            ZStack {
                                // 1. 内部深度：极淡的次表面色彩
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.05), Color.cyan.opacity(0.02)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // 2. 核心材质：极致通透
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                
                                // 3. 表面流光：使用 plusLighter 增强亮度
                                // 单独提取为子视图以确保动画独立
                                ShimmerLayer(shimmerOffset: shimmerOffset)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        ZStack {
                            // 4. 基础折射边框
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                            
                            // 5. 极锐利镜面高光
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: UnitPoint(x: 0.3, y: 0.3)
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                    )
                    .contentShape(Rectangle())
                    .scaleEffect(dragScale)
                    .opacity(dragOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // 3. 拖拽提示组件 - 在最上层显示
            if isDragging {
                FloatingHubDragOverlay(pulseOpacity: pulseOpacity)
                    .frame(width: 280, height: 320)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.85)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isDragging)
            }
        }
        .frame(width: 280, height: 320, alignment: .top)
        .onAppear {
            // 标记窗口可见
            isWindowVisible = true
            // 初始化 items
            self.items = queryItems
            // 重置拖拽状态
            dragScale = 1.0
            dragOpacity = 1.0
            HubLogger.log("📂 HubContentView onAppear, items.count = \(items.count)")
            
            // 直接启动 shimmer 动画
            shimmerOffset = -1.0
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
            
            // 启动安全收起计时器 - 如果鼠标从未进入 Hub，3秒后自动收起
            let safetyWorkItem = DispatchWorkItem { [onClose] in
                // 如果鼠标从未进入过（isHovering 仍为 false），则自动收起
                if !self.isHovering && !self.showConfirmation && !self.showSettings && !self.isDragging && self.items.isEmpty {
                    HubLogger.log("🖱️ 安全收起：鼠标从未进入 Hub")
                    HubLogger.log("🔴 调用 onClose()"); onClose()
                }
            }
            self.closeWorkItem = safetyWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: safetyWorkItem)
            
            // 监听来自悬浮球的文件拖放通知
            NotificationCenter.default.addObserver(
                forName: .hubProcessDroppedFiles,
                object: nil,
                queue: .main
            ) { notification in
                HubLogger.log("📥 HubContentView 接收到文件处理通知")
                if let providers = notification.userInfo?["providers"] as? [NSItemProvider] {
                    HubLogger.log("📄 处理 \(providers.count) 个文件")
                    self.handleDrop(providers: providers)
                    // 强制刷新 items
                    self.refreshItems()
                }
            }
            
            // 监听显示拖拽过渡效果通知
            NotificationCenter.default.addObserver(
                forName: .hubShowDragOverlay,
                object: nil,
                queue: .main
            ) { notification in
                HubLogger.log("🎯 HubContentView 接收到显示拖拽过渡效果通知")
                if let isDragging = notification.userInfo?["isDragging"] as? Bool {
                    self.isDragging = isDragging
                    
                    // 如果拖拽结束（isDragging = false）且鼠标从未进入 Hub，自动关闭
                    if !isDragging && !self.isHovering {
                        HubLogger.log("🖱️ 拖拽结束且鼠标未进入 Hub，准备自动收起")
                        let workItem = DispatchWorkItem { [onClose] in
                            HubLogger.log("🖱️ 拖拽取消，自动收起 Hub")
                            HubLogger.log("🔴 调用 onClose()"); onClose()
                        }
                        self.closeWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
                    }
                }
            }
            
            // 监听鼠标进入通知（来自 HubHostingView）
            NotificationCenter.default.addObserver(
                forName: .hubMouseEntered,
                object: nil,
                queue: .main
            ) { _ in
                HubLogger.log("🖱️ 收到 mouseEntered 通知"); self.handleHover(true)
            }
            
            // 监听鼠标离开通知（来自 HubHostingView）
            NotificationCenter.default.addObserver(
                forName: .hubMouseExited,
                object: nil,
                queue: .main
            ) { _ in
                HubLogger.log("🖱️ 收到 mouseExited 通知"); self.handleHover(false)
            }
        }
        .onChange(of: isWindowVisible) { _, isVisible in
            HubLogger.log("👁️ isWindowVisible changed: \(isVisible)")
        }
        .onChange(of: showSettings) { _, _ in
            // 使用显式动画处理设置页切换
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {}
        }
        .onChange(of: showConfirmation) { _, _ in
            // 使用显式动画处理确认对话框
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {}
        }
        .onChange(of: queryItems) { _, newItems in
            HubLogger.log("🔄 queryItems 变化，更新 items: \(newItems.count)")
            self.items = newItems
        }
        .onChange(of: isDragging) { oldValue, newValue in
            if oldValue != newValue {
                HubLogger.log("🎯 isDragging changed: \(oldValue) -> \(newValue)")
                handleDraggingChange(newValue)
                // 使用显式动画处理拖拽缩放和透明度效果
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    dragScale = newValue ? 0.98 : 1.0
                    dragOpacity = newValue ? 0 : 1
                }
            }
        }
    }
    
    /// 处理鼠标悬停 - 鼠标移出时自动收起
    private func handleHover(_ hovering: Bool) {
        HubLogger.log("🖱️ HubContentView onHover: \(hovering), showSettings: \(showSettings), showConfirmation: \(showConfirmation), isDragging: \(isDragging), items.count: \(items.count)")
        isHovering = hovering
        
        if hovering {
            // 鼠标进入，取消之前的收起操作
            closeWorkItem?.cancel()
            closeWorkItem = nil
            HubLogger.log("🖱️ 鼠标进入，取消收起")
        } else {
            // 鼠标移出 - 延迟后自动收起
            HubLogger.log("🖱️ 鼠标移出，准备 0.5s 后自动收起")
            let workItem = DispatchWorkItem { [onClose] in
                HubLogger.log("🖱️ 执行自动收起 Hub")
                HubLogger.log("🔴 调用 onClose()"); onClose()
            }
            closeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    
    /// 处理拖拽状态变化
    private func handleDraggingChange(_ dragging: Bool) {
        HubLogger.log("🎯 handleDraggingChange: \(dragging)")
        if dragging {
            pulseOpacity = 0.2
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.9
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                pulseOpacity = 0.3
            }
        }
    }
    
    /// Shimmer 流光层 - 独立子视图确保动画正确运行
    private struct ShimmerLayer: View {
        let shimmerOffset: CGFloat
        
        var body: some View {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                    )
                )
                .blendMode(.plusLighter)
        }
    }
    
    /// Hub 内容视图 - 与刘海模式的 hubLayoutContent 对应
    private var hubContentView: some View {
        ZStack {
            // 主内容
            mainContent
                .opacity(showSettings || showConfirmation ? 0 : 1)
                .offset(x: showSettings ? -30 : 0)
            
            // 设置页面
            SettingsContentView(onClose: { showSettings = false })
                .padding(.top, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(showSettings && !showConfirmation ? 1 : 0)
                .offset(x: showSettings ? 0 : 30)
            
            // 确认对话框
            if showConfirmation {
                ConfirmationView(
                    title: confirmationTitle,
                    message: confirmationMessage,
                    confirmTitle: confirmationTitle.contains("清空") ? "清空" : "退出",
                    onConfirm: {
                        confirmationAction?()
                        dismissConfirmation()
                    },
                    onCancel: dismissConfirmation
                )
                .padding(.top, 24)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("暂存区")
                    .font(.system(size: 16, weight: .semibold))

                Text("\(items.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    )
                    .foregroundColor(.secondary)

                Spacer()

                if !items.isEmpty {
                    Button("清空") {
                        showConfirmationDialog(
                            title: "确认清空",
                            message: "将删除所有暂存的 \(items.count) 个项目，此操作不可恢复。",
                            action: {
                                for item in items {
                                    modelContext.delete(item)
                                }
                            }
                        )
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(.white.opacity(0.08))
                .padding(.horizontal, 16)

            // 内容区
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .background(.white.opacity(0.08))
                .padding(.horizontal, 16)

            // Footer
            HStack {
                Button("设置") {
                    showSettings = true
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)

                Spacer()

                Button("退出") {
                    showConfirmationDialog(
                        title: "确认退出",
                        message: "确定要退出 Hub 吗？",
                        action: {
                            NSApp.terminate(nil)
                        }
                    )
                }
                .font(.system(size: 12))
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onDrop(of: [.fileURL, .url], isTargeted: .constant(false)) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private var contentArea: some View {
        ZStack {
            if items.isEmpty {
                emptyState
                    .onAppear {
                        HubLogger.log("📂 contentArea: items.isEmpty = true, count = \(items.count)")
                    }
            } else {
                let iconSize = HubMetrics.floatingOrbItemSize
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(iconSize), spacing: 12),
                            GridItem(.fixed(iconSize), spacing: 12),
                            GridItem(.fixed(iconSize), spacing: 12),
                            GridItem(.fixed(iconSize), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(items) { item in
                            DraggableItemView(
                                item: item,
                                modelContext: modelContext,
                                iconSize: iconSize,
                                itemHeight: HubMetrics.floatingOrbItemHeight
                            )
                                .contextMenu {
                                    Button("删除") {
                                        withAnimation {
                                            modelContext.delete(item)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    HubLogger.log("📂 contentArea: 显示 Grid, items.count = \(items.count)")
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("暂存区为空")
                .font(.system(size: 13, weight: .medium))
            
            Text("拖放文件到这里")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private func showConfirmationDialog(title: String, message: String, action: @escaping () -> Void) {
        confirmationTitle = title
        confirmationMessage = message
        confirmationAction = action
        withAnimation(.easeOut(duration: 0.2)) {
            showConfirmation = true
        }
    }
    
    private func dismissConfirmation() {
        withAnimation(.easeIn(duration: 0.15)) {
            showConfirmation = false
        }
        confirmationAction = nil
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        HubLogger.log("🔧 handleDrop 开始处理，providers: \(providers.count)")
        for provider in providers {
            // 先尝试加载为文件 URL
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        HubLogger.log("✅ 成功加载文件 URL: \(url.lastPathComponent)")
                        self.addItem(from: url)
                    } else {
                        // 回退到普通 URL
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            guard let url = url, error == nil else { 
                                HubLogger.log("❌ 加载 URL 失败: \(error?.localizedDescription ?? "未知错误")")
                                return 
                            }
                            DispatchQueue.main.async {
                                HubLogger.log("✅ 成功加载 URL: \(url.lastPathComponent)")
                                self.addItem(from: url)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addItem(from url: URL) {
        HubLogger.log("💾 添加项目: \(url.lastPathComponent)")
        
        // 检查是否已存在相同路径的文件
        let path = url.path
        if items.contains(where: { $0.originalPath == path }) {
            HubLogger.log("⚠️ 文件已存在，跳过: \(url.lastPathComponent)")
            // 隐藏拖拽过渡效果，延迟后检查是否关闭
            isDragging = false
            scheduleAutoCloseAfterDrop()
            return
        }
        
        let item = StashedItem(
            name: url.lastPathComponent,
            fileType: StashedItem.inferFileType(from: url.lastPathComponent, path: url.path),
            originalPath: path
        )
        modelContext.insert(item)
        
        // 尝试保存上下文以触发 UI 更新
        do {
            try modelContext.save()
            HubLogger.log("✅ 项目已保存到模型上下文")
            // 立即刷新 items
            refreshItems()
            // 隐藏拖拽过渡效果
            isDragging = false
            // 延迟后检查是否关闭
            scheduleAutoCloseAfterDrop()
        } catch {
            HubLogger.log("❌ 保存失败: \(error)")
            // 隐藏拖拽过渡效果
            isDragging = false
            // 延迟后检查是否关闭
            scheduleAutoCloseAfterDrop()
        }
    }
    
    /// 拖放完成后延迟检查是否关闭
    private func scheduleAutoCloseAfterDrop() {
        // 取消之前的关闭操作
        closeWorkItem?.cancel()
        
        // 延迟 2.5 秒后检查是否关闭
        let workItem = DispatchWorkItem { [onClose, isHovering] in
            // 只有鼠标不在 Hub 内时才关闭
            if !isHovering {
                HubLogger.log("🖱️ 拖放完成延迟关闭：鼠标不在 Hub 内，关闭 Hub")
                onClose()
            } else {
                HubLogger.log("🖱️ 拖放完成延迟关闭：鼠标在 Hub 内，保持展开")
            }
        }
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }
    
    private func refreshItems() {
        // 手动刷新 items 数组
        let descriptor = FetchDescriptor<StashedItem>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        do {
            let newItems = try modelContext.fetch(descriptor)
            self.items = newItems
            HubLogger.log("🔄 Items 已刷新: \(newItems.count)")
        } catch {
            HubLogger.log("❌ 刷新失败: \(error)")
        }
    }
}

// MARK: - 悬浮球模式拖拽过渡效果

/// 悬浮球模式下的拖拽过渡效果视图
struct FloatingHubDragOverlay: View {
    let pulseOpacity: CGFloat
    
    var body: some View {
        ZStack {
            // 背景材质 - 更深的背景以确保可见
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .cyan.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            
            // 内容
            VStack(spacing: 20) {
                ZStack {
                    // 外发光环
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(pulseOpacity * 0.8),
                                    Color.cyan.opacity(pulseOpacity * 0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // 核心等离子球
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(pulseOpacity),
                                    Color.cyan.opacity(pulseOpacity * 0.6),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    // 动态扩散环
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(pulseOpacity), .blue.opacity(0.3)],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(pulseOpacity * 360))
                        .scaleEffect(0.8 + pulseOpacity * 0.3)
                    
                    // 基础图标容器
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.blue)
                }
                
                VStack(spacing: 6) {
                    Text("松手暂存")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Drop to stash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .tracking(1)
                }
            }
        }
    }
}