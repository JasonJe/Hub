//
//  ConfirmationView.swift
//  Hub
//
//  集成式确认视图 - 与Hub协调一致
//

import SwiftUI

struct ConfirmationView: View {
    let title: String
    let message: String
    let confirmTitle: String  // 添加自定义确认按钮标题
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和描述
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
            
            // 按钮组 - 水平排列
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
                        .fill(.red)
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
    }
}

#Preview {
    ConfirmationView(
        title: "确认操作",
        message: "您确定要执行此操作吗？",
        confirmTitle: "确认",
        onConfirm: {},
        onCancel: {}
    )
    .frame(width: 400, height: 300)
    .background(.black)
}