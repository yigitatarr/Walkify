//
//  BodyProfileSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct BodyProfileSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 170
    @State private var useCustomStepLength = false
    @State private var stepLengthCm: Double = 70

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Kilo (kg)")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Text("\(Int(weightKg))")
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Slider(value: $weightKg, in: 30...150, step: 1)
                        .tint(AppTheme.accentOrange)
                } header: {
                    Text("Vücut Ölçüleri")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Section {
                    HStack {
                        Text("Boy (cm)")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Text("\(Int(heightCm))")
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Slider(value: $heightCm, in: 100...220, step: 1)
                        .tint(AppTheme.accentOrange)
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Section {
                    Toggle("Özel adım uzunluğu", isOn: $useCustomStepLength)
                        .tint(AppTheme.accentOrange)

                    if useCustomStepLength {
                        HStack {
                            Text("Adım uzunluğu (cm)")
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            Spacer()
                            Text("\(Int(stepLengthCm))")
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        Slider(value: $stepLengthCm, in: 50...120, step: 1)
                            .tint(AppTheme.accentOrange)
                    } else {
                        Text("Boyundan hesaplanan: \(String(format: "%.0f", heightCm * 0.415)) cm")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                } header: {
                    Text("Adım Uzunluğu")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                } footer: {
                    Text("Özel değer girmazsan boyundan otomatik hesaplanır")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Section {
                    let dist = ActivityCalculator.distanceFromSteps(10000, stepLengthCm: useCustomStepLength ? stepLengthCm : heightCm * 0.415)
                    let cal = ActivityCalculator.caloriesFromDistance(distanceKm: dist, weightKg: weightKg)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("10.000 adım örneği")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Text("\(String(format: "%.2f", dist)) km · \(cal) kcal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    }
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background(for: colorScheme))
            .onAppear {
                weightKg = profile?.weightKg ?? 70
                heightCm = profile?.heightCm ?? 170
                useCustomStepLength = (profile?.stepLengthCm ?? 0) > 0
                stepLengthCm = profile?.stepLengthCm ?? (profile?.heightCm ?? 170) * 0.415
            }
            .navigationTitle("Vücut Profili")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveProfile()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }

    private func saveProfile() {
        profile?.weightKg = weightKg
        profile?.heightCm = heightCm
        profile?.stepLengthCm = useCustomStepLength ? stepLengthCm : nil
        try? modelContext.save()
    }
}
