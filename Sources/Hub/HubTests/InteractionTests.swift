//
//  InteractionTests.swift
//  HubTests
//

import Testing
import AppKit
import SwiftUI
@testable import Hub

struct InteractionTests {

    @Test
    func testHitTestingOnContentArea() {
        // 准备 HostingView
        let view = HubHostingView(rootView: EmptyView())
        view.frame = NSRect(x: 0, y: 0, width: HubMetrics.windowSize.width, height: HubMetrics.windowSize.height)
        
        // 点击在内容区域中心 (应该拦截)
        let contentPoint = NSPoint(
            x: HubMetrics.sidePadding + HubMetrics.openHubSize.width / 2,
            y: HubMetrics.shadowPadding + HubMetrics.openHubSize.height / 2
        )
        
        #expect(view.hitTest(contentPoint) != nil, "内容区域的点击应该被拦截")
    }
    
    @Test
    func testHitTestingOnShadowArea() {
        // 准备 HostingView
        let view = HubHostingView(rootView: EmptyView())
        view.frame = NSRect(x: 0, y: 0, width: HubMetrics.windowSize.width, height: HubMetrics.windowSize.height)
        
        // 点击在左侧阴影边缘 (应该穿透)
        let leftShadowPoint = NSPoint(x: HubMetrics.sidePadding / 2, y: HubMetrics.windowSize.height / 2)
        #expect(view.hitTest(leftShadowPoint) == nil, "左侧阴影区的点击应该穿透")
        
        // 点击在底部阴影边缘 (应该穿透)
        let bottomShadowPoint = NSPoint(x: HubMetrics.windowSize.width / 2, y: HubMetrics.shadowPadding / 2)
        #expect(view.hitTest(bottomShadowPoint) == nil, "底部阴影区的点击应该穿透")
    }
}
