//
//  HealthKitSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct HealthKitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let onDismiss: () -> Void

    @State private var healthManager = HealthKitManager()
    @State private var isAuthorized = false
    @State private var isSyncing = false
    @State private var lastSyncMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accentOrange)

                Text("HealthKit")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                Text("Daha doğru takip için Sağlık uygulamasından adım verilerini senkronize et.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if !healthManager.isAvailable {
                    Text("Bu cihazda Sağlık uygulaması kullanılamıyor")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                } else if !isAuthorized {
                    Button {
                        Task {
                            let granted = await healthManager.requestAuthorization()
                            await MainActor.run {
                                isAuthorized = granted
                            }
                        }
                    } label: {
                        Text("Sağlık Erişimine İzin Ver")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.accentGradient)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.success)
                            Text("Sağlık erişimi verildi")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }

                        Button {
                            Task {
                                await performSync()
                            }
                        } label: {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Şimdi Senkronize Et")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.accentGradient)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSyncing)

                        if let message = lastSyncMessage {
                            Text(message)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("HealthKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }

    private func performSync() async {
        isSyncing = true
        lastSyncMessage = nil
        defer { isSyncing = false }

        let days = await healthManager.fetchLastDays(7)
        let calendar = Calendar.current

        await MainActor.run {
            for (date, steps) in days {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

                let descriptor = FetchDescriptor<StepRecord>(
                    predicate: #Predicate<StepRecord> { record in
                        record.date >= startOfDay && record.date < endOfDay
                    }
                )

                do {
                    let existing = try modelContext.fetch(descriptor).first
                    let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
                    let (calcDistance, calcCalories) = ActivityCalculator.distanceAndCalories(from: steps, profile: profile)

                    if let record = existing {
                        record.steps = steps
                        record.distance = calcDistance
                        record.calories = calcCalories
                        record.activeMinutes = steps / 100
                    } else if steps > 0 {
                        let record = StepRecord(
                            date: startOfDay,
                            steps: steps,
                            distance: calcDistance,
                            calories: calcCalories,
                            activeMinutes: steps / 100
                        )
                        modelContext.insert(record)
                    }
                } catch {
                    #if DEBUG
                    print("HealthKit sync error: \(error)")
                    #endif
                }
            }
            try? modelContext.save()
            lastSyncMessage = "\(days.count) günlük veri senkronize edildi"
        }
    }
}
