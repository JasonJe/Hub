//
//  DraggableItemView.swift
//  Hub
//
//  可拖拽的文件项视图
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - 图标缓存

/// 文件图标缓存 - 使用 NSCache 自动管理内存
private class FileIconCache {
    static let shared = FileIconCache()
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        // 设置缓存限制
        cache.countLimit = 100  // 最多缓存 100 个图标
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB 内存限制
    }
    
    func icon(for path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 64, height: 64)  // 统一尺寸
        cache.setObject(icon, forKey: key, cost: 64 * 64 * 4)  // 估算内存占用
        return icon
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - 可拖拽的文件项视图

/// 可拖拽的文件项视图
/// 支持拖拽到其他应用并自动从 Hub 移除
struct DraggableItemView: View {
    /// 文件项数据
    let item: StashedItem
    
    /// SwiftData 模型上下文
    let modelContext: ModelContext
    
    /// 图标尺寸（默认刘海模式较小尺寸）
    var iconSize: CGFloat = HubMetrics.dynamicIslandItemSize
    
    /// 总高度（默认刘海模式）
    var itemHeight: CGFloat = HubMetrics.dynamicIslandItemHeight
    
    /// 悬停状态
    @State private var isHovering = false
    
    // 文件项总尺寸
    private var itemSize: CGSize {
        CGSize(width: iconSize, height: itemHeight)
    }
    
    /// 删除按钮尺寸
    private var deleteButtonSize: CGFloat {
        max(14, iconSize * 0.28)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 文件项内容
            fileItemContent
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .shadow(color: .black.opacity(isHovering ? 0.2 : 0), radius: 10, x: 0, y: 5)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)

            // 删除按钮 - 放在最上层，独立于文件图标
            if isHovering {
                deleteButton
                    .offset(x: iconSize - deleteButtonSize * 0.7, y: -deleteButtonSize * 0.3)
                    .zIndex(10)  // 确保在最上层
                    .transition(.scale.combined(with: .opacity))
            }

            // 拖拽处理器 - 设置明确的 frame 确保能接收鼠标事件
            DraggableOverlay(
                filePath: item.originalPath,
                fileName: item.name,
                onDragCompleted: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        modelContext.delete(item)
                    }
                },
                onHoverChanged: { hovering in
                    // 立即更新状态，不使用动画
                    isHovering = hovering
                }
            )
            .frame(width: itemSize.width, height: itemSize.height)
        }
        .frame(width: itemSize.width, height: itemSize.height)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                modelContext.delete(item)
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: deleteButtonSize, height: deleteButtonSize)

                Image(systemName: "xmark")
                    .font(.system(size: deleteButtonSize * 0.55, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - File Item Content
    
    private var fileItemContent: some View {
        let cornerRadius = iconSize * 0.25  // 动态圆角
        let innerIconSize = iconSize * 0.68  // 内部图标尺寸
        return VStack(spacing: 4) {
            // 文件图标 - Liquid Glass 风格
            ZStack {
                // 玻璃片背景
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .frame(width: iconSize, height: iconSize)
                    // 边框光泽
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isHovering ? Color.blue.opacity(0.4) : .white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
                    // 顶部液态高光
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                            .frame(height: iconSize * 0.5)
                            .clipped()
                    }

                // 使用缓存的图标
                let nsImage = FileIconCache.shared.icon(for: item.originalPath)
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: innerIconSize, height: innerIconSize)
            }
            .frame(width: iconSize, height: iconSize)

            // 文件名
            Text(item.name)
                .font(.system(size: max(8, iconSize * 0.15)))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: iconSize)
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
        // 确保在尺寸变化时更新 tracking area
        nsView.updateTrackingAreas()
    }
    
    // 确保 NSView 获取正确的尺寸
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: DraggableOverlayView, context: Context) -> CGSize? {
        return proposal.replacingUnspecifiedDimensions(by: CGSize(width: 64, height: 80))
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
        autoresizingMask = [.width, .height]  // 确保跟随父视图尺寸变化
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        autoresizingMask = [.width, .height]
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        // 尺寸变化时更新 tracking area
        updateTrackingAreas()
    }

    // MARK: - Layout

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // 移除旧的 tracking area
        if let oldArea = trackingArea {
            removeTrackingArea(oldArea)
        }
        
        // 如果 bounds 为空，不创建 tracking area
        guard bounds.width > 0 && bounds.height > 0 else {
            return
        }

        // 创建新的 tracking area 来检测悬停
        // 使用完整的选项确保在各种情况下都能正确检测
        // 注意：FloatingPanel 使用 nonactivatingPanel，所以需要 activeAlways
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,              // 持续追踪鼠标移动
            .cursorUpdate,            // 光标更新
            .activeAlways,            // 始终激活（不受窗口状态影响）
            .enabledDuringMouseDrag,  // 在鼠标拖拽时也能检测
            .assumeInside             // 假设鼠标初始在区域内
        ]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        if let area = trackingArea {
            addTrackingArea(area)
        }
        
        // 强制窗口接受鼠标移动事件
        if let window = window {
            window.acceptsMouseMovedEvents = true
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // 视图添加到窗口时，检查鼠标是否已经在区域内
        if let window = window {
            window.acceptsMouseMovedEvents = true
            
            // 获取当前鼠标位置并检查是否在视图内
            let mouseLocation = NSEvent.mouseLocation
            let windowMouseLocation = window.convertPoint(fromScreen: mouseLocation)
            let viewMouseLocation = convert(windowMouseLocation, from: nil)
            
            if bounds.contains(viewMouseLocation) && !isCurrentlyHovering {
                isCurrentlyHovering = true
                onHoverChanged?(true)
            }
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
    
    override func mouseMoved(with event: NSEvent) {
        // 持续检查鼠标位置，确保悬停状态正确
        let mouseLocation = event.locationInWindow
        let viewMouseLocation = convert(mouseLocation, from: nil)
        
        if bounds.contains(viewMouseLocation) && !isCurrentlyHovering {
            isCurrentlyHovering = true
            onHoverChanged?(true)
        } else if !bounds.contains(viewMouseLocation) && isCurrentlyHovering {
            isCurrentlyHovering = false
            onHoverChanged?(false)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // 检查是否在删除按钮区域内（右上角）
        // 使用动态计算的按钮尺寸
        let buttonSize = max(14, bounds.width * 0.28)
        let hitAreaPadding: CGFloat = 6
        let hitAreaSize = buttonSize + hitAreaPadding
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
        
        // 使用缓存的图标
        let icon = FileIconCache.shared.icon(for: filePath)
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
