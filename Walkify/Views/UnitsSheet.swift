//
//  UnitsSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct UnitsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    unitRow("Metrik", subtitle: "km", isSelected: profile?.useMetricUnits ?? true) {
                        profile?.useMetricUnits = true
                        onDismiss()
                    }
                    unitRow("İngiliz", subtitle: "mil", isSelected: !(profile?.useMetricUnits ?? true)) {
                        profile?.useMetricUnits = false
                        onDismiss()
                    }
                }
            }
            .background(AppTheme.background(for: colorScheme))
            .scrollContentBackground(.hidden)
            .navigationTitle("Birimler")
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

    private func unitRow(_ title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
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
