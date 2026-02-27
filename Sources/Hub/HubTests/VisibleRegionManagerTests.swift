//
//  VisibleRegionManagerTests.swift
//  HubTests
//
//  Tests for VisibleRegionManager visible region calculations
//

import Testing
import AppKit
@testable import Hub

@MainActor
struct VisibleRegionManagerTests {
    
    // MARK: - Singleton Tests
    
    @Test
    func testSharedInstance() {
        let manager1 = VisibleRegionManager.shared
        let manager2 = VisibleRegionManager.shared
        
        #expect(manager1 === manager2)
    }
    
    // MARK: - Refresh Tests
    
    @Test
    func testRefreshPopulatesVisibleRects() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        // Should have at least one screen
        #expect(manager.visibleRects.count >= 1)
    }
    
    @Test
    func testRefreshPopulatesScreenInfos() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        #expect(manager.screenInfos.count >= 1)
    }
    
    // MARK: - Contains Tests
    
    @Test
    func testContainsPointInVisibleRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        // Use the center of the first visible rect
        if let firstRect = manager.visibleRects.first {
            let centerPoint = CGPoint(x: firstRect.midX, y: firstRect.midY)
            #expect(manager.contains(centerPoint) == true)
        }
    }
    
    @Test
    func testContainsPointOutsideVisibleRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        // Point far outside any screen
        let farPoint = CGPoint(x: -10000, y: -10000)
        #expect(manager.contains(farPoint) == false)
    }
    
    // MARK: - Mostly Contains Tests
    
    @Test
    func testMostlyContainsValidRect() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            // Small rect in the center of visible region
            let smallRect = CGRect(
                x: firstRect.midX - 10,
                y: firstRect.midY - 10,
                width: 20,
                height: 20
            )
            #expect(manager.mostlyContains(smallRect, threshold: 0.8) == true)
        }
    }
    
    @Test
    func testMostlyContainsInvalidRect() {
        let manager = VisibleRegionManager.shared
        
        // Rect far outside any screen
        let farRect = CGRect(x: -10000, y: -10000, width: 100, height: 100)
        #expect(manager.mostlyContains(farRect) == false)
    }
    
    @Test
    func testMostlyContainsInvalidRectSize() {
        let manager = VisibleRegionManager.shared
        
        // Rect with invalid size
        let invalidRect = CGRect(x: 100, y: 100, width: 0, height: 0)
        #expect(manager.mostlyContains(invalidRect) == false)
    }
    
    @Test
    func testMostlyContainsWithInvalidThreshold() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let rect = CGRect(
                x: firstRect.midX - 10,
                y: firstRect.midY - 10,
                width: 20,
                height: 20
            )
            // Threshold should be clamped to valid range
            #expect(manager.mostlyContains(rect, threshold: 2.0) == true)
            #expect(manager.mostlyContains(rect, threshold: -1.0) == true)
        }
    }
    
    // MARK: - Calculate Visible Area Tests
    
    @Test
    func testCalculateVisibleAreaForRectInRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let rect = CGRect(
                x: firstRect.midX - 50,
                y: firstRect.midY - 50,
                width: 100,
                height: 100
            )
            let area = manager.calculateVisibleArea(for: rect)
            #expect(area > 0)
        }
    }
    
    @Test
    func testCalculateVisibleAreaForRectOutsideRegion() {
        let manager = VisibleRegionManager.shared
        
        let farRect = CGRect(x: -10000, y: -10000, width: 100, height: 100)
        let area = manager.calculateVisibleArea(for: farRect)
        #expect(area == 0)
    }
    
    // MARK: - Find Containing Rect Tests
    
    @Test
    func testFindContainingRectForPointInRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let centerPoint = CGPoint(x: firstRect.midX, y: firstRect.midY)
            let containingRect = manager.findContainingRect(for: centerPoint)
            #expect(containingRect != nil)
        }
    }
    
    @Test
    func testFindContainingRectForPointOutsideRegion() {
        let manager = VisibleRegionManager.shared
        
        let farPoint = CGPoint(x: -10000, y: -10000)
        let containingRect = manager.findContainingRect(for: farPoint)
        #expect(containingRect == nil)
    }
    
    // MARK: - Clamp Tests
    
    @Test
    func testClampToVisibleRegionForPointInRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let centerPoint = CGPoint(x: firstRect.midX, y: firstRect.midY)
            let clampedPoint = manager.clampToVisibleRegion(centerPoint)
            #expect(clampedPoint == centerPoint)
        }
    }
    
    @Test
    func testClampToVisibleRegionForPointOutsideRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        let farPoint = CGPoint(x: -10000, y: -10000)
        let clampedPoint = manager.clampToVisibleRegion(farPoint)
        
        // Should be clamped to a valid position
        #expect(clampedPoint.x > -10000)
        #expect(clampedPoint.y > -10000)
    }
    
    @Test
    func testClampRectToVisibleRegion() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        let rect = CGRect(x: -10000, y: -10000, width: 100, height: 100)
        let clampedOrigin = manager.clampRectToVisibleRegion(rect)
        
        // Should be clamped to a valid position
        #expect(clampedOrigin.x > -10000)
        #expect(clampedOrigin.y > -10000)
    }
    
    @Test
    func testClampRectWithInvalidSize() {
        let manager = VisibleRegionManager.shared
        
        let invalidRect = CGRect(x: 100, y: 100, width: 0, height: 0)
        let clampedOrigin = manager.clampRectToVisibleRegion(invalidRect)
        
        // Should return the original point (or safe default)
        #expect(clampedOrigin.x >= 0 || clampedOrigin.x == invalidRect.origin.x)
    }
    
    @Test
    func testClampRectWithNegativeSize() {
        let manager = VisibleRegionManager.shared
        
        let invalidRect = CGRect(x: 100, y: 100, width: -50, height: -50)
        let clampedOrigin = manager.clampRectToVisibleRegion(invalidRect)
        
        // Should handle gracefully
        #expect(clampedOrigin.x >= 0 || clampedOrigin.x == invalidRect.origin.x)
    }
    
    @Test
    func testClampRectWithValidPadding() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let rect = CGRect(
                x: firstRect.midX - 50,
                y: firstRect.midY - 50,
                width: 100,
                height: 100
            )
            let clampedOrigin = manager.clampRectToVisibleRegion(rect, padding: 10)
            
            // Should be clamped with padding consideration
            #expect(clampedOrigin.x >= firstRect.minX - 10)
        }
    }
    
    @Test
    func testClampRectWithNegativePadding() {
        let manager = VisibleRegionManager.shared
        manager.refresh()
        
        if let firstRect = manager.visibleRects.first {
            let rect = CGRect(
                x: firstRect.midX - 50,
                y: firstRect.midY - 50,
                width: 100,
                height: 100
            )
            // Negative padding should be clamped to 0
            let clampedOrigin = manager.clampRectToVisibleRegion(rect, padding: -10)
            
            // Should handle gracefully (padding should be clamped to 0)
            #expect(clampedOrigin.x >= firstRect.minX)
        }
    }
    
    // MARK: - Screen Configuration Change Tests
    
    @Test
    func testOnScreenConfigurationChangedCallback() {
        let manager = VisibleRegionManager.shared
        
        manager.onScreenConfigurationChanged = {
            // Callback set successfully
        }
        
        #expect(manager.onScreenConfigurationChanged != nil)
    }
    
    // MARK: - Input Validation Tests
    
    @Test
    func testMostlyContainsWithNaNRect() {
        let manager = VisibleRegionManager.shared
        
        let nanRect = CGRect(x: CGFloat.nan, y: CGFloat.nan, width: CGFloat.nan, height: CGFloat.nan)
        #expect(manager.mostlyContains(nanRect) == false)
    }
    
    @Test
    func testMostlyContainsWithInfiniteRect() {
        let manager = VisibleRegionManager.shared
        
        let infiniteRect = CGRect.infinite
        #expect(manager.mostlyContains(infiniteRect) == false)
    }
}
