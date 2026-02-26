//
//  HubDialog.swift
//  Hub
//
//  精致紧凑的确认弹窗 - 与Hub协调一致
//

import SwiftUI

struct HubDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isAppearing: Bool = false
    
    var body: some View {
        ZStack {
            // 半透明遮罩 - 淡入效果
            Color.black
                .opacity(isAppearing ? 0.35 : 0)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            // 弹窗内容
            VStack(spacing: 16) {
                // 标题和描述 - 紧凑布局
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // 分割线
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5)
                
                // 按钮组 - 水平排列更紧凑
                HStack(spacing: 8) {
                    // 取消按钮
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                    )
                    
                    // 确认按钮
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(confirmColor)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(width: 240)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(
                color: .black.opacity(0.25),
                radius: 20,
                x: 0,
                y: 10
            )
            // 手风琴动画 - 从底部弹起
            .offset(y: isAppearing ? 0 : 60)
            .scaleEffect(isAppearing ? 1.0 : 0.9, anchor: .bottom)
            .opacity(isAppearing ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
}
