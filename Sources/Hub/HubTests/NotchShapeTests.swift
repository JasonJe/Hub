//
//  NotchShapeTests.swift
//  HubTests
//
//  Tests for NotchShape drawing and animation
//

import Testing
import SwiftUI
@testable import Hub

struct NotchShapeTests {

    // MARK: - Initialization Tests
    
    @Test
    func testNotchShapeDefaultCorners() {
        let shape = NotchShape()
        
        // 默认值：顶部 6，底部 14
        let animatableData = shape.animatableData
        #expect(animatableData.first == 6)
        #expect(animatableData.second == 14)
    }
    
    @Test
    func testNotchShapeCustomCorners() {
        let shape = NotchShape(topCornerRadius: 10, bottomCornerRadius: 20)
        
        let animatableData = shape.animatableData
        #expect(animatableData.first == 10)
        #expect(animatableData.second == 20)
    }
    
    @Test
    func testNotchShapeZeroCorners() {
        let shape = NotchShape(topCornerRadius: 0, bottomCornerRadius: 0)
        
        let animatableData = shape.animatableData
        #expect(animatableData.first == 0)
        #expect(animatableData.second == 0)
    }
    
    // MARK: - Path Tests
    
    @Test
    func testNotchShapePathNotEmpty() {
        let shape = NotchShape(topCornerRadius: 4, bottomCornerRadius: 32)
        let rect = CGRect(x: 0, y: 0, width: 360, height: 220)
        
        let path = shape.path(in: rect)
        
        #expect(path.isEmpty == false)
    }
    
    @Test
    func testNotchShapePathWithZeroRect() {
        let shape = NotchShape()
        let rect = CGRect.zero
        
        let path = shape.path(in: rect)
        
        // 零尺寸 rect 仍应返回路径（可能为空或单点）
        #expect(path != nil)
    }
    
    @Test
    func testNotchShapePathWithSmallRect() {
        let shape = NotchShape(topCornerRadius: 4, bottomCornerRadius: 8)
        let rect = CGRect(x: 0, y: 0, width: 50, height: 30)
        
        let path = shape.path(in: rect)
        
        #expect(path.isEmpty == false)
    }
    
    @Test
    func testNotchShapePathWithLargeRect() {
        let shape = NotchShape(topCornerRadius: 4, bottomCornerRadius: 32)
        let rect = CGRect(x: 0, y: 0, width: 1000, height: 500)
        
        let path = shape.path(in: rect)
        
        #expect(path.isEmpty == false)
    }
    
    // MARK: - AnimatableData Tests
    
    @Test
    func testNotchShapeAnimatableDataSetter() {
        var shape = NotchShape(topCornerRadius: 4, bottomCornerRadius: 32)
        
        // 通过 setter 更新
        shape.animatableData = AnimatablePair(10, 20)
        
        #expect(shape.animatableData.first == 10)
        #expect(shape.animatableData.second == 20)
    }
    
    @Test
    func testNotchShapeAnimatableDataGetter() {
        let shape = NotchShape(topCornerRadius: 8, bottomCornerRadius: 24)
        
        let data = shape.animatableData
        
        #expect(data.first == 8)
        #expect(data.second == 24)
    }
    
    // MARK: - Shape Protocol Tests
    
    @Test
    func testNotchShapeConformsToShape() {
        let shape = NotchShape()
        
        // 验证 Shape 协议一致性（编译时检查）
        let _: any Shape = shape
        
        #expect(true)
    }
    
    @Test
    func testNotchShapeAnimatable() {
        let shape = NotchShape()
        
        // 验证 Animatable 协议一致性（编译时检查）
        let _: any Animatable = shape
        
        #expect(true)
    }
    
    // MARK: - Corner Radius Configuration Tests
    
    @Test
    func testOpenedCornerRadiusConfiguration() {
        // 展开状态的圆角配置
        let openedTop = HubMetrics.cornerRadiusInsets.opened.top
        let openedBottom = HubMetrics.cornerRadiusInsets.opened.bottom
        
        #expect(openedTop == 4)
        #expect(openedBottom == 32)
    }
    
    @Test
    func testClosedCornerRadiusConfiguration() {
        // 闭合状态的圆角配置
        let closedTop = HubMetrics.cornerRadiusInsets.closed.top
        let closedBottom = HubMetrics.cornerRadiusInsets.closed.bottom
        
        #expect(closedTop == 0)
        #expect(closedBottom == 24)
    }
    
    @Test
    func testOpenedTopCornerSmallerThanBottom() {
        // 展开状态：顶部圆角应小于底部
        let openedTop = HubMetrics.cornerRadiusInsets.opened.top
        let openedBottom = HubMetrics.cornerRadiusInsets.opened.bottom
        
        #expect(openedTop < openedBottom)
    }
    
    @Test
    func testClosedTopCornerIsZero() {
        // 闭合状态：顶部圆角应为 0（贴合刘海）
        let closedTop = HubMetrics.cornerRadiusInsets.closed.top
        
        #expect(closedTop == 0)
    }
    
    // MARK: - Path Boundary Tests
    
    @Test
    func testNotchShapePathContainsExpectedPoints() {
        let shape = NotchShape(topCornerRadius: 4, bottomCornerRadius: 32)
        let rect = CGRect(x: 0, y: 0, width: 360, height: 220)
        
        let path = shape.path(in: rect)
        let boundingBox = path.boundingRect
        
        // 路径边界应在 rect 范围内
        #expect(boundingBox.minX >= rect.minX)
        #expect(boundingBox.maxX <= rect.maxX)
        #expect(boundingBox.minY >= rect.minY)
        #expect(boundingBox.maxY <= rect.maxY)
    }
    
    @Test
    func testNotchShapePathWithEqualCorners() {
        // 当顶部和底部圆角相等时
        let shape = NotchShape(topCornerRadius: 20, bottomCornerRadius: 20)
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        
        let path = shape.path(in: rect)
        
        #expect(path.isEmpty == false)
    }
    
    @Test
    func testNotchShapePathWithTopCornerLargerThanBottom() {
        // 当顶部圆角大于底部圆角时（非常规情况）
        let shape = NotchShape(topCornerRadius: 30, bottomCornerRadius: 10)
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        
        let path = shape.path(in: rect)
        
        #expect(path.isEmpty == false)
    }
}