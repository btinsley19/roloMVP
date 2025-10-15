//
//  Colors.swift
//  RoloMVP
//

import SwiftUI

extension Color {
    static let roloAccent = Color.accentColor
    static let roloPrimary = Color.blue
    static let roloSecondary = Color.gray
    static let roloBackground = Color(UIColor.systemBackground)
    static let roloSecondaryBackground = Color(UIColor.secondarySystemBackground)
    
    // Priority colors for tags and contacts
    static func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1...3: return .green
        case 4...6: return .blue
        case 7...8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }
}

