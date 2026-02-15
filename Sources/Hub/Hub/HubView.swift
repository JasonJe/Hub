//
//  HubView.swift
//  Hub
//
//  Hub 主视图 - 参考 boring.notch 实现
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Animation Constants

/// 动画参数常量
private enum AnimationConstants {
    /// Hub 展开动画 - Liquid Glass 风格 spring 参数
    /// 更柔和、流畅的液体流动感
    static let openAnimationResponse: Double = 0.5
    static let openAnimationDamping: Double = 0.75
    static let openAnimationBlendDuration: Double = 0
    
    /// Hub 收起动画 - Liquid Glass 风格 spring 参数
    static let closeAnimationResponse: Double = 0.4
    static let closeAnimationDamping: Double = 0.85
    static let closeAnimationBlendDuration: Double = 0
    
    /// 拖拽状态过渡动画时长
    static let dragTransitionDuration: Double = 0.25
    
    /// 拖拽成功动画 - spring 参数
    static let dropSuccessResponse: Double = 0.35
    static let dropSuccessDamping: Double = 0.7
    
    /// 拖拽成功状态保持时长（秒）
    static let dropSuccessHoldDuration: Double = 1.5
    
    /// 拖拽成功后延迟收起时长（秒）
    static let dropSuccessCloseDelay: Double = 1.0
    
    /// 拖拽失败时重置状态延迟（秒）
    static let dragFailureResetDelay: Double = 1.0
    
    /// 悬停效果动画时长 - Liquid Glass 风格
    static let hoverEffectDuration: Double = 0.3
}

// MARK: - Layout Constants

/// 布局参数常量
private enum LayoutConstants {
    /// Hub 外边距
    static let hubBottomPadding: CGFloat = 8
    static let hubHorizontalPadding: CGFloat = 12
    static let hubVerticalPadding: CGFloat = 12
    
    /// Idle 内容区域内边距
    static let idleContentPadding: CGFloat = 20
    
    /// 拖拽提示层内边距
    static let dragOverlayTopPadding: CGFloat = 24
    static let dragOverlayHorizontalPadding: CGFloat = 12
    static let dragOverlayBottomPadding: CGFloat = 12
    
    /// 视图元素间距
    static let contentSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 4
    
    /// 拖拽提示图标尺寸
    static let dragIconCircleSize: CGFloat = 70
    static let dragIconInnerCircleSize: CGFloat = 48
    static let dragIconBorderWidth: CGFloat = 2
    static let dragIconBlurRadius: CGFloat = 8
    static let dragIconArrowSize: CGFloat = 20
    
    /// 拖拽成功图标尺寸
    static let successIconCircleSize: CGFloat = 70
    static let successIconCheckmarkSize: CGFloat = 28
    
    /// 文字大小
    static let primaryTextSize: CGFloat = 16
    static let secondaryTextSize: CGFloat = 10
    static let letterSpacing: CGFloat = 1
}

/// Hub 主视图
/// 管理 Hub 的展开/收起状态、拖放处理和内容显示
struct HubView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StashedItem.dateAdded, order: .reverse) private var items: [StashedItem]
    
    // MARK: - State
    
    @StateObject private var vm = HubViewModel()
    @State private var isHovering = false
    @State private var showHoverEffect = false
    @State private var isDragging = false
    @State private var dropSuccess = false
    @State private var pulseOpacity: CGFloat = 0.3
    
    /// 首次使用引导状态
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false
    
    /// 获取首次引导状态
    private var shouldShowOnboarding: Bool {
        let settings = HubSettings()
        return !settings.hasCompletedOnboarding
    }
    
    // MARK: - Computed Properties
    
    /// 顶部圆角半径
    private var topCornerRadius: CGFloat {
        (vm.hubState == .open) ? cornerRadiusInsets.opened.top : cornerRadiusInsets.closed.top
    }
    
    /// 底部圆角半径
    private var bottomCornerRadius: CGFloat {
        (vm.hubState == .open) ? cornerRadiusInsets.opened.bottom : cornerRadiusInsets.closed.bottom
    }
    
    /// 当前 Notch 形状
    private var currentHubShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }
    
    /// chin 高度（菜单栏与刘海高度的差值）
    private var chinHeight: CGFloat {
        let menuBarHeight = (NSScreen.main?.frame.maxY ?? 0) - (NSScreen.main?.visibleFrame.maxY ?? 0)
        let currentHeight = vm.closedHubSize.height
        if currentHeight == 0 { return 0 }
        return max(0, menuBarHeight - currentHeight)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // 拖放接收层 - 始终存在，透明的 Color.clear 作为拖放目标
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL, .url], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            
            // 主内容（非拖拽状态）
            VStack(spacing: 0) {
                // 主内容布局
                            hubLayout
                                    .frame(alignment: .top)
                                    .padding(.horizontal, vm.hubState == .open ? LayoutConstants.hubHorizontalPadding : 0)
                                    .padding(.bottom, vm.hubState == .open ? LayoutConstants.hubVerticalPadding : 0)
                                    // macOS 26 Liquid Glass - 极致透明玻璃效果
                                    .background(
                                        ZStack {
                                            // 核心：超透明材质模糊
                                            currentHubShape
                                                .fill(.ultraThinMaterial)
                                            
                                            // 玻璃光泽层：轻柔顶部高光
                                            currentHubShape
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            .white.opacity(0.25),
                                                            .white.opacity(0.1),
                                                            .white.opacity(0.03),
                                                            .clear
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: UnitPoint(x: 0.5, y: 0.6)
                                                    )
                                                )
                                        }
                                    )
                                    .clipShape(currentHubShape)
                                    // 玻璃边框：明亮高光边框
                                    .overlay(
                                        currentHubShape
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        .white.opacity(0.5),
                                                        .white.opacity(0.25),
                                                        .white.opacity(0.1),
                                                        .white.opacity(0.02)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .frame(height: vm.hubState == .open ? vm.hubSize.height : nil)
                                    // 使用 spring 动画
                                    .animation(vm.hubState == .open ?
                                        Animation.spring(response: AnimationConstants.openAnimationResponse,
                                                        dampingFraction: AnimationConstants.openAnimationDamping,
                                                        blendDuration: AnimationConstants.openAnimationBlendDuration) :
                                        Animation.spring(response: AnimationConstants.closeAnimationResponse,
                                                        dampingFraction: AnimationConstants.closeAnimationDamping,
                                                        blendDuration: AnimationConstants.closeAnimationBlendDuration),
                                        value: vm.hubState
                                    )                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        if vm.hubState == .closed {
                            vm.open()
                        }
                    }

                // chin 区域
                if chinHeight > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: vm.closedHubSize.width, height: chinHeight)
                }
            }
            // 拖拽状态下的过渡动画
            .opacity(isDragging ? 0 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
            
            // 拖拽提示层（拖拽状态）
            if isDragging {
                dragOverlayView
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: windowSize.width, maxHeight: windowSize.height, alignment: .top)
        .padding(.bottom, LayoutConstants.hubBottomPadding)
        // 首次使用引导
        .overlay {
            if showOnboarding {
                OnboardingView {
                    completeOnboarding()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            checkAndShowOnboarding()
        }
        // 监听应用激活，重新检查引导状态
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkAndShowOnboarding()
        }
        // ESC 键关闭
        .onExitCommand {
            if vm.hubState == .open {
                vm.close()
            }
        }
        // 点击外部关闭
        .onReceive(NotificationCenter.default.publisher(for: .hubClickOutside)) { _ in
            if vm.hubState == .open {
                vm.close()
            }
        }
        // 监听拖拽状态，拖拽进入时展开
        .onChange(of: isDragging) { newValue in
            if newValue && vm.hubState == .closed {
                vm.open()
            }
        }
        // 监听 DragDetector 的拖拽进入通知
        .onReceive(NotificationCenter.default.publisher(for: .hubDragEntered)) { _ in
            if vm.hubState == .closed {
                vm.open()
            }
            isDragging = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .hubDragExited)) { _ in
            isDragging = false
            // 延迟检查，确保数据已更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkAndCloseIfEmpty()
            }
        }
    }
    
    // MARK: - Layout
    
    /// 主内容布局
        @ViewBuilder
        private var hubLayout: some View {
            VStack(alignment: .leading, spacing: 0) {
                if vm.hubState == .open {
                    // 展开状态内容 - 使用 ZStack 实现页面切换动画
                    ZStack {
                        // 暂存内容视图
                        StashedContentView(items: items, onOpenSettings: {
                            vm.openSettings()
                        })
                        .padding(.top, max(24, vm.closedHubSize.height))
                        .opacity(vm.showSettings ? 0 : 1)
                        .offset(x: vm.showSettings ? -30 : 0)
    
                        // 设置视图
                        SettingsContentView(onClose: {
                            vm.closeSettings()
                        })
                        .padding(.top, max(24, vm.closedHubSize.height))
                        .opacity(vm.showSettings ? 1 : 0)
                        .offset(x: vm.showSettings ? 0 : 30)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showSettings)
                    .frame(height: vm.hubSize.height)
                } else {
                    // 闭合状态内容
                    IdleContentView(itemCount: items.count)
                        .frame(width: vm.closedHubSize.width - 20,
                               height: vm.closedHubSize.height)
                }
            }
        }    
    /// 拖拽提示视图 - 仅在拖拽时显示
    @ViewBuilder
    private var dragOverlayView: some View {
        VStack(spacing: LayoutConstants.contentSpacing) {
            Spacer()
            
            if dropSuccess {
                // 成功状态
                successView
            } else {
                // 拖拽中状态
                draggingView
            }
            
            Spacer()
        }
        .padding(.top, max(LayoutConstants.dragOverlayTopPadding, vm.closedHubSize.height))
        .padding(.horizontal, LayoutConstants.dragOverlayHorizontalPadding)
        .padding(.bottom, LayoutConstants.dragOverlayBottomPadding)
        .frame(width: vm.hubSize.width, height: vm.hubSize.height)
        // macOS 26 Liquid Glass - 极致透明玻璃效果
        .background(
            ZStack {
                // 核心：超透明材质模糊
                currentHubShape
                    .fill(.ultraThinMaterial)
                
                // 玻璃光泽层：轻柔顶部高光
                currentHubShape
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.1),
                                .white.opacity(0.03),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.6)
                        )
                    )
            }
        )
        .clipShape(currentHubShape)
        // 边框光泽 + 脉冲效果
        .overlay {
            if dropSuccess {
                // 成功状态 - 绿色边框
                ZStack {
                    currentHubShape
                        .stroke(
                            LinearGradient(
                                colors: [.green.opacity(0.6), .green.opacity(0.4), .green.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                    currentHubShape
                        .stroke(Color.green.opacity(0.4), lineWidth: 4)
                        .blur(radius: 3)
                }
            } else {
                // 拖拽中状态 - 蓝色脉冲
                ZStack {
                    // 外层发光脉冲
                    currentHubShape
                        .stroke(
                            Color.blue.opacity(pulseOpacity * 0.7),
                            lineWidth: 4
                        )
                        .blur(radius: 3)
                    
                    // 内层边框
                    currentHubShape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(pulseOpacity * 0.8),
                                    .blue.opacity(pulseOpacity * 0.5),
                                    .blue.opacity(pulseOpacity * 0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                }
            }
        }
        // 边框脉冲动画
        .onAppear {
            if !dropSuccess {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.9
                }
            }
        }
        .onDisappear {
            pulseOpacity = 0.3
        }
    }
    
    /// 拖拽成功视图 - Liquid Glass 风格
    private var successView: some View {
        VStack(spacing: LayoutConstants.contentSpacing) {
            ZStack {
                // 玻璃片背景
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: LayoutConstants.successIconCircleSize, height: LayoutConstants.successIconCircleSize)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    // 顶部液态高光
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                            .frame(width: LayoutConstants.successIconCircleSize, height: LayoutConstants.successIconCircleSize / 2)
                            .clipped()
                    }
                
                // 成功图标
                Image(systemName: "checkmark")
                    .font(.system(size: LayoutConstants.successIconCheckmarkSize, weight: .bold))
                    .foregroundStyle(Color.green)
            }
            
            VStack(spacing: LayoutConstants.textSpacing) {
                Text("已暂存")
                    .font(.system(size: LayoutConstants.primaryTextSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("File stashed")
                    .font(.system(size: LayoutConstants.secondaryTextSize))
                    .foregroundColor(.secondary)
                    .tracking(LayoutConstants.letterSpacing)
            }
        }
    }
    
    /// 拖拽中视图 - Liquid Glass 风格
    private var draggingView: some View {
        VStack(spacing: LayoutConstants.contentSpacing) {
            ZStack {
                // 玻璃片背景
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: LayoutConstants.dragIconCircleSize, height: LayoutConstants.dragIconCircleSize)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    // 顶部液态高光
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                            .frame(width: LayoutConstants.dragIconCircleSize, height: LayoutConstants.dragIconCircleSize / 2)
                            .clipped()
                    }
                
                // 外层脉冲光晕
                Circle()
                    .stroke(
                        Color.blue.opacity(pulseOpacity * 0.6),
                        lineWidth: 3
                    )
                    .frame(width: LayoutConstants.dragIconCircleSize + 8, height: LayoutConstants.dragIconCircleSize + 8)
                    .blur(radius: 2)
                
                // 内层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(pulseOpacity * 0.4),
                                Color.blue.opacity(pulseOpacity * 0.2),
                                Color.blue.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: LayoutConstants.dragIconInnerCircleSize / 2
                        )
                    )
                    .frame(width: LayoutConstants.dragIconInnerCircleSize, height: LayoutConstants.dragIconInnerCircleSize)
                
                // 箭头
                Image(systemName: "arrow.down")
                    .font(.system(size: LayoutConstants.dragIconArrowSize, weight: .bold))
                    .foregroundStyle(Color.blue)
            }
            
            VStack(spacing: LayoutConstants.textSpacing) {
                Text("松手暂存")
                    .font(.system(size: LayoutConstants.primaryTextSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Drop to stash")
                    .font(.system(size: LayoutConstants.secondaryTextSize))
                    .foregroundColor(.secondary)
                    .tracking(LayoutConstants.letterSpacing)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    /// 处理悬停事件
    private func handleHover(_ hovering: Bool) {
        isHovering = hovering
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showHoverEffect = hovering
        }
        // 鼠标悬停时自动展开
        if hovering && vm.hubState == .closed {
            vm.open()
        }
        // 鼠标离开时自动收起（只有在没有拖拽操作时）
        if !hovering && vm.hubState == .open && items.isEmpty {
            vm.close()
        }
    }
    
    /// 处理拖放
    private func handleDrop(providers: [NSItemProvider]) {
        HubLogger.drag("handleDrop called with \(providers.count) providers")
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            HubLogger.error("Load item error", error: error)
                            return
                        }
                        
                        var fileURL: URL?
                        
                        if let url = item as? URL {
                            fileURL = url
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            fileURL = url
                        }
                        
                        if let url = fileURL {
                            HubLogger.drag("Adding file: \(url.lastPathComponent)")
                            self.addItem(name: url.lastPathComponent, path: url.path)
                            
                            // 显示成功动画
                            withAnimation(.spring(response: AnimationConstants.dropSuccessResponse,
                                             dampingFraction: AnimationConstants.dropSuccessDamping)) {
                                self.dropSuccess = true
                            }

                            // 捕获当前状态快照，避免竞态问题
                            let wasHovering = self.isHovering

                            // 延迟重置成功状态并保持展开
                            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.dropSuccessHoldDuration) {
                                withAnimation(.spring(response: AnimationConstants.dropSuccessResponse,
                                                 dampingFraction: AnimationConstants.dropSuccessDamping)) {
                                    self.dropSuccess = false
                                    self.isDragging = false
                                }

                                // 再停留一会后收起（使用捕获的状态快照判断）
                                // 注意：如果成功添加了文件，items 不为空，不会收起
                                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.dropSuccessCloseDelay) {
                                    // 使用 onChange 监听来处理收起逻辑，而不是直接访问 items
                                    // 这里只在不悬停时触发检查
                                    if !self.isHovering {
                                        self.checkAndCloseIfEmpty()
                                    }
                                }
                            }
                        } else {
                            HubLogger.drag("Could not extract URL from item: \(String(describing: item))")
                            self.isDragging = false
                        }
                    }
                }
            }
        }
        
        // 如果没有成功添加任何文件，重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.dragFailureResetDelay) {
            if !self.dropSuccess {
                self.isDragging = false
            }
        }
    }
    
    /// 添加文件项
    private func addItem(name: String, path: String) {
        // 检查重复
        let descriptor = FetchDescriptor<StashedItem>(
            predicate: #Predicate { $0.originalPath == path }
        )
        
        do {
            let existingItems = try modelContext.fetch(descriptor)
            if !existingItems.isEmpty { return }
        } catch {
            HubLogger.error("Error checking for duplicates", error: error)
        }
        
        let type = StashedItem.inferFileType(from: name)
        let newItem = StashedItem(name: name, fileType: type, originalPath: path)
        modelContext.insert(newItem)
    }

    /// 完成首次引导
    private func completeOnboarding() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showOnboarding = false
        }
        
        // 标记引导已完成
        var settings = HubSettings()
        settings.hasCompletedOnboarding = true
        hasCheckedOnboarding = true
        
        // 立即展开 Hub
        vm.open()
    }

    /// 检查并显示首次引导
    private func checkAndShowOnboarding() {
        // 已检查过或已显示，不再重复
        guard !hasCheckedOnboarding && !showOnboarding else { return }
        
        if shouldShowOnboarding {
            hasCheckedOnboarding = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    showOnboarding = true
                }
            }
        }
    }

    /// 检查是否需要收起 Hub（当暂存区为空且不悬停时）
    private func checkAndCloseIfEmpty() {
        if items.isEmpty && !isHovering && vm.hubState == .open {
            vm.close()
        }
    }
}
