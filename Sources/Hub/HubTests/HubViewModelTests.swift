//
//  HubViewModelTests.swift
//  HubTests
//

import Testing
import CoreFoundation
@testable import Hub

@MainActor
struct HubViewModelTests {

    @Test
    func testInitialState() {
        let vm = HubViewModel()
        #expect(vm.hubState == .closed)
        #expect(vm.showSettings == false)
    }
    
    @Test
    func testInitialSize() {
        let vm = HubViewModel()
        #expect(vm.hubSize.height > 0)
        #expect(vm.hubSize.width > 0)
    }
    
    @Test
    func testOpenChangesState() {
        let vm = HubViewModel()
        vm.open()
        #expect(vm.hubState == .open)
        #expect(vm.hubSize == HubMetrics.openHubSize)
    }
    
    @Test
    func testCloseResetsSettings() {
        let vm = HubViewModel()
        vm.open()
        vm.showSettings = true
        vm.close()
        #expect(vm.showSettings == false)
    }
    
    @Test
    func testOpenSettingsOpensHubIfClosed() {
        let vm = HubViewModel()
        vm.openSettings()
        #expect(vm.hubState == .open)
        #expect(vm.showSettings == true)
    }
}
