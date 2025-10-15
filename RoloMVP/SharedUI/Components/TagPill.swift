//
//  TagPill.swift
//  RoloMVP
//

import SwiftUI

struct TagPill: View {
    let name: String
    let color: Color
    
    init(name: String, color: Color = .blue) {
        self.name = name
        self.color = color
    }
    
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        TagPill(name: "Work", color: .blue)
        TagPill(name: "Friend", color: .green)
        TagPill(name: "Important", color: .red)
    }
}

