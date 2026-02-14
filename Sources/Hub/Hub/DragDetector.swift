//
//  DragDetector.swift
//  Hub
//
//  参考 boring.notch 的 DragDetector 实现
//

import Cocoa
import UniformTypeIdentifiers

final class DragDetector {
    
    // MARK: - Callbacks
    
    typealias VoidCallback = () -> Void
    typealias PositionCallback = (_ globalPoint: CGPoint) -> Void
    
    var onDragEntersHubRegion: VoidCallback?
    var onDragExitsHubRegion: VoidCallback?
    var onDragMove: PositionCallback?
    
    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?
    
    private var pasteboardChangeCount: Int = -1
    private var isDragging: Bool = false
    private var isContentDragging: Bool = false
    private var hasEnteredHubRegion: Bool = false
    
    private var hubRegion: CGRect
    private let dragPasteboard = NSPasteboard(name: .drag)
    
    init(hubRegion: CGRect) {
        self.hubRegion = hubRegion
    }
    
    // MARK: - Private Helpers
    
    /// 检查拖拽粘贴板是否包含有效内容类型
    private func hasValidDragContent() -> Bool {
        let validTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType(UTType.url.identifier),
            .string
        ]
        return dragPasteboard.types?.contains(where: validTypes.contains) ?? false
    }
    
    func startMonitoring() {
        stopMonitoring()
        
        // 跟踪粘贴板以检测内容拖动
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            self.pasteboardChangeCount = self.dragPasteboard.changeCount
            self.isDragging = true
            self.isContentDragging = false
            self.hasEnteredHubRegion = false
        }
        
        // 跟踪拖动移动和 Hub 区域交叉
        mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            guard let self = self else { return }
            guard self.isDragging else { return }
            
            let newContent = self.dragPasteboard.changeCount != self.pasteboardChangeCount
            
            // 检测是否正在拖动实际内容且是有效内容
            if newContent && !self.isContentDragging && self.hasValidDragContent() {
                self.isContentDragging = true
            }
            
            // 仅在拖动内容时处理位置
            if self.isContentDragging {
                let mouseLocation = NSEvent.mouseLocation
                self.onDragMove?(mouseLocation)
                
                // 跟踪 Hub 区域进入/退出
                let containsMouse = self.hubRegion.contains(mouseLocation)
                if containsMouse && !self.hasEnteredHubRegion {
                    self.hasEnteredHubRegion = true
                    self.onDragEntersHubRegion?()
                } else if !containsMouse && self.hasEnteredHubRegion {
                    self.hasEnteredHubRegion = false
                    self.onDragExitsHubRegion?()
                }
            }
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            guard let self = self else { return }
            guard self.isDragging else { return }

            // 鼠标松开代表拖拽结束
            // 如果之前进入了 Hub 区域，发送退出通知（无论当前鼠标位置）
            if self.hasEnteredHubRegion {
                self.onDragExitsHubRegion?()
            }

            self.isDragging = false
            self.isContentDragging = false
            self.hasEnteredHubRegion = false
            self.pasteboardChangeCount = -1
        }
    }
    
    func stopMonitoring() {
        [mouseDownMonitor, mouseDraggedMonitor, mouseUpMonitor].forEach { monitor in
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        mouseDownMonitor = nil
        mouseDraggedMonitor = nil
        mouseUpMonitor = nil
        isDragging = false
        isContentDragging = false
        hasEnteredHubRegion = false
    }
    
    /// 更新 Hub 区域
    func updateRegion(_ region: CGRect) {
        // 更新 Hub 区域并重置状态
        hubRegion = region
        hasEnteredHubRegion = false
    }
    
    deinit {
        stopMonitoring()
    }
}
