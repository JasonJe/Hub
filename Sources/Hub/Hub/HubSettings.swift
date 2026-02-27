//
//  HubSettings.swift
//  Hub
//
//  T041 & T042: Hub settings with UserDefaults persistence
//

import Foundation
import ServiceManagement
import AppKit

// MARK: - 错误类型

/// Hub 设置相关错误
enum HubSettingsError: LocalizedError {
    case launchAtLoginRegistrationFailed(underlyingError: Error?)
    case launchAtLoginUnregistrationFailed(underlyingError: Error?)
    case requiresUserApproval
    
    var errorDescription: String? {
        switch self {
        case .launchAtLoginRegistrationFailed(let error):
            return "无法注册开机自启: \(error?.localizedDescription ?? "未知错误")"
        case .launchAtLoginUnregistrationFailed(let error):
            return "无法取消开机自启: \(error?.localizedDescription ?? "未知错误")"
        case .requiresUserApproval:
            return "需要在系统设置中手动批准"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .launchAtLoginRegistrationFailed, .launchAtLoginUnregistrationFailed:
            return "请检查系统权限设置，或尝试重启应用"
        case .requiresUserApproval:
            return "已在系统设置中打开登录项页面，请在列表中找到 Hub 并启用"
        }
    }
}

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
    
    // MARK: - 内存缓存
    
    /// 内存缓存 - 减少频繁的磁盘 IO
    private static var cache: [String: Any] = [:]
    
    /// 清除缓存（用于测试或重置）
    static func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Properties
    
    var launchAtLogin: Bool {
        get {
            if let cached = Self.cache[Keys.launchAtLogin] as? Bool {
                return cached
            }
            let value = defaults.bool(forKey: Keys.launchAtLogin)
            Self.cache[Keys.launchAtLogin] = value
            return value
        }
        set {
            Self.cache[Keys.launchAtLogin] = newValue
            defaults.set(newValue, forKey: Keys.launchAtLogin)
        }
    }
    
    var soundEnabled: Bool {
        get {
            if let cached = Self.cache[Keys.soundEnabled] as? Bool {
                return cached
            }
            // Default to true if not set
            let value = defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled)
            Self.cache[Keys.soundEnabled] = value
            return value
        }
        set {
            Self.cache[Keys.soundEnabled] = newValue
            defaults.set(newValue, forKey: Keys.soundEnabled)
        }
    }
    
    /// 模式：灵动岛 / 悬浮球
    var mode: HubMode {
        get {
            if let cached = Self.cache[Keys.mode] as? HubMode {
                return cached
            }
            let value: HubMode
            if let rawValue = defaults.string(forKey: Keys.mode),
               let mode = HubMode(rawValue: rawValue) {
                value = mode
            } else {
                value = .dynamicIsland
            }
            Self.cache[Keys.mode] = value
            return value
        }
        set {
            Self.cache[Keys.mode] = newValue
            defaults.set(newValue.rawValue, forKey: Keys.mode)
        }
    }
    
    /// 悬浮模式下的位置
    var position: HubPosition {
        get {
            if let cached = Self.cache[Keys.position] as? HubPosition {
                return cached
            }
            let value: HubPosition
            if let rawValue = defaults.string(forKey: Keys.position),
               let position = HubPosition(rawValue: rawValue) {
                value = position
            } else {
                value = .right
            }
            Self.cache[Keys.position] = value
            return value
        }
        set {
            Self.cache[Keys.position] = newValue
            defaults.set(newValue.rawValue, forKey: Keys.position)
        }
    }
    
    /// 悬浮模式下的自定义位置 X
    var floatingX: CGFloat {
        get {
            if let cached = Self.cache[Keys.floatingX] as? CGFloat {
                return cached
            }
            let value = CGFloat(defaults.double(forKey: Keys.floatingX))
            Self.cache[Keys.floatingX] = value
            return value
        }
        set {
            Self.cache[Keys.floatingX] = newValue
            defaults.set(Double(newValue), forKey: Keys.floatingX)
        }
    }
    
    /// 悬浮模式下的自定义位置 Y
    var floatingY: CGFloat {
        get {
            if let cached = Self.cache[Keys.floatingY] as? CGFloat {
                return cached
            }
            let value = CGFloat(defaults.double(forKey: Keys.floatingY))
            Self.cache[Keys.floatingY] = value
            return value
        }
        set {
            Self.cache[Keys.floatingY] = newValue
            defaults.set(Double(newValue), forKey: Keys.floatingY)
        }
    }

    /// 是否已完成首次引导
    var hasCompletedOnboarding: Bool {
        get {
            if let cached = Self.cache[Keys.hasCompletedOnboarding] as? Bool {
                return cached
            }
            let value = defaults.bool(forKey: Keys.hasCompletedOnboarding)
            Self.cache[Keys.hasCompletedOnboarding] = value
            return value
        }
        set {
            Self.cache[Keys.hasCompletedOnboarding] = newValue
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    // MARK: - Methods
    
    /// Save settings - Apple 文档说明不需要显式调用 synchronize()
    /// 系统会自动在合适的时机同步 UserDefaults
    func save() {
        // 无需操作，UserDefaults 会自动同步
    }
    
    /// T045: 设置开机自启（简单版本，返回布尔值）
    /// - Parameter enabled: 是否启用开机自启
    /// - Returns: 操作是否成功
    @discardableResult
    mutating func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        let result = setLaunchAtLoginWithDetail(enabled)
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// 设置开机自启（详细版本，返回 Result 类型）
    /// - Parameter enabled: 是否启用开机自启
    /// - Returns: Result 类型，成功返回 true，失败返回具体错误
    mutating func setLaunchAtLoginWithDetail(_ enabled: Bool) -> Result<Bool, HubSettingsError> {
        // 先检查当前状态
        let currentStatus = SMAppService.mainApp.status

        if enabled {
            // 如果已经是启用状态，无需操作
            if currentStatus == .enabled {
                defaults.set(true, forKey: Keys.launchAtLogin)
                return .success(true)
            }

            do {
                try SMAppService.mainApp.register()
                HubLogger.settings("Successfully registered for launch at login")
                defaults.set(true, forKey: Keys.launchAtLogin)
                return .success(true)
            } catch {
                HubLogger.error("Failed to register for launch at login", error: error)

                // 检查是否需要用户批准
                let newStatus = SMAppService.mainApp.status
                if newStatus == .requiresApproval {
                    HubLogger.settings("Requires user approval - opening System Settings")
                    // 打开系统设置的登录项页面
                    Self.openLoginItemsSettings()
                    // 回滚：更新为实际状态
                    defaults.set(false, forKey: Keys.launchAtLogin)
                    return .failure(.requiresUserApproval)
                }

                // 回滚：更新为实际状态
                defaults.set(newStatus == .enabled, forKey: Keys.launchAtLogin)
                return .failure(.launchAtLoginRegistrationFailed(underlyingError: error))
            }
        } else {
            // 如果已经是禁用状态，无需操作
            if currentStatus == .notRegistered {
                defaults.set(false, forKey: Keys.launchAtLogin)
                return .success(true)
            }

            do {
                try SMAppService.mainApp.unregister()
                HubLogger.settings("Successfully unregistered from launch at login")
                defaults.set(false, forKey: Keys.launchAtLogin)
                return .success(true)
            } catch {
                HubLogger.error("Failed to unregister from launch at login", error: error)

                // 回滚：更新为实际状态
                let actualStatus = Self.isRegisteredForLaunchAtLogin()
                defaults.set(actualStatus, forKey: Keys.launchAtLogin)
                return .failure(.launchAtLoginUnregistrationFailed(underlyingError: error))
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
