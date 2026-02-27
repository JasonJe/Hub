//
//  HubDragOverlay.swift
//  Hub
//
//  升级版：液态等离子脉冲效果
//

import SwiftUI

struct HubDragOverlay: View {
    let dropSuccess: Bool
    let pulseOpacity: CGFloat
    let hubState: HubState
    let closedHubHeight: CGFloat
    let currentHubShape: NotchShape
    
    /// 拖拽时始终使用展开状态的形状
    private var expandedShape: NotchShape {
        NotchShape(
            topCornerRadius: HubMetrics.cornerRadiusInsets.opened.top,
            bottomCornerRadius: HubMetrics.cornerRadiusInsets.opened.bottom
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 1. 双层折射玻璃底座
                ZStack {
                    expandedShape.fill(.ultraThinMaterial)
                    expandedShape.fill(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                }
                .clipShape(expandedShape)
                .overlay(
                    ZStack {
                        expandedShape.stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        expandedShape.stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                    }
                )
                
                // 2. 增强型内容
                VStack(spacing: HubMetrics.Layout.contentSpacing) {
                    Spacer()
                    
                    if dropSuccess {
                        HubSuccessFeedbackView()
                    } else {
                        HubDraggingPulseView(pulseOpacity: pulseOpacity)
                    }
                    
                    Spacer()
                }
                .padding(.top, max(HubMetrics.Layout.dragOverlayTopPadding, closedHubHeight))
            }
            .frame(width: HubMetrics.openHubSize.width, height: HubMetrics.openHubSize.height)
            .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Spacer(minLength: 0)
        }
    }
}

/// 升级版脉冲组件
struct HubDraggingPulseView: View {
    let pulseOpacity: CGFloat
    
    var body: some View {
        VStack(spacing: HubMetrics.Layout.contentSpacing) {
            ZStack {
                // 核心等离子球
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(pulseOpacity * 0.5),
                                Color.cyan.opacity(pulseOpacity * 0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: pulseOpacity * 10)
                
                // 动态扩散环
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.blue.opacity(0), .blue.opacity(pulseOpacity), .blue.opacity(0)],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: HubMetrics.Layout.dragIconCircleSize + 20, height: HubMetrics.Layout.dragIconCircleSize + 20)
                    .rotationEffect(.degrees(pulseOpacity * 360))
                    .scaleEffect(0.9 + pulseOpacity * 0.2)
                
                // 基础图标容器
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: HubMetrics.Layout.dragIconCircleSize, height: HubMetrics.Layout.dragIconCircleSize)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.blue)
            }
            
            VStack(spacing: HubMetrics.Layout.textSpacing) {
                Text("松手暂存")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Drop to stash")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .tracking(1)
            }
        }
    }
}

struct HubSuccessFeedbackView: View {
    var body: some View {
        VStack(spacing: HubMetrics.Layout.contentSpacing) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: HubMetrics.Layout.successIconCircleSize, height: HubMetrics.Layout.successIconCircleSize)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                
                Image(systemName: "checkmark")
                    .font(.system(size: HubMetrics.Layout.successIconCheckmarkSize, weight: .bold))
                    .foregroundStyle(Color.green)
            }
            
            VStack(spacing: HubMetrics.Layout.textSpacing) {
                Text("已暂存").font(.system(size: 16, weight: .semibold))
                Text("File stashed").font(.system(size: 10)).foregroundColor(.secondary).tracking(1)
            }
        }
    }
}
