//
//  ThemeSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct ThemeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    themeRow("Açık", icon: "sun.max.fill", value: "light")
                    themeRow("Koyu", icon: "moon.fill", value: "dark")
                    themeRow("Sistem", icon: "circle.lefthalf.filled", value: "system")
                }
            }
            .background(AppTheme.background(for: colorScheme))
            .scrollContentBackground(.hidden)
            .navigationTitle("Tema")
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

    private func themeRow(_ title: String, icon: String, value: String) -> some View {
        let isSelected = (profile?.themePreference ?? "dark") == value
        return Button {
            profile?.themePreference = value
            onDismiss()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accentOrange)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentOrange)
                }
            }
        }
        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
    }
}
