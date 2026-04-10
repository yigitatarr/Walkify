//
//  SubscriptionSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct SubscriptionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Plan card
                VStack(spacing: 16) {
                    Image(systemName: profile?.isPremium == true ? "crown.fill" : "person.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(profile?.isPremium == true ? AppTheme.accentOrange : AppTheme.textSecondary(for: colorScheme))

                    Text(profile?.isPremium == true ? "Premium Üye" : "Ücretsiz")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                    Text(profile?.isPremium == true ? "Tüm özelliklere erişiminiz var" : "Tüm özelliklerin kilidini açmak için yükseltin")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
                )

                
                HStack {
                    Text("Premium Üyelik")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { profile?.isPremium ?? false },
                        set: { newValue in
                            profile?.isPremium = newValue
                            try? modelContext.save()
                        }
                    ))
                    .tint(AppTheme.accentOrange)
                    .labelsHidden()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )

                Spacer()
            }
            .padding(24)
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Abonelik")
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
