//
//  ScreenManager.swift
//  Hub
//
//  屏幕管理器 - 管理屏幕类型检测和主显示屏变化监听
//

import Cocoa

/// 屏幕管理器
@MainActor
final class ScreenManager {
    
    // MARK: - Singleton
    
    static let shared = ScreenManager()
    
    // MARK: - Properties
    
    let screenDetector = ScreenTypeDetector()
    private var isMonitoring = false
    private var lastPrimaryScreenID: Int?
    var onScreenTypeChanged: ((HubMode) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupScreenMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 获取主屏幕
    func getMainScreen() -> NSScreen? {
        return screenDetector.getMainScreen()
    }
    
    /// 检测主屏幕类型
    func detectMainScreenType() -> ScreenType {
        return screenDetector.detectMainScreenType()
    }
    
    /// 根据屏幕类型获取对应的模式
    func getModeForScreenType() -> HubMode {
        let screenType = detectMainScreenType()
        
        switch screenType {
        case .notch:
            return .dynamicIsland
        case .regular:
            return .floating
        }
    }
    
    /// 模拟屏幕类型（用于测试）
    func mockScreenType(_ type: ScreenType) {
        screenDetector.mockType = type
    }
    
    // MARK: - Private Methods
    
    /// 设置屏幕监听
    private func setupScreenMonitoring() {
        guard !isMonitoring else { return }
        
        // 记录当前主显示屏
        lastPrimaryScreenID = getPrimaryScreenID()
        
        // 监听屏幕参数变化（包括主显示屏切换、分辨率变化等）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        isMonitoring = true
        HubLogger.screen("屏幕监控已启动")
    }
    
    /// 获取主显示屏的唯一标识
    private func getPrimaryScreenID() -> Int {
        // 使用设备描述中的信息作为标识
        guard let screen = NSScreen.screens.first else { return 0 }
        let description = screen.deviceDescription
        // 使用 displayID 作为唯一标识
        if let displayID = description[NSDeviceDescriptionKey("NSScreenNumber")] as? Int {
            return displayID
        }
        return screen.hash
    }
    
    /// 屏幕参数变化回调
    @objc private func screenParametersDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清除缓存
            self.screenDetector.clearCache()
            
            // 检查主显示屏是否发生变化
            let currentPrimaryID = self.getPrimaryScreenID()
            guard currentPrimaryID != self.lastPrimaryScreenID else {
                // 主显示屏没有变化，可能是分辨率等其他变化
                HubLogger.screen("主显示屏未变化（ID: \(currentPrimaryID)）")
                return
            }
            
            // 主显示屏发生变化
            self.lastPrimaryScreenID = currentPrimaryID
            let newMode = self.getModeForScreenType()
            
            HubLogger.screen("主显示屏已切换，新模式: \(newMode.displayName)")
            
            // 通知 AppDelegate 切换模式
            self.onScreenTypeChanged?(newMode)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WindowManager Extension

extension WindowManager {
    
    /// 在指定屏幕上计算窗口位置
    func calculateWindowRect(for mode: HubMode, on screen: NSScreen? = nil) -> NSRect {
        let targetScreen = screen ?? NSScreen.main
        let screenFrame = targetScreen?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        
        let fullWidth = HubMetrics.windowSize.width
        let fullHeight = HubMetrics.windowSize.height
        let contentWidth = HubMetrics.openHubSize.width
        
        switch mode {
        case .dynamicIsland:
            // 刘海屏模式：居中，顶部
            let y = screenFrame.maxY - fullHeight
            let x = screenFrame.origin.x + (screenFrame.width - contentWidth) / 2 - HubMetrics.sidePadding
            return NSRect(x: x, y: y, width: fullWidth, height: fullHeight)
            
        case .floating:
            // 悬浮球模式：使用保存的位置或默认位置
            let settings = HubSettings()
            var x = settings.floatingX
            var y = settings.floatingY
            
            // 如果没有保存位置，使用默认位置（屏幕右侧中间）
            if x == 0 && y == 0 {
                x = screenFrame.origin.x + screenFrame.width - contentWidth - 100 - HubMetrics.sidePadding
                y = screenFrame.origin.y + screenFrame.height / 2
            }
            
            // 确保在屏幕范围内
            x = max(screenFrame.minX, min(x, screenFrame.maxX - fullWidth))
            y = max(screenFrame.minY, min(y, screenFrame.maxY - fullHeight))
            
            return NSRect(x: x, y: y, width: fullWidth, height: fullHeight)
        }
    }
}


