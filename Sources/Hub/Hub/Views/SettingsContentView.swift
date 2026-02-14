//
//  SettingsContentView.swift
//  Hub
//
//  设置视图（嵌入 Hub 窗体）
//

import SwiftUI

/// 设置视图
/// 嵌入在 Hub 窗体内显示
struct SettingsContentView: View {
    /// 关闭回调
    var onClose: () -> Void
    
    /// 开机自启状态
    @State private var launchAtLogin: Bool = HubSettings.isRegisteredForLaunchAtLogin()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider().background(Color.white.opacity(0.05))
            
            // 设置内容
            settingsContent
            
            // Footer
            footerView
        }
        .onAppear {
            // 每次显示时刷新状态
            launchAtLogin = HubSettings.isRegisteredForLaunchAtLogin()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Text("设置")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Settings Content
    
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 通用分组
            VStack(alignment: .leading, spacing: 12) {
                Text("通用")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                // 开机自启
                Toggle(isOn: $launchAtLogin) {
                    Text("开机自启")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { _, newValue in
                    var settings = HubSettings()
                    settings.setLaunchAtLogin(newValue)
                    launchAtLogin = HubSettings.isRegisteredForLaunchAtLogin()
                }
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // 版本信息
            VStack(alignment: .leading, spacing: 2) {
                Text("Hub v\(appVersion) (\(appBuild))")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.5))
                Text("Copyright © 2026 Jason Je")
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
    }
    
    // MARK: - Helpers
    
    /// 获取应用版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// 获取构建号
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsContentView(onClose: {})
        .frame(width: 360, height: 220)
        .background(.black)
}
