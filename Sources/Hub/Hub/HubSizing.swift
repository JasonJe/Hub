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
    static let openHubSize: CGSize = .init(width: 360, height: 220)

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
