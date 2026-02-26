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
            
            Divider().background(.white.opacity(0.08))
            
            // 设置内容
            ScrollView(showsIndicators: false) {
                settingsContent
            }
            
            Spacer(minLength: 0)
            
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
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Text("设置")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Settings Content
    
    private var settingsContent: some View {
        VStack(spacing: 20) {
            // 通用分组
            VStack(alignment: .leading, spacing: 16) {
                Text("通用")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                // 开机自启 - 使用卡片式设计
                HStack(spacing: 12) {
                    Image(systemName: "power")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.08))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机自启")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("系统启动时自动运行 Hub")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: launchAtLogin) { _, newValue in
                            var settings = HubSettings()
                            settings.setLaunchAtLogin(newValue)
                            launchAtLogin = HubSettings.isRegisteredForLaunchAtLogin()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.05))
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 4) {
            Divider()
                .background(.white.opacity(0.08))
                .padding(.horizontal, 20)
            
            HStack {
                Spacer()
                
                // 版本信息
                VStack(alignment: .center, spacing: 2) {
                    Text("Hub v\(appVersion) (\(appBuild))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text("Copyright © 2026 JasonJe")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
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
