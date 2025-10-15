//
//  AvatarView.swift
//  RoloMVP
//

import SwiftUI

struct AvatarView: View {
    let photoUrl: String?
    let fullName: String
    let size: CGFloat
    
    init(photoUrl: String?, fullName: String, size: CGFloat = 50) {
        self.photoUrl = photoUrl
        self.fullName = fullName
        self.size = size
    }
    
    var body: some View {
        Group {
            if let photoUrl = photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    fallbackView
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(Color.roloSecondary.opacity(0.3))
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var initials: String {
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(photoUrl: nil, fullName: "John Doe", size: 60)
        AvatarView(photoUrl: nil, fullName: "Jane Smith", size: 40)
        AvatarView(photoUrl: nil, fullName: "A", size: 50)
    }
}

