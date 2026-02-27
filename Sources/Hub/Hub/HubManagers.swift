//
//  HubManagers.swift
//  Hub
//
//  职责分离辅助管理器 - 将 ViewModel 职责分离到专门的管理器
//  ViewModel 可继续作为门面协调这些管理器，保持接口不变
//

import SwiftUI
import Combine

// MARK: - 弹窗管理器

/// 管理弹窗/对话框状态
@MainActor
class DialogManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var activeType: HubDialogType?
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var action: (() -> Void)?
    
    /// 显示弹窗
    func show(_ type: HubDialogType, clearAction: (() -> Void)? = nil) {
        withAnimation(.spring(response: HubMetrics.Animation.dialogResponse, dampingFraction: HubMetrics.Animation.dialogDamping)) {
            switch type {
            case .exit:
                self.title = "退出 Hub"
                self.message = "确认退出吗？"
                self.action = { NSApp.terminate(nil) }
            case .clearAll:
                self.title = "清空"
                self.message = "确认删除所有文件吗？"
                self.action = clearAction
            }
            self.isShowing = true
            self.activeType = nil
        }
    }
    
    /// 关闭弹窗
    func dismiss() {
        withAnimation(.spring(response: HubMetrics.Animation.dialogResponse, dampingFraction: HubMetrics.Animation.dialogDamping)) {
            self.isShowing = false
            self.activeType = nil
        }
    }
}

// MARK: - 位置管理器

/// 管理窗口和悬浮球位置
@MainActor
class PositionManager: ObservableObject {
    @Published var orbPosition: CGPoint = .zero
    @Published var expandedWindowPosition: CGPoint = .zero
    
    private let orbSize: CGFloat = 56
    private let padding: CGFloat = 20
    
    /// 更新悬浮球位置并保存
    func updateOrbPosition(_ position: CGPoint) {
        orbPosition = position
        savePosition()
    }
    
    /// 约束位置到屏幕范围内
    func constrainPosition(_ position: CGPoint, in screenFrame: CGRect) -> CGPoint {
        let minX = screenFrame.minX + padding
        let maxX = screenFrame.maxX - orbSize - padding
        let minY = screenFrame.minY + padding
        let maxY = screenFrame.maxY - orbSize - padding
        
        return CGPoint(
            x: max(minX, min(position.x, maxX)),
            y: max(minY, min(position.y, maxY))
        )
    }
    
    /// 计算展开窗体位置
    func calculateExpandedWindowPosition(from orbPosition: CGPoint) -> CGPoint {
        return CGPoint(
            x: orbPosition.x - 280 - 10,
            y: orbPosition.y
        )
    }
    
    /// 从设置加载位置
    func loadPosition() {
        let settings = HubSettings()
        orbPosition = CGPoint(x: settings.floatingX, y: settings.floatingY)
    }
    
    /// 保存位置到设置
    private func savePosition() {
        var settings = HubSettings()
        settings.floatingX = orbPosition.x
        settings.floatingY = orbPosition.y
        settings.save()
    }
}

// MARK: - Hub 状态管理器

/// 管理 Hub 核心状态
@MainActor
class HubStateManager: ObservableObject {
    @Published var hubState: HubState = .closed
    @Published var hubSize: CGSize = HubMetrics.getClosedHubSize()
    @Published var closedHubSize: CGSize = HubMetrics.getClosedHubSize()
    
    /// 展开 Hub
    func open() {
        hubSize = HubMetrics.openHubSize
        hubState = .open
    }
    
    /// 关闭 Hub
    func close() {
        hubSize = HubMetrics.getClosedHubSize()
        closedHubSize = hubSize
        hubState = .closed
    }
    
    /// 切换状态
    func toggle() {
        if hubState == .closed {
            open()
        } else {
            close()
        }
    }
}

// MARK: - 悬浮球状态管理器

/// 管理悬浮球展开/收起状态
@MainActor
class OrbStateManager: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var isDragging: Bool = false
    @Published var showExpandedWindow: Bool = false
    
    /// 展开
    func expand() {
        guard !isDragging else { return }
        isExpanded = true
        showExpandedWindow = true
    }
    
    /// 收起
    func collapse() {
        isExpanded = false
        showExpandedWindow = false
    }
    
    /// 切换
    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    /// 开始拖拽
    func startDragging() {
        isDragging = true
        collapse()
    }
    
    /// 结束拖拽
    func endDragging() {
        isDragging = false
    }
}

// MARK: - 设置状态管理器

/// 管理设置视图状态
@MainActor
class SettingsManager: ObservableObject {
    @Published var isShowing: Bool = false
    
    /// 打开设置
    func open() {
        withAnimation(.spring(response: HubMetrics.Animation.popoverResponse, dampingFraction: HubMetrics.Animation.popoverDamping)) {
            isShowing = true
        }
    }
    
    /// 关闭设置
    func close() {
        withAnimation(.spring(response: HubMetrics.Animation.popoverResponse, dampingFraction: HubMetrics.Animation.popoverDamping)) {
            isShowing = false
        }
    }
    
    /// 切换
    func toggle() {
        if isShowing {
            close()
        } else {
            open()
        }
    }
}

// MARK: - 组合管理器（重构后的 ViewModel 参考）

/// 组合所有管理器的门面类（重构后的 ViewModel 参考）
/// 现有 ViewModel 可保持不变，新代码可直接使用此结构
@MainActor
class HubViewModelRefactored: ObservableObject {
    let stateManager = HubStateManager()
    let orbManager = OrbStateManager()
    let positionManager = PositionManager()
    let dialogManager = DialogManager()
    let settingsManager = SettingsManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // 当 Hub 关闭时，自动关闭设置
        stateManager.$hubState
            .filter { $0 == .closed }
            .sink { [weak self] _ in
                self?.settingsManager.close()
            }
            .store(in: &cancellables)
        
        // 加载保存的位置
        positionManager.loadPosition()
    }
    
    // MARK: - 便捷方法（保持与现有 ViewModel 兼容的接口）
    
    var hubState: HubState { stateManager.hubState }
    var hubSize: CGSize { stateManager.hubSize }
    var isOrbExpanded: Bool { orbManager.isExpanded }
    var showSettings: Bool { settingsManager.isShowing }
    var showConfirmation: Bool { dialogManager.isShowing }
    
    func open() { stateManager.open() }
    func close() { stateManager.close() }
    func expandOrb() { orbManager.expand() }
    func collapseOrb() { orbManager.collapse() }
    func openSettings() { settingsManager.open() }
    func closeSettings() { settingsManager.close() }
}

/*
 使用说明：
 
 1. 现有代码不需要修改，继续使用 HubViewModel
 2. 新代码可以选择：
    - 继续使用 HubViewModel（推荐，保持一致性）
    - 直接使用各专门的管理器（如果只需要特定功能）
    - 使用 HubViewModelRefactored（重构后的版本）
 
 3. 渐进式迁移：
    - 可以逐步将 HubViewModel 内部委托给各管理器
    - 保持公共接口不变
    - 最终达到职责分离的目标
 */
