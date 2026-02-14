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
                // 纯黑背景，与Hub主页面一致
                Color.black
                
                // 主内容 - 添加顶部padding避免被刘海遮挡
                VStack(spacing: 12) {
                    // 动画箭头区域
                    ZStack {
                        // 外层光晕
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(glowOpacity),
                                        Color.blue.opacity(glowOpacity * 0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    glowOpacity = 0.6
                                }
                            }
                        
                        // 内层圆环
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 44, height: 44)
                        
                        // 箭头
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .offset(y: arrowOffset)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    arrowOffset = -5
                                }
                            }
                    }
                    
                    // 文字说明
                    VStack(spacing: 5) {
                        Text("欢迎使用 Hub")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 2) {
                            Text("将鼠标移至刘海区域")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("拖放文件即可暂存")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    // 按钮
                    Button(action: {
                        withAnimation(.easeIn(duration: 0.15)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onComplete()
                        }
                    }) {
                        Text("开始使用")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 32)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 28) // 顶部留出刘海空间
                .padding(.bottom, 20) // 底部留出空间
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 8)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                        showContent = true
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(NotchStyleShape(bottomCornerRadius: 24))
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
