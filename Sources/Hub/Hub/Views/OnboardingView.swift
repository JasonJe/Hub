//
//  OnboardingView.swift
//  Hub
//
//  首次使用引导视图
//

import SwiftUI

/// 顶部无圆角、底部有圆角的形状
struct NotchStyleShape: Shape {
    var bottomCornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let r = bottomCornerRadius
        
        // 从左上角开始
        path.move(to: CGPoint(x: 0, y: 0))
        // 顶边
        path.addLine(to: CGPoint(x: w, y: 0))
        // 右边
        path.addLine(to: CGPoint(x: w, y: h - r))
        // 右下圆角
        path.addArc(
            center: CGPoint(x: w - r, y: h - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        // 底边
        path.addLine(to: CGPoint(x: r, y: h))
        // 左下圆角
        path.addArc(
            center: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        // 左边
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

/// 首次使用引导视图
/// 显示动画提示用户如何使用 Hub
struct OnboardingView: View {
    /// 完成引导的回调
    var onComplete: () -> Void
    
    /// 动画状态
    @State private var arrowOffset: CGFloat = 0
    @State private var showContent: Bool = false
    @State private var glowOpacity: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // macOS 26 Liquid Glass - 极致透明玻璃效果
                ZStack {
                    // 核心：超透明材质模糊
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // 玻璃光泽层：轻柔顶部高光
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .white.opacity(0.1),
                                    .white.opacity(0.03),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.6)
                            )
                        )
                }
                
                // 主内容 - 添加顶部padding避免被刘海遮挡
                VStack(spacing: 12) {
                    // 动画箭头区域 - Liquid Glass 风格（参考松手暂存页面）
                    ZStack {
                        // 玻璃片背景
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                            )
                            // 顶部液态高光
                            .overlay(alignment: .top) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                            startPoint: .top,
                                            endPoint: UnitPoint(x: 0.5, y: 0.5)
                                        )
                                    )
                                    .frame(width: 56, height: 28)
                                    .clipped()
                            }
                        
                        // 外层脉冲光晕
                        Circle()
                            .stroke(
                                Color.blue.opacity(glowOpacity * 0.6),
                                lineWidth: 2.5
                            )
                            .frame(width: 62, height: 62)
                            .blur(radius: 2)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    glowOpacity = 0.9
                                }
                            }
                        
                        // 内层光晕 - 四层渐变
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(glowOpacity * 0.4),
                                        Color.blue.opacity(glowOpacity * 0.2),
                                        Color.blue.opacity(0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 6,
                                    endRadius: 19
                                )
                            )
                            .frame(width: 38, height: 38)
                        
                        // 箭头
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.blue)
                            .offset(y: arrowOffset)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    arrowOffset = -6
                                }
                            }
                    }
                    
                    // 文字说明
                    VStack(spacing: 5) {
                        Text("欢迎使用 Hub")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 2) {
                            Text("将鼠标移至刘海区域")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            Text("拖放文件即可暂存")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    
                    // 按钮 - Liquid Glass 风格
                    Button(action: {
                        onComplete()
                    }) {
                        Text("开始使用")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 38)
                            .background(
                                Capsule()
                                    .fill(.blue)
                                    .overlay(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                                    startPoint: .top,
                                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                                )
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 32) // 顶部留出刘海空间
                .padding(.bottom, 20) // 底部留出空间
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                        showContent = true
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(NotchStyleShape(bottomCornerRadius: 20))
            // 玻璃边框：轻柔高光边框
            .overlay(
                NotchStyleShape(bottomCornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.25),
                                .white.opacity(0.1),
                                .white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        OnboardingView(onComplete: {})
            .frame(width: 360, height: 280)
    }
}
