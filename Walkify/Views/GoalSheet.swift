//
//  GoalSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct GoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    private let presets = [5000, 7500, 10000, 12000, 15000, 20000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Günlük adım hedefini seç")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { goal in
                        Button {
                            profile?.dailyStepGoal = goal
                            try? modelContext.save()
                            onDismiss()
                        } label: {
                            Text("\(goal / 1000)k")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle((profile?.dailyStepGoal ?? 10000) == goal ? .white : AppTheme.textPrimary(for: colorScheme))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill((profile?.dailyStepGoal ?? 10000) == goal ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.cardBackground(for: colorScheme)))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Günlük Hedef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        try? modelContext.save()
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }
}
