//
//  HubViewModelTests.swift
//  HubTests
//
//  Tests for HubViewModel state management
//

import Testing
import CoreFoundation
@testable import Hub

@MainActor
struct HubViewModelTests {

    // MARK: - Initial State Tests
    
    @Test
    func testInitialState() {
        let vm = HubViewModel()
        
        #expect(vm.hubState == .closed)
        #expect(vm.showSettings == false)
    }
    
    @Test
    func testInitialSize() {
        let vm = HubViewModel()
        
        // 初始尺寸应该基于刘海尺寸
        #expect(vm.hubSize.height > 0)
        #expect(vm.hubSize.width > 0)
        #expect(vm.closedHubSize.height > 0)
        #expect(vm.closedHubSize.width > 0)
    }
    
    // MARK: - Open/Close Tests
    
    @Test
    func testOpenChangesState() {
        let vm = HubViewModel()
        
        vm.open()
        
        #expect(vm.hubState == .open)
        #expect(vm.hubSize == openHubSize)
    }
    
    @Test
    func testCloseChangesState() {
        let vm = HubViewModel()
        vm.open()
        
        vm.close()
        
        #expect(vm.hubState == .closed)
        #expect(vm.showSettings == false)
    }
    
    @Test
    func testCloseResetsSettings() {
        let vm = HubViewModel()
        vm.open()
        vm.showSettings = true
        
        vm.close()
        
        #expect(vm.showSettings == false)
    }
    
    // MARK: - Settings Tests
    
    @Test
    func testOpenSettingsSetsFlag() {
        let vm = HubViewModel()
        
        vm.openSettings()
        
        #expect(vm.showSettings == true)
    }
    
    @Test
    func testOpenSettingsOpensHubIfClosed() {
        let vm = HubViewModel()
        #expect(vm.hubState == .closed)
        
        vm.openSettings()
        
        #expect(vm.hubState == .open)
        #expect(vm.showSettings == true)
    }
    
    @Test
    func testOpenSettingsKeepsHubOpenIfAlreadyOpen() {
        let vm = HubViewModel()
        vm.open()
        
        vm.openSettings()
        
        #expect(vm.hubState == .open)
        #expect(vm.showSettings == true)
    }
    
    @Test
    func testCloseSettingsClearsFlag() {
        let vm = HubViewModel()
        vm.showSettings = true
        
        vm.closeSettings()
        
        #expect(vm.showSettings == false)
    }
    
    @Test
    func testCloseSettingsDoesNotCloseHub() {
        let vm = HubViewModel()
        vm.open()
        vm.showSettings = true
        
        vm.closeSettings()
        
        #expect(vm.hubState == .open)
        #expect(vm.showSettings == false)
    }
    
    // MARK: - State Transition Tests
    
    @Test
    func testOpenCloseCycle() {
        let vm = HubViewModel()
        
        // 初始状态
        #expect(vm.hubState == .closed)
        
        // 打开
        vm.open()
        #expect(vm.hubState == .open)
        
        // 再次打开（应该保持打开）
        vm.open()
        #expect(vm.hubState == .open)
        
        // 关闭
        vm.close()
        #expect(vm.hubState == .closed)
        
        // 再次关闭（应该保持关闭）
        vm.close()
        #expect(vm.hubState == .closed)
    }
    
    @Test
    func testSettingsToggleCycle() {
        let vm = HubViewModel()
        
        // 初始状态
        #expect(vm.showSettings == false)
        
        // 打开设置
        vm.openSettings()
        #expect(vm.showSettings == true)
        
        // 关闭设置
        vm.closeSettings()
        #expect(vm.showSettings == false)
        
        // 再次打开设置
        vm.openSettings()
        #expect(vm.showSettings == true)
    }
}
