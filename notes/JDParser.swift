import Foundation
import SwiftUI

enum JDLevel {
    case area      // 10-19
    case category  // 10
    case item      // 10.01
    case unknown
    
    var icon: String {
        switch self {
        case .area: return "folder.fill.badge.person.crop"
        case .category: return "folder.fill"
        case .item: return "doc.text.fill"
        case .unknown: return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .area: return .purple
        case .category: return .blue
        case .item: return .green
        case .unknown: return .gray
        }
    }
    
    var label: String {
        switch self {
        case .area: return "Area"
        case .category: return "Category"
        case .item: return "Note"
        case .unknown: return "File"
        }
    }
}

struct JDInfo {
    let number: String?
    let title: String
    let level: JDLevel
    
    var displayNumber: String {
        number ?? ""
    }
}

extension GitHubItem {
    var jdInfo: JDInfo {
        let cleanName = name.replacingOccurrences(of: ".md", with: "")
        
        // Try 10.01 pattern first (most specific)
        if let match = cleanName.range(of: #"^\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Try 10-19 pattern (areas)
        if let match = cleanName.range(of: #"^\d{2}-\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Try 10 pattern (categories)
        if let match = cleanName.range(of: #"^\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        return JDInfo(number: nil, title: cleanName, level: .unknown)
    }
}
