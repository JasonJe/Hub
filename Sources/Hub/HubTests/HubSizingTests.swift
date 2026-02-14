//
//  HubSizingTests.swift
//  HubTests
//
//  Tests for Hub sizing constants and calculations
//

import Testing
import SwiftUI
@testable import Hub

struct HubSizingTests {

    // MARK: - Constant Values Tests
    
    @Test
    func testShadowPaddingValue() {
        // 阴影内边距应为 20pt
        #expect(shadowPadding == 20)
    }
    
    @Test
    func testOpenHubSizeValue() {
        // 展开时宽度 360pt，高度 220pt
        #expect(openHubSize.width == 360)
        #expect(openHubSize.height == 220)
    }
    
    @Test
    func testWindowSizeIncludesShadowPadding() {
        // 窗口总尺寸 = 展开尺寸 + 阴影内边距
        #expect(windowSize.width == openHubSize.width)
        #expect(windowSize.height == openHubSize.height + shadowPadding)
        #expect(windowSize.height == 240) // 220 + 20
    }
    
    @Test
    func testWindowSizeWidthEqualsOpenHubWidth() {
        // 窗口宽度应等于展开宽度
        #expect(windowSize.width == 360)
    }
    
    // MARK: - Corner Radius Tests
    
    @Test
    func testOpenedCornerRadiusTopValue() {
        // 展开状态顶部圆角 4pt
        #expect(cornerRadiusInsets.opened.top == 4)
    }
    
    @Test
    func testOpenedCornerRadiusBottomValue() {
        // 展开状态底部圆角 32pt
        #expect(cornerRadiusInsets.opened.bottom == 32)
    }
    
    @Test
    func testClosedCornerRadiusTopValue() {
        // 闭合状态顶部圆角 0pt（贴合刘海）
        #expect(cornerRadiusInsets.closed.top == 0)
    }
    
    @Test
    func testClosedCornerRadiusBottomValue() {
        // 闭合状态底部圆角 24pt
        #expect(cornerRadiusInsets.closed.bottom == 24)
    }
    
    @Test
    func testOpenedBottomCornerLargerThanTop() {
        // 展开状态底部圆角 > 顶部圆角
        #expect(cornerRadiusInsets.opened.bottom > cornerRadiusInsets.opened.top)
    }
    
    @Test
    func testClosedBottomCornerLargerThanTop() {
        // 闭合状态底部圆角 > 顶部圆角
        #expect(cornerRadiusInsets.closed.bottom > cornerRadiusInsets.closed.top)
    }
    
    // MARK: - Size Calculation Tests
    
    @Test
    func testOpenHubSizeIsPositive() {
        #expect(openHubSize.width > 0)
        #expect(openHubSize.height > 0)
    }
    
    @Test
    func testWindowSizeIsPositive() {
        #expect(windowSize.width > 0)
        #expect(windowSize.height > 0)
    }
    
    @Test
    func testShadowPaddingIsPositive() {
        #expect(shadowPadding > 0)
    }
    
    // MARK: - Size Ratio Tests
    
    @Test
    func testOpenHubWidthHeightRatio() {
        // 宽度应大于高度
        #expect(openHubSize.width > openHubSize.height)
    }
    
    @Test
    func testWindowSizeHeightIsLarger() {
        // 窗口高度应大于展开高度
        #expect(windowSize.height > openHubSize.height)
    }
    
    // MARK: - Corner Radius Consistency Tests
    
    @Test
    func testOpenedTopCornerNonNegative() {
        #expect(cornerRadiusInsets.opened.top >= 0)
    }
    
    @Test
    func testOpenedBottomCornerNonNegative() {
        #expect(cornerRadiusInsets.opened.bottom >= 0)
    }
    
    @Test
    func testClosedTopCornerNonNegative() {
        #expect(cornerRadiusInsets.closed.top >= 0)
    }
    
    @Test
    func testClosedBottomCornerNonNegative() {
        #expect(cornerRadiusInsets.closed.bottom >= 0)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testAllSizesAreValid() {
        // 所有尺寸值都应该是有效的正数
        #expect(shadowPadding > 0)
        #expect(openHubSize.width > 0)
        #expect(openHubSize.height > 0)
        #expect(windowSize.width > 0)
        #expect(windowSize.height > 0)
    }
    
    @Test
    func testAllCornerRadiiAreValid() {
        // 所有圆角值都应该是非负数
        #expect(cornerRadiusInsets.opened.top >= 0)
        #expect(cornerRadiusInsets.opened.bottom >= 0)
        #expect(cornerRadiusInsets.closed.top >= 0)
        #expect(cornerRadiusInsets.closed.bottom >= 0)
    }
    
    // MARK: - Design Constants Verification
    
    @Test
    func testDesignConstantsMatchExpected() {
        // 验证设计常量符合预期
        // 这些测试确保设计规格没有被意外修改
        
        // 阴影
        #expect(shadowPadding == 20)
        
        // 展开尺寸
        #expect(openHubSize.width == 360)
        #expect(openHubSize.height == 220)
        
        // 窗口尺寸
        #expect(windowSize.width == 360)
        #expect(windowSize.height == 240)
        
        // 展开圆角
        #expect(cornerRadiusInsets.opened.top == 4)
        #expect(cornerRadiusInsets.opened.bottom == 32)
        
        // 闭合圆角
        #expect(cornerRadiusInsets.closed.top == 0)
        #expect(cornerRadiusInsets.closed.bottom == 24)
    }
    
    // MARK: - Window Size Calculation Tests
    
    @Test
    func testWindowSizeCalculation() {
        let expectedHeight = openHubSize.height + shadowPadding
        #expect(windowSize.height == expectedHeight)
    }
    
    @Test
    func testWindowWidthUnchangedByShadowPadding() {
        // 阴影只影响高度，不影响宽度
        #expect(windowSize.width == openHubSize.width)
    }
    
    // MARK: - Minimum Size Tests
    
    @Test
    func testMinimumOpenWidth() {
        // 展开宽度至少应能容纳 4 列图标
        // 64pt * 4 + 间距 + 内边距 ≈ 360pt
        #expect(openHubSize.width >= 300)
    }
    
    @Test
    func testMinimumOpenHeight() {
        // 展开高度至少应能容纳标题栏 + 内容 + 底部栏
        #expect(openHubSize.height >= 150)
    }
}