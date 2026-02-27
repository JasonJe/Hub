//
//  HubEvents.swift
//  Hub
//
//  类型安全的事件系统 - 使用 Combine 替代 NotificationCenter
//
//  ⚠️ 重要：迁移指南
//  - 现有代码继续使用 NotificationCenter，无需修改
//  - 新功能推荐使用 HubEvents，类型安全且 IDE 友好
//  - 不要同时使用两种系统发布相同事件，会导致重复处理
//  - 渐进式迁移：可在订阅端先迁移到 HubEvents，再迁移发布端
//
//  迁移对照表：
//  | 旧方式 (NotificationCenter)              | 新方式 (HubEvents)                        |
//  |------------------------------------------|-------------------------------------------|
//  | .post(name: .hubWindowStateChanged, ...) | HubEvents.shared.publishHubWindow...      |
//  | .publisher(for: .hubWindowStateChanged)  | HubEvents.shared.hubWindowStateChanged    |
//  | userInfo: ["isExpanded": true]           | HubWindowStateEvent(isExpanded: true)     |
//

import Combine
import SwiftUI
import AppKit

// MARK: - 类型安全事件系统

/// Hub 事件总线 - 使用 Combine 提供类型安全的事件发布/订阅
@MainActor
final class HubEvents {
    static let shared = HubEvents()
    
    private init() {}
    
    // MARK: - 事件发布者
    
    /// Hub 窗口状态变化事件
    let hubWindowStateChanged = PassthroughSubject<HubWindowStateEvent, Never>()
    
    /// 悬浮球拖拽事件
    let orbDragEvent = PassthroughSubject<OrbDragEvent, Never>()
    
    /// 文件拖放事件
    let fileDropEvent = PassthroughSubject<FileDropEvent, Never>()
    
    /// 鼠标事件
    let mouseEvent = PassthroughSubject<MouseEvent, Never>()
    
    /// 设置事件
    let settingsEvent = PassthroughSubject<SettingsEvent, Never>()
    
    /// Hub 模式变化事件
    let hubModeChanged = PassthroughSubject<HubMode, Never>()
    
    // MARK: - 订阅管理
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 便捷订阅方法
    func subscribe<T>(_ subject: PassthroughSubject<T, Never>, handler: @escaping (T) -> Void) -> AnyCancellable {
        return subject.sink { value in
            Task { @MainActor in
                handler(value)
            }
        }
    }
}

// MARK: - 事件类型定义

/// Hub 窗口状态事件
struct HubWindowStateEvent {
    let isExpanded: Bool
    let corner: ScreenCorner?
}

/// 悬浮球拖拽事件
struct OrbDragEvent {
    enum EventType {
        case started
        case updated(position: CGPoint)
        case ended
    }
    
    let type: EventType
}

/// 文件拖放事件
struct FileDropEvent {
    enum EventType {
        case dragEntered
        case dragExited
        case dropped(providers: [NSItemProvider])
        case processing(providers: [NSItemProvider])
    }
    
    let type: EventType
}

/// 鼠标事件
struct MouseEvent {
    enum EventType {
        case enteredHub
        case exitedHub
        case enteredOrb
        case exitedOrb
        case clickedOutside
    }
    
    let type: EventType
}

/// 设置事件
struct SettingsEvent {
    enum EventType {
        case openSettings
        case closeSettings
        case applySettings
    }
    
    let type: EventType
}

// MARK: - 便捷扩展

extension HubEvents {
    /// 发布 Hub 窗口状态变化
    func publishHubWindowStateChanged(isExpanded: Bool, corner: ScreenCorner? = nil) {
        hubWindowStateChanged.send(HubWindowStateEvent(isExpanded: isExpanded, corner: corner))
    }
    
    /// 发布悬浮球拖拽开始
    func publishOrbDragStarted() {
        orbDragEvent.send(OrbDragEvent(type: .started))
    }
    
    /// 发布悬浮球拖拽更新
    func publishOrbDragUpdated(position: CGPoint) {
        orbDragEvent.send(OrbDragEvent(type: .updated(position: position)))
    }
    
    /// 发布悬浮球拖拽结束
    func publishOrbDragEnded() {
        orbDragEvent.send(OrbDragEvent(type: .ended))
    }
    
    /// 发布文件拖放
    func publishFileDropped(providers: [NSItemProvider]) {
        fileDropEvent.send(FileDropEvent(type: .dropped(providers: providers)))
    }
    
    /// 发布鼠标进入 Hub
    func publishMouseEnteredHub() {
        mouseEvent.send(MouseEvent(type: .enteredHub))
    }
    
    /// 发布鼠标离开 Hub
    func publishMouseExitedHub() {
        mouseEvent.send(MouseEvent(type: .exitedHub))
    }
    
    /// 发布设置变化
    func publishSettingsEvent(_ type: SettingsEvent.EventType) {
        settingsEvent.send(SettingsEvent(type: type))
    }
}

// MARK: - 与通知中心的桥接（可选使用）

extension HubEvents {
    /// 将通知中心事件桥接到 Combine（供迁移使用）
    func bridgeNotification(_ name: Notification.Name, to subject: PassthroughSubject<Bool, Never>, key: String) {
        NotificationCenter.default.publisher(for: name)
            .compactMap { $0.userInfo?[key] as? Bool }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                subject.send(value)
            }
            .store(in: &cancellables)
    }
}

// MARK: - 使用示例（注释供参考）

/*
 // 新代码使用方式：
 
 // 1. 订阅事件
 let cancellable = HubEvents.shared.hubWindowStateChanged
     .sink { event in
         print("Hub expanded: \(event.isExpanded)")
     }
 
 // 2. 发布事件
 HubEvents.shared.publishHubWindowStateChanged(isExpanded: true)
 
 // 3. 在视图中使用
 struct MyView: View {
     @State private var isExpanded = false
     private let events = HubEvents.shared
     private var cancellables = Set<AnyCancellable>()
     
     var body: some View {
         Text(isExpanded ? "Expanded" : "Collapsed")
             .onAppear {
                 events.hubWindowStateChanged
                     .assign(to: \.isExpanded, on: self)
                     .store(in: &cancellables)
             }
     }
 }
 */
