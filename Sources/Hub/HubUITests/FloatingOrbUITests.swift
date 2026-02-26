//
//  FloatingOrbUITests.swift
//  HubUITests
//
//  悬浮球功能 UI 测试
//

import XCTest

final class FloatingOrbUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 设置为悬浮球模式启动
        app.launchArguments = ["--mode", "floating", "--ui-testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 悬浮球显示测试
    
    func testFloatingOrbAppearsInFloatingMode() throws {
        // 验证悬浮球是否存在
        let orb = app.buttons["悬浮球"]
        XCTAssertTrue(orb.exists, "悬浮球应存在")
        XCTAssertTrue(orb.isHittable, "悬浮球应可点击")
    }
    
    func testFloatingOrbInitialState() throws {
        let orb = app.buttons["悬浮球"]
        
        // 初始状态应为收起
        XCTAssertFalse(app.popovers.element.exists, "初始时不应显示展开窗体")
    }
    
    // MARK: - 悬停展开测试
    
    func testOrbExpandsOnHover() throws {
        let orb = app.buttons["悬浮球"]
        
        // 悬停到悬浮球上
        orb.hover()
        
        // 等待展开动画
        let expectation = expectation(description: "展开窗体出现")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证展开窗体出现
        XCTAssertTrue(app.popovers.element.exists, "悬停后应显示展开窗体")
    }
    
    func testOrbCollapsesOnExit() throws {
        let orb = app.buttons["悬浮球"]
        
        // 先悬停展开
        orb.hover()
        sleep(1)
        
        // 移出悬浮球
        let emptyArea = app.windows.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
        emptyArea.hover()
        
        // 等待收起动画
        let expectation = expectation(description: "收起动画完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证收起
        XCTAssertFalse(app.popovers.element.exists, "移出后应收起展开窗体")
    }
    
    // MARK: - 拖动功能测试
    
    func testOrbCanBeDragged() throws {
        let orb = app.buttons["悬浮球"]
        let initialPosition = orb.frame.origin
        
        // 点击并拖动
        let start = orb.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = orb.coordinate(withNormalizedOffset: CGVector(dx: 2.0, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // 等待拖动完成
        sleep(1)
        
        let finalPosition = orb.frame.origin
        XCTAssertNotEqual(initialPosition, finalPosition, "拖动后位置应改变")
    }
    
    func testOrbCollapsesDuringDrag() throws {
        let orb = app.buttons["悬浮球"]
        
        // 先悬停展开
        orb.hover()
        sleep(1)
        
        // 开始拖动
        let start = orb.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = orb.coordinate(withNormalizedOffset: CGVector(dx: 1.5, dy: 1.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // 拖动时应收起
        XCTAssertFalse(app.popovers.element.exists, "拖动时应收起展开窗体")
    }
    
    // MARK: - 展开窗体内容测试
    
    func testExpandedWindowContent() throws {
        let orb = app.buttons["悬浮球"]
        
        // 展开悬浮球
        orb.hover()
        sleep(1)
        
        // 验证展开窗体中的元素
        XCTAssertTrue(app.staticTexts["Hub"].exists, "应显示 Hub 标题")
        XCTAssertTrue(app.staticTexts["拖拽文件到这里"].exists, "应显示提示文字")
        XCTAssertTrue(app.buttons["gearshape"].exists, "应显示设置按钮")
        XCTAssertTrue(app.buttons["power"].exists, "应显示退出按钮")
    }
    
    func testExpandedWindowCloseButton() throws {
        let orb = app.buttons["悬浮球"]
        
        // 展开悬浮球
        orb.hover()
        sleep(1)
        
        // 点击关闭按钮
        app.buttons["xmark.circle.fill"].tap()
        
        // 等待收起
        sleep(1)
        XCTAssertFalse(app.popovers.element.exists, "点击关闭后应收起")
    }
    
    // MARK: - 模式切换测试
    
    func testSwitchBetweenModes() throws {
        // 打开设置
        let orb = app.buttons["悬浮球"]
        orb.hover()
        sleep(1)
        
        app.buttons["gearshape"].tap()
        sleep(1)
        
        // 切换到刘海屏模式
        let dynamicIslandButton = app.buttons["Dynamic Island"]
        if dynamicIslandButton.exists {
            dynamicIslandButton.tap()
            sleep(2)
            
            // 验证切换到刘海屏模式
            XCTAssertTrue(app.otherElements["刘海屏容器"].exists, "应显示刘海屏容器")
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func hover() {
        // 模拟悬停
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.hover()
    }
}
