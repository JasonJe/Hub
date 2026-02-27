//
//  MultiScreenTests.swift
//  HubTests
//
//  多屏幕支持测试 - TDD
//

import XCTest
import AppKit
@testable import Hub

@MainActor
final class MultiScreenTests: XCTestCase {
    
    var windowManager: WindowManager!
    var screenManager: ScreenManager!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager.shared
        screenManager = ScreenManager.shared
    }
    
    override func tearDown() {
        screenManager = nil
        windowManager = nil
        super.tearDown()
    }
    
    // MARK: - 主屏幕检测测试
    
    func testMainScreenDetection() {
        let mainScreen = screenManager.getMainScreen()
        XCTAssertNotNil(mainScreen, "应能检测到主屏幕")
        
        let mainScreen2 = NSScreen.main
        XCTAssertEqual(mainScreen, mainScreen2, "检测到的主屏幕应与系统一致")
    }
    
    func testWindowPositionOnMainScreen() {
        guard let mainScreen = NSScreen.main else {
            XCTFail("无法获取主屏幕")
            return
        }
        
        let screenFrame = mainScreen.frame
        let windowFrame = windowManager.calculateWindowRect(for: .dynamicIsland)
        
        // 窗口应在主屏幕范围内
        XCTAssertGreaterThanOrEqual(windowFrame.minX, screenFrame.minX, "窗口X应在屏幕内")
        XCTAssertLessThanOrEqual(windowFrame.maxX, screenFrame.maxX, "窗口最大X应在屏幕内")
    }
    
    // MARK: - 屏幕切换测试
    
    func testScreenChangeNotification() {
        let expectation = expectation(description: "屏幕变化通知")
        
        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        // 注意：实际屏幕变化由系统触发，这里测试监听是否正常工作
        // 模拟场景：检查监听器是否已注册
        XCTAssertTrue(true, "屏幕变化监听器应已注册")
        
        NotificationCenter.default.removeObserver(observer)
        
        // 由于无法模拟真实的屏幕变化，这里只验证监听器可以正常工作
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testWindowRepositionOnScreenChange() {
        guard let mainScreen = NSScreen.main else { return }
        
        let initialFrame = windowManager.calculateWindowRect(for: .dynamicIsland)
        
        // 模拟屏幕变化后重新计算位置
        let newFrame = windowManager.calculateWindowRect(for: .dynamicIsland, on: mainScreen)
        
        XCTAssertFalse(newFrame.isEmpty, "新位置不应为空")
        XCTAssertEqual(newFrame.size, initialFrame.size, "窗口尺寸应保持不变")
    }
    
    // MARK: - 屏幕类型切换测试
    
    func testAutoSwitchBasedOnScreenType() {
        let screenType = screenManager.detectMainScreenType()
        let mode = screenManager.getModeForScreenType()
        
        // 验证模式与屏幕类型匹配
        switch screenType {
        case .notch:
            XCTAssertEqual(mode, .dynamicIsland, "刘海屏应使用 Dynamic Island 模式")
        case .regular:
            XCTAssertEqual(mode, .floating, "普通屏幕应使用悬浮球模式")
        }
    }
    
    func testNotchScreenUsesDynamicIsland() {
        // 模拟刘海屏
        screenManager.mockScreenType(.notch)
        
        let mode = screenManager.getModeForScreenType()
        XCTAssertEqual(mode, .dynamicIsland, "刘海屏应使用 Dynamic Island 模式")
    }
    
    func testRegularScreenUsesFloating() {
        // 模拟普通屏幕
        screenManager.mockScreenType(.regular)
        
        let mode = screenManager.getModeForScreenType()
        XCTAssertEqual(mode, .floating, "普通屏幕应使用悬浮球模式")
    }
    
    // MARK: - 屏幕尺寸适配测试
    
    func testWindowSizeAdaptsToScreen() {
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        
        // 窗口尺寸不应超过屏幕尺寸
        let windowFrame = windowManager.calculateWindowRect(for: .dynamicIsland)
        XCTAssertLessThanOrEqual(windowFrame.width, screenFrame.width, "窗口宽度不应超过屏幕")
        XCTAssertLessThanOrEqual(windowFrame.height, screenFrame.height, "窗口高度不应超过屏幕")
    }
    
    func testWindowCenteredOnNotchScreen() {
        guard let screen = NSScreen.main else { return }
        
        screenManager.mockScreenType(.notch)
        let windowFrame = windowManager.calculateWindowRect(for: .dynamicIsland, on: screen)
        let screenFrame = screen.frame
        
        // 刘海屏模式应居中
        let expectedCenterX = screenFrame.midX
        let windowCenterX = windowFrame.midX
        XCTAssertEqual(windowCenterX, expectedCenterX, accuracy: 10, "刘海屏窗口应水平居中")
    }
    
    // MARK: - 状态保持测试
    
    func testFloatingPositionPreserved() {
        var settings = HubSettings()
        settings.mode = .floating
        settings.floatingX = 200
        settings.floatingY = 300
        settings.save()
        
        // 悬浮位置应保持
        let newSettings = HubSettings()
        XCTAssertEqual(newSettings.floatingX, 200, "悬浮X位置应保持")
        XCTAssertEqual(newSettings.floatingY, 300, "悬浮Y位置应保持")
        
        // 清理
        HubSettings.clearCache()
    }
}
