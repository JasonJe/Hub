//
//  HubViewModel.swift
//  Hub
//
//  Hub 状态管理
//

import SwiftUI
import Combine

// MARK: - 状态枚举

/// Hub 的状态枚举 - 参考 boring.notch
enum HubState: String, Equatable {
    case closed  // 闭合/空闲状态
    case open    // 展开/暂存状态
}

/// 弹窗类型
enum HubDialogType: Equatable {
    case exit      // 退出确认
    case clearAll  // 清空确认
}

// MARK: - ViewModel

/// Hub 视图模型，管理 Hub 的状态和尺寸
@MainActor
class HubViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var hubState: HubState = .closed
    @Published var hubSize: CGSize = HubMetrics.getClosedHubSize()
    @Published var closedHubSize: CGSize = HubMetrics.getClosedHubSize()
    @Published var showSettings: Bool = false  // 是否显示设置视图
    @Published var isShowingAlert: Bool = false // 是否正在显示弹窗
    @Published var activeDialog: HubDialogType? = nil // 当前活动的弹窗类型
    @Published var showConfirmation: Bool = false // 是否显示确认视图
    @Published var confirmationTitle: String = "" // 确认标题
    @Published var confirmationMessage: String = "" // 确认消息
    @Published var confirmationAction: (() -> Void)? = nil // 确认操作
    
    // MARK: - 悬浮球相关属性
    
    @Published var isOrbExpanded: Bool = false
    @Published var isOrbDragging: Bool = false
    @Published var showExpandedWindow: Bool = false
    @Published var orbPosition: CGPoint = CGPoint(x: 0, y: 0)
    @Published var expandedWindowPosition: CGPoint = CGPoint(x: 0, y: 0)
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .hubCollapseMenu)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.collapseOrb()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: .hubExpandMenu)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.expandOrb()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 显示指定类型的弹窗
    func showDialog(_ type: HubDialogType, clearAction: (() -> Void)? = nil) {
        print("[DEBUG] HubViewModel.showDialog(\(type)) 被调用")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            switch type {
            case .exit:
                self.confirmationTitle = "退出 Hub"
                self.confirmationMessage = "确认退出吗？"
                self.confirmationAction = {
                    NSApp.terminate(nil)
                }
            case .clearAll:
                self.confirmationTitle = "清空"
                self.confirmationMessage = "确认删除所有文件吗？"
                self.confirmationAction = clearAction
            }
            self.showConfirmation = true
            self.isShowingAlert = true
            self.activeDialog = nil
        }
    }
    
    /// 关闭当前弹窗
    func dismissDialog() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.showConfirmation = false
            self.isShowingAlert = false
            self.activeDialog = nil
        }
    }
    
    /// 展开 Hub
    func open() {
        HubLogger.log("📢 HubViewModel.open() called, current state: \(self.hubState)")
        self.hubSize = HubMetrics.openHubSize
        self.hubState = .open
        HubLogger.log("✅ Hub state changed to: \(self.hubState), size: \(self.hubSize)")
    }
    
    /// 关闭 Hub
    func close() {
        // 如果当前显示设置，则先关闭设置而不是整个Hub
        if self.showSettings {
            self.showSettings = false
        } else {
            self.hubSize = HubMetrics.getClosedHubSize()
            self.closedHubSize = self.hubSize
            self.hubState = .closed
        }
    }
    
    /// 显示设置
    func openSettings() {
        print("[DEBUG] HubViewModel.openSettings() 被调用")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.showSettings = true
            if self.hubState == .closed {
                self.hubSize = HubMetrics.openHubSize
                self.hubState = .open
            }
        }
    }
    
    /// 隐藏设置
    func closeSettings() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.showSettings = false
        }
    }
    
    // MARK: - 悬浮球方法
    
    /// 切换悬浮球展开/收起
    func toggleOrb() {
        if isOrbExpanded {
            collapseOrb()
        } else {
            expandOrb()
        }
    }
    
    /// 展开悬浮球
    func expandOrb() {
        guard !isOrbDragging else { return }
        isOrbExpanded = true
        showExpandedWindow = true
    }
    
    /// 收起悬浮球
    func collapseOrb() {
        isOrbExpanded = false
        showExpandedWindow = false
    }
    
    /// 带动画的展开
    func expandOrbWithAnimation(completion: (() -> Void)? = nil) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandOrb()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion?()
        }
    }
    
    /// 带动画的收起
    func collapseOrbWithAnimation(completion: (() -> Void)? = nil) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            collapseOrb()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            completion?()
        }
    }
    
    /// 开始拖动悬浮球
    func startOrbDrag() {
        isOrbDragging = true
        // 拖动时收起窗体
        collapseOrb()
    }
    
    /// 结束拖动悬浮球
    func endOrbDrag() {
        isOrbDragging = false
    }
    
    /// 更新悬浮球位置
    func updateOrbPosition(_ position: CGPoint) {
        orbPosition = position
        
        // 保存位置到设置
        var settings = HubSettings()
        settings.floatingX = position.x
        settings.floatingY = position.y
        settings.save()
    }
    
    /// 约束悬浮球位置到屏幕范围内
    func constrainedOrbPosition(for position: CGPoint, in screenFrame: CGRect) -> CGPoint {
        let orbSize: CGFloat = 56
        let padding: CGFloat = 20
        
        let minX = screenFrame.minX + padding
        let maxX = screenFrame.maxX - orbSize - padding
        let minY = screenFrame.minY + padding
        let maxY = screenFrame.maxY - orbSize - padding
        
        return CGPoint(
            x: max(minX, min(position.x, maxX)),
            y: max(minY, min(position.y, maxY))
        )
    }
    
    /// 计算展开窗体的位置
    func calculateExpandedWindowPosition() -> CGPoint {
        // 展开窗体在悬浮球左侧展开
        return CGPoint(
            x: orbPosition.x - 280 - 10, // 窗体宽度 + 间距
            y: orbPosition.y
        )
    }
}
