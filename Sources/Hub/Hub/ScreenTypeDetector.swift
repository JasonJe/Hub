//
//  ScreenTypeDetector.swift
//  Hub
//
//  屏幕类型检测器 - 自动识别刘海屏和普通屏
//

import Cocoa
import os

/// 屏幕类型枚举
enum ScreenType: Equatable, CustomStringConvertible {
    case notch        // 刘海屏
    case regular      // 普通屏
    
    var description: String {
        switch self {
        case .notch:
            return "刘海屏"
        case .regular:
            return "普通屏"
        }
    }
}

/// 屏幕类型检测器
@MainActor
final class ScreenTypeDetector {
    
    // MARK: - Properties
    
    private var cachedScreenType: ScreenType?
    private var cachedScreen: NSScreen?
    
    /// 用于测试的模拟屏幕类型
    var mockType: ScreenType?
    
    // 已知刘海屏尺寸列表 (宽高比和最小高度)
    private let notchScreenProfiles: [(width: CGFloat, height: CGFloat, minHeight: CGFloat)] = [
        (width: 3456, height: 2234, minHeight: 100), // 14" MacBook Pro
        (width: 3024, height: 1964, minHeight: 100), // 14" MacBook Pro (部分分辨率)
        (width: 1728, height: 1117, minHeight: 32),  // 14" MacBook Pro 缩放模式
    ]
    
    // MARK: - Public Methods
    
    /// 获取系统设置中配置的主显示屏（带菜单栏的屏幕）
    /// NSScreen.screens 数组中第一个屏幕就是系统设置里配置的主显示屏
    func getMainScreen() -> NSScreen? {
        let screens = NSScreen.screens
        
        // 第一个屏幕是系统设置中配置的主显示屏（带菜单栏）
        if let primaryScreen = screens.first {
            HubLogger.screen("主显示屏: \(primaryScreen.frame), 所有屏幕: \(screens.map { $0.frame })")
            return primaryScreen
        }
        
        return nil
    }
    
    /// 获取所有屏幕
    func getAllScreens() -> [NSScreen] {
        return NSScreen.screens
    }
    
    /// 获取主屏幕 Frame
    func getMainScreenFrame() -> CGRect {
        guard let screen = getMainScreen() else {
            return CGRect(x: 0, y: 0, width: 1440, height: 900)
        }
        return screen.frame
    }
    
    /// 检测是否有刘海
    func hasNotch() -> Bool {
        // 如果有缓存且屏幕未变化，返回缓存值
        if let cached = cachedScreenType,
           let cachedScreen = cachedScreen,
           cachedScreen === getMainScreen() {
            return cached == .notch
        }
        
        guard let screen = getMainScreen() else {
            return false
        }
        
        // 获取屏幕信息用于调试
        let frame = screen.frame
        HubLogger.screen("检测屏幕 - Frame: \(frame)")
        
        // 使用多种方法综合判断
        let hasNotchBySafeArea = checkNotchBySafeArea(screen)
        let hasNotchBySize = checkNotchBySize(screen)
        let hasNotchByAPI = checkNotchByPrivateAPI(screen)
        
        // 优先使用安全区域检测（最准确）
        // 如果安全区域检测到刘海，直接返回 true
        if hasNotchBySafeArea {
            cachedScreenType = .notch
            cachedScreen = screen
            HubLogger.screen("检测到刘海屏 (SafeArea)")
            return true
        }
        
        // 如果尺寸或 API 检测到刘海，也认为是刘海屏
        let result = hasNotchBySize || hasNotchByAPI
        
        cachedScreenType = result ? .notch : .regular
        cachedScreen = screen
        
        HubLogger.screen("刘海检测结果: \(result ? "有刘海" : "无刘海"), " +
                      "SafeArea: \(hasNotchBySafeArea), " +
                      "Size: \(hasNotchBySize), " +
                      "API: \(hasNotchByAPI)")
        
        return result
    }
    
    /// 检测主屏幕类型
    func detectMainScreenType() -> ScreenType {
        // 检查是否有内存模拟设置（用于测试）
        if let mock = mockType {
            HubLogger.screen("使用内存模拟屏幕类型: \(mock)")
            return mock
        }

        // 使用综合检测方法
        return hasNotch() ? .notch : .regular
    }
    
    /// 基于安全区域检测刘海
    func checkNotchBySafeArea(_ screen: NSScreen) -> Bool {
        // 1. 最准确的方法：检查是否有辅助区域（这是 Apple 为刘海屏设计的 API）
        if screen.auxiliaryTopLeftArea != nil || screen.auxiliaryTopRightArea != nil {
            HubLogger.screen("检测到辅助区域 (Notch confirmed)")
            return true
        }

        // 2. 备选方案：检查安全区域高度
        // macOS 12+ 支持 safeAreaInsets
        if #available(macOS 12.0, *) {
            let insets = screen.safeAreaInsets
            HubLogger.screen("SafeArea insets - top: \(insets.top), left: \(insets.left), bottom: \(insets.bottom), right: \(insets.right)")
            
            // 普通屏幕的菜单栏高度通常在 24pt 左右
            // 刘海屏的菜单栏/安全区域高度通常在 32pt 或更高
            // 这里使用 30pt 作为阈值，以排除普通菜单栏误判
            return insets.top > 30
        }
        return false
    }
    
    /// 基于屏幕尺寸检测刘海
    func checkNotchBySize(_ screen: NSScreen) -> Bool {
        let frame = screen.frame
        let screenWidth = frame.width
        let screenHeight = frame.height
        
        HubLogger.screen("屏幕尺寸 - width: \(screenWidth), height: \(screenHeight), aspect: \(screenWidth/screenHeight)")
        
        // 检查是否匹配已知的刘海屏尺寸
        for profile in notchScreenProfiles {
            let widthMatch = abs(screenWidth - profile.width) < 10
            let heightMatch = abs(screenHeight - profile.height) < 10
            if widthMatch && heightMatch {
                HubLogger.screen("匹配刘海屏尺寸: \(profile.width)x\(profile.height)")
                return true
            }
        }
        
        // 通过宽高比辅助判断 (刘海屏通常是较宽的屏幕，约 16:10 或更宽)
        let aspectRatio = screenWidth / screenHeight
        
        // MacBook Pro 14/16 寸刘海屏的宽高比约为 1.55
        // 传统 16:10 屏幕的宽高比约为 1.6
        // 使用更宽的阈值来区分
        if aspectRatio > 1.5 && screenHeight > 1000 {
            // 高分辨率宽屏可能是刘海屏
            // 但我们需要更多判断条件
            HubLogger.screen("可能是刘海屏 (宽高比: \(aspectRatio))，需要进一步确认")
        }
        
        return false
    }
    
    /// 使用私有 API 检测刘海
    private func checkNotchByPrivateAPI(_ screen: NSScreen) -> Bool {
        // 通过 NSScreen 的 deviceDescription 获取更多信息
        let description = screen.deviceDescription
        
        // 检查是否有额外的显示区域信息
        if let auxiliaryInfo = description[NSDeviceDescriptionKey("NSScreenAuxiliaryInfo")] as? [String: Any] {
            // 辅助信息中可能包含刘海相关信息
            if let displayMode = auxiliaryInfo["DisplayMode"] as? [String: Any] {
                // 检查显示模式信息
                if let hasNotch = displayMode["HasNotch"] as? Bool {
                    return hasNotch
                }
            }
        }
        
        return false
    }
    
    /// 触发屏幕检测更新
    func triggerScreenCheck() {
        cachedScreenType = nil
        cachedScreen = nil
        
        NotificationCenter.default.post(
            name: .screenConfigurationChanged,
            object: nil,
            userInfo: ["type": detectMainScreenType()]
        )
    }
    
    /// 清除缓存
    func clearCache() {
        cachedScreenType = nil
        cachedScreen = nil
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let screenConfigurationChanged = Notification.Name("screenConfigurationChanged")
}

// MARK: - Logger Extension

extension HubLogger {
    /// 屏幕相关日志分类
    private static let screenLog = OSLog(subsystem: "com.jasonje.Hub", category: "Screen")
    
    static func screen(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: screenLog, type: type, message)
    }
}
