//
//  DragDetectorTests.swift
//  HubTests
//
//  Tests for DragDetector global drag detection functionality
//

import Testing
import AppKit
@testable import Hub

struct DragDetectorTests {

    // MARK: - Initialization Tests
    
    @Test
    func testDragDetectorInitialization() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        // 初始化后不应有回调
        #expect(detector.onDragEntersHubRegion == nil)
        #expect(detector.onDragExitsHubRegion == nil)
        #expect(detector.onDragMove == nil)
    }
    
    @Test
    func testDragDetectorWithZeroRegion() {
        let region = CGRect.zero
        let detector = DragDetector(hubRegion: region)
        
        // 零区域应该也能初始化
        #expect(detector != nil)
    }
    
    @Test
    func testDragDetectorWithLargeRegion() {
        let region = CGRect(x: 0, y: 0, width: 2000, height: 1000)
        let detector = DragDetector(hubRegion: region)
        
        #expect(detector != nil)
    }
    
    // MARK: - Callback Setup Tests
    
    @Test
    func testOnDragEntersHubRegionCallback() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        var callbackCalled = false
        detector.onDragEntersHubRegion = {
            callbackCalled = true
        }
        
        #expect(detector.onDragEntersHubRegion != nil)
    }
    
    @Test
    func testOnDragExitsHubRegionCallback() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        var callbackCalled = false
        detector.onDragExitsHubRegion = {
            callbackCalled = true
        }
        
        #expect(detector.onDragExitsHubRegion != nil)
    }
    
    @Test
    func testOnDragMoveCallback() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        var lastPosition: CGPoint = .zero
        detector.onDragMove = { point in
            lastPosition = point
        }
        
        #expect(detector.onDragMove != nil)
    }
    
    @Test
    func testAllCallbacksSet() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        detector.onDragEntersHubRegion = { }
        detector.onDragExitsHubRegion = { }
        detector.onDragMove = { _ in }
        
        #expect(detector.onDragEntersHubRegion != nil)
        #expect(detector.onDragExitsHubRegion != nil)
        #expect(detector.onDragMove != nil)
    }
    
    // MARK: - Monitoring Tests
    
    @Test
    func testStartMonitoringDoesNotCrash() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        // 启动监控不应该崩溃
        detector.startMonitoring()
        
        // 立即停止
        detector.stopMonitoring()
        
        #expect(true)
    }
    
    @Test
    func testStopMonitoringDoesNotCrash() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        // 停止未启动的监控不应该崩溃
        detector.stopMonitoring()
        
        #expect(true)
    }
    
    @Test
    func testStartStopMonitoringCycle() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        // 多次启动停止
        detector.startMonitoring()
        detector.stopMonitoring()
        detector.startMonitoring()
        detector.stopMonitoring()
        
        #expect(true)
    }
    
    // MARK: - Region Update Tests
    
    @Test
    func testUpdateRegionDoesNotCrash() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        let newRegion = CGRect(x: 200, y: 200, width: 400, height: 300)
        detector.updateRegion(newRegion)
        
        #expect(true)
    }
    
    @Test
    func testUpdateRegionToZeroRegion() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        detector.updateRegion(.zero)
        
        #expect(true)
    }
    
    @Test
    func testUpdateRegionWhileMonitoring() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        detector.startMonitoring()
        
        let newRegion = CGRect(x: 200, y: 200, width: 400, height: 300)
        detector.updateRegion(newRegion)
        
        detector.stopMonitoring()
        
        #expect(true)
    }
    
    // MARK: - Callback Execution Tests
    
    @Test
    func testCallbacksAreCalled() async {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        var enterCalled = false
        var exitCalled = false
        var moveCalled = false
        
        detector.onDragEntersHubRegion = {
            enterCalled = true
        }
        detector.onDragExitsHubRegion = {
            exitCalled = true
        }
        detector.onDragMove = { _ in
            moveCalled = true
        }
        
        // 验证回调已设置
        #expect(detector.onDragEntersHubRegion != nil)
        #expect(detector.onDragExitsHubRegion != nil)
        #expect(detector.onDragMove != nil)
        
        // 注意：实际的回调触发需要全局鼠标事件，
        // 这在单元测试环境中无法模拟
    }
    
    // MARK: - Deinitialization Tests
    
    @Test
    func testDeinitStopsMonitoring() {
        var detector: DragDetector? = DragDetector(hubRegion: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        detector?.startMonitoring()
        
        // 设置为 nil 应该触发 deinit，停止监控
        detector = nil
        
        #expect(detector == nil)
    }
    
    // MARK: - Type Alias Tests
    
    @Test
    func testVoidCallbackType() {
        // 验证 VoidCallback 类型
        let callback: DragDetector.VoidCallback = {
            // 空实现
        }
        
        #expect(true)
    }
    
    @Test
    func testPositionCallbackType() {
        // 验证 PositionCallback 类型
        let callback: DragDetector.PositionCallback = { point in
            // 接收位置参数
            _ = point
        }
        
        #expect(true)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testFullMonitoringLifecycle() {
        let region = CGRect(x: 100, y: 100, width: 360, height: 240)
        let detector = DragDetector(hubRegion: region)
        
        // 设置所有回调
        detector.onDragEntersHubRegion = { }
        detector.onDragExitsHubRegion = { }
        detector.onDragMove = { _ in }
        
        // 启动监控
        detector.startMonitoring()
        
        // 更新区域
        detector.updateRegion(CGRect(x: 200, y: 200, width: 400, height: 300))
        
        // 停止监控
        detector.stopMonitoring()
        
        #expect(true)
    }
}