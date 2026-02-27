//
//  FloatingOrbView.swift
//  Hub
//
//  悬浮球模式 - 小窗口设计，支持全屏拖拽和角落锚定
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FloatingOrbView: View {
    @ObservedObject var viewModel: HubViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StashedItem.dateAdded, order: .reverse) private var items: [StashedItem]
    
    // 尺寸配置（再增大10%）
    private let orbSize: CGFloat = 57
    private let menuWidth: CGFloat = 300
    private let menuHeight: CGFloat = 400
    private let padding: CGFloat = 16
    
    // 状态
    @State private var currentCorner: ScreenCorner = .bottomRight
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var shimmerOffset: CGFloat = -1.0  // 液态玻璃流光动画
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 点击外部收起
                if viewModel.isOrbExpanded || viewModel.showSettings || viewModel.showConfirmation {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            collapseAll()
                        }
                }
                
                // 菜单层
                if viewModel.isOrbExpanded || viewModel.showSettings || viewModel.showConfirmation {
                    menuContainer(in: geometry.size)
                }
                
                // 悬浮球层
                orbButton(in: geometry.size)
            }
        }
        .frame(width: windowWidth, height: windowHeight)
    }
    
    // MARK: - 窗口尺寸（固定大小，避免展开时位置偏移）
    
    // 固定窗口大小：足够容纳悬浮球 + 菜单展开
    private let windowWidth: CGFloat = 400   // 52球 + 16*2边距 + 300菜单 = 384，取整400
    private let windowHeight: CGFloat = 450  // max(400菜单, 84球区) + 边距
    
    // MARK: - 悬浮球按钮
    
    private func orbButton(in size: CGSize) -> some View {
        orbContent
            .position(orbPosition(in: size))
            .onHover { hovering in
                handleHover(hovering)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .global)
                    .onChanged { value in
                        handleDragChanged(value: value)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value)
                    }
            )
    }
    
    private var orbContent: some View {
        ZStack {
            // 液态玻璃：多层材质叠加
            // 底层：柔和发光
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.cyan.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: orbSize / 2
                    )
                )
                .frame(width: orbSize + 8, height: orbSize + 8)
                .blur(radius: 8)
            
            // 主体：液态玻璃材质
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: orbSize, height: orbSize)
                // 内发光边缘
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .white.opacity(0.2),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                // 高光反射
                .overlay(
                    Circle()
                        .fill(
                            EllipticalGradient(
                                colors: [.white.opacity(0.4), .clear],
                                center: .top,
                                startRadiusFraction: 0.0,
                                endRadiusFraction: 0.6
                            )
                        )
                        .frame(height: orbSize * 0.6)
                        .clipped(),
                    alignment: .top
                )
                // 底部折射
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .blue.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                // 柔和阴影
                .shadow(
                    color: .black.opacity(isHovering ? 0.35 : 0.2),
                    radius: isHovering ? 20 : 12,
                    x: 0,
                    y: isHovering ? 10 : 6
                )
                // 悬停放大效果
                .scaleEffect(isHovering && !isDragging ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering && !isDragging)
            
            // 简洁图标：使用更抽象的设计
            ZStack {
                // 展开状态：关闭图标
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.95), .white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(viewModel.isOrbExpanded ? 1 : 0)
                    .rotationEffect(.degrees(viewModel.isOrbExpanded ? 0 : -90))
                    .scaleEffect(viewModel.isOrbExpanded ? 1 : 0.5)
                
                // 收起状态：抽象圆点（代表 Hub）
                Image(systemName: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .cyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(viewModel.isOrbExpanded ? 0 : 1)
                    .rotationEffect(.degrees(viewModel.isOrbExpanded ? 90 : 0))
                    .scaleEffect(viewModel.isOrbExpanded ? 0.5 : 1)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.isOrbExpanded)
        }
        .frame(width: orbSize + 20, height: orbSize + 20)
        .contentShape(Circle())
    }
    
    // MARK: - 悬浮球位置（固定在窗口角落）
    
    private func orbPosition(in size: CGSize) -> CGPoint {
        switch currentCorner {
        case .topLeft:
            // 左上角落：悬浮球在窗口右下
            return CGPoint(x: windowWidth - padding - orbSize/2, 
                          y: windowHeight - padding - orbSize/2)
        case .topRight:
            // 右上角落：悬浮球在窗口左下
            return CGPoint(x: padding + orbSize/2, 
                          y: windowHeight - padding - orbSize/2)
        case .bottomLeft:
            // 左下角落：悬浮球在窗口右上
            return CGPoint(x: windowWidth - padding - orbSize/2, 
                          y: padding + orbSize/2)
        case .bottomRight:
            // 右下角落：悬浮球在窗口左上
            return CGPoint(x: padding + orbSize/2, 
                          y: padding + orbSize/2)
        }
    }
    
    // MARK: - 菜单容器
    
    private func menuContainer(in size: CGSize) -> some View {
        let position = menuPosition(in: size)
        let anchor = menuAnchor
        let isExpanded = viewModel.isOrbExpanded || viewModel.showSettings || viewModel.showConfirmation
        
        return ZStack {
            // 主内容和设置页面 - 使用 ZStack 同时显示，动画与刘海模式一致
            ZStack {
                // 主菜单内容
                mainMenuContent
                    .opacity(viewModel.showSettings || viewModel.showConfirmation ? 0 : 1)
                    .offset(x: viewModel.showSettings ? -30 : 0)
                
                // 设置页面
                settingsContent
                    .opacity(viewModel.showSettings && !viewModel.showConfirmation ? 1 : 0)
                    .offset(x: viewModel.showSettings ? 0 : 30)
                
                // 确认对话框
                if viewModel.showConfirmation {
                    confirmationContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showSettings || viewModel.showConfirmation)
        }
        .position(position)
        .scaleEffect(isExpanded ? 1 : 0.85, anchor: anchor)
        .opacity(isExpanded ? 1 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1), value: isExpanded)
        .onAppear {
            // 启动 shimmer 动画
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
    
    private var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("暂存区")
                    .font(.system(size: 15, weight: .semibold))
                
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
                        viewModel.showDialog(.clearAll)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.red.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider()
                .background(.white.opacity(0.06))
                .padding(.horizontal, 16)
            
            // 内容
            menuGrid
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
                .background(.white.opacity(0.06))
                .padding(.horizontal, 16)
            
            // Footer
            HStack(spacing: 12) {
                Button(action: { viewModel.openSettings() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 11))
                        Text("设置")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { viewModel.showDialog(.exit) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text("退出")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(width: menuWidth, height: menuHeight)
        .background(
            ZStack {
                // 1. 内部深度：极淡的次表面色彩（与刘海模式一致）
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
                
                // 3. 表面流光：使用 plusLighter 增强亮度（与刘海模式一致）
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.12), .clear],
                            startPoint: UnitPoint(x: shimmerOffset, y: 0),
                            endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            ZStack {
                // 4. 基础折射边框（与刘海模式一致）
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                
                // 5. 极锐利镜面高光（与刘海模式一致）
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
        // 核心阴影系统（与刘海模式一致）
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var menuGrid: some View {
        ZStack {
            if items.isEmpty {
                emptyState
            } else {
                let iconSize = HubMetrics.floatingOrbItemSize
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(iconSize), spacing: 10),
                            GridItem(.fixed(iconSize), spacing: 10),
                            GridItem(.fixed(iconSize), spacing: 10),
                            GridItem(.fixed(iconSize), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            DraggableItemView(
                                item: item,
                                modelContext: modelContext,
                                iconSize: iconSize,
                                itemHeight: HubMetrics.floatingOrbItemHeight
                            )
                                .contextMenu {
                                    Button("删除") {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { 
                                            modelContext.delete(item) 
                                        }
                                    }
                                }
                                .scaleEffect(viewModel.isOrbExpanded ? 1 : 0.8)
                                .opacity(viewModel.isOrbExpanded ? 1 : 0)
                                .offset(y: viewModel.isOrbExpanded ? 0 : 10)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.015),
                                    value: viewModel.isOrbExpanded
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: .constant(false)) { providers in
            if !viewModel.isOrbExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.expandOrb()
                }
            }
            handleDrop(providers: providers)
            return true
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // 简洁的图标组合
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .cyan.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text("拖放文件到此处")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text("暂存区为空")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
        }
    }
    
    private var settingsContent: some View {
        SettingsContentView(onClose: { viewModel.closeSettings() })
            .padding(.top, 16)
            .frame(width: menuWidth, height: menuHeight)
            .background(
                ZStack {
                    // 1. 内部深度：极淡的次表面色彩（与刘海模式一致）
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
                    
                    // 3. 表面流光
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.12), .clear],
                                startPoint: UnitPoint(x: shimmerOffset, y: 0),
                                endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                            )
                        )
                        .blendMode(.plusLighter)
                }
            )
            .overlay(
                ZStack {
                    // 4. 基础折射边框（与刘海模式一致）
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                    
                    // 5. 极锐利镜面高光（与刘海模式一致）
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
            // 核心阴影系统（与刘海模式一致）
            .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var confirmationContent: some View {
        ConfirmationView(
            title: viewModel.confirmationTitle,
            message: viewModel.confirmationMessage,
            confirmTitle: viewModel.confirmationTitle.contains("清空") ? "清空" : "退出",
            onConfirm: {
                viewModel.confirmationAction?()
                viewModel.dismissDialog()
            },
            onCancel: { viewModel.dismissDialog() }
        )
        .frame(width: 260, height: 180)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 35, x: 0, y: 18)
    }
    
    // MARK: - 菜单位置（根据角落固定位置）
    
    private func menuPosition(in size: CGSize) -> CGPoint {
        switch currentCorner {
        case .topLeft:
            // 左上：菜单向右下展开
            return CGPoint(x: menuWidth/2 + padding, 
                          y: windowHeight - menuHeight/2 - padding)
        case .topRight:
            // 右上：菜单向左下展开
            return CGPoint(x: windowWidth - menuWidth/2 - padding, 
                          y: windowHeight - menuHeight/2 - padding)
        case .bottomLeft:
            // 左下：菜单向右上展开
            return CGPoint(x: menuWidth/2 + padding, 
                          y: menuHeight/2 + padding)
        case .bottomRight:
            // 右下：菜单向左上展开
            return CGPoint(x: windowWidth - menuWidth/2 - padding, 
                          y: menuHeight/2 + padding)
        }
    }
    
    private var menuAnchor: UnitPoint {
        switch currentCorner {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        }
    }
    
    // MARK: - 悬停处理
    
    @State private var hoverWorkItem: DispatchWorkItem?
    
    private func handleHover(_ hovering: Bool) {
        isHovering = hovering
        
        guard !isDragging else { return }
        
        // 取消之前的计时任务
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        
        if hovering && !viewModel.isOrbExpanded {
            // 延迟展开，避免误触发
            let workItem = DispatchWorkItem { [viewModel] in
                // 使用 capture list 捕获 viewModel 而不是 self
                guard hovering,
                      !viewModel.isOrbExpanded else { return }
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.expandOrb()
                }
            }
            hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
            
        } else if !hovering && viewModel.isOrbExpanded && !viewModel.showSettings && !viewModel.showConfirmation {
            // 延迟收起，给用户时间移入菜单
            let workItem = DispatchWorkItem { [viewModel] in
                guard !hovering else { return }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.collapseOrb()
                    viewModel.closeSettings()
                    viewModel.dismissDialog()
                }
            }
            hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
        }
    }
    
    // MARK: - 拖拽处理（自由拖拽 + 角落吸附）
    
    @State private var lastMouseLocation: NSPoint?
    
    private func handleDragChanged(value: DragGesture.Value) {
        guard let panel = WindowManager.shared.panel else { return }
        
        if !isDragging {
            isDragging = true
            lastMouseLocation = NSEvent.mouseLocation
            
            if viewModel.isOrbExpanded {
                withAnimation(.easeIn(duration: 0.15)) {
                    viewModel.collapseOrb()
                }
            }
            viewModel.startOrbDrag()
            return
        }
        
        // 获取当前鼠标位置
        let currentMouse = NSEvent.mouseLocation
        
        guard let lastMouse = lastMouseLocation else {
            lastMouseLocation = currentMouse
            return
        }
        
        // 计算鼠标移动增量
        let deltaX = currentMouse.x - lastMouse.x
        let deltaY = currentMouse.y - lastMouse.y
        
        // 更新最后位置
        lastMouseLocation = currentMouse
        
        // 获取当前窗口位置并应用增量
        let currentOrigin = panel.frame.origin
        var newX = currentOrigin.x + deltaX
        var newY = currentOrigin.y + deltaY
        
        // 自由拖拽，无区域限制（只确保不丢失）
        if let screen = NSScreen.main {
            let frame = screen.frame
            newX = max(frame.minX - 100, min(newX, frame.maxX + 100))
            newY = max(frame.minY - 100, min(newY, frame.maxY + 100))
        }
        
        // 直接设置位置，不使用动画
        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
    }
    
    private func handleDragEnded(value: DragGesture.Value) {
        guard isDragging else { return }
        
        isDragging = false
        lastMouseLocation = nil
        viewModel.endOrbDrag()
        
        // 吸附到最近角落
        snapToNearestCorner()
    }
    
    private func snapToNearestCorner() {
        guard let panel = WindowManager.shared.panel,
              let screen = NSScreen.main else { return }
        
        let frame = screen.visibleFrame
        let origin = panel.frame.origin
        
        // 计算到四个角落的距离
        let distTopLeft = distance(from: origin, to: CGPoint(x: frame.minX, y: frame.maxY))
        let distTopRight = distance(from: origin, to: CGPoint(x: frame.maxX, y: frame.maxY))
        let distBottomLeft = distance(from: origin, to: CGPoint(x: frame.minX, y: frame.minY))
        let distBottomRight = distance(from: origin, to: CGPoint(x: frame.maxX, y: frame.minY))
        
        // 找到最近的角落
        let minDist = min(distTopLeft, distTopRight, distBottomLeft, distBottomRight)
        
        var targetCorner: ScreenCorner
        var targetOrigin: NSPoint
        
        if minDist == distTopLeft {
            targetCorner = .topLeft
            targetOrigin = NSPoint(x: frame.minX, y: frame.maxY - orbSize - padding * 2)
        } else if minDist == distTopRight {
            targetCorner = .topRight
            targetOrigin = NSPoint(x: frame.maxX - orbSize - padding * 2, y: frame.maxY - orbSize - padding * 2)
        } else if minDist == distBottomLeft {
            targetCorner = .bottomLeft
            targetOrigin = NSPoint(x: frame.minX, y: frame.minY)
        } else {
            targetCorner = .bottomRight
            targetOrigin = NSPoint(x: frame.maxX - orbSize - padding * 2, y: frame.minY)
        }
        
        // 更新角落状态
        currentCorner = targetCorner
        
        // 动画吸附
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            panel.setFrameOrigin(targetOrigin)
        }
        
        // 保存位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var settings = HubSettings()
            settings.floatingX = targetOrigin.x
            settings.floatingY = targetOrigin.y
            settings.save()
        }
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func collapseAll() {
        withAnimation(.easeIn(duration: 0.2)) {
            viewModel.collapseOrb()
            viewModel.closeSettings()
            viewModel.dismissDialog()
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url, error == nil else { return }
                DispatchQueue.main.async {
                    // 检查是否已存在相同路径的文件
                    if self.items.contains(where: { $0.originalPath == url.path }) {
                        return
                    }
                    
                    let item = StashedItem(
                        name: url.lastPathComponent,
                                                    fileType: StashedItem.inferFileType(from: url.lastPathComponent, path: url.path),                        originalPath: url.path
                    )
                    self.modelContext.insert(item)
                }
            }
        }
    }
}

// MARK: - 屏幕角落枚举

enum ScreenCorner: String {
    case topLeft = "左上"
    case topRight = "右上"
    case bottomLeft = "左下"
    case bottomRight = "右下"
}
