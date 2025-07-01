//
//  DesignSystem.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import SwiftUI

struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        static let statusGreen = Color.green
        static let statusRed = Color.red
        static let statusOrange = Color.orange
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let backgroundPrimary = Color(NSColor.windowBackgroundColor)
        static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
        static let primary = Color.accentColor
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.semibold)
        static let title = Font.system(.title, design: .rounded).weight(.medium)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body)
        static let callout = Font.system(.callout)
        static let caption = Font.system(.caption)
        static let footnote = Font.system(.footnote)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}