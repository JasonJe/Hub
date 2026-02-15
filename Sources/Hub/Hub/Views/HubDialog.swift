//
//  HubDialog.swift
//  Hub
//
//  液态玻璃风格对话框
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
            // 半透明遮罩层 - 增强聚焦感
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            // 弹窗主体
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
                
                Divider().background(.white.opacity(0.08))
                
                // 按钮组
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 13))
                            .foregroundColor(.primary.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                    
                    Divider().frame(height: 44).background(.white.opacity(0.08))
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(confirmColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 44)
            }
            .frame(width: 240)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                    // 顶部高亮
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
