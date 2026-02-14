//
//  StashedItemDuplicationTests.swift
//  HubTests
//
//  T014: Tests for duplicate path detection
//

import Testing
import SwiftData
@testable import Hub

struct StashedItemDuplicationTests {

    @Test
    func testDuplicatePathDetection() throws {
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
        let duplicatePath = "/Users/test/Documents/report.pdf"
        
        // Insert first item
        let item1 = StashedItem(
            name: "report.pdf",
            fileType: "pdf",
            originalPath: duplicatePath
        )
        context.insert(item1)
        try context.save()
        
        // Check if path exists - should find the existing item
        let existingItems = try fetchItemsWithPath(duplicatePath, in: context)
        #expect(existingItems.count == 1, "Should find existing item")
        
        // Attempt to add duplicate - should be detected
        let isDuplicate = try checkForDuplicate(path: duplicatePath, in: context)
        #expect(isDuplicate == true, "Should detect duplicate path")
    }
    
    @Test
    func testNonDuplicatePath() throws {
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
        
        // Insert first item
        let item1 = StashedItem(
            name: "report.pdf",
            fileType: "pdf",
            originalPath: "/Users/test/Documents/report.pdf"
        )
        context.insert(item1)
        try context.save()
        
        // Check different path - should not find any
        let newPath = "/Users/test/Documents/different.pdf"
        let isDuplicate = try checkForDuplicate(path: newPath, in: context)
        #expect(isDuplicate == false, "Should not detect duplicate for new path")
    }
    
    // Helper function to check for duplicate path
    private func checkForDuplicate(path: String, in context: ModelContext) throws -> Bool {
        let items = try fetchItemsWithPath(path, in: context)
        return !items.isEmpty
    }
    
    // Helper function to fetch items with a specific path
    private func fetchItemsWithPath(_ path: String, in context: ModelContext) throws -> [StashedItem] {
        // Fetch all items and filter manually (workaround for #Predicate in tests)
        let descriptor = FetchDescriptor<StashedItem>()
        let allItems = try context.fetch(descriptor)
        return allItems.filter { $0.originalPath == path }
    }

}
