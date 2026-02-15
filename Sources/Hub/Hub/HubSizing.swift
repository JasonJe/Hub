//
//  HubSizing.swift
//  Hub
//
//  参考 boring.notch 的 sizing/matters.swift
//

import Foundation
import SwiftUI

// MARK: - Hub 尺寸和布局常量

/// Hub 尺寸和布局常量命名空间
/// 使用 enum 作为命名空间，避免全局变量污染
enum HubMetrics {
    // MARK: - 尺寸常量

    /// 阴影内边距 - 用于扩展窗口高度以容纳底部阴影效果
    /// 来源：boring.notch 的阴影效果设计
    static let shadowPadding: CGFloat = 20

    /// Hub 展开时的尺寸
    /// 宽度 360pt：适合显示 4 列文件图标 (64pt * 4 + 间距 + 内边距)
    /// 高度 220pt：容纳标题栏、文件网格、底部操作栏
    static let openHubSize: CGSize = .init(width: 360, height: 220)

    /// 窗口总尺寸 - 包含内容区和阴影区
    static var windowSize: CGSize {
        .init(width: openHubSize.width, height: openHubSize.height + shadowPadding)
    }

    // MARK: - 圆角配置

    /// macOS 26 Liquid Glass 风格圆角配置
    /// 更大的圆角，更圆润的现代设计
    /// - opened: 展开状态下，顶部圆角 (16pt) + 底部大圆角 (28pt)
    /// - closed: 闭合状态下，顶部无圆角 (贴合刘海) + 底部圆角 (20pt)
    static let cornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (
        opened: (top: 16, bottom: 28),
        closed: (top: 0, bottom: 20)
    )

    // MARK: - 布局调整常量

    /// 刘海宽度补偿值
    /// 用于补偿刘海两侧安全区域计算的误差，使 Hub 宽度与刘海完美贴合
    static let notchWidthCompensation: CGFloat = 0

    /// Hub 闭合状态下额外宽度
    /// 使 Hub 宽度与刘海对齐，不超出
    static let closedHubExtraWidth: CGFloat = 0

    // MARK: - UI 组件尺寸

    /// 删除按钮尺寸（直径）
    /// 用于文件项右上角的删除按钮，需要与 NSView 层的 hitTest 区域同步
    static let deleteButtonSize: CGFloat = 18

    /// 删除按钮点击区域扩展
    /// 为了更容易点击，hitTest 区域略大于实际按钮尺寸
    static let deleteButtonHitAreaPadding: CGFloat = 6

    // MARK: - 交互参数

    /// 拖拽触发阈值（像素）- 超过此距离才开始拖拽操作
    /// 较小的值让拖拽更容易触发，较大的值可以避免误触
    static let dragThreshold: CGFloat = 3.0

    // MARK: - 屏幕尺寸辅助函数

    /// 获取主屏幕的完整 frame
    /// - Returns: 主屏幕 frame，如果无法获取则返回 nil
    @MainActor
    static func getScreenFrame() -> CGRect? {
        guard let screen = NSScreen.main else { return nil }
        return screen.frame
    }

    /// 获取闭合状态下的 Hub 尺寸（基于设备刘海/灵动岛）
    ///
    /// 刘海宽度计算：
    /// - 使用 `auxiliaryTopLeftArea` 和 `auxiliaryTopRightArea` 获取刘海两侧的安全区域
    /// - 屏幕宽度减去两侧安全区域即为刘海宽度
    ///
    /// 刘海高度计算：
    /// - 优先使用 `safeAreaInsets.top`（适用于带刘海的 MacBook）
    /// - 回退到菜单栏高度计算（适用于外接显示器）
    ///
    /// - Returns: 闭合状态下的 CGSize，宽度略大于刘海，高度与刘海一致
    @MainActor
    static func getClosedHubSize() -> CGSize {
        // 默认值：标准刘海尺寸
        var notchHeight: CGFloat = 32
        var notchWidth: CGFloat = 220

        guard let screen = NSScreen.main else {
            return .init(width: notchWidth, height: notchHeight)
        }

        // 计算刘海宽度：屏幕宽度 - 刘海两侧安全区域 + 补偿值
        if let topLeft = screen.auxiliaryTopLeftArea?.width,
           let topRight = screen.auxiliaryTopRightArea?.width {
            notchWidth = screen.frame.width - topLeft - topRight + notchWidthCompensation
        }

        // 计算刘海高度
        if screen.safeAreaInsets.top > 0 {
            // 带刘海的 MacBook：使用安全区域顶部边距
            notchHeight = screen.safeAreaInsets.top
        } else {
            // 外接显示器：使用菜单栏高度
            notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        }

        // idle 状态：宽度略宽于刘海，高度与刘海一致
        return .init(width: max(220, notchWidth + closedHubExtraWidth), height: notchHeight)
    }
}

// MARK: - 向后兼容的全局别名（已废弃，请使用 HubMetrics）

/// 向后兼容的全局变量别名
/// - Warning: 已废弃，请使用 HubMetrics.shadowPadding
@available(*, deprecated, message: "请使用 HubMetrics.shadowPadding")
let shadowPadding: CGFloat = HubMetrics.shadowPadding

/// 向后兼容的全局变量别名
/// - Warning: 已废弃，请使用 HubMetrics.openHubSize
@available(*, deprecated, message: "请使用 HubMetrics.openHubSize")
let openHubSize: CGSize = HubMetrics.openHubSize

/// 向后兼容的全局变量别名
/// - Warning: 已废弃，请使用 HubMetrics.windowSize
@available(*, deprecated, message: "请使用 HubMetrics.windowSize")
var windowSize: CGSize { HubMetrics.windowSize }

/// 向后兼容的全局变量别名
/// - Warning: 已废弃，请使用 HubMetrics.cornerRadiusInsets
@available(*, deprecated, message: "请使用 HubMetrics.cornerRadiusInsets")
let cornerRadiusInsets = HubMetrics.cornerRadiusInsets

/// 向后兼容的全局函数别名
/// - Warning: 已废弃，请使用 HubMetrics.getScreenFrame()
@available(*, deprecated, message: "请使用 HubMetrics.getScreenFrame()")
@MainActor func getScreenFrame() -> CGRect? { HubMetrics.getScreenFrame() }

/// 向后兼容的全局函数别名
/// - Warning: 已废弃，请使用 HubMetrics.getClosedHubSize()
@available(*, deprecated, message: "请使用 HubMetrics.getClosedHubSize()")
@MainActor func getClosedHubSize() -> CGSize { HubMetrics.getClosedHubSize() }
