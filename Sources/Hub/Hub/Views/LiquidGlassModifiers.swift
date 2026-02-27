//
//  LiquidGlassModifiers.swift
//  Hub
//
//  可复用的液态玻璃背景修饰符 - 统一液态玻璃视觉效果
//

import SwiftUI

// MARK: - 液态玻璃背景修饰符

/// 液态玻璃背景修饰符 - 为任意形状添加液态玻璃效果
struct LiquidGlassBackgroundModifier: ViewModifier {
    let shape: AnyShape
    let shimmerOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. 内部深度：极淡的次表面色彩
                    shape.fill(HubColors.glassGradient)
                    
                    // 2. 核心材质：极致通透
                    shape.fill(.ultraThinMaterial)
                    
                    // 3. 表面流光
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
            )
            .clipShape(shape)
            .overlay(
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
            )
            // 核心阴影系统
            .shadow(color: HubColors.shadowPrimary, radius: 25, x: 0, y: 12)
            .shadow(color: HubColors.shadowSecondary, radius: 10, x: 0, y: 5)
            .shadow(color: HubColors.shadowSubtle, radius: 2, x: 0, y: 1)
    }
}

// MARK: - 悬浮球液态玻璃修饰符

/// 悬浮球液态玻璃修饰符 - 专门为圆形悬浮球设计
struct OrbLiquidGlassModifier: ViewModifier {
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 液态玻璃背景 - 多层材质叠加
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [HubColors.orbBase, HubColors.orbAccent, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(Circle().fill(.ultraThinMaterial))
                    
                    // 顶部液态高光
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [HubColors.highlightHover, HubColors.highlightMedium, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: size * 0.55)
                        .clipped()
                    
                    // 底部折射效果
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, HubColors.orbBottomRefraction],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // 精致边框
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [HubColors.orbBorderLight, HubColors.orbBorderDim],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .frame(width: size, height: size)
            )
            // 双层阴影
            .shadow(color: HubColors.orbShadowPrimary, radius: 6, x: 0, y: 3)
            .shadow(color: HubColors.orbShadowSubtle, radius: 2, x: 0, y: 1)
    }
}

// MARK: - 便捷扩展

extension View {
    /// 添加液态玻璃背景效果
    /// - Parameters:
    ///   - shape: 形状类型
    ///   - shimmerOffset: 流光偏移量（-1.0 ~ 1.5）
    func liquidGlassBackground<S: Shape>(_ shape: S, shimmerOffset: CGFloat = -1.0) -> some View {
        modifier(LiquidGlassBackgroundModifier(shape: AnyShape(shape), shimmerOffset: shimmerOffset))
    }
    
    /// 添加悬浮球液态玻璃效果
    /// - Parameter size: 悬浮球尺寸
    func orbLiquidGlass(size: CGFloat = HubMetrics.orbVisualSize) -> some View {
        modifier(OrbLiquidGlassModifier(size: size))
    }
}

// MARK: - AnyShape 类型擦除

/// 类型擦除的形状包装器
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - 预览

#if DEBUG
#Preview("液态玻璃效果") {
    ZStack {
        Color.gray.opacity(0.3)
        
        VStack(spacing: 40) {
            // 矩形液态玻璃
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .frame(width: 200, height: 100)
                .liquidGlassBackground(RoundedRectangle(cornerRadius: 16))
            
            // 圆形悬浮球效果
            Circle()
                .fill(.clear)
                .frame(width: HubMetrics.orbVisualSize, height: HubMetrics.orbVisualSize)
                .orbLiquidGlass()
            
            // Notch 形状液态玻璃
            NotchShape(topCornerRadius: 16, bottomCornerRadius: 28)
                .fill(.clear)
                .frame(width: 300, height: 150)
                .liquidGlassBackground(NotchShape(topCornerRadius: 16, bottomCornerRadius: 28))
        }
    }
    .frame(width: 400, height: 400)
}
#endif
