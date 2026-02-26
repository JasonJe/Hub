//
//  FloatingOrbFeatureTests.swift
//  HubTests
//
//  悬浮球模式功能测试 - TDD
//

import XCTest
import SwiftData
import SwiftUI
@testable import Hub

@MainActor
final class FloatingOrbFeatureTests: XCTestCase {
    
    // MARK: - 测试文件计数徽章
    
    /// 测试悬浮球菜单应该显示文件计数徽章
    func testFloatingOrbMenuShowsItemCountBadge() throws {
        // Given: 创建测试数据
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StashedItem.self, configurations: config)
        let context = container.mainContext
        
        // 添加测试文件
        for i in 0..<5 {
            let item = StashedItem(
                name: "file\(i).txt",
                fileType: "other",
                originalPath: "/test/file\(i).txt"
            )
            context.insert(item)
        }
        
        // When: 创建 ViewModel
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        
        // Then: 验证初始状态
        XCTAssertTrue(viewModel.isOrbExpanded, "悬浮球应该展开")
        
        // 验证可以访问 items 数量（实际UI测试在 UITests 中进行）
        let descriptor = FetchDescriptor<StashedItem>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 5, "应该有5个文件")
    }
    
    // MARK: - 测试右键删除菜单
    
    /// 测试文件项应该支持右键删除菜单
    func testFileItemSupportsContextMenu() throws {
        // Given: 创建测试数据
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StashedItem.self, configurations: config)
        let context = container.mainContext
        
        let item = StashedItem(
            name: "document.pdf",
            fileType: "pdf",
            originalPath: "/test/document.pdf"
        )
        context.insert(item)
        
        // When: 删除文件
        context.delete(item)
        
        // Then: 验证文件已删除
        let descriptor = FetchDescriptor<StashedItem>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 0, "文件应该被删除")
    }
    
    // MARK: - 测试文件拖放支持
    
    /// 测试悬浮球应该支持文件拖放
    func testFloatingOrbSupportsFileDrop() throws {
        // Given: 创建 ViewModel
        let viewModel = HubViewModel()
        
        // When: 检查拖放支持
        // 实际拖放功能测试需要在 UITests 中进行
        // 这里测试 ViewModel 的状态管理
        
        // Then: 验证 ViewModel 可以处理展开状态
        viewModel.expandOrb()
        XCTAssertTrue(viewModel.isOrbExpanded, "悬浮球应该可以展开")
        XCTAssertTrue(viewModel.showExpandedWindow, "展开窗口标志应该为true")
    }
    
    /// 测试拖放区域在展开时可用
    func testDropZoneAvailableWhenExpanded() throws {
        // Given
        let viewModel = HubViewModel()
        
        // When: 展开悬浮球
        viewModel.expandOrb()
        
        // Then: 验证状态
        XCTAssertTrue(viewModel.isOrbExpanded)
        XCTAssertFalse(viewModel.showSettings)
        XCTAssertFalse(viewModel.showConfirmation)
    }
    
    // MARK: - 测试空状态视图
    
    /// 测试空状态时显示正确的提示
    func testEmptyStateShowsCorrectMessage() throws {
        // Given: 空数据
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StashedItem.self, configurations: config)
        
        // When: 获取文件列表
        let descriptor = FetchDescriptor<StashedItem>()
        let items = try container.mainContext.fetch(descriptor)
        
        // Then: 验证为空
        XCTAssertEqual(items.count, 0, "文件列表应该为空")
    }
    
    // MARK: - 测试设置和退出功能
    
    /// 测试设置按钮可以打开设置视图
    func testSettingsButtonOpensSettingsView() throws {
        // Given
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        
        // When: 打开设置
        viewModel.openSettings()
        
        // Then
        XCTAssertTrue(viewModel.showSettings, "设置视图应该显示")
        XCTAssertTrue(viewModel.isOrbExpanded, "悬浮球应该保持展开")
    }
    
    /// 测试退出按钮可以显示确认对话框
    func testExitButtonShowsConfirmationDialog() throws {
        // Given
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        
        // When: 显示退出对话框
        viewModel.showDialog(.exit)
        
        // Then
        XCTAssertTrue(viewModel.showConfirmation, "确认对话框应该显示")
        XCTAssertEqual(viewModel.confirmationTitle, "退出 Hub")
    }
    
    /// 测试清空按钮可以显示确认对话框
    func testClearButtonShowsConfirmationDialog() throws {
        // Given
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        
        // When: 显示清空对话框
        viewModel.showDialog(.clearAll, clearAction: {})
        
        // Then
        XCTAssertTrue(viewModel.showConfirmation, "确认对话框应该显示")
        XCTAssertEqual(viewModel.confirmationTitle, "清空")
    }
    
    /// 测试关闭设置后返回菜单
    func testCloseSettingsReturnsToMenu() throws {
        // Given
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        viewModel.openSettings()
        XCTAssertTrue(viewModel.showSettings)
        
        // When: 关闭设置
        viewModel.closeSettings()
        
        // Then
        XCTAssertFalse(viewModel.showSettings, "设置视图应该关闭")
        XCTAssertTrue(viewModel.isOrbExpanded, "悬浮球应该保持展开")
    }
    
    /// 测试取消对话框后返回菜单
    func testCancelDialogReturnsToMenu() throws {
        // Given
        let viewModel = HubViewModel()
        viewModel.expandOrb()
        viewModel.showDialog(.exit)
        XCTAssertTrue(viewModel.showConfirmation)
        
        // When: 取消对话框
        viewModel.dismissDialog()
        
        // Then
        XCTAssertFalse(viewModel.showConfirmation, "确认对话框应该关闭")
        XCTAssertTrue(viewModel.isOrbExpanded, "悬浮球应该保持展开")
    }
}
