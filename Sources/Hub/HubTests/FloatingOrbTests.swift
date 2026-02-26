//
//  FloatingOrbTests.swift
//  HubTests
//
//  悬浮球功能测试 - TDD
//

import XCTest
import SwiftUI
import AppKit
@testable import Hub

@MainActor
final class FloatingOrbTests: XCTestCase {
    
    var viewModel: HubViewModel!
    var orbView: FloatingOrbView!
    
    override func setUp() {
        super.setUp()
        viewModel = HubViewModel()
        orbView = FloatingOrbView(viewModel: viewModel)
    }
    
    override func tearDown() {
        orbView = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - 悬浮球状态测试
    
    func testOrbInitialState() {
        XCTAssertFalse(viewModel.isOrbExpanded, "悬浮球初始应为收起状态")
        XCTAssertFalse(viewModel.isOrbDragging, "悬浮球初始不应在拖动中")
    }
    
    func testOrbExpandOnHover() {
        viewModel.expandOrb()
        XCTAssertTrue(viewModel.isOrbExpanded, "悬停后悬浮球应展开")
    }
    
    func testOrbCollapseOnExit() {
        viewModel.expandOrb()
        viewModel.collapseOrb()
        XCTAssertFalse(viewModel.isOrbExpanded, "鼠标移出后悬浮球应收起")
    }
    
    func testOrbCollapseWhileDragging() {
        viewModel.expandOrb()
        viewModel.startOrbDrag()
        XCTAssertFalse(viewModel.isOrbExpanded, "拖动时悬浮球应收起")
        XCTAssertTrue(viewModel.isOrbDragging, "应标记为拖动状态")
    }
    
    func testOrbDragStateReset() {
        viewModel.startOrbDrag()
        viewModel.endOrbDrag()
        XCTAssertFalse(viewModel.isOrbDragging, "拖动结束后应重置状态")
    }
    
    // MARK: - 悬浮球位置测试
    
    func testOrbPositionSave() {
        let testPosition = CGPoint(x: 100, y: 200)
        viewModel.updateOrbPosition(testPosition)
        
        XCTAssertEqual(viewModel.orbPosition.x, testPosition.x, "X坐标应保存")
        XCTAssertEqual(viewModel.orbPosition.y, testPosition.y, "Y坐标应保存")
    }
    
    func testOrbPositionConstraints() {
        // 测试边界约束
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let outOfBoundsPosition = CGPoint(x: -100, y: -100)
        
        viewModel.updateOrbPosition(outOfBoundsPosition)
        let constrainedPosition = viewModel.constrainedOrbPosition(for: outOfBoundsPosition, in: screenFrame)
        
        XCTAssertGreaterThanOrEqual(constrainedPosition.x, screenFrame.minX, "X不应小于屏幕最小值")
        XCTAssertGreaterThanOrEqual(constrainedPosition.y, screenFrame.minY, "Y不应小于屏幕最小值")
    }
    
    // MARK: - 拖动功能测试
    
    func testOrbDragRequiresClick() {
        // 悬浮球拖动需要点击才能开始
        viewModel.startOrbDrag()
        XCTAssertTrue(viewModel.isOrbDragging, "点击后应开始拖动")
    }
    
    func testOrbPositionUpdateDuringDrag() {
        viewModel.startOrbDrag()
        let newPosition = CGPoint(x: 300, y: 400)
        viewModel.updateOrbPosition(newPosition)
        
        XCTAssertEqual(viewModel.orbPosition, newPosition, "拖动过程中位置应更新")
    }
    
    func testOrbCollapseDuringDrag() {
        viewModel.expandOrb()
        viewModel.startOrbDrag()
        
        // 拖动时窗体应收起
        XCTAssertFalse(viewModel.isOrbExpanded, "拖动时悬浮球应收起")
    }
    
    // MARK: - 展开窗体测试
    
    func testExpandedWindowAppearsOnHover() {
        viewModel.expandOrb()
        XCTAssertTrue(viewModel.showExpandedWindow, "悬停时应显示展开窗体")
    }
    
    func testExpandedWindowClosesOnExit() {
        viewModel.expandOrb()
        viewModel.collapseOrb()
        XCTAssertFalse(viewModel.showExpandedWindow, "移出时应关闭展开窗体")
    }
    
    func testExpandedWindowPosition() {
        viewModel.orbPosition = CGPoint(x: 500, y: 500)
        viewModel.expandOrb()
        
        let expectedPosition = viewModel.calculateExpandedWindowPosition()
        XCTAssertNotNil(expectedPosition, "应计算出展开窗体位置")
    }
    
    // MARK: - 动画测试
    
    func testOrbAnimationState() {
        let expectation = expectation(description: "动画完成")
        
        viewModel.expandOrbWithAnimation {
            XCTAssertTrue(self.viewModel.isOrbExpanded, "动画完成后应展开")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOrbCollapseAnimation() {
        viewModel.expandOrb()
        
        let expectation = expectation(description: "收起动画完成")
        viewModel.collapseOrbWithAnimation {
            XCTAssertFalse(self.viewModel.isOrbExpanded, "动画完成后应收起")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
