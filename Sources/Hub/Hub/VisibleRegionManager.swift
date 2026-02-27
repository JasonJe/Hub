//
//  VisibleRegionManager.swift
//  Hub
//
//  可见区域管理器 - 管理多屏幕可见区域多边形
//  统一处理多屏幕、Dock、菜单栏等边界情况
//

import AppKit

/// 可见区域多边形管理器
/// 将所有屏幕的可见区域合并为一个或多个矩形区域
/// 提供点包含检测和边界距离计算
@MainActor
class VisibleRegionManager {
    
    // MARK: - Singleton
    
    static let shared = VisibleRegionManager()
    
    // MARK: - Properties
    
    /// 所有可见区域矩形（每个屏幕一个）
    private(set) var visibleRects: [CGRect] = []
    
    /// 所有屏幕信息（用于调试）
    private(set) var screenInfos: [(frame: CGRect, visibleFrame: CGRect)] = []
    
    /// 屏幕配置变化回调
    var onScreenConfigurationChanged: (() -> Void)?
    
    /// 是否正在监听屏幕变化
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    private init() {
        refresh()
        startMonitoring()
    }
    
    // MARK: - Screen Monitoring
    
    /// 开始监听屏幕配置变化
    private func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // 监听屏幕参数变化（分辨率、位置、连接/断开等）
        // NSApplication.didChangeScreenParametersNotification 会捕获所有屏幕相关变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        HubLogger.log("🖥️ 开始监听屏幕配置变化")
    }
    
    /// 停止监听屏幕配置变化
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        HubLogger.log("🖥️ 停止监听屏幕配置变化")
    }
    
    /// 屏幕参数变化处理
    @objc private func handleScreenParametersChanged() {
        HubLogger.log("🖥️ 检测到屏幕配置变化")
        
        // 保存旧的配置用于比较
        let oldRects = visibleRects
        
        // 刷新可见区域
        refresh()
        
        // 检查是否真的有变化
        let hasChanged = oldRects.count != visibleRects.count ||
                        !zip(oldRects, visibleRects).allSatisfy { $0 == $1 }
        
        if hasChanged {
            HubLogger.log("🖥️ 屏幕可见区域已变化，触发回调")
            onScreenConfigurationChanged?()
        } else {
            HubLogger.log("🖥️ 屏幕可见区域无变化")
        }
    }
    
    // MARK: - Public Methods
    
    /// 刷新可见区域（屏幕配置变化时调用）
    func refresh() {
        visibleRects = []
        screenInfos = []
        
        let screens = NSScreen.screens
        
        HubLogger.log("🔄 可见区域已刷新，共 \(screens.count) 个屏幕")
        
        for (index, screen) in screens.enumerated() {
            let frame = screen.frame
            let visibleFrame = screen.visibleFrame
            
            visibleRects.append(visibleFrame)
            screenInfos.append((frame: frame, visibleFrame: visibleFrame))
            
            // 计算被排除的区域（Dock 和菜单栏）
            let leftExcluded = visibleFrame.minX - frame.minX
            let rightExcluded = frame.maxX - visibleFrame.maxX
            let bottomExcluded = visibleFrame.minY - frame.minY
            let topExcluded = frame.maxY - visibleFrame.maxY
            
            HubLogger.log("  屏幕[\(index)]:")
            HubLogger.log("    完整区域: \(frame)")
            HubLogger.log("    可见区域: \(visibleFrame)")
            HubLogger.log("    排除区域: 左=\(leftExcluded), 右=\(rightExcluded), 下=\(bottomExcluded), 上=\(topExcluded)")
            
            // 推断 Dock 位置
            if leftExcluded > 10 {
                HubLogger.log("    ⚓ Dock 可能在左侧")
            } else if rightExcluded > 10 {
                HubLogger.log("    ⚓ Dock 可能在右侧")
            } else if bottomExcluded > 10 {
                HubLogger.log("    ⚓ Dock 可能在底部")
            }
            
            // 菜单栏通常在顶部
            if topExcluded > 20 {
                HubLogger.log("    📋 菜单栏: \(topExcluded)pt")
            }
        }
    }
    
    /// 检查点是否在任意可见区域内
    /// - Parameter point: 要检查的点
    /// - Returns: 是否在可见区域内
    func contains(_ point: CGPoint) -> Bool {
        for rect in visibleRects {
            if rect.contains(point) {
                return true
            }
        }
        return false
    }
    
    /// 检查矩形是否大部分在可见区域内
    /// - Parameters:
    ///   - rect: 要检查的矩形
    ///   - threshold: 最小可见比例（默认 0.8，即 80%）
    /// - Returns: 是否大部分在可见区域内
    func mostlyContains(_ rect: CGRect, threshold: CGFloat = 0.8) -> Bool {
        // 输入验证：无效矩形
        guard rect.width > 0 && rect.height > 0 else {
            HubLogger.log("⚠️ mostlyContains: 无效矩形尺寸")
            return false
        }
        
        // 输入验证：阈值范围
        let validThreshold = max(0, min(1, threshold))
        
        let visibleArea = calculateVisibleArea(for: rect)
        let totalArea = rect.width * rect.height
        let ratio = visibleArea / totalArea
        return ratio >= validThreshold
    }
    
    /// 计算矩形在可见区域内的面积
    /// - Parameter rect: 要计算的矩形
    /// - Returns: 可见面积
    func calculateVisibleArea(for rect: CGRect) -> CGFloat {
        // 输入验证：无效矩形返回 0
        guard rect.width > 0 && rect.height > 0 else {
            return 0
        }
        
        var totalVisibleArea: CGFloat = 0
        
        for visibleRect in visibleRects {
            let intersection = rect.intersection(visibleRect)
            if !intersection.isNull {
                totalVisibleArea += intersection.width * intersection.height
            }
        }
        
        return totalVisibleArea
    }
    
    /// 找到包含指定点的可见区域
    /// - Parameter point: 要检查的点
    /// - Returns: 包含该点的可见区域，如果没有则返回 nil
    func findContainingRect(for point: CGPoint) -> CGRect? {
        for rect in visibleRects {
            if rect.contains(point) {
                return rect
            }
        }
        return nil
    }
    
    /// 计算点到最近可见区域边界的距离和方向
    /// - Parameter point: 要计算的点
    /// - Returns: (最近的可见区域, 到该区域边界的距离向量)
    func distanceToNearestVisibleRegion(from point: CGPoint) -> (rect: CGRect, offset: CGPoint)? {
        var nearestRect: CGRect?
        var minDistance = CGFloat.infinity
        var offset = CGPoint.zero
        
        for rect in visibleRects {
            // 计算点到矩形边界的最短距离
            let (distance, dx, dy) = distanceFromPoint(point, to: rect)
            
            if distance < minDistance {
                minDistance = distance
                nearestRect = rect
                offset = CGPoint(x: dx, y: dy)
            }
        }
        
        if let rect = nearestRect {
            return (rect, offset)
        }
        return nil
    }
    
    /// 将点移动到最近的可见区域内
    /// - Parameters:
    ///   - point: 要移动的点
    ///   - padding: 距离边缘的最小距离（默认 0）
    /// - Returns: 移动后的点
    func clampToVisibleRegion(_ point: CGPoint, padding: CGFloat = 0) -> CGPoint {
        // 首先检查是否已在某个区域内
        for rect in visibleRects {
            let paddedRect = rect.insetBy(dx: padding, dy: padding)
            if paddedRect.contains(point) {
                return point
            }
        }
        
        // 不在任何区域内，找到最近的区域并移动到边界内
        if let (rect, _) = distanceToNearestVisibleRegion(from: point) {
            let paddedRect = rect.insetBy(dx: padding, dy: padding)
            return clampPoint(point, to: paddedRect)
        }
        
        // 兜底：返回第一个区域的中心
        if let firstRect = visibleRects.first {
            return CGPoint(x: firstRect.midX, y: firstRect.midY)
        }
        
        return point
    }
    
    /// 将矩形移动到完全在可见区域内
    /// - Parameters:
    ///   - rect: 要移动的矩形
    ///   - padding: 距离边缘的最小距离（默认 0）
    /// - Returns: 移动后的矩形原点
    func clampRectToVisibleRegion(_ rect: CGRect, padding: CGFloat = 0) -> CGPoint {
        // 输入验证：无效矩形尺寸
        guard rect.width > 0 && rect.height > 0 else {
            HubLogger.log("⚠️ clampRectToVisibleRegion: 无效矩形尺寸，返回原点")
            return rect.origin
        }
        
        // 输入验证：负数 padding 修正为 0
        let safePadding = max(0, padding)
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        HubLogger.log("  📐 clampRectToVisibleRegion:")
        HubLogger.log("    输入矩形: origin=(\(rect.origin.x), \(rect.origin.y)), size=(\(rect.width), \(rect.height))")
        HubLogger.log("    中心点: (\(center.x), \(center.y))")
        HubLogger.log("    可见区域数量: \(visibleRects.count)")
        
        for (index, visibleRect) in visibleRects.enumerated() {
            HubLogger.log("    可见区域[\(index)]: \(visibleRect)")
        }
        
        // 找到包含中心点的区域
        for visibleRect in visibleRects {
            let paddedRect = visibleRect.insetBy(dx: safePadding, dy: safePadding)
            if paddedRect.contains(center) {
                // 中心点在区域内，检查整个矩形是否在区域内
                let clampedOrigin = clampRect(rect, to: paddedRect)
                let clampedRect = CGRect(origin: clampedOrigin, size: rect.size)
                
                HubLogger.log("    中心点在区域内: \(visibleRect)")
                HubLogger.log("    填充后区域: \(paddedRect)")
                HubLogger.log("    限制后原点: (\(clampedOrigin.x), \(clampedOrigin.y))")
                
                // 检查是否完全在区域内
                if paddedRect.contains(clampedRect) {
                    HubLogger.log("    ✅ 矩形完全在区域内")
                    return clampedOrigin
                }
            }
        }
        
        // 不在任何区域内，找到最近的区域
        if let (nearestRect, _) = distanceToNearestVisibleRegion(from: center) {
            let paddedRect = nearestRect.insetBy(dx: safePadding, dy: safePadding)
            let result = clampRect(rect, to: paddedRect)
            HubLogger.log("    中心点不在任何区域内，最近区域: \(nearestRect)")
            HubLogger.log("    结果: (\(result.x), \(result.y))")
            return result
        }
        
        // 兜底：返回第一个区域的左下角
        if let firstRect = visibleRects.first {
            let paddedRect = firstRect.insetBy(dx: safePadding, dy: safePadding)
            let result = CGPoint(x: paddedRect.minX, y: paddedRect.minY)
            HubLogger.log("    兜底返回第一个区域: \(firstRect)")
            HubLogger.log("    结果: (\(result.x), \(result.y))")
            return result
        }
        
        HubLogger.log("    ⚠️ 没有可见区域，返回原点")
        return rect.origin
    }
    
    // MARK: - Debug
    
    /// 打印调试信息
    func debugPrint() {
        HubLogger.log("═══ 可见区域信息 ═══")
        for (index, info) in screenInfos.enumerated() {
            HubLogger.log("屏幕[\(index)]:")
            HubLogger.log("  frame: \(info.frame)")
            HubLogger.log("  visibleFrame: \(info.visibleFrame)")
        }
        HubLogger.log("═════════════════")
    }
    
    // MARK: - Private Methods
    
    /// 计算点到矩形边界的距离
    /// - Returns: (距离, x方向偏移, y方向偏移)
    private func distanceFromPoint(_ point: CGPoint, to rect: CGRect) -> (CGFloat, CGFloat, CGFloat) {
        // 如果点在矩形内，距离为 0
        if rect.contains(point) {
            return (0, 0, 0)
        }
        
        // 计算到各边的距离
        let dx: CGFloat
        let dy: CGFloat
        
        if point.x < rect.minX {
            dx = point.x - rect.minX
        } else if point.x > rect.maxX {
            dx = point.x - rect.maxX
        } else {
            dx = 0
        }
        
        if point.y < rect.minY {
            dy = point.y - rect.minY
        } else if point.y > rect.maxY {
            dy = point.y - rect.maxY
        } else {
            dy = 0
        }
        
        let distance = sqrt(dx * dx + dy * dy)
        return (distance, dx, dy)
    }
    
    /// 将点限制在矩形内
    private func clampPoint(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        return CGPoint(
            x: max(rect.minX, min(point.x, rect.maxX)),
            y: max(rect.minY, min(point.y, rect.maxY))
        )
    }
    
    /// 将矩形限制在另一个矩形内
    private func clampRect(_ rect: CGRect, to bounds: CGRect) -> CGPoint {
        var origin = rect.origin
        
        // 水平方向
        if rect.width <= bounds.width {
            origin.x = max(bounds.minX, min(origin.x, bounds.maxX - rect.width))
        } else {
            origin.x = bounds.minX
        }
        
        // 垂直方向
        if rect.height <= bounds.height {
            origin.y = max(bounds.minY, min(origin.y, bounds.maxY - rect.height))
        } else {
            origin.y = bounds.minY
        }
        
        return origin
    }
}
