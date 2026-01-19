//
//  Category.swift
//  Knowhere
//
//  Data model for prompt categories
//

import Foundation
import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        icon: String = "folder.fill"
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Default Categories
extension Category {
    static let defaults: [Category] = [
        Category(name: "Coding", colorHex: "#FF6B6B", icon: "chevron.left.forwardslash.chevron.right"),
        Category(name: "Writing", colorHex: "#4ECDC4", icon: "pencil"),
        Category(name: "Research", colorHex: "#45B7D1", icon: "magnifyingglass"),
        Category(name: "Creative", colorHex: "#96CEB4", icon: "lightbulb.fill"),
        Category(name: "Business", colorHex: "#FFEAA7", icon: "briefcase.fill")
    ]
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
