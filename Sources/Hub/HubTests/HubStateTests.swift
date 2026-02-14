//
//  HubStateTests.swift
//  HubTests
//
//  T030: Tests for HubState transitions
//

import Testing
@testable import Hub

struct HubStateTests {

    @Test
    func testHubStateTransitions() {
        // Test closed -> open transition
        var state: HubState = .closed
        #expect(state == .closed)
        
        state = .open
        #expect(state == .open)
    }
    
    @Test
    func testStateRawValues() {
        #expect(HubState.closed.rawValue == "closed")
        #expect(HubState.open.rawValue == "open")
    }
    
    @Test
    func testStateEquality() {
        #expect(HubState.closed == HubState.closed)
        #expect(HubState.open == HubState.open)
        #expect(HubState.closed != HubState.open)
    }

}
