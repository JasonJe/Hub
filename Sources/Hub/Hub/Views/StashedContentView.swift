//
//  StashedContentView.swift
//  Hub
//
//  Hub 展开状态视图 - 暂存区
//

import SwiftUI
import SwiftData

/// Hub 展开状态视图
/// 显示暂存的文件列表和操作按钮
struct StashedContentView: View {
    /// 暂存的文件列表
    var items: [StashedItem]
    
    /// 打开设置的回调
    var onOpenSettings: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    /// 文件网格列配置
    let columns = [
        GridItem(.fixed(64), spacing: 8),
        GridItem(.fixed(64), spacing: 8),
        GridItem(.fixed(64), spacing: 8),
        GridItem(.fixed(64), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider().background(Color.white.opacity(0.05))
            
            // 文件网格
            fileGridView
            
            // Footer
            footerView
        }
    }
    
    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Text("暂存区")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text("\(items.count)")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .foregroundColor(.gray)

            Spacer()

            // 一键清空按钮
            if !items.isEmpty {
                Button(action: {
                    clearAllItems()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("清空")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Helper Methods

    /// 清空所有暂存项
    private func clearAllItems() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            for item in items {
                modelContext.delete(item)
            }
        }
    }
    
    // MARK: - File Grid
    
    private var fileGridView: some View {
        ScrollView(showsIndicators: false) {
            if items.isEmpty {
                emptyStateView
            } else {
                populatedGrid
            }
        }
    }
    
    /// 有内容时的网格内容
    private var populatedGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                DraggableItemView(item: item, modelContext: modelContext)
                    .contextMenu {
                        Button("删除") {
                            modelContext.delete(item)
                        }
                    }
            }
        }
        .padding(16)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24))
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // 提示文本
            VStack(spacing: 4) {
                Text("暂存区为空")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("拖放文件到这里暂存")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            Spacer()
        }
        .frame(height: 110)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // 设置按钮
            Button(action: onOpenSettings) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                    Text("设置")
                }
                .font(.system(size: 10))
                .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 退出按钮
            Button(action: {
                NSApp.terminate(nil)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 10))
                    Text("退出")
                }
                .font(.system(size: 10))
                .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
    }
}

#Preview {
    StashedContentView(items: [], onOpenSettings: {})
        .frame(width: 360, height: 220)
        .background(.black)
}
