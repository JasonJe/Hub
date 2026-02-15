//
//  IdleContentView.swift
//  Hub
//
//  Hub 闭合/空闲状态视图
//

import SwiftUI

/// Hub 闭合状态视图
/// 显示 Hub 图标和暂存文件数量
struct IdleContentView: View {
    /// 暂存的文件数量
    var itemCount: Int
    
    var body: some View {
        HStack {
            // Hub 图标和名称
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
                
                Text("Hub")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 状态指示器
            if itemCount > 0 {
                // 有暂存文件时显示数量徽章 - Liquid Glass 风格
                Text("\(itemCount)")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .overlay(alignment: .top) {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.25), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .frame(height: 10)
                            }
                    )
                    .foregroundColor(.secondary)
            } else {
                // 无暂存文件时显示绿色状态点 - 液态光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green, .green.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 3
                        )
                    )
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.4), radius: 3, x: 0, y: 0)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    HStack {
        IdleContentView(itemCount: 0)
            .frame(width: 200, height: 32)
            .background(.black)
        
        IdleContentView(itemCount: 3)
            .frame(width: 200, height: 32)
            .background(.black)
    }
}
