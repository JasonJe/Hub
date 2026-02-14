//
//  StashedItemTypeTests.swift
//  HubTests
//
//  T013: Tests for file type detection (pdf/folder/image)
//

import Testing
@testable import Hub

struct StashedItemTypeTests {

    // Test PDF file type detection
    @Test
    func testFileTypeDetectionPDF() {
        let testCases = [
            ("document.pdf", "pdf"),
            ("report.PDF", "pdf"),
            ("file.pdf ", "pdf"),
            (".pdf", "pdf")
        ]
        
        for (filename, expectedType) in testCases {
            let fileType = StashedItem.inferFileType(from: filename)
            #expect(fileType == expectedType, "Failed for: \(filename)")
        }
    }
    
    // Test image file type detection
    @Test
    func testFileTypeDetectionImage() {
        let testCases = [
            ("photo.png", "image"),
            ("image.jpg", "image"),
            ("picture.JPEG", "image"),
            ("icon.gif", "image"),
            ("clip.heic", "image")
        ]
        
        for (filename, expectedType) in testCases {
            let fileType = StashedItem.inferFileType(from: filename)
            #expect(fileType == expectedType, "Failed for: \(filename)")
        }
    }
    
    // Test folder detection
    @Test
    func testFileTypeDetectionFolder() {
        let testCases = [
            ("folder", "folder"),
            ("Documents", "folder"),
            ("My Folder", "folder"),
            ("", "folder")  // No extension = folder
        ]
        
        for (filename, expectedType) in testCases {
            let fileType = StashedItem.inferFileType(from: filename)
            #expect(fileType == expectedType, "Failed for: \(filename)")
        }
    }
    
    // Test other file types
    @Test
    func testFileTypeDetectionOther() {
        let testCases = [
            ("doc", "other"),
            ("txt", "other"),
            ("xlsx", "other"),
            ("presentation.key", "other")
        ]
        
        for (filename, expectedType) in testCases {
            let fileType = StashedItem.inferFileType(from: filename)
            #expect(fileType == expectedType, "Failed for: \(filename)")
        }
    }

}
