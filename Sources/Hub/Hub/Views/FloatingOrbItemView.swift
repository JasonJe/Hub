//
//  FloatingOrbItemView.swift
//  Hub
//
//  悬浮球模式下的文件项视图 - 与刘海屏模式样式一致
//

import SwiftUI
import SwiftData
import AppKit

struct FloatingOrbItemView: View {
    let item: StashedItem
    var modelContext: ModelContext
    
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // 文件项内容
            fileItemContent
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .shadow(color: .black.opacity(isHovering ? 0.2 : 0), radius: 10, x: 0, y: 5)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            
            // 删除按钮（悬停时显示）
            if isHovering {
                deleteButton
                    .position(x: 56, y: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - 删除按钮
    private var deleteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                modelContext.delete(item)
                try? modelContext.save()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 文件项内容
    private var fileItemContent: some View {
        VStack(spacing: 4) {
            // 文件图标 - 使用真实文件图标
            ZStack {
                // 玻璃片背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    // 边框光泽
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isHovering ? Color.blue.opacity(0.4) : .white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
                    // 顶部液态高光
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                            .frame(height: 32)
                            .clipped()
                    }
                
                // 使用真实文件图标
                let nsImage = NSWorkspace.shared.icon(forFile: item.originalPath)
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            }
            .frame(width: 64, height: 64)
            
            // 文件名
            Text(item.name)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 64)
        }
    }
}