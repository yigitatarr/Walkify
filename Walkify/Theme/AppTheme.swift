//
//  AppTheme.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI

// MARK: - App Colors

enum AppTheme {
    // Dark (default)
    static let background = Color(hex: "0D0D0F")
    static let cardBackground = Color(hex: "1A1A1D")
    static let cardBackgroundSecondary = Color(hex: "141416")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9B9BA3")
    static let textMuted = Color(hex: "6B6B73")
    static let tabBarBackground = Color(hex: "121214")

    // Light
    private static let backgroundLight = Color(hex: "F5F5F7")
    private static let cardBackgroundLight = Color.white
    private static let cardBackgroundSecondaryLight = Color(hex: "E8E8EA")
    private static let textPrimaryLight = Color(hex: "1A1A1D")
    private static let textSecondaryLight = Color(hex: "6B6B73")
    private static let textMutedLight = Color(hex: "9B9BA3")
    private static let tabBarBackgroundLight = Color(hex: "FFFFFF")

    // Accent (same for both)
    static let accentOrange = Color(hex: "FF6B35")
    static let accentRed = Color(hex: "E63946")

    // Status (same for both)
    static let success = Color(hex: "4ADE80")
    static let successDark = Color(hex: "22C55E")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "EF4444")
    static let premiumGreen = Color(hex: "22C55E")

    // Adaptive (use these with @Environment(\.colorScheme))
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? background : backgroundLight
    }
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardBackground : cardBackgroundLight
    }
    static func cardBackgroundSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardBackgroundSecondary : cardBackgroundSecondaryLight
    }
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimary : textPrimaryLight
    }
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondary : textSecondaryLight
    }
    static func textMuted(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textMuted : textMutedLight
    }
    static func tabBarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? tabBarBackground : tabBarBackgroundLight
    }
}

// MARK: - Gradients

extension AppTheme {
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentOrange, accentRed],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var accentGradientVertical: LinearGradient {
        LinearGradient(
            colors: [accentOrange, accentRed],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                cardBackground.opacity(0.9),
                cardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
