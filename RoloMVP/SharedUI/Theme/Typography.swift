//
//  Typography.swift
//  RoloMVP
//

import SwiftUI

extension Font {
    static let roloTitle = Font.largeTitle.weight(.bold)
    static let roloHeadline = Font.headline.weight(.semibold)
    static let roloBody = Font.body
    static let roloCaption = Font.caption
    static let roloSubheadline = Font.subheadline
}

extension Text {
    func roloTitle() -> some View {
        self.font(.roloTitle)
    }
    
    func roloHeadline() -> some View {
        self.font(.roloHeadline)
    }
    
    func roloBody() -> some View {
        self.font(.roloBody)
    }
    
    func roloCaption() -> some View {
        self.font(.roloCaption)
            .foregroundColor(.secondary)
    }
}

