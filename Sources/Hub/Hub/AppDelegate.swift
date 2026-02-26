//
//  AppDelegate.swift
//  Hub
//
//  Created by 邱基盛 on 2026/2/13.
//

import SwiftUI
import SwiftData
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContainer: ModelContainer?
    
    /// 最低支持的 macOS 主版本号
    /// macOS 26 对应 macOS 16 (Sequoia)，支持 Liquid Glass 设计特性
    private let minimumMacOSVersion = 26  // macOS 16 (Sequoia)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查系统版本
        guard checkSystemVersion() else {
            return
        }
        
        // 设置应用为 accessory 模式（无 Dock 图标）
        NSApp.setActivationPolicy(.accessory)
        
        // 清理旧版本的模拟残留设置
        UserDefaults.standard.removeObject(forKey: "mockScreenType")
        
        // 直接在 AppDelegate 中创建 ModelContainer
        do {
            let schema = Schema([StashedItem.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            HubLogger.error("Failed to create ModelContainer", error: error)
            return
        }
        
        guard let container = modelContainer else { return }
        
        // 检查是否有强制模式参数（用于测试）
        let forcedMode = getForcedModeFromArguments()
        
        // 只在启动时检测一次屏幕类型并应用对应模式
        let modeToApply: HubMode
        if let forced = forcedMode {
            modeToApply = forced
            HubLogger.log("使用强制模式: \(modeToApply.displayName)")
        } else {
            // 检测主屏幕类型并获取对应模式
            modeToApply = ScreenManager.shared.getModeForScreenType()
            HubLogger.log("根据屏幕类型自动选择模式: \(modeToApply.displayName)")
        }
        
        // 保存模式设置
        var settings = HubSettings()
        settings.mode = modeToApply
        settings.save()
        
        // 创建主视图并注入环境
        let contentView = HubView()
            .modelContainer(container)
        
        // 应用对应模式
        applyMode(modeToApply, contentView: contentView)
        
        // 设置屏幕类型变化回调，主显示屏切换时自动切换模式
        ScreenManager.shared.onScreenTypeChanged = { [weak self] newMode in
            guard let self = self else { return }
            HubLogger.log("主显示屏变化，切换到新模式: \(newMode.displayName)")
            
            // 先关闭当前窗口
            self.closeCurrentMode()
            
            // 更新设置
            var settings = HubSettings()
            settings.mode = newMode
            settings.save()
            
            // 创建新的视图并应用新模式
            let newContentView = HubView()
                .modelContainer(container)
            self.applyMode(newMode, contentView: newContentView)
        }
        
        HubLogger.log("Window setup complete")
    }
    
    /// 应用指定模式
    private func applyMode(_ mode: HubMode, contentView: some View) {
        if mode == .floating {
            // 悬浮球模式：双窗口架构
            OrbWindowManager.shared.setup(modelContainer: modelContainer!)
        } else {
            // 刘海模式：单窗口
            WindowManager.shared.setupWindow(view: contentView)
        }
        HubLogger.log("已应用模式: \(mode.displayName)")
    }
    
    /// 关闭当前模式的窗口
    private func closeCurrentMode() {
        // 关闭悬浮球窗口
        OrbWindowManager.shared.closeWindow()
        
        // 关闭刘海模式窗口
        WindowManager.shared.closeWindow()
        
        HubLogger.log("已关闭当前模式窗口")
    }
    
    /// 从命令行参数获取强制模式
    private func getForcedModeFromArguments() -> HubMode? {
        let args = ProcessInfo.processInfo.arguments
        
        if args.contains("--floating") {
            return .floating
        }
        if args.contains("--dynamic-island") {
            return .dynamicIsland
        }
        
        // 检查是否有 --mode 参数
        if let modeIndex = args.firstIndex(of: "--mode"),
           modeIndex + 1 < args.count {
            let modeValue = args[modeIndex + 1]
            if modeValue == "floating" {
                return .floating
            } else if modeValue == "dynamicIsland" {
                return .dynamicIsland
            }
        }
        
        return nil
    }
    
    /// 检查系统版本是否满足要求
    /// - Returns: 是否满足最低版本要求
    private func checkSystemVersion() -> Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        
        // 检查主版本号
        if version.majorVersion < minimumMacOSVersion {
            showVersionAlert(currentVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)")
            return false
        }
        
        return true
    }
    
    /// 显示版本不兼容提示
    private func showVersionAlert(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "系统版本不兼容"
        alert.informativeText = """
        Hub 需要 macOS \(minimumMacOSVersion).0 或更高版本。
        
        当前系统版本：macOS \(currentVersion)
        
        Hub 使用了 macOS \(minimumMacOSVersion) 的 Liquid Glass（液态玻璃）设计特性，
        请升级系统后使用。
        """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "退出")
        
        // 激活应用以确保对话框显示在最前
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        
        // 退出应用
        NSApp.terminate(nil)
    }
}
