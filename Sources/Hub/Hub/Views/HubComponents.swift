//
//  HubComponents.swift
//  Hub
//
//  可复用的 Hub 组件 - 提取独立组件减少视图层级嵌套
//

import SwiftUI

// MARK: - Hub 玻璃背景视图

/// 独立的玻璃背景组件 - 减少主视图层级嵌套
struct HubGlassBackground: View {
    let shape: NotchShape
    let shimmerOffset: CGFloat
    
    var body: some View {
        ZStack {
            // 1. 内部深度：极淡的次表面色彩
            shape.fill(HubColors.glassGradient)
            
            // 2. 核心材质：极致通透
            shape.fill(.ultraThinMaterial)
            
            // 3. 表面流光：使用 plusLighter 增强亮度
            shape
                .fill(
                    LinearGradient(
                        colors: [.clear, HubColors.highlightLiquid, .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                    )
                )
                .blendMode(.plusLighter)
        }
    }
}

// MARK: - Hub 边框覆盖层

/// 独立的边框覆盖组件
struct HubBorderOverlay: View {
    let shape: NotchShape
    
    var body: some View {
        ZStack {
            // 4. 基础折射边框
            shape.stroke(HubColors.borderGradient, lineWidth: 1.2)
            
            // 5. 极锐利镜面高光
            shape.stroke(
                LinearGradient(
                    colors: [HubColors.highlightBright, HubColors.highlightMedium, .clear],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.3, y: 0.3)
                ),
                lineWidth: 0.5
            )
        }
    }
}

// MARK: - Hub 阴影修饰符

/// Hub 阴影修饰符
struct HubShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: HubColors.shadowPrimary, radius: 25, x: 0, y: 12)
            .shadow(color: HubColors.shadowSecondary, radius: 10, x: 0, y: 5)
            .shadow(color: HubColors.shadowSubtle, radius: 2, x: 0, y: 1)
    }
}

extension View {
    /// 应用 Hub 标准阴影
    func hubShadow() -> some View {
        modifier(HubShadowModifier())
    }
}

// MARK: - Hub 完整玻璃容器

/// 完整的玻璃容器组件 - 整合背景、边框、阴影
struct HubGlassContainer<Content: View>: View {
    let shape: NotchShape
    let shimmerOffset: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .background(HubGlassBackground(shape: shape, shimmerOffset: shimmerOffset))
            .clipShape(shape)
            .overlay(HubBorderOverlay(shape: shape))
            .hubShadow()
    }
}

// MARK: - 空状态视图

/// 空状态提示视图
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: HubMetrics.Layout.contentSpacing) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            
            VStack(spacing: HubMetrics.Layout.textSpacing) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 预览

#if DEBUG
#Preview("Hub 组件") {
    ZStack {
        Color.gray.opacity(0.3)
        
        VStack(spacing: 40) {
            // 玻璃背景
            HubGlassBackground(
                shape: NotchShape(topCornerRadius: 16, bottomCornerRadius: 28),
                shimmerOffset: -1.0
            )
            .frame(width: 300, height: 150)
            .overlay(
                HubBorderOverlay(shape: NotchShape(topCornerRadius: 16, bottomCornerRadius: 28))
            )
            .hubShadow()
            
            // 完整容器
            HubGlassContainer(
                shape: NotchShape(topCornerRadius: 16, bottomCornerRadius: 28),
                shimmerOffset: 0.5
            ) {
                VStack {
                    Text("Hub Content")
                        .font(.headline)
                    Text("示例内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 150)
            }
            
            // 空状态
            EmptyStateView(
                title: "暂无文件",
                subtitle: "拖拽文件到此处暂存",
                icon: "tray"
            )
            .frame(width: 200, height: 100)
        }
    }
    .frame(width: 400, height: 500)
}
#endif
