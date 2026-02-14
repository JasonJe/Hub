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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
}
