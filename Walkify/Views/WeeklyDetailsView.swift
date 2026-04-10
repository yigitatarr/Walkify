//
//  WeeklyDetailsView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct WeeklyDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \StepRecord.date, order: .reverse) private var stepRecords: [StepRecord]
    @Query private var profiles: [UserProfile]

    private var useMetric: Bool { profiles.first?.useMetricUnits ?? true }

    private var weeklyData: [(Date, Int, Double)] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            let record = stepRecords.first { calendar.isDate($0.date, inSameDayAs: date) }
            let steps = record?.steps ?? 0
            let distance = record?.distance ?? ActivityCalculator.distanceFromSteps(steps, profile: profiles.first)
            return (startOfDay, steps, distance)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatDistance(_ km: Double) -> String {
        if useMetric {
            return String(format: "%.2f km", km)
        } else {
            return String(format: "%.2f mi", km / 1.609)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(item.0))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                                Text(formatDistance(item.2))
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            }
                            Spacer()
                            Text("\(item.1) adım")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.accentOrange)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.cardBackground(for: colorScheme))
                        )
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Haftalık Detaylar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    }
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }
}
