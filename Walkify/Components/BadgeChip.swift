//
//  BadgeChip.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI

struct BadgeChip: View {
    let badgeType: BadgeType

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentOrange.opacity(0.3), AppTheme.accentRed.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: badgeType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accentOrange)
            }
            Text(badgeType.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}
