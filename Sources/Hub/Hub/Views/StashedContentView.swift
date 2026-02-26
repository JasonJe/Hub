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
    
    /// 返回Hub的回调（当显示设置时使用）
    var onReturnToHub: (() -> Void)?
    
    /// 同步弹窗状态到父视图
    @Binding var isShowingAlert: Bool
    
    /// 触发指定弹窗的回调
    var onShowDialog: (HubDialogType, (() -> Void)?) -> Void
    
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
            
            Divider().background(.white.opacity(0.08))
            
            // 文件网格
            fileGridView
            
            Spacer(minLength: 0) // 新增：将页脚推向底部
            
            // Footer
            footerView
        }
    }
    
    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Text("暂存区")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            // 计数徽章 - Liquid Glass 风格
            Text("\(items.count)")
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

            Spacer()

            // 一键清空按钮
            if !items.isEmpty {
                Button(action: {
                    onShowDialog(.clearAll, {
                        clearAllItems()
                    })
                }) {
                    Text("清空")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(.red.opacity(0.2), lineWidth: 0.5)
                                )
                        )
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            for item in items {
                modelContext.delete(item)
            }
        }
    }
    
    /// 清空所有暂存项并关闭对话框
    func clearAllItemsAndDismiss() {
        clearAllItems()
        onShowDialog(.clearAll, nil) // 触发dismissDialog
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
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            
            // 图标 - Liquid Glass 风格
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    // 顶部液态高光
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                            .frame(width: 64, height: 32)
                            .clipped()
                    }
                
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            // 提示文本
            VStack(spacing: 5) {
                Text("暂存区为空")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("拖放文件到这里暂存")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 8)
        .frame(height: 110)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // 设置按钮 - 如果在设置页面，则显示返回Hub按钮
            if let returnToHub = onReturnToHub {
                // 显示返回Hub按钮
                Button(action: returnToHub) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 10))
                        Text("返回Hub")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                // 显示设置按钮
                Button(action: {
                    print("[DEBUG] 设置按钮被点击")
                    onOpenSettings()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10))
                        Text("设置")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // 退出按钮
            Button(action: {
                print("[DEBUG] 退出按钮被点击")
                onShowDialog(.exit, nil)
            }) {
                Text("退出")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20) // 增加：提升至 20pt 彻底解决触底感
    }
}

#Preview {
    StashedContentView(items: [], onOpenSettings: {}, onReturnToHub: nil, isShowingAlert: .constant(false), onShowDialog: { _, _ in })
        .frame(width: 360, height: 220)
        .background(.black)
}
