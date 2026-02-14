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
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 状态指示器
            if itemCount > 0 {
                // 有暂存文件时显示数量徽章
                Text("\(itemCount)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            } else {
                // 无暂存文件时显示绿色状态点
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: .green.opacity(0.6), radius: 3)
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
