//
//  HubView.swift
//  Hub
//
//  Hub 主视图 - 优化重构版
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HubView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StashedItem.dateAdded, order: .reverse) private var items: [StashedItem]
    
    // MARK: - State
    @StateObject private var vm = HubViewModel()
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var dropSuccess = false
    @State private var isProcessingDrop = false // 新增：正在处理拖放锁
    @State private var pulseOpacity: CGFloat = 0.3
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false
    
    @State private var shimmerOffset: CGFloat = -1.0
    
    // MARK: - Computed Properties
    private var topCornerRadius: CGFloat {
        (vm.hubState == .open) ? HubMetrics.cornerRadiusInsets.opened.top : HubMetrics.cornerRadiusInsets.closed.top
    }
    
    private var bottomCornerRadius: CGFloat {
        (vm.hubState == .open) ? HubMetrics.cornerRadiusInsets.opened.bottom : HubMetrics.cornerRadiusInsets.closed.bottom
    }
    
    private var currentHubShape: NotchShape {
        NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
    }
    
    private var chinHeight: CGFloat {
        let menuBarHeight = (NSScreen.main?.frame.maxY ?? 0) - (NSScreen.main?.visibleFrame.maxY ?? 0)
        let currentHeight = vm.closedHubSize.height
        return currentHeight == 0 ? 0 : max(0, menuBarHeight - currentHeight)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. 拖放接收区 (全透明)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL, .url], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            
            // 2. 主内容层 - 使用固定宽度容器并强制中心对齐，确保对称形变
            ZStack(alignment: .top) {
                // 玻璃容器主体
                hubLayoutContent
                    .frame(width: vm.hubSize.width, height: vm.hubSize.height, alignment: .top)
                    .background(
                        ZStack {
                            // 1. 内部深度：极淡的次表面色彩
                            currentHubShape
                                .fill(LinearGradient(colors: [Color.blue.opacity(0.05), Color.cyan.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            // 2. 核心材质：极致通透
                            currentHubShape.fill(.ultraThinMaterial)
                            
                            // 3. 表面流光：使用 plusLighter 增强亮度
                            currentHubShape
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.12), .clear],
                                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                                    )
                                )
                                .blendMode(.plusLighter)
                                .onAppear {
                                    withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                                        shimmerOffset = 1.5
                                    }
                                }
                        }
                    )
                    .clipShape(currentHubShape)
                    .overlay(
                        ZStack {
                            // 4. 基础折射边框
                            currentHubShape.stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                            
                            // 5. 极锐利镜面高光 (Specular Highlight)
                            currentHubShape.stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: UnitPoint(x: 0.3, y: 0.3)
                                ),
                                lineWidth: 0.5
                            )
                        }
                    )
                    // 核心阴影系统
                    .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .animation(hubAnimation, value: vm.hubSize) // 关键：由尺寸变化驱动形状动画
                    .contentShape(Rectangle())
                    .onHover(perform: handleHover)
                    .onTapGesture { if vm.hubState == .closed { vm.open() } }

                // Chin 区域：独立层级，避免在垂直方向推挤玻璃体
                if vm.hubState == .closed && chinHeight > 0 {
                    Color.clear
                        .frame(width: vm.closedHubSize.width, height: chinHeight)
                        .offset(y: vm.closedHubSize.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 在 window 内部置顶并居中
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .opacity(isDragging ? 0 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isDragging)
            
            // 3. 拖拽提示组件
            if isDragging {
                HubDragOverlay(
                    dropSuccess: dropSuccess,
                    pulseOpacity: pulseOpacity,
                    hubState: vm.hubState,
                    closedHubHeight: vm.closedHubSize.height,
                    currentHubShape: currentHubShape
                )
                .padding(.horizontal, HubMetrics.sidePadding)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 1.02)),
                    removal: .opacity.combined(with: .scale(scale: 0.96))
                ))
            }
            
            // 4. 全局液态对话框层
            if vm.isShowingAlert, let dialogType = vm.activeDialog {
                renderDialog(for: dialogType)
            }
        }
        .frame(width: HubMetrics.windowSize.width, height: HubMetrics.windowSize.height, alignment: .top)
        .overlay { onboardingOverlay }
        .onAppear(perform: checkAndShowOnboarding)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in checkAndShowOnboarding() }
        .onExitCommand { if vm.hubState == .open { vm.close() } }
        .onReceive(NotificationCenter.default.publisher(for: .hubClickOutside)) { _ in 
            if vm.hubState == .open && !vm.isShowingAlert { 
                vm.close() 
            } 
        }
        .onChange(of: isDragging) { _, newValue in handleDraggingChange(newValue) }
        .onReceive(NotificationCenter.default.publisher(for: .hubDragEntered)) { _ in isDragging = true }
        .onReceive(NotificationCenter.default.publisher(for: .hubDragExited)) { _ in 
            isDragging = false
            // 如果正在处理拖放，不执行自动检查收起
            if !isProcessingDrop {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.checkAndCloseIfEmpty() }
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var hubLayoutContent: some View {
        VStack(alignment: .center, spacing: 0) {
            if vm.hubState == .open {
                ZStack {
                    StashedContentView(
                        items: items,
                        onOpenSettings: { vm.openSettings() },
                        isShowingAlert: $vm.isShowingAlert,
                        onShowDialog: { type, clearAction in vm.showDialog(type, clearAction: clearAction) }
                    )
                        .padding(.top, max(24, vm.closedHubSize.height))
                        .padding(.horizontal, HubMetrics.Layout.hubHorizontalPadding)
                        .opacity(vm.showSettings || vm.showConfirmation ? 0 : 1)
                        .offset(x: vm.showSettings ? -30 : 0)

                    SettingsContentView(onClose: { vm.closeSettings() })
                        .padding(.top, max(24, vm.closedHubSize.height))
                        .padding(.horizontal, HubMetrics.Layout.hubHorizontalPadding)
                        .opacity(vm.showSettings && !vm.showConfirmation ? 1 : 0)
                        .offset(x: vm.showSettings ? 0 : 30)

                    // 确认对话框
                    if vm.showConfirmation {
                        ConfirmationView(
                            title: vm.confirmationTitle,
                            message: vm.confirmationMessage,
                            confirmTitle: vm.confirmationTitle.contains("清空") ? "清空" : "退出",
                            onConfirm: {
                                vm.confirmationAction?()
                                vm.dismissDialog()
                            },
                            onCancel: { vm.dismissDialog() }
                        )
                        .padding(.top, max(24, vm.closedHubSize.height))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showSettings || vm.showConfirmation)
            } else {
                IdleContentView(itemCount: items.count)
                    .frame(width: vm.closedHubSize.width, height: vm.closedHubSize.height)
            }
        }
    }
    
    @ViewBuilder
    private var onboardingOverlay: some View {
        if showOnboarding {
            OnboardingView { completeOnboarding() }.transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Logic & Handlers
    
    private var hubAnimation: Animation {
        vm.hubState == .open ?
            .spring(response: HubMetrics.Animation.openResponse, dampingFraction: HubMetrics.Animation.openDamping) :
            .spring(response: HubMetrics.Animation.closeResponse, dampingFraction: HubMetrics.Animation.closeDamping)
    }
    
    private func handleHover(_ hovering: Bool) {
        isHovering = hovering
        if hovering && vm.hubState == .closed { vm.open() }
        if !hovering && vm.hubState == .open && !vm.isShowingAlert {
            // 延迟处理，给用户时间移回窗口
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.isHovering {
                    // 先关闭设置或确认弹窗（如果有）
                    if self.vm.showSettings {
                        self.vm.showSettings = false
                    }
                    if self.vm.showConfirmation {
                        self.vm.dismissDialog()
                    }
                    // 然后直接关闭 hub
                    self.vm.close()
                }
            }
        }
    }
    
    private func handleDraggingChange(_ dragging: Bool) {
        if dragging {
            if vm.hubState == .closed { vm.open() }
            pulseOpacity = 0.2
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { pulseOpacity = 0.9 }
        } else {
            withAnimation(.easeOut(duration: 0.3)) { pulseOpacity = 0.3 }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        HubLogger.drag("handleDrop started")
        isProcessingDrop = true // 开启锁定
        
        // 预加载所有已存在的路径，避免对每个文件单独查询
        let existingPaths = Set(items.map { $0.originalPath })
        
        let group = DispatchGroup()
        var addedCount = 0
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                if let url = item as? URL ?? (item as? Data).flatMap({ URL(dataRepresentation: $0, relativeTo: nil) }) {
                    DispatchQueue.main.async {
                        // 使用内存中的 Set 进行查重，避免频繁的 Core Data 查询
                        if !existingPaths.contains(url.path) {
                            self.addItem(name: url.lastPathComponent, path: url.path)
                            addedCount += 1
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if addedCount > 0 {
                // 第一阶段：展示成功动画
                withAnimation(.spring(response: HubMetrics.Animation.dropSuccessResponse, 
                                     dampingFraction: HubMetrics.Animation.dropSuccessDamping)) {
                    self.dropSuccess = true
                }

                // 第二阶段：保持成功态 1.2s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    // 第三阶段：分步揭示 - 缓慢淡出蓝色遮罩，同时内容放大浮现
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        self.dropSuccess = false
                        self.isDragging = false
                    }

                    // 第四阶段：静止展示期 (2.5s)，让用户看一眼暂存的文件
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isProcessingDrop = false // 解除锁定
                        
                        // 最后：如果不悬停，则优雅收起
                        if !self.isHovering && !vm.isShowingAlert {
                            vm.close()
                        }
                    }
                }
            } else {
                self.isDragging = false
                self.isProcessingDrop = false
            }
        }
    }
    
    private func addItem(name: String, path: String) {
        let descriptor = FetchDescriptor<StashedItem>(predicate: #Predicate { $0.originalPath == path })
        if (try? modelContext.fetch(descriptor).isEmpty) ?? true {
            modelContext.insert(StashedItem(name: name, fileType: StashedItem.inferFileType(from: name, path: path), originalPath: path))
        }
    }

    private func completeOnboarding() {
        withAnimation { showOnboarding = false }
        var settings = HubSettings(); settings.hasCompletedOnboarding = true; vm.open()
    }

    private func checkAndShowOnboarding() {
        guard !hasCheckedOnboarding && !showOnboarding && !HubSettings().hasCompletedOnboarding else { return }
        hasCheckedOnboarding = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { showOnboarding = true } }
    }

    @ViewBuilder
    private func renderDialog(for type: HubDialogType) -> some View {
        switch type {
        case .exit:
            HubDialog(
                title: "退出 Hub",
                message: "确认退出应用吗？",
                confirmTitle: "退出",
                confirmColor: .red,
                onConfirm: { NSApp.terminate(nil) },
                onCancel: { vm.dismissDialog() }
            )
        case .clearAll:
            HubDialog(
                title: "清空暂存区",
                message: "确认删除所有暂存文件吗？此操作无法撤销。",
                confirmTitle: "清空",
                confirmColor: .red,
                onConfirm: { 
                    items.forEach { modelContext.delete($0) }
                    vm.dismissDialog()
                },
                onCancel: { vm.dismissDialog() }
            )
        }
    }

    private func checkAndCloseIfEmpty() {
        if items.isEmpty && !isHovering && vm.hubState == .open { vm.close() }
    }
}
