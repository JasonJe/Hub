//
//  Logger.swift
//  Hub
//
//  统一日志记录工具
//

import Foundation
import os

/// Hub 统一日志记录器
/// 使用 os.log 替代 print，提供更好的日志管理和性能
enum HubLogger {
    
    /// 日志子系统标识符
    private static let subsystem = "com.jasonje.Hub"
    
    /// 应用程序日志分类
    private static let appLog = OSLog(subsystem: subsystem, category: "App")
    
    /// UI 相关日志分类
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    
    /// 窗口管理相关日志分类
    private static let windowLog = OSLog(subsystem: subsystem, category: "Window")
    
    /// 拖放操作相关日志分类
    private static let dragLog = OSLog(subsystem: subsystem, category: "Drag")
    
    /// 设置相关日志分类
    private static let settingsLog = OSLog(subsystem: subsystem, category: "Settings")
    
    /// 错误相关日志分类
    private static let errorLog = OSLog(subsystem: subsystem, category: "Error")
    
    // MARK: - Public Methods
    
    /// 记录应用程序级别日志（info 级别）
    static func log(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: appLog, type: type, message)
    }
    
    /// 记录 UI 相关日志
    static func ui(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: uiLog, type: type, message)
    }
    
    /// 记录窗口管理相关日志
    static func window(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: windowLog, type: type, message)
    }
    
    /// 记录拖放操作相关日志
    static func drag(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: dragLog, type: type, message)
    }
    
    /// 记录设置相关日志
    static func settings(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: settingsLog, type: type, message)
    }
    
    /// 记录错误日志
    static func error(_ message: String) {
        os_log("%{public}@", log: errorLog, type: .error, message)
    }
    
    /// 记录错误日志（带错误对象）
    static func error(_ message: String, error: Error) {
        os_log("%{public}@ - Error: %{public}@", log: errorLog, type: .error, message, error.localizedDescription)
    }
}