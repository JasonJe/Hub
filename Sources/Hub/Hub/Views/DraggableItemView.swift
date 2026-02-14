//
//  DraggableItemView.swift
//  Hub
//
//  可拖拽的文件项视图
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - 可拖拽的文件项视图

/// 可拖拽的文件项视图
/// 支持拖拽到其他应用并自动从 Hub 移除
struct DraggableItemView: View {
    /// 文件项数据
    let item: StashedItem
    
    /// SwiftData 模型上下文
    let modelContext: ModelContext
    
    /// 悬停状态
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // 文件项内容
            fileItemContent

            // 拖拽处理器
            DraggableOverlay(
                filePath: item.originalPath,
                fileName: item.name,
                onDragCompleted: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        modelContext.delete(item)
                    }
                },
                onHoverChanged: { hovering in
                    isHovering = hovering
                }
            )
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                modelContext.delete(item)
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: HubMetrics.deleteButtonSize, height: HubMetrics.deleteButtonSize)

                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - File Item Content
    
    private var fileItemContent: some View {
        VStack(spacing: 4) {
            // 文件图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHovering ? Color.blue : Color.white.opacity(0.05),
                                    lineWidth: isHovering ? 2 : 1)
                    )

                // 使用系统图标
                let nsImage = NSWorkspace.shared.icon(forFile: item.originalPath)
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)

                // 删除按钮（图标右上角）
                if isHovering {
                    deleteButton
                        .position(x: 56, y: 8)
                }
            }
            .frame(width: 64, height: 64)

            // 文件名
            Text(item.name)
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 64)
        }
    }
}

// MARK: - NSViewRepresentable for Drag

/// 拖拽覆盖层 - SwiftUI 包装器
struct DraggableOverlay: NSViewRepresentable {
    let filePath: String
    let fileName: String
    let onDragCompleted: () -> Void
    let onHoverChanged: (Bool) -> Void

    func makeNSView(context: Context) -> DraggableOverlayView {
        let view = DraggableOverlayView()
        view.filePath = filePath
        view.fileName = fileName
        view.onDragCompleted = onDragCompleted
        view.onHoverChanged = onHoverChanged
        return view
    }

    func updateNSView(_ nsView: DraggableOverlayView, context: Context) {
        nsView.filePath = filePath
        nsView.fileName = fileName
        nsView.onDragCompleted = onDragCompleted
        nsView.onHoverChanged = onHoverChanged
    }
}

// MARK: - Custom NSView with NSDraggingSource

/// 自定义 NSView，支持拖拽源
class DraggableOverlayView: NSView, NSDraggingSource {
    // MARK: - Properties

    var filePath: String?
    var fileName: String?
    var onDragCompleted: (() -> Void)?
    var onHoverChanged: ((Bool) -> Void)?

    private var mouseDownEvent: NSEvent?

    /// 拖拽触发阈值 - 使用共享常量
    private var dragThreshold: CGFloat {
        return HubMetrics.dragThreshold
    }
    private var trackingArea: NSTrackingArea?
    private var isCurrentlyHovering: Bool = false

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Layout

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // 移除旧的 tracking area
        if let oldArea = trackingArea {
            removeTrackingArea(oldArea)
        }

        // 创建新的 tracking area 来检测悬停
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        if let area = trackingArea {
            addTrackingArea(area)
        }
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        isCurrentlyHovering = true
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        isCurrentlyHovering = false
        onHoverChanged?(false)
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // 检查是否在删除按钮区域内（右上角）
        // 使用共享常量确保与 SwiftUI 层的按钮尺寸同步
        let hitAreaSize = HubMetrics.deleteButtonSize + HubMetrics.deleteButtonHitAreaPadding
        let deleteButtonRect = NSRect(
            x: bounds.width - hitAreaSize,
            y: bounds.height - hitAreaSize,
            width: hitAreaSize,
            height: hitAreaSize
        )
        if deleteButtonRect.contains(point) {
            return nil // 让点击穿透到 SwiftUI 层
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
    }    
    override func mouseDragged(with event: NSEvent) {
        guard let mouseDownEvent = mouseDownEvent else {
            super.mouseDragged(with: event)
            return
        }
        
        // 计算拖拽距离
        let dragDistance = hypot(
            event.locationInWindow.x - mouseDownEvent.locationInWindow.x,
            event.locationInWindow.y - mouseDownEvent.locationInWindow.y
        )
        
        // 超过阈值才开始拖拽
        if dragDistance > dragThreshold {
            startDragSession(with: event)
            self.mouseDownEvent = nil
        } else {
            super.mouseDragged(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseDownEvent = nil
        super.mouseUp(with: event)
    }
    
    // MARK: - Drag Session
    
    private func startDragSession(with event: NSEvent) {
        guard let filePath = filePath else { return }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        // 创建粘贴板项目
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(fileURL.absoluteString, forType: .fileURL)
        pasteboardItem.setString(fileURL.path, forType: .string)
        
        // 创建拖拽项目
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        
        // 设置拖拽图像
        let icon = NSWorkspace.shared.icon(forFile: filePath)
        icon.size = NSSize(width: 64, height: 64)
        let imageFrame = NSRect(x: 0, y: 0, width: 64, height: 64)
        draggingItem.setDraggingFrame(imageFrame, contents: icon)
        
        // 开始拖拽会话
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    // MARK: - NSDraggingSource
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .outsideApplication:
            return .move  // 拖到其他应用时为移动
        case .withinApplication:
            return [.move, .copy]  // 应用内可以移动或复制
        @unknown default:
            return .move
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // 只有拖拽到外部应用且操作成功时才删除文件
        // operation 为 .move 表示拖拽到外部应用成功
        // 在应用内拖拽时 operation 可能是 .copy 或其他，不应该删除
        if operation == .move {
            DispatchQueue.main.async {
                self.onDragCompleted?()
            }
        }
    }
}
