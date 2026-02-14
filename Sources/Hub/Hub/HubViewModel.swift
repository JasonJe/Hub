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

// MARK: - ViewModel

/// Hub 视图模型，管理 Hub 的状态和尺寸
@MainActor
class HubViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var hubState: HubState = .closed
    @Published var hubSize: CGSize = getClosedHubSize()
    @Published var closedHubSize: CGSize = getClosedHubSize()
    @Published var showSettings: Bool = false  // 是否显示设置视图
    
    // MARK: - Public Methods
    
    /// 展开 Hub
    func open() {
        self.hubSize = openHubSize
        self.hubState = .open
    }
    
    /// 关闭 Hub
    func close() {
        self.hubSize = getClosedHubSize()
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
