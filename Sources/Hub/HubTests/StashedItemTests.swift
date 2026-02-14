//
//  StashedItemTests.swift
//  HubTests
//
//  Tests for SwiftData container and StashedItem model
//

import Testing
import SwiftData
import UniformTypeIdentifiers
@testable import Hub

struct StashedItemTests {

    @Test
    func testSwiftDataContainerInitialization() throws {
        // Test that SwiftData container can be initialized with StashedItem schema
        let schema = Schema([StashedItem.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        // Container should be created without throwing
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        #expect(container != nil)
    }
    
    @Test
    func testStashedItemCreation() throws {
        // Test that StashedItem can be created and persisted
        let schema = Schema([StashedItem.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // Use in-memory for testing
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        let context = ModelContext(container)
        
        // Create a stashed item
        let item = StashedItem(
            name: "test-file.png",
            fileType: "image",
            originalPath: "/Users/test/test-file.png"
        )
        
        context.insert(item)
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<StashedItem>()
        let items = try context.fetch(descriptor)
        
        #expect(items.count == 1)
        #expect(items.first?.name == "test-file.png")
        #expect(items.first?.fileType == "image")
    }
    
    // T012: StashedItem creation from file URL
    @Test
    func testStashedItemCreationFromURL() throws {
        // Test creating StashedItem from a file URL
        let testURL = URL(fileURLWithPath: "/Users/test/Documents/report.pdf")
        
        let item = StashedItem(
            name: testURL.lastPathComponent,
            fileType: "pdf",
            originalPath: testURL.path
        )
        
        #expect(item.name == "report.pdf")
        #expect(item.fileType == "pdf")
        #expect(item.originalPath == "/Users/test/Documents/report.pdf")
        #expect(item.id != nil)
        #expect(item.dateAdded != nil)
    }
    
    // T022: StashedItem deletion
    @Test
    func testStashedItemDeletion() throws {
        // Setup in-memory container
        let schema = Schema([StashedItem.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        let context = ModelContext(container)
        
        // Create and insert an item
        let item = StashedItem(
            name: "test-file.pdf",
            fileType: "pdf",
            originalPath: "/Users/test/test-file.pdf"
        )
        context.insert(item)
        try context.save()
        
        // Verify item exists
        var descriptor = FetchDescriptor<StashedItem>()
        var items = try context.fetch(descriptor)
        #expect(items.count == 1)
        
        // Delete the item
        context.delete(item)
        try context.save()
        
        // Verify item is deleted
        items = try context.fetch(descriptor)
        #expect(items.count == 0)
    }

}
