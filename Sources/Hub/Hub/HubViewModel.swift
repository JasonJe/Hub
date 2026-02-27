//
//  HubViewModel.swift
//  Hub
//
//  Hub 状态管理 - 重构版
//  内部委托给专门的管理器，保持公共接口不变
//

import SwiftUI
import Combine
import QuartzCore

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

/// Hub 视图模型 - 作为门面协调各专门管理器
/// 公共接口保持不变，内部委托给专门的管理器
@MainActor
class HubViewModel: ObservableObject {
    
    // MARK: - 内部管理器（私有）
    
    private let _stateManager = HubStateManager()
    private let _orbManager = OrbStateManager()
    private let _dialogManager = DialogManager()
    private let _settingsManager = SettingsManager()
    private let _positionManager = PositionManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties（绑定自管理器）
    
    /// Hub 状态
    @Published var hubState: HubState = .closed
    @Published var hubSize: CGSize = HubMetrics.getClosedHubSize()
    @Published var closedHubSize: CGSize = HubMetrics.getClosedHubSize()
    
    /// 设置状态
    @Published var showSettings: Bool = false
    
    /// 弹窗状态
    @Published var isShowingAlert: Bool = false
    @Published var activeDialog: HubDialogType? = nil
    @Published var showConfirmation: Bool = false
    @Published var confirmationTitle: String = ""
    @Published var confirmationMessage: String = ""
    @Published var confirmationAction: (() -> Void)? = nil
    
    /// 悬浮球状态
    @Published var isOrbExpanded: Bool = false
    @Published var isOrbDragging: Bool = false
    @Published var showExpandedWindow: Bool = false
    @Published var orbPosition: CGPoint = CGPoint(x: 0, y: 0)
    @Published var expandedWindowPosition: CGPoint = CGPoint(x: 0, y: 0)
    
    // MARK: - 初始化
    
    init() {
        setupBindings()
        setupNotifications()
    }
    
    // MARK: - 绑定管理器属性到 ViewModel
    
    private func setupBindings() {
        // Hub 状态绑定
        _stateManager.$hubState
            .assign(to: &$hubState)
        
        _stateManager.$hubSize
            .assign(to: &$hubSize)
        
        _stateManager.$closedHubSize
            .assign(to: &$closedHubSize)
        
        // 悬浮球状态绑定
        _orbManager.$isExpanded
            .assign(to: &$isOrbExpanded)
        
        _orbManager.$isDragging
            .assign(to: &$isOrbDragging)
        
        _orbManager.$showExpandedWindow
            .assign(to: &$showExpandedWindow)
        
        // 设置状态绑定
        _settingsManager.$isShowing
            .assign(to: &$showSettings)
        
        // 弹窗状态绑定
        _dialogManager.$isShowing
            .assign(to: &$showConfirmation)
        
        _dialogManager.$isShowing
            .map { $0 }
            .assign(to: &$isShowingAlert)
        
        _dialogManager.$title
            .assign(to: &$confirmationTitle)
        
        _dialogManager.$message
            .assign(to: &$confirmationMessage)
        
        _dialogManager.$action
            .assign(to: &$confirmationAction)
        
        // 位置绑定
        _positionManager.$orbPosition
            .assign(to: &$orbPosition)
        
        _positionManager.$expandedWindowPosition
            .assign(to: &$expandedWindowPosition)
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
    
    // MARK: - Public Methods（委托给管理器）
    
    /// 显示指定类型的弹窗
    func showDialog(_ type: HubDialogType, clearAction: (() -> Void)? = nil) {
        print("[DEBUG] HubViewModel.showDialog(\(type)) 被调用")
        _dialogManager.show(type, clearAction: clearAction)
    }
    
    /// 关闭当前弹窗
    func dismissDialog() {
        _dialogManager.dismiss()
    }
    
    /// 展开 Hub
    func open() {
        HubLogger.log("📢 HubViewModel.open() called, current state: \(self.hubState)")
        _stateManager.open()
        HubLogger.log("✅ Hub state changed to: \(self.hubState), size: \(self.hubSize)")
    }
    
    /// 关闭 Hub
    func close() {
        // 如果当前显示设置，则先关闭设置而不是整个Hub
        if showSettings {
            _settingsManager.close()
        } else {
            _stateManager.close()
        }
    }
    
    /// 显示设置
    func openSettings() {
        print("[DEBUG] HubViewModel.openSettings() 被调用")
        _settingsManager.open()
        if hubState == .closed {
            _stateManager.open()
        }
    }
    
    /// 隐藏设置
    func closeSettings() {
        _settingsManager.close()
    }
    
    // MARK: - 悬浮球方法
    
    /// 切换悬浮球展开/收起
    func toggleOrb() {
        _orbManager.toggle()
    }
    
    /// 展开悬浮球
    func expandOrb() {
        _orbManager.expand()
    }
    
    /// 收起悬浮球
    func collapseOrb() {
        _orbManager.collapse()
    }
    
    /// 带动画的展开 - 使用 NSAnimationContext 完成回调
    func expandOrbWithAnimation(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = HubMetrics.Animation.hoverResponse
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            withAnimation(.spring(response: HubMetrics.Animation.hoverResponse, dampingFraction: 0.8)) {
                _orbManager.expand()
            }
        } completionHandler: {
            completion?()
        }
    }
    
    /// 带动画的收起 - 使用 NSAnimationContext 完成回调
    func collapseOrbWithAnimation(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = HubMetrics.Animation.toggleResponse
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            withAnimation(.spring(response: HubMetrics.Animation.toggleResponse, dampingFraction: 0.85)) {
                _orbManager.collapse()
            }
        } completionHandler: {
            completion?()
        }
    }
    
    /// 开始拖动悬浮球
    func startOrbDrag() {
        _orbManager.startDragging()
    }
    
    /// 结束拖动悬浮球
    func endOrbDrag() {
        _orbManager.endDragging()
    }
    
    /// 更新悬浮球位置
    func updateOrbPosition(_ position: CGPoint) {
        _positionManager.updateOrbPosition(position)
    }
    
    /// 约束悬浮球位置到屏幕范围内
    func constrainedOrbPosition(for position: CGPoint, in screenFrame: CGRect) -> CGPoint {
        return _positionManager.constrainPosition(position, in: screenFrame)
    }
    
    /// 计算展开窗体的位置
    func calculateExpandedWindowPosition() -> CGPoint {
        return _positionManager.calculateExpandedWindowPosition(from: orbPosition)
    }
}