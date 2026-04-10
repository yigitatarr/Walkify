//
//  BadgesView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct BadgesView: View {
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse) private var earnedBadges: [EarnedBadge]
    @Environment(\.colorScheme) private var colorScheme
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                if earnedBadges.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "medal")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                        Text("Henüz rozet kazanmadın")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Text("Yürümeye devam et, ilk rozetini kazanmak çok yakın!")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(earnedBadges, id: \.id) { badge in
                        if let type = badge.type {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.accentOrange.opacity(0.3), AppTheme.accentRed.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                    Image(systemName: type.icon)
                                        .font(.system(size: 28))
                                        .foregroundStyle(AppTheme.accentOrange)
                                }
                                Text(type.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                                    .multilineTextAlignment(.center)
                                Text(type.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                    .multilineTextAlignment(.center)
                                Text(badge.earnedAt, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardBackground(for: colorScheme))
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Kazanılan Rozetler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }
}
