//
//  DraggableItemTests.swift
//  HubTests
//
//  Tests for draggable item functionality
//

import Testing
import AppKit
@testable import Hub

struct DraggableItemTests {

    // MARK: - DraggableOverlayView Tests
    
    @Test
    func testDraggableOverlayViewCreation() {
        let view = DraggableOverlayView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        
        #expect(view.acceptsFirstResponder == true)
        #expect(view.filePath == nil)
        #expect(view.fileName == nil)
    }
    
    @Test
    func testDraggableOverlayViewAcceptsFirstMouse() {
        let view = DraggableOverlayView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        
        // 应该接受首次鼠标点击
        #expect(view.acceptsFirstMouse(for: nil) == true)
    }
    
    @Test
    func testDraggableOverlayViewSetProperties() {
        let view = DraggableOverlayView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        
        view.filePath = "/Users/test/file.pdf"
        view.fileName = "file.pdf"
        
        #expect(view.filePath == "/Users/test/file.pdf")
        #expect(view.fileName == "file.pdf")
    }
    
    // MARK: - Drag Threshold Tests
    
    @Test
    func testDragThresholdCalculation() {
        // 测试拖拽距离计算
        let point1 = NSPoint(x: 0, y: 0)
        let point2 = NSPoint(x: 1, y: 1)
        
        let distance = hypot(
            point2.x - point1.x,
            point2.y - point1.y
        )
        
        // 预期距离约为 1.414
        #expect(abs(distance - 1.414) < 0.01)
    }
    
    @Test
    func testDragThresholdComparison() {
        // 拖拽阈值为 3.0 点
        let threshold: CGFloat = 3.0
        
        // 小于阈值
        let smallDistance = hypot(1.0, 1.0)
        #expect(smallDistance < threshold)
        
        // 等于阈值
        let equalDistance = hypot(2.121, 2.121) // ≈ 3.0
        #expect(abs(equalDistance - threshold) < 0.01)
        
        // 大于阈值
        let largeDistance = hypot(3.0, 3.0)
        #expect(largeDistance > threshold)
    }
    
    // MARK: - Drag Operation Tests
    
    @Test
    func testDragOperationMoveExists() {
        // 验证 move 操作存在且非空
        let moveOp = NSDragOperation.move
        #expect(moveOp.rawValue != 0)
    }
    
    @Test
    func testDragOperationCopyExists() {
        // 验证 copy 操作存在且非空
        let copyOp = NSDragOperation.copy
        #expect(copyOp.rawValue != 0)
    }
    
    @Test
    func testDragOperationEmpty() {
        // 验证空操作
        let emptyOp: NSDragOperation = []
        #expect(emptyOp.rawValue == 0)
    }
    
    @Test
    func testDragOperationCombination() {
        // 验证操作组合
        let combinedOp: NSDragOperation = [.move, .copy]
        #expect(combinedOp.rawValue != 0)
    }
    
    // MARK: - Callback Property Tests
    
    @Test
    func testDragCompletedCallbackSetup() {
        let view = DraggableOverlayView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        
        var callbackCalled = false
        view.onDragCompleted = {
            callbackCalled = true
        }
        
        // 手动触发回调
        view.onDragCompleted?()
        
        #expect(callbackCalled == true)
    }
    
    @Test
    func testDragCompletedCallbackNil() {
        let view = DraggableOverlayView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        
        // 回调为 nil 时调用应该不会崩溃
        view.onDragCompleted = nil
        view.onDragCompleted?()
        
        // 测试通过表示没有崩溃
    }
}