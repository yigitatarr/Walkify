//
//  NotificationsSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct NotificationsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var profiles: [UserProfile]
    let onDismiss: () -> Void

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Günlük Hatırlatıcı")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { profile?.notificationsEnabled ?? true },
                            set: {
                                profile?.notificationsEnabled = $0
                                if !$0 { NotificationService.shared.cancelAll() }
                                try? modelContext.save()
                            }
                        ))
                        .tint(AppTheme.accentOrange)
                        .labelsHidden()
                        .accessibilityLabel("Günlük Hatırlatıcı")
                    }
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                } header: {
                    Text("Hatırlatıcılar")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                } footer: {
                    Text("Günlük adım hedefine ulaşman için hatırlatmalar al")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            #if DEBUG
            Section {
                Button {
                    NotificationService.shared.sendSampleNotifications()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(AppTheme.accentOrange)
                        Text("Örnek bildirim gönder")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                    }
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))
            } header: {
                Text("Test")
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            #endif
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Bildirimler")
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
