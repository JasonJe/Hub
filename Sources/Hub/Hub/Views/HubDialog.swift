//
//  HubDialog.swift
//  Hub
//
//  珠宝级重塑：极致精细的液态玻璃对话框
//

import SwiftUI

struct HubDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // 背景暗化，增加沉浸感
            Color.black.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            // 弹窗主体
            VStack(spacing: 0) {
                // 内容区
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary.opacity(0.9))
                    
                    Text(message)
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 极细光影分割线
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)
                
                // 按钮组
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // 垂直分割线
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 0.5, height: 24)
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(confirmColor.opacity(0.9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 36)
            }
            .frame(width: 180) // 极致宽度
            .background(
                ZStack {
                    // 1. 极致通透材质
                    RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial)
                    
                    // 2. 内置液态蓝光与次表面深度
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            // 3. 双层折射与镜面高光
            .overlay(
                ZStack {
                    // 基础边缘折射
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.2
                        )
                    // 极锐利镜面高光 (Specular)
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.8), .clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
