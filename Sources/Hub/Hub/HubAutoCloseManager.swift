//  HubAutoCloseManager.swift
//  Hub
//
//  Hub 自动收起管理器 - 统一管理所有自动收起场景

import Foundation
import AppKit

/// Hub 自动收起管理器
@MainActor
class HubAutoCloseManager {
    static let shared = HubAutoCloseManager()
    
    // MARK: - 状态
    
    /// 鼠标是否在 Hub 窗口内
    var isMouseInHub: Bool = false
    
    /// 鼠标是否在悬浮球内
    var isMouseInOrb: Bool = false
    
    /// 是否正在拖拽文件
    var isDragging: Bool = false
    
    /// 是否显示设置页面
    var isShowingSettings: Bool = false
    
    /// 是否显示确认对话框
    var isShowingConfirmation: Bool = false
    
    /// Hub 是否有内容
    var hasItems: Bool = false
    
    /// Hub 是否展开
    var isHubExpanded: Bool = false
    
    /// 鼠标是否曾经进入过 Hub
    var hasMouseEnteredHub: Bool = false
    
    // MARK: - 计时器
    
    private var closeWorkItem: DispatchWorkItem?
    
    // MARK: - 回调
    
    var onClose: (() -> Void)?
    
    // MARK: - 公共方法
    
    /// 重置状态（每次展开时调用）
    func reset() {
        isMouseInHub = false
        isMouseInOrb = false
        isDragging = false
        isShowingSettings = false
        isShowingConfirmation = false
        hasMouseEnteredHub = false
        cancelAutoClose()
    }
    
    /// Hub 展开完成
    func hubDidExpand() {
        isHubExpanded = true
        hasMouseEnteredHub = false
        
        // 启动安全收起计时器（如果鼠标从未进入 Hub）
        scheduleSafetyClose()
    }
    
    /// Hub 收起完成
    func hubDidClose() {
        isHubExpanded = false
        cancelAutoClose()
    }
    
    /// 鼠标进入 Hub
    func mouseEnteredHub() {
        HubLogger.log("🖱️ AutoCloseManager: 鼠标进入 Hub")
        isMouseInHub = true
        hasMouseEnteredHub = true
        cancelAutoClose()
    }
    
    /// 鼠标离开 Hub
    func mouseExitedHub() {
        HubLogger.log("🖱️ AutoCloseManager: 鼠标离开 Hub")
        isMouseInHub = false
        
        // 检查是否应该自动收起
        checkAndScheduleAutoClose()
    }
    
    /// 鼠标进入悬浮球
    func mouseEnteredOrb() {
        HubLogger.log("🖱️ AutoCloseManager: 鼠标进入悬浮球")
        isMouseInOrb = true
        cancelAutoClose()
    }
    
    /// 鼠标离开悬浮球
    func mouseExitedOrb() {
        HubLogger.log("🖱️ AutoCloseManager: 鼠标离开悬浮球")
        isMouseInOrb = false
        
        // 如果 Hub 展开但鼠标不在 Hub 内，检查是否应该收起
        if isHubExpanded && !isMouseInHub {
            checkAndScheduleAutoClose()
        }
    }
    
    /// 开始拖拽
    func startDragging() {
        isDragging = true
        cancelAutoClose()
    }
    
    /// 结束拖拽
    func endDragging() {
        isDragging = false
        
        // 如果鼠标不在 Hub 内，检查是否应该收起
        if !isMouseInHub {
            checkAndScheduleAutoClose()
        }
    }
    
    /// 设置页面状态变化
    func settingsStateChanged(_ isShowing: Bool) {
        isShowingSettings = isShowing
        if isShowing {
            cancelAutoClose()
        } else if !isMouseInHub {
            checkAndScheduleAutoClose()
        }
    }
    
    /// 确认对话框状态变化
    func confirmationStateChanged(_ isShowing: Bool) {
        isShowingConfirmation = isShowing
        if isShowing {
            cancelAutoClose()
        } else if !isMouseInHub {
            checkAndScheduleAutoClose()
        }
    }
    
    /// 项目数量变化
    func itemsCountChanged(_ hasItems: Bool) {
        self.hasItems = hasItems
    }
    
    // MARK: - 私有方法
    
    /// 检查是否应该自动收起，并设置计时器
    private func checkAndScheduleAutoClose() {
        // 不应该收起的情况
        guard shouldAutoClose() else {
            HubLogger.log("🖱️ AutoCloseManager: 不满足收起条件，不自动收起")
            return
        }
        
        // 确定延迟时间
        let delay: TimeInterval
        if !hasMouseEnteredHub {
            // 鼠标从未进入 Hub，快速收起
            delay = 1.0
        } else if hasItems {
            // 有内容，给更长时间
            delay = 1.0
        } else {
            // 默认延迟
            delay = 0.5
        }
        
        scheduleAutoClose(after: delay)
    }
    
    /// 检查是否应该自动收起
    private func shouldAutoClose() -> Bool {
        // 鼠标在 Hub 内，不收起
        if isMouseInHub { return false }
        
        // 鼠标在悬浮球内，不收起（用户可能在查看悬浮球）
        if isMouseInOrb { return false }
        
        // 正在拖拽，不收起
        if isDragging { return false }
        
        // 显示设置页面，不收起
        if isShowingSettings { return false }
        
        // 显示确认对话框，不收起
        if isShowingConfirmation { return false }
        
        return true
    }
    
    /// 启动安全收起计时器
    private func scheduleSafetyClose() {
        cancelAutoClose()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // 如果鼠标从未进入 Hub，自动收起
            if !self.hasMouseEnteredHub && self.shouldAutoClose() {
                HubLogger.log("🖱️ AutoCloseManager: 安全收起（鼠标从未进入 Hub）")
                self.onClose?()
            }
        }
        
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
    
    /// 设置自动收起计时器
    private func scheduleAutoClose(after delay: TimeInterval) {
        cancelAutoClose()
        
        HubLogger.log("🖱️ AutoCloseManager: \(delay)秒后自动收起")
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // 再次检查条件
            if self.shouldAutoClose() {
                HubLogger.log("🖱️ AutoCloseManager: 执行自动收起")
                self.onClose?()
            } else {
                HubLogger.log("🖱️ AutoCloseManager: 条件已变化，取消收起")
            }
        }
        
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    /// 取消自动收起
    private func cancelAutoClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
    }
}
