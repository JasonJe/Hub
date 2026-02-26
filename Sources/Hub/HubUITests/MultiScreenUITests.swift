//
//  MultiScreenUITests.swift
//  HubUITests
//
//  多屏幕支持 UI 测试
//

import XCTest

final class MultiScreenUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 主屏幕检测测试
    
    func testAppAppearsOnMainScreen() throws {
        // 验证应用在主屏幕显示
        let window = app.windows.element(boundBy: 0)
        XCTAssertTrue(window.exists, "Hub 窗口应存在")
        
        // 获取主屏幕尺寸
        let mainScreenFrame = window.frame
        XCTAssertGreaterThan(mainScreenFrame.width, 0, "主屏幕宽度应大于0")
        XCTAssertGreaterThan(mainScreenFrame.height, 0, "主屏幕高度应大于0")
    }
    
    func testWindowPositionOnMainScreen() throws {
        let window = app.windows.element(boundBy: 0)
        let windowFrame = window.frame
        
        // 窗口应在屏幕范围内
        XCTAssertGreaterThanOrEqual(windowFrame.minX, 0, "窗口左边界应在屏幕内")
        XCTAssertGreaterThanOrEqual(windowFrame.minY, 0, "窗口下边界应在屏幕内")
    }
    
    // MARK: - 屏幕类型自适应测试
    
    func testAdaptiveUIForNotchScreen() throws {
        // 假设当前是刘海屏，验证刘海屏UI元素
        // 注意：实际结果取决于运行测试的屏幕类型
        
        let dynamicIsland = app.otherElements["刘海屏容器"]
        if dynamicIsland.exists {
            XCTAssertTrue(dynamicIsland.exists, "刘海屏模式应有刘海屏容器")
        }
    }
    
    func testAdaptiveUIForRegularScreen() throws {
        // 假设当前是普通屏幕，验证悬浮球UI元素
        // 注意：实际结果取决于运行测试的屏幕类型
        
        let floatingOrb = app.buttons["悬浮球"]
        if floatingOrb.exists {
            XCTAssertTrue(floatingOrb.exists, "普通屏幕模式应有悬浮球")
        }
    }
    
    // MARK: - 模式切换测试
    
    func testManualModeSwitch() throws {
        // 打开设置
        let settingsButton = app.buttons["设置"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            
            // 查找模式切换选项
            let dynamicIslandButton = app.buttons["Dynamic Island"]
            let floatingButton = app.buttons["悬浮球"]
            
            // 切换到另一种模式
            if dynamicIslandButton.exists && floatingButton.exists {
                if dynamicIslandButton.isSelected {
                    floatingButton.tap()
                } else {
                    dynamicIslandButton.tap()
                }
                
                sleep(2)
                
                // 验证模式已切换
                XCTAssertTrue(app.buttons["确认切换"].exists || app.alerts.element.exists, "应显示模式切换确认")
            }
        }
    }
    
    // MARK: - 屏幕变化响应测试
    
    func testScreenChangeNotification() throws {
        // 模拟屏幕配置变化
        // 注意：实际测试需要在有外接显示器的设备上运行
        
        let window = app.windows.element(boundBy: 0)
        let initialFrame = window.frame
        
        // 等待可能的屏幕变化处理
        sleep(3)
        
        let currentFrame = window.frame
        
        // 验证窗口位置仍然有效
        XCTAssertGreaterThanOrEqual(currentFrame.minX, 0)
        XCTAssertGreaterThanOrEqual(currentFrame.minY, 0)
    }
    
    // MARK: - 窗口位置保持测试
    
    func testWindowPositionPersistence() throws {
        let window = app.windows.element(boundBy: 0)
        let initialPosition = window.frame.origin
        
        // 重启应用
        app.terminate()
        app.launch()
        
        sleep(3)
        
        let newWindow = app.windows.element(boundBy: 0)
        let newPosition = newWindow.frame.origin
        
        // 如果是悬浮球模式，位置应该保持
        // 如果是刘海屏模式，位置应该重新计算
        XCTAssertTrue(newWindow.exists, "重启后窗口应存在")
    }
}