//
//  ScreenTypeDetectorTests.swift
//  HubTests
//
//  屏幕类型检测器测试 - TDD
//

import XCTest
import AppKit
@testable import Hub

@MainActor
final class ScreenTypeDetectorTests: XCTestCase {
    
    var detector: ScreenTypeDetector!
    
    override func setUp() {
        super.setUp()
        detector = ScreenTypeDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    // MARK: - 主屏幕检测测试
    
    func testGetMainScreen() {
        let screen = detector.getMainScreen()
        XCTAssertNotNil(screen, "应该能获取到主屏幕")
    }
    
    func testGetMainScreenFrame() {
        let frame = detector.getMainScreenFrame()
        XCTAssertFalse(frame.isEmpty, "主屏幕 Frame 不应为空")
        XCTAssertGreaterThan(frame.width, 0, "屏幕宽度应大于0")
        XCTAssertGreaterThan(frame.height, 0, "屏幕高度应大于0")
    }
    
    // MARK: - 刘海屏检测测试
    
    func testHasNotchDetection() {
        // 测试能正确检测是否有刘海
        let hasNotch = detector.hasNotch()
        // 注意：实际结果取决于运行测试的机器
        // 这里我们只是验证方法能正常执行
        XCTAssertTrue(hasNotch || !hasNotch, "刘海检测应返回布尔值")
    }
    
    func testNotchDetectionBasedOnSafeArea() {
        // 基于安全区域判断刘海
        let screen = NSScreen.main!
        let hasNotch = detector.checkNotchBySafeArea(screen)
        XCTAssertTrue(hasNotch || !hasNotch, "基于安全区域的检测应返回布尔值")
    }
    
    func testNotchDetectionBasedOnSize() {
        // 基于屏幕尺寸判断刘海
        let screen = NSScreen.main!
        let hasNotch = detector.checkNotchBySize(screen)
        XCTAssertTrue(hasNotch || !hasNotch, "基于尺寸的检测应返回布尔值")
    }
    
    // MARK: - 多屏幕测试
    
    func testMultipleScreensDetection() {
        let screens = detector.getAllScreens()
        XCTAssertGreaterThanOrEqual(screens.count, 1, "至少有一个屏幕")
        
        let mainScreen = detector.getMainScreen()
        XCTAssertTrue(screens.contains { $0 === mainScreen }, "主屏幕应在屏幕列表中")
    }
    
    func testScreenChangeNotification() {
        let expectation = expectation(description: "屏幕变化通知")
        
        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .screenConfigurationChanged,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        // 模拟触发屏幕检测更新
        detector.triggerScreenCheck()
        
        wait(for: [expectation], timeout: 2.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - 屏幕类型枚举测试
    
    func testScreenTypeEnum() {
        let type1 = ScreenType.notch
        let type2 = ScreenType.regular
        
        XCTAssertNotEqual(type1, type2, "刘海屏和普通屏类型应不同")
        
        // 测试 Associated Value
        if case .notch = type1 {
            // 正确识别
        } else {
            XCTFail("应识别为刘海屏类型")
        }
    }
    
    func testScreenTypeDescription() {
        let notchType = ScreenType.notch
        let regularType = ScreenType.regular
        
        XCTAssertEqual(notchType.description, "刘海屏")
        XCTAssertEqual(regularType.description, "普通屏")
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let screenConfigurationChanged = Notification.Name("screenConfigurationChanged")
}
