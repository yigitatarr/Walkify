//
//  MainTabBar.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import UIKit

enum TabItem: Int, CaseIterable {
    case overview = 0
    case stats = 1
    case profile = 2

    var title: String {
        switch self {
        case .overview: return "Ana Sayfa"
        case .stats: return "İstatistik"
        case .profile: return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .stats: return "chart.bar"
        case .profile: return "person"
        }
    }
}

struct MainTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    colorScheme: colorScheme
                ) {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.tabBarBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
                )
        )
    }
}

private struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    var colorScheme: ColorScheme = .dark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)))
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary(for: colorScheme) : AppTheme.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        VStack {
            Spacer()
            MainTabBar(selectedTab: .constant(.overview))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }
}
