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
    
    // MARK: - Public Methods
    
    /// 显示指定类型的弹窗
    func showDialog(_ type: HubDialogType) {
        self.activeDialog = type
        self.isShowingAlert = true
    }
    
    /// 关闭当前弹窗
    func dismissDialog() {
        self.activeDialog = nil
        self.isShowingAlert = false
    }
    
    /// 展开 Hub
    func open() {
        self.hubSize = HubMetrics.openHubSize
        self.hubState = .open
    }
    
    /// 关闭 Hub
    func close() {
        self.hubSize = HubMetrics.getClosedHubSize()
        self.closedHubSize = self.hubSize
        self.hubState = .closed
        self.showSettings = false  // 关闭时重置设置状态
    }
    
    /// 显示设置
    func openSettings() {
        self.showSettings = true
        if self.hubState == .closed {
            self.open()
        }
    }
    
    /// 隐藏设置
    func closeSettings() {
        self.showSettings = false
    }
}
