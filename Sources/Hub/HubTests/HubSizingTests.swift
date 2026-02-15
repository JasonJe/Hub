//
//  HubSizingTests.swift
//  HubTests
//

import Testing
import SwiftUI
@testable import Hub

struct HubSizingTests {

    @Test
    func testShadowPaddingValue() {
        #expect(HubMetrics.shadowPadding == 80)
    }
    
    @Test
    func testSidePaddingValue() {
        #expect(HubMetrics.sidePadding == 60)
    }
    
    @Test
    func testOpenHubSizeValue() {
        #expect(HubMetrics.openHubSize.width == 360)
        #expect(HubMetrics.openHubSize.height == 220)
    }
    
    @Test
    func testWindowSizeCalculation() {
        // 窗口总尺寸 = 展开尺寸 + sidePadding*2 (水平) + shadowPadding (垂直)
        let expectedWidth = HubMetrics.openHubSize.width + HubMetrics.sidePadding * 2
        let expectedHeight = HubMetrics.openHubSize.height + HubMetrics.shadowPadding
        
        #expect(HubMetrics.windowSize.width == expectedWidth)
        #expect(HubMetrics.windowSize.height == expectedHeight)
    }
    
    @Test
    func testCornerRadiiAreValid() {
        #expect(HubMetrics.cornerRadiusInsets.opened.top == 16)
        #expect(HubMetrics.cornerRadiusInsets.opened.bottom == 28)
        #expect(HubMetrics.cornerRadiusInsets.closed.top == 0)
        #expect(HubMetrics.cornerRadiusInsets.closed.bottom == 20)
    }
}
