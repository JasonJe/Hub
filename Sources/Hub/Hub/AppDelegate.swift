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
    private let minimumMacOSVersion = 26
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查系统版本
        guard checkSystemVersion() else {
            return
        }
        
        // 设置应用为 accessory 模式（无 Dock 图标）
        NSApp.setActivationPolicy(.accessory)
        
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
        
        // 创建主视图并注入环境
        let contentView = HubView()
            .modelContainer(container)
        
        // 初始化悬浮窗口
        WindowManager.shared.setupWindow(view: contentView)
        
        HubLogger.log("Window setup complete")
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
