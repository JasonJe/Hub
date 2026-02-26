//
//  ButtonClickTests.swift
//  HubUITests
//
//  测试按钮点击功能
//

import XCTest

final class ButtonClickTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // 等待应用启动
        sleep(2)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// 测试设置按钮点击
    func testSettingsButtonClick() throws {
        // 首先点击 Hub 展开它
        let hubElement = app.otherElements["HubView"].firstMatch
        if hubElement.exists {
            hubElement.tap()
            sleep(1)
        }
        
        // 查找设置按钮
        let settingsButton = app.buttons["设置"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "设置按钮应该存在")
        
        // 点击设置按钮
        settingsButton.tap()
        sleep(1)
        
        // 验证设置视图是否显示
        // 设置视图应该有"返回"或"设置"标题
        let settingsTitle = app.staticTexts["设置"]
        XCTAssertTrue(settingsTitle.exists || app.buttons["返回"].exists, "设置视图应该显示")
    }
    
    /// 测试退出按钮点击
    func testExitButtonClick() throws {
        // 首先点击 Hub 展开它
        let hubElement = app.otherElements["HubView"].firstMatch
        if hubElement.exists {
            hubElement.tap()
            sleep(1)
        }
        
        // 查找退出按钮
        let exitButton = app.buttons["退出"]
        XCTAssertTrue(exitButton.waitForExistence(timeout: 5), "退出按钮应该存在")
        
        // 点击退出按钮
        exitButton.tap()
        sleep(1)
        
        // 验证确认对话框是否显示
        let confirmDialog = app.staticTexts["退出 Hub"]
        XCTAssertTrue(confirmDialog.exists, "退出确认对话框应该显示")
    }
    
    /// 测试清空按钮点击
    func testClearButtonClick() throws {
        // 首先点击 Hub 展开它
        let hubElement = app.otherElements["HubView"].firstMatch
        if hubElement.exists {
            hubElement.tap()
            sleep(1)
        }
        
        // 查找清空按钮
        let clearButton = app.buttons["清空"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "清空按钮应该存在")
        
        // 点击清空按钮
        clearButton.tap()
        sleep(1)
        
        // 验证确认对话框是否显示
        let confirmDialog = app.staticTexts["确认删除所有文件吗？"]
        XCTAssertTrue(confirmDialog.exists, "清空确认对话框应该显示")
    }
    
    /// 测试按钮是否存在并可交互
    func testButtonsAreHittable() throws {
        // 首先点击 Hub 展开它
        let hubElement = app.otherElements["HubView"].firstMatch
        if hubElement.exists {
            hubElement.tap()
            sleep(1)
        }
        
        // 测试设置按钮
        let settingsButton = app.buttons["设置"]
        if settingsButton.exists {
            print("[TEST] 设置按钮存在，isHittable: \(settingsButton.isHittable)")
            XCTAssertTrue(settingsButton.isHittable, "设置按钮应该是可点击的")
        }
        
        // 测试退出按钮
        let exitButton = app.buttons["退出"]
        if exitButton.exists {
            print("[TEST] 退出按钮存在，isHittable: \(exitButton.isHittable)")
            XCTAssertTrue(exitButton.isHittable, "退出按钮应该是可点击的")
        }
        
        // 测试清空按钮
        let clearButton = app.buttons["清空"]
        if clearButton.exists {
            print("[TEST] 清空按钮存在，isHittable: \(clearButton.isHittable)")
            XCTAssertTrue(clearButton.isHittable, "清空按钮应该是可点击的")
        }
    }
}
