//
//  HubSettings.swift
//  Hub
//
//  T041 & T042: Hub settings with UserDefaults persistence
//

import Foundation
import ServiceManagement
import AppKit

/// Hub display mode
enum HubMode: String, CaseIterable, Codable {
    case dynamicIsland = "dynamicIsland"  // 灵动岛模式
    case floating = "floating"              // 悬浮模式
    
    var displayName: String {
        switch self {
        case .dynamicIsland: return "灵动岛"
        case .floating: return "悬浮球"
        }
    }
}

/// Hub display position (for floating mode)
enum HubPosition: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "左侧"
        case .right: return "右侧"
        }
    }
}

/// User settings for Hub
struct HubSettings {
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let launchAtLogin = "hub.launchAtLogin"
        static let soundEnabled = "hub.soundEnabled"
        static let mode = "hub.mode"
        static let position = "hub.position"
        static let floatingX = "hub.floatingX"
        static let floatingY = "hub.floatingY"
        static let hasCompletedOnboarding = "hub.hasCompletedOnboarding"
    }
    
    // MARK: - Properties
    
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
    
    var soundEnabled: Bool {
        get {
            // Default to true if not set
            if defaults.object(forKey: Keys.soundEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }
    
    /// 模式：灵动岛 / 悬浮球
    var mode: HubMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.mode),
                  let mode = HubMode(rawValue: rawValue) else {
                return .dynamicIsland
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.mode) }
    }
    
    /// 悬浮模式下的位置
    var position: HubPosition {
        get {
            guard let rawValue = defaults.string(forKey: Keys.position),
                  let position = HubPosition(rawValue: rawValue) else {
                return .right
            }
            return position
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.position) }
    }
    
    /// 悬浮模式下的自定义位置 X
    var floatingX: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.floatingX)) }
        set { defaults.set(Double(newValue), forKey: Keys.floatingX) }
    }
    
    /// 悬浮模式下的自定义位置 Y
    var floatingY: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.floatingY)) }
        set { defaults.set(Double(newValue), forKey: Keys.floatingY) }
    }

    /// 是否已完成首次引导
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    // MARK: - Methods
    
    /// Save settings - Apple 文档说明不需要显式调用 synchronize()
    /// 系统会自动在合适的时机同步 UserDefaults
    func save() {
        // 无需操作，UserDefaults 会自动同步
    }
    
    /// T045: Set launch at login using SMAppService
    /// - Parameter enabled: 是否启用开机自启
    /// - Returns: 操作是否成功
    @discardableResult
    mutating func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        // 先检查当前状态
        let currentStatus = SMAppService.mainApp.status

        if enabled {
            // 如果已经是启用状态，无需操作
            if currentStatus == .enabled {
                defaults.set(true, forKey: Keys.launchAtLogin)
                return true
            }

            do {
                try SMAppService.mainApp.register()
                HubLogger.settings("Successfully registered for launch at login")
                defaults.set(true, forKey: Keys.launchAtLogin)
                return true
            } catch {
                HubLogger.error("Failed to register for launch at login", error: error)

                // 检查是否需要用户批准
                let newStatus = SMAppService.mainApp.status
                if newStatus == .requiresApproval {
                    HubLogger.settings("Requires user approval - opening System Settings")
                    // 打开系统设置的登录项页面
                    Self.openLoginItemsSettings()
                }

                // 回滚：更新为实际状态
                defaults.set(newStatus == .enabled, forKey: Keys.launchAtLogin)
                return false
            }
        } else {
            // 如果已经是禁用状态，无需操作
            if currentStatus == .notRegistered {
                defaults.set(false, forKey: Keys.launchAtLogin)
                return true
            }

            do {
                try SMAppService.mainApp.unregister()
                HubLogger.settings("Successfully unregistered from launch at login")
                defaults.set(false, forKey: Keys.launchAtLogin)
                return true
            } catch {
                HubLogger.error("Failed to unregister from launch at login", error: error)

                // 回滚：更新为实际状态
                let actualStatus = Self.isRegisteredForLaunchAtLogin()
                defaults.set(actualStatus, forKey: Keys.launchAtLogin)
                return false
            }
        }
    }

    /// 检查当前登录项状态
    static func isRegisteredForLaunchAtLogin() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    /// 检查是否需要用户批准
    static func requiresApproval() -> Bool {
        return SMAppService.mainApp.status == .requiresApproval
    }

    /// 打开系统设置的登录项页面
    static func openLoginItemsSettings() {
        // macOS 13+ 使用新的 URL scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings") {
            NSWorkspace.shared.open(url)
        }
    }
}
