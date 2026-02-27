//
//  HubProtocols.swift
//  Hub
//
//  协议层 - 解耦单例依赖，支持依赖注入和测试
//  现有代码可继续使用单例，新代码可通过协议注入
//

import SwiftUI
import AppKit
import SwiftData

// MARK: - 窗口管理协议

/// Hub 窗口管理协议
protocol HubWindowManaging: AnyObject {
    func show(from corner: ScreenCorner, orbFrame: NSRect, modelContainer: ModelContainer?)
    func hide()
    func handleDroppedFiles(_ providers: [NSItemProvider])
}

/// 悬浮球窗口管理协议
protocol OrbWindowManaging: AnyObject {
    var currentCorner: ScreenCorner { get }
    var frame: NSRect { get }
    
    func setup(modelContainer: ModelContainer)
    func closeWindow()
    func showHubWindow()
    func snapToNearestCorner()
    func updatePosition(x: CGFloat, y: CGFloat)
}

// MARK: - 自动收起管理协议

/// 自动收起管理协议
protocol HubAutoCloseManaging: AnyObject {
    var isMouseInHub: Bool { get set }
    var isMouseInOrb: Bool { get set }
    var isDragging: Bool { get set }
    var isShowingSettings: Bool { get set }
    var isShowingConfirmation: Bool { get set }
    var hasItems: Bool { get set }
    var isHubExpanded: Bool { get set }
    var hasMouseEnteredHub: Bool { get set }
    var onClose: (() -> Void)? { get set }
    
    func reset()
    func hubDidExpand()
    func hubDidClose()
    func mouseEnteredHub()
    func mouseExitedHub()
    func mouseEnteredOrb()
    func mouseExitedOrb()
    func startDragging()
    func endDragging()
    func settingsStateChanged(_ isShowing: Bool)
    func confirmationStateChanged(_ isShowing: Bool)
    func itemsCountChanged(_ hasItems: Bool)
}

// MARK: - 屏幕管理协议

/// 屏幕管理协议
protocol ScreenManaging: AnyObject {
    func getMainScreen() -> NSScreen?
    func detectMainScreenType() -> ScreenType
    func getModeForScreenType() -> HubMode
    func mockScreenType(_ type: ScreenType)
}

// MARK: - 默认实现扩展

/// 让现有单例类默认实现协议
extension HubWindowManager: HubWindowManaging {}

extension OrbWindowManager: OrbWindowManaging {}

extension HubAutoCloseManager: HubAutoCloseManaging {}

extension ScreenManager: ScreenManaging {}

// MARK: - 依赖容器

/// 简单的依赖容器 - 用于管理依赖注入
@MainActor
final class HubDependencies {
    static let shared = HubDependencies()
    
    private init() {}
    
    // MARK: - 可覆盖的依赖
    
    /// 窗口管理器（默认使用单例）
    var windowManager: HubWindowManaging {
        _windowManagerOverride ?? HubWindowManager.shared
    }
    
    /// 悬浮球管理器（默认使用单例）
    var orbManager: OrbWindowManaging {
        _orbManagerOverride ?? OrbWindowManager.shared
    }
    
    /// 自动收起管理器（默认使用单例）
    var autoCloseManager: HubAutoCloseManaging {
        _autoCloseManagerOverride ?? HubAutoCloseManager.shared
    }
    
    /// 屏幕管理器（默认使用单例）
    var screenManager: ScreenManaging {
        _screenManagerOverride ?? ScreenManager.shared
    }
    
    // MARK: - 测试用覆盖方法
    
    /// 用于测试：覆盖窗口管理器
    func overrideWindowManager(_ manager: HubWindowManaging) {
        _windowManagerOverride = manager
    }
    
    /// 用于测试：覆盖悬浮球管理器
    func overrideOrbManager(_ manager: OrbWindowManaging) {
        _orbManagerOverride = manager
    }
    
    /// 用于测试：覆盖自动收起管理器
    func overrideAutoCloseManager(_ manager: HubAutoCloseManaging) {
        _autoCloseManagerOverride = manager
    }
    
    /// 用于测试：覆盖屏幕管理器
    func overrideScreenManager(_ manager: ScreenManaging) {
        _screenManagerOverride = manager
    }
    
    /// 重置所有覆盖
    func resetOverrides() {
        _windowManagerOverride = nil
        _orbManagerOverride = nil
        _autoCloseManagerOverride = nil
        _screenManagerOverride = nil
    }
    
    // MARK: - 私有存储
    
    private var _windowManagerOverride: HubWindowManaging?
    private var _orbManagerOverride: OrbWindowManaging?
    private var _autoCloseManagerOverride: HubAutoCloseManaging?
    private var _screenManagerOverride: ScreenManaging?
}

// MARK: - 环境键

/// SwiftUI 环境键 - 用于在视图层级中传递依赖
struct HubDependenciesKey: EnvironmentKey {
    static let defaultValue = HubDependencies.shared
}

extension EnvironmentValues {
    var hubDependencies: HubDependencies {
        get { self[HubDependenciesKey.self] }
        set { self[HubDependenciesKey.self] = newValue }
    }
}

/*

 // MARK: - 使用示例
 
 // 1. 在生产代码中使用（默认使用单例）
 
 class MyViewModel {
     private let windowManager: HubWindowManaging
     
     init(windowManager: HubWindowManaging = HubDependencies.shared.windowManager) {
         self.windowManager = windowManager
     }
     
     func showHub() {
         windowManager.show(from: .bottomRight, orbFrame: .zero, modelContainer: nil)
     }
 }
 
 
 // 2. 在测试中使用 Mock
 
 class MockWindowManager: HubWindowManaging {
     var showCalled = false
     
     func show(from corner: ScreenCorner, orbFrame: NSRect, modelContainer: ModelContainer?) {
         showCalled = true
     }
     
     func hide() {}
     func handleDroppedFiles(_ providers: [NSItemProvider]) {}
 }
 
 @Test
 func testShowHub() {
     let mock = MockWindowManager()
     HubDependencies.shared.overrideWindowManager(mock)
     
     // 测试代码...
     
     #expect(mock.showCalled)
     
     HubDependencies.shared.resetOverrides()
 }
 
 
 // 3. 在 SwiftUI 视图中使用环境注入
 
 struct MyView: View {
     @Environment(\.hubDependencies) private var dependencies
     
     var body: some View {
         Button("Show Hub") {
             dependencies.windowManager.show(from: .bottomRight, orbFrame: .zero, modelContainer: nil)
         }
     }
 }
 
 
 // 4. 为预览提供 Mock 依赖
 
 #Preview {
     MyView()
         .environment(\.hubDependencies, {
             let deps = HubDependencies()
             deps.overrideWindowManager(MockWindowManager())
             return deps
         }())
 }

 */