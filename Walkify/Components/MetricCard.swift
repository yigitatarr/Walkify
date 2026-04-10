//
//  MetricCard.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI

struct MetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let value: String
    let label: String
    let iconColor: Color

    init(
        icon: String,
        value: String,
        label: String,
        iconColor: Color = AppTheme.accentOrange
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.3), iconColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        HStack(spacing: 12) {
            MetricCard(icon: "map.fill", value: "6.2 km", label: "DISTANCE")
            MetricCard(icon: "flame.fill", value: "450 kcal", label: "CALORIES")
            MetricCard(icon: "clock.fill", value: "1h 20m", label: "TIME")
        }
        .padding()
    }
}
