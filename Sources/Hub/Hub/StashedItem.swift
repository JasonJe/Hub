//
//  StashedItem.swift
//  Hub
//
//  Created by 邱基盛 on 2026/2/13.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@Model
final class StashedItem {
    var id: UUID
    var name: String
    var fileType: String // "image", "pdf", "folder", "other"
    var originalPath: String
    var dateAdded: Date

    init(name: String, fileType: String, originalPath: String) {
        self.id = UUID()
        self.name = name
        self.fileType = fileType
        self.originalPath = originalPath
        self.dateAdded = Date()
    }

    /// 使用 UTType 和 FileManager 推断文件类型
    /// 比硬编码扩展名列表更健壮，能识别更多文件格式
    static func inferFileType(from filename: String, path: String? = nil) -> String {
        // 如果提供了路径，先检查实际文件类型
        if let path = path {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    return "folder"
                }
            }
        }
        
        let ext = (filename as NSString).pathExtension.lowercased()

        // 无扩展名，假设是文件夹
        if ext.isEmpty {
            return "folder"
        }

        // 使用 UTType 进行类型推断
        guard let utType = UTType(filenameExtension: ext) else {
            return "other"
        }

        // PDF 文件
        if utType.conforms(to: .pdf) {
            return "pdf"
        }

        // 图片文件（包括所有图片格式）
        if utType.conforms(to: .image) {
            return "image"
        }

        // 默认类型
        return "other"
    }
}
