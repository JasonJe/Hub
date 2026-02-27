//
//  HubMetrics.swift
//  Hub
//
//  统一管理全应用的尺寸、布局、动画及设计常量
//

import SwiftUI

/// Hub 设计系统与度量标准
enum HubMetrics {
    // MARK: - 窗口与阴影尺寸
    
    /// 阴影内边距 - 确保发散阴影拥有极致的显示空间
    static let shadowPadding: CGFloat = 80
    
    /// 水平内边距 - 确保侧面阴影自然消失
    static let sidePadding: CGFloat = 60

    /// Hub 展开时的核心尺寸
    static let openHubSize: CGSize = .init(width: 360, height: 260)

    /// 窗口总尺寸 (包含内容 + 阴影缓冲区)
    static var windowSize: CGSize {
        .init(
            width: openHubSize.width + sidePadding * 2,
            height: openHubSize.height + shadowPadding
        )
    }

    // MARK: - 圆角配置
    
    /// macOS 26 Liquid Glass 风格圆角
    static let cornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (
        opened: (top: 16, bottom: 28),
        closed: (top: 0, bottom: 20)
    )

    // MARK: - 悬浮球尺寸
    
    /// 悬浮球视觉半径（球体本身的半径）
    static let orbVisualRadius: CGFloat = 18
    
    /// 悬浮球视觉直径
    static let orbVisualSize: CGFloat = 36
    
    /// 悬浮球窗口尺寸（包含边距）
    static let orbWindowSize: CGFloat = 61

    // MARK: - 文件项图标尺寸
    
    /// 刘海模式文件项图标尺寸
    static let dynamicIslandItemSize: CGFloat = 52
    
    /// 悬浮球模式文件项图标尺寸
    static let floatingOrbItemSize: CGFloat = 52
    
    /// 刘海模式文件项总高度（图标 + 文字）
    static let dynamicIslandItemHeight: CGFloat = 70
    
    /// 悬浮球模式文件项总高度
    static let floatingOrbItemHeight: CGFloat = 70

    // MARK: - 布局微调
    
    static let notchWidthCompensation: CGFloat = 0
    static let closedHubExtraWidth: CGFloat = 0
    static let deleteButtonSize: CGFloat = 18
    static let deleteButtonHitAreaPadding: CGFloat = 6
    static let dragThreshold: CGFloat = 3.0

    // MARK: - 动画参数 (原 AnimationConstants)
    
    enum Animation {
        /// Hub 展开动画
        static let openResponse: Double = 0.5
        static let openDamping: Double = 0.75
        
        /// Hub 收起动画
        static let closeResponse: Double = 0.4
        static let closeDamping: Double = 0.85
        
        /// 状态切换
        static let transitionDuration: Double = 0.25
        
        /// 成功反馈
        static let dropSuccessResponse: Double = 0.35
        static let dropSuccessDamping: Double = 0.7
        static let dropSuccessHoldDuration: Double = 1.5
        static let dropSuccessCloseDelay: Double = 1.0
        
        /// 悬停效果
        static let hoverDuration: Double = 0.3
        
        /// 悬停动画（快速响应）
        static let hoverResponse: Double = 0.3
        static let hoverDamping: Double = 0.7
        
        /// 弹出动画（中等速度）
        static let popoverResponse: Double = 0.35
        static let popoverDamping: Double = 0.75
        
        /// 切换动画（快速）
        static let toggleResponse: Double = 0.25
        static let toggleDamping: Double = 0.8
        
        /// 对话框动画
        static let dialogResponse: Double = 0.35
        static let dialogDamping: Double = 0.85
        
        /// 便捷方法：获取悬停动画
        static func hover() -> SwiftUI.Animation {
            .spring(response: hoverResponse, dampingFraction: hoverDamping)
        }
        
        /// 便捷方法：获取弹出动画
        static func popover() -> SwiftUI.Animation {
            .spring(response: popoverResponse, dampingFraction: popoverDamping)
        }
        
        /// 便捷方法：获取切换动画
        static func toggle() -> SwiftUI.Animation {
            .spring(response: toggleResponse, dampingFraction: toggleDamping)
        }
        
        /// 便捷方法：获取对话框动画
        static func dialog() -> SwiftUI.Animation {
            .spring(response: dialogResponse, dampingFraction: dialogDamping)
        }
    }

    // MARK: - 内部布局参数 (原 LayoutConstants)
    
    enum Layout {
        static let hubHorizontalPadding: CGFloat = 12
        static let hubVerticalPadding: CGFloat = 12
        static let dragOverlayTopPadding: CGFloat = 24
        static let contentSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        
        /// 图标尺寸
        static let dragIconCircleSize: CGFloat = 70
        static let dragIconInnerCircleSize: CGFloat = 48
        static let successIconCircleSize: CGFloat = 70
        static let successIconCheckmarkSize: CGFloat = 28
    }

    // MARK: - 辅助函数
    
    @MainActor
    static func getClosedHubSize() -> CGSize {
        var notchHeight: CGFloat = 32
        var notchWidth: CGFloat = 220
        guard let screen = NSScreen.main else { return .init(width: notchWidth, height: notchHeight) }

        if let topLeft = screen.auxiliaryTopLeftArea?.width,
           let topRight = screen.auxiliaryTopRightArea?.width {
            notchWidth = screen.frame.width - topLeft - topRight + notchWidthCompensation
        }

        if screen.safeAreaInsets.top > 0 {
            notchHeight = screen.safeAreaInsets.top
        } else {
            notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        }

        return .init(width: max(220, notchWidth + closedHubExtraWidth), height: notchHeight)
    }
}

// MARK: - 颜色系统

/// Hub 统一颜色系统 - 液态玻璃风格
enum HubColors {
    // MARK: - 基础色
    
    /// 玻璃基底色 - 蓝色调
    static let glassBase = Color.blue.opacity(0.05)
    
    /// 玻璃强调色 - 青色调
    static let glassAccent = Color.cyan.opacity(0.02)
    
    /// 玻璃渐变
    static var glassGradient: LinearGradient {
        LinearGradient(
            colors: [glassBase, glassAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - 边框色
    
    /// 边框亮色
    static let borderLight = Color.white.opacity(0.4)
    
    /// 边框暗色
    static let borderDim = Color.white.opacity(0.1)
    
    /// 边框透明
    static let borderClear = Color.clear
    
    /// 边框微光
    static let borderSubtle = Color.white.opacity(0.05)
    
    /// 边框渐变
    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [borderLight, borderDim, borderClear, borderSubtle],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - 高光色
    
    /// 镜面高光亮
    static let highlightBright = Color.white.opacity(0.8)
    
    /// 镜面高光中
    static let highlightMedium = Color.white.opacity(0.2)
    
    /// 液态高光
    static let highlightLiquid = Color.white.opacity(0.12)
    
    /// 悬停高光
    static let highlightHover = Color.white.opacity(0.35)
    
    // MARK: - 阴影色
    
    /// 阴影主色
    static let shadowPrimary = Color.black.opacity(0.15)
    
    /// 阴影次级
    static let shadowSecondary = Color.black.opacity(0.1)
    
    /// 阴影微妙
    static let shadowSubtle = Color.black.opacity(0.05)
    
    // MARK: - 悬浮球专用色
    
    /// 悬浮球基底
    static let orbBase = Color.blue.opacity(0.08)
    
    /// 悬浮球强调
    static let orbAccent = Color.cyan.opacity(0.04)
    
    /// 悬浮球底部折射
    static let orbBottomRefraction = Color.blue.opacity(0.12)
    
    /// 悬浮球边框亮
    static let orbBorderLight = Color.white.opacity(0.5)
    
    /// 悬浮球边框暗
    static let orbBorderDim = Color.white.opacity(0.2)
    
    /// 悬浮球阴影
    static let orbShadowPrimary = Color.black.opacity(0.08)
    
    /// 悬浮球阴影微
    static let orbShadowSubtle = Color.black.opacity(0.12)
}
