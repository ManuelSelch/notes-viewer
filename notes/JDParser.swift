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
        
        // Prefixed item (dot, numeric): GBS.10.01
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Prefixed item (dot, letter): ITSec.S02.01
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.[A-Za-z]\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Prefixed area (dot, numeric): GBS.10-19
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.\d{2}-\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Prefixed area (dot, letter): ITSec.S
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.[A-Za-z](?:[\s\-_]|$)"#, options: .regularExpression) {
            let number = String(cleanName[match]).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Prefixed category (dot, numeric): GBS.10
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.\d{2}(?:[\s\-_]|$)"#, options: .regularExpression) {
            let number = String(cleanName[match]).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        // Prefixed category (dot, letter): ITSec.S02
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\.[A-Za-z]\d{2}(?:[\s\-_]|$)"#, options: .regularExpression) {
            let number = String(cleanName[match]).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        // Prefixed item (space, numeric): GBS 10.01
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Prefixed item (space, letter): U03 S02.01
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+[A-Za-z]\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Prefixed area (space, numeric): GBS 10-19
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+\d{2}-\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Prefixed area (space, letter): U03 S
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+[A-Za-z](?:\s|$)"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Prefixed category (space, numeric): GBS 10
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+\d{2}(?:\s|$)"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        // Prefixed category (space, letter): U03 S02
        if let match = cleanName.range(of: #"^[A-Za-z0-9\-]+\s+[A-Za-z]\d{2}(?:\s|$)"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        // Standard item: 10.01
        if let match = cleanName.range(of: #"^\d{2}\.\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .item)
        }
        
        // Standard area: 10-19
        if let match = cleanName.range(of: #"^\d{2}-\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .area)
        }
        
        // Standard category: 10
        if let match = cleanName.range(of: #"^\d{2}"#, options: .regularExpression) {
            let number = String(cleanName[match])
            let remainder = String(cleanName[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            return JDInfo(number: number, title: remainder.isEmpty ? name : remainder, level: .category)
        }
        
        return JDInfo(number: nil, title: cleanName, level: .unknown)
    }
}
