//
//  HubApp.swift
//  Hub
//
//  Created by 邱基盛 on 2026/2/13.
//

import SwiftUI
import SwiftData

@main
struct HubApp: App {
    // 使用 AppDelegate 管理生命周期
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 由于我们使用自定义 NSPanel，这里只需保留一个空的 Settings Scene
        Settings {
            EmptyView()
        }
    }
}