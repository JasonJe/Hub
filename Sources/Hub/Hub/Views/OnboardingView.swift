//
//  OnboardingView.swift
//  Hub
//
//  首次使用引导视图 - 适配版
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var arrowOffset: CGFloat = 0
    @State private var showContent: Bool = false
    @State private var glowOpacity: CGFloat = 0
    
    private var openedShape: NotchShape {
        NotchShape(
            topCornerRadius: HubMetrics.cornerRadiusInsets.opened.top,
            bottomCornerRadius: HubMetrics.cornerRadiusInsets.opened.bottom
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 1. 玻璃背景
                glassBackground
                
                // 2. 引导交互内容
                VStack(spacing: 20) {
                    onboardingIcon
                    
                    VStack(spacing: 10) {
                        Text("欢迎使用 Hub")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("将文件拖放至刘海区域即可暂存")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 30)
                    
                    startButton
                }
                // P3 修复：进一步增加顶部偏移，确保图标完全处于刘海下方的舒适区
                .padding(.top, max(52, (NSScreen.main?.safeAreaInsets.top ?? 0) + 24))
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }
            .frame(width: HubMetrics.openHubSize.width, height: HubMetrics.openHubSize.height)
            .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HubMetrics.sidePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { startAnimations() }
    }
    
    // MARK: - Subviews
    
    private var glassBackground: some View {
        ZStack {
            // 1. 次表面深度
            openedShape.fill(LinearGradient(colors: [Color.blue.opacity(0.05), Color.cyan.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            // 2. 核心材质
            openedShape.fill(.ultraThinMaterial)
            
            // 3. 全局光泽
            openedShape.fill(
                LinearGradient(
                    colors: [.white.opacity(0.1), .white.opacity(0.02), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .clipShape(openedShape)
        .overlay(
            ZStack {
                // 4. 折射边框
                openedShape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                
                // 5. 极锐利镜面高光
                openedShape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.3, y: 0.3)
                    ),
                    lineWidth: 0.5
                )
            }
        )
    }
    
    private var onboardingIcon: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
            
            Circle()
                .stroke(Color.blue.opacity(glowOpacity * 0.6), lineWidth: 2)
                .frame(width: 54, height: 54)
                .blur(radius: 2)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.blue)
                .offset(y: arrowOffset)
        }
    }
    
    private var startButton: some View {
        Button(action: onComplete) {
            Text("开始使用")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.85))
                .frame(width: 140, height: 38)
                .background(
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(RadialGradient(colors: [Color.blue.opacity(0.12), Color.clear], center: .center, startRadius: 0, endRadius: 70))
                        Capsule().fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .center))
                    }
                )
                .overlay(
                    Capsule().stroke(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1), .blue.opacity(0.15)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.9
            arrowOffset = -8
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }
    }
}
