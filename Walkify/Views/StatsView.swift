//
//  StatsView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

enum StatsPeriod: String, CaseIterable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
    case yearly = "Yıllık"
}

struct StatsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(StepDataManager.self) private var stepDataManager
    @Query(sort: \StepRecord.date, order: .reverse) private var stepRecords: [StepRecord]
    @Query private var profiles: [UserProfile]
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse) private var earnedBadges: [EarnedBadge]
    @State private var selectedPeriod: StatsPeriod = .weekly
    @State private var showBadges = false
    @State private var dailyHourlySteps: [Int] = []

    private var useMetric: Bool { profiles.first?.useMetricUnits ?? true }
    private var goal: Int { profiles.first?.dailyStepGoal ?? 10000 }

    private var weeklySteps: Int {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.steps }
    }

    private var lastWeekSteps: Int {
        let calendar = Calendar.current
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else { return 0 }
        return stepRecords
            .filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }
            .reduce(0) { $0 + $1.steps }
    }

    private var percentChange: Int? {
        guard lastWeekSteps > 0 else { return nil }
        return ((weeklySteps - lastWeekSteps) * 100) / lastWeekSteps
    }

    private var periodSteps: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            return todaySteps
        case .weekly:
            return weeklySteps
        case .monthly:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return weeklySteps }
            return stepRecords
                .filter { $0.date >= start }
                .reduce(0) { $0 + $1.steps }
        case .yearly:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return weeklySteps }
            return stepRecords
                .filter { $0.date >= start }
                .reduce(0) { $0 + $1.steps }
        }
    }

    private var periodDistance: Double {
        let calendar = Calendar.current
        let profile = profiles.first
        switch selectedPeriod {
        case .daily:
            let rec = stepRecords.first { calendar.isDateInToday($0.date) }
            return rec?.distance ?? ActivityCalculator.distanceFromSteps(todaySteps, profile: profile)
        case .weekly:
            return totalDistance > 0 ? totalDistance : ActivityCalculator.distanceFromSteps(weeklySteps, profile: profile)
        case .monthly:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            let steps = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
            let dist = stepRecords.filter { $0.date >= start }.reduce(0.0) { $0 + $1.distance }
            return dist > 0 ? dist : ActivityCalculator.distanceFromSteps(steps, profile: profile)
        case .yearly:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            let steps = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
            let dist = stepRecords.filter { $0.date >= start }.reduce(0.0) { $0 + $1.distance }
            return dist > 0 ? dist : ActivityCalculator.distanceFromSteps(steps, profile: profile)
        }
    }

    private var periodCalories: Int {
        let calendar = Calendar.current
        let profile = profiles.first
        switch selectedPeriod {
        case .daily:
            let rec = stepRecords.first { calendar.isDateInToday($0.date) }
            return rec?.calories ?? ActivityCalculator.caloriesFromSteps(todaySteps, profile: profile)
        case .weekly:
            return totalCalories > 0 ? totalCalories : ActivityCalculator.caloriesFromSteps(weeklySteps, profile: profile)
        case .monthly:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            let steps = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
            let cal = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.calories }
            return cal > 0 ? cal : ActivityCalculator.caloriesFromSteps(steps, profile: profile)
        case .yearly:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            let steps = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
            let cal = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.calories }
            return cal > 0 ? cal : ActivityCalculator.caloriesFromSteps(steps, profile: profile)
        }
    }

    private var periodActiveMinutes: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            return stepRecords
                .filter { calendar.isDateInToday($0.date) }
                .reduce(0) { $0 + $1.activeMinutes }
        case .weekly:
            return weeklyActiveMinutes
        case .monthly:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.activeMinutes }
        case .yearly:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.activeMinutes }
        }
    }

    private var periodFloorsAscended: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            return stepRecords.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.floorsAscended }
        case .weekly:
            return (0..<7).reduce(0) { total, offset in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return total }
                return total + stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.floorsAscended }
            }
        case .monthly:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.floorsAscended }
        case .yearly:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.floorsAscended }
        }
    }

    private var periodElevationText: String {
        let meters = Double(periodFloorsAscended) * 3.0
        let useMetric = profiles.first?.useMetricUnits ?? true
        if useMetric {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.0f ft", meters * 3.281)
        }
    }

    private var graphData: [(String, Int)] {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            return dailyHourlySteps.enumerated().map { hour, steps in
                (hourLabelForDaily(hour), steps)
            }
        case .weekly:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (0..<7).reversed().compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
                let dayKey = formatter.string(from: date).uppercased()
                let steps = stepRecords
                    .filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.steps }
                return (String(dayKey.prefix(3)), steps)
            }
        case .monthly:
            return (0..<4).reversed().compactMap { offset in
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date()),
                      let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return nil }
                let steps = stepRecords
                    .filter { $0.date >= interval.start && $0.date < interval.end }
                    .reduce(0) { $0 + $1.steps }
                return ("\(4 - offset). hft", steps)
            }
        case .yearly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return (0..<12).reversed().compactMap { offset in
                guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: Date()),
                      let interval = calendar.dateInterval(of: .month, for: monthStart) else { return nil }
                let steps = stepRecords
                    .filter { $0.date >= interval.start && $0.date < interval.end }
                    .reduce(0) { $0 + $1.steps }
                return (formatter.string(from: monthStart), steps)
            }
        }
    }

    private func hourLabelForDaily(_ hour: Int) -> String {
        if hour == 0 { return "0" }
        if hour == 23 { return "23" }
        if hour % 6 == 0 { return "\(hour)" }
        return ""
    }

    private var totalDistance: Double {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.distance }
    }

    private var totalCalories: Int {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.calories }
    }

    private var weeklyActiveMinutes: Int {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.activeMinutes }
    }

    private var todaySteps: Int {
        stepRecords
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.steps }
    }

    private var daysReachedGoal: (reached: Int, total: Int) {
        StreakManager.daysReachedGoalThisWeek(stepRecords: stepRecords, goal: goal)
    }

    private var goalReachedPerDay: [(Bool, String)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.steps }
            return (steps >= goal, formatter.string(from: date))
        }
    }

    private var bestDayThisWeek: (dayName: String, steps: Int)? {
        guard selectedPeriod == .weekly,
              let best = graphData.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        let fullNames = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
        let index = graphData.firstIndex(where: { $0.1 == best.1 }) ?? 0
        return (fullNames[min(index, fullNames.count - 1)], best.1)
    }

    private var currentStreak: Int { StreakManager.currentStreak(stepRecords: stepRecords, goal: goal) }
    private var longestStreakEver: Int { StreakManager.longestStreak(stepRecords: stepRecords, goal: goal) }

    private var bestWeekSteps: Int? {
        let calendar = Calendar.current
        var best = 0
        for weekOffset in 0..<52 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { continue }
            let weekTotal = stepRecords
                .filter { $0.date >= interval.start && $0.date < interval.end }
                .reduce(0) { $0 + $1.steps }
            best = max(best, weekTotal)
        }
        return best > 0 ? best : nil
    }

    private var badgesEarnedThisWeek: Int {
        let calendar = Calendar.current
        return earnedBadges.filter { calendar.isDate($0.earnedAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    private var estimatedGoalTime: Date? {
        guard todaySteps > 0, todaySteps < goal else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let elapsedMinutes = now.timeIntervalSince(startOfDay) / 60
        guard elapsedMinutes > 0 else { return nil }
        let stepsPerMinute = Double(todaySteps) / elapsedMinutes
        let stepsRemaining = goal - todaySteps
        let minutesNeeded = Double(stepsRemaining) / stepsPerMinute
        return calendar.date(byAdding: .minute, value: Int(minutesNeeded), to: now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Period selector
                    periodSelector

                    // Activity Trends
                    activityTrendsSection

                    // Day labels
                    dayLabels

                    // Metric cards
                    metricCardsSection

                    // Streak & Hedefe ulaşma (sadece haftalık)
                    if selectedPeriod == .weekly {
                        streakAndGoalSection
                        bestDayAndAverageSection
                    }

                    // Tahmini tamamlanma (bugün için)
                    if selectedPeriod == .daily || selectedPeriod == .weekly, let eta = estimatedGoalTime {
                        estimatedCompletionCard(eta: eta)
                    }

                    // Dönemsel rozetler
                    if selectedPeriod == .weekly, badgesEarnedThisWeek > 0 {
                        badgesThisWeekCard
                    }

                    // Weekly Insight (haftalık + yeterli veri)
                    if selectedPeriod == .weekly, weeklySteps >= 1000 {
                        weeklyInsightCard
                    }

                    // Tarihsel: En iyi hafta (haftalık ve bu hafta rekor değilse)
                    if selectedPeriod == .weekly, let best = bestWeekSteps, best > weeklySteps {
                        bestWeekComparisonCard(best: best)
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await stepDataManager.syncHistoricalData()
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Performans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        WeeklyDetailsView()
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    }
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
            .task(id: selectedPeriod) {
                if selectedPeriod == .daily {
                    dailyHourlySteps = Array(repeating: 0, count: 24)
                    dailyHourlySteps = await stepDataManager.fetchHourlyStepsForToday()
                } else {
                    dailyHourlySteps = []
                }
            }
        }
    }


    // MARK: - Subviews

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(StatsPeriod.allCases, id: \.rawValue) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedPeriod == period ? .white : AppTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedPeriod == period ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color.clear))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activityTrendsSection: some View {
        let periodLabel = switch selectedPeriod {
        case .daily: "Bugün"
        case .weekly: "Bu hafta"
        case .monthly: "Son 30 gün"
        case .yearly: "Son 1 yıl"
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Aktivite Trendleri · \(periodLabel)")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: 4) {
                Text("\(formatNumber(periodSteps))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text("adım")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.accentOrange)
            }

            if selectedPeriod == .weekly {
                if let change = percentChange {
                    HStack(spacing: 6) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(change >= 0 ? AppTheme.success : AppTheme.error)
                        Text("\(change >= 0 ? "+" : "")\(change)% geçen haftaya göre")
                            .font(.system(size: 14))
                            .foregroundStyle(change >= 0 ? AppTheme.success : AppTheme.error)
                    }
                } else if lastWeekSteps == 0 && weeklySteps > 0 {
                    Text("Harika başlangıç! Devam et!")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.success)
                }
            }

            if !graphData.isEmpty {
                LineGraphView(data: graphData.map(\.1))
                    .frame(height: 160)
            }
        }
    }

    @ViewBuilder
    private var dayLabels: some View {
        if !graphData.isEmpty {
            let highlightIndex: Int = selectedPeriod == .daily
                ? Calendar.current.component(.hour, from: Date())
                : graphData.count - 1
            HStack {
                ForEach(Array(graphData.enumerated()), id: \.offset) { index, item in
                    Text(item.0)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(index == highlightIndex ? AppTheme.accentOrange : AppTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var metricCardsSection: some View {
        let profile = profiles.first
        let distance = periodDistance
        let calories = periodCalories
        let lastWeekDist = ActivityCalculator.distanceFromSteps(lastWeekSteps, profile: profile)
        let lastWeekCal = ActivityCalculator.caloriesFromSteps(lastWeekSteps, profile: profile)

        let distanceChange: String?
        if selectedPeriod == .weekly, lastWeekSteps > 0 {
            let diff = distance - lastWeekDist
            distanceChange = useMetric ? String(format: "%+.1f km", diff) : String(format: "%+.1f mi", diff / 1.609)
        } else {
            distanceChange = nil
        }

        let caloriesChange: String?
        if selectedPeriod == .weekly, lastWeekSteps > 0 {
            let diff = calories - lastWeekCal
            caloriesChange = "\(diff >= 0 ? "+" : "")\(diff)"
        } else {
            caloriesChange = nil
        }

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatsMetricCard(
                    title: "TOPLAM ADIM",
                    value: formatShort(periodSteps),
                    change: selectedPeriod == .weekly ? percentChange.map { "\($0 >= 0 ? "+" : "")\($0)%" } : nil,
                    colorScheme: colorScheme
                )
                StatsMetricCard(
                    title: "MESAFE",
                    value: formatDistance(distance),
                    change: distanceChange,
                    colorScheme: colorScheme
                )
            }
            HStack(spacing: 12) {
                StatsMetricCard(
                    title: "KALORİ",
                    value: formatShort(calories),
                    change: caloriesChange,
                    colorScheme: colorScheme
                )
                StatsMetricCard(
                    title: "AKTİF DAKİKA",
                    value: "\(periodActiveMinutes) dk",
                    change: nil,
                    colorScheme: colorScheme
                )
            }
            HStack(spacing: 12) {
                StatsMetricCard(
                    title: "RAKIM",
                    value: periodElevationText,
                    change: nil,
                    colorScheme: colorScheme
                )
                StatsMetricCard(
                    title: "KAT ÇIKILAN",
                    value: "\(periodFloorsAscended)",
                    change: nil,
                    colorScheme: colorScheme
                )
            }
        }
    }

    private var weeklyInsightCard: some View {
        let message = weeklyInsightMessage
        return HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(AppTheme.accentGradient)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("Haftalık İpucu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    /// Gerçek veriye göre motivasyon mesajı (minimum 1000 adım şartı zaten kontrol edildi)
    // MARK: - Yeni bölümler

    private var streakAndGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(AppTheme.accentOrange)
                        Text("Seri")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Text("\(currentStreak) gün")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    if longestStreakEver > currentStreak {
                        Text("En iyi: \(longestStreakEver) gün")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Hedef \(daysReachedGoal.reached)/\(daysReachedGoal.total) gün")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    HStack(spacing: 4) {
                        ForEach(Array(goalReachedPerDay.enumerated()), id: \.offset) { _, item in
                            Circle()
                                .fill(item.0 ? AppTheme.success : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
                )
            }
        }
    }

    private var bestDayAndAverageSection: some View {
        let avgDaily = weeklySteps / 7
        let profile = profiles.first
        let distance = totalDistance > 0 ? totalDistance : ActivityCalculator.distanceFromSteps(weeklySteps, profile: profile)
        return HStack(spacing: 12) {
            if let best = bestDayThisWeek {
                VStack(alignment: .leading, spacing: 6) {
                    Text("EN İYİ GÜN")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text(best.dayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text(formatNumber(best.steps))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.accentOrange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
                )
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("ORTALAMA / GÜN")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Text(formatShort(avgDaily) + " adım")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text(formatDistance(distance / 7))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
            )
        }
    }

    private func estimatedCompletionCard(eta: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.accentOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tahmini hedef saati")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Text("Bu tempoyla ~\(formatter.string(from: eta))'da hedefe ulaşırsın")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var badgesThisWeekCard: some View {
        Button {
            showBadges = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accentOrange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bu hafta kazanılan")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("\(badgesEarnedThisWeek) rozet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showBadges) {
            BadgesView(onDismiss: { showBadges = false })
        }
    }

    private func bestWeekComparisonCard(best: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(AppTheme.accentOrange.opacity(0.6))
                .frame(width: 4)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("En iyi haftan")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
                Text("Rekorun \(formatNumber(best)) adımdı. Bu hafta \(formatNumber(weeklySteps)) ile rekoruna \(formatNumber(best - weeklySteps)) adım kala.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    /// Gerçek veriye göre motivasyon mesajı (minimum 1000 adım şartı zaten kontrol edildi)
    private var weeklyInsightMessage: String {
        let goal = profiles.first?.dailyStepGoal ?? 10000
        let avgDaily = weeklySteps / 7

        if let change = percentChange {
            if change >= 20 {
                return "Harika gidiyorsun! 💪 Bu hafta geçen haftaya göre \(change)% daha aktifsin. Bu tempo ile hedeflerine ulaşmana ramak kaldı!"
            } else if change >= 10 {
                return "Süpersin! Geçen haftaya göre \(change)% daha fazla yürüdün. Küçük adımlar büyük değişimlere yol açar!"
            } else if change > 0 {
                return "İyi gidiyorsun! Bu hafta biraz daha aktifsin. Devam et, hedefin \(formatNumber(goal)) adım!"
            } else if change >= -10 {
                return "Bu hafta biraz daha az yürüdün ama sorun değil. Yarın taze bir başlangıç yapabilirsin!"
            } else {
                return "Bu hafta tempoyu düşürdün. Unutma: her adım önemli. Yarın daha fazla yürümeye ne dersin?"
            }
        }

        // Geçen hafta veri yok - ilk hafta veya yeni başlangıç
        if avgDaily >= goal {
            return "Muhteşem! Günlük ortalaman hedefini aşıyor. Bu enerjiyi koru! 🔥"
        } else if avgDaily >= goal / 2 {
            return "Yarı yola geldin! Günlük \(formatNumber(avgDaily)) adım atmışsın. Hedefe \(formatNumber(goal - avgDaily)) adım kaldı!"
        } else if weeklySteps >= 5000 {
            return "Güzel başlangıç! \(formatNumber(weeklySteps)) adım attın. Hedefin \(formatNumber(goal)) adım – her gün biraz daha ekle!"
        } else {
            return "Hareket etmeye başladın! Her adım sağlığına katkı. Yarın biraz daha fazla yürüyebilirsin."
        }
    }

    private func formatNumber(_ n: Int) -> String {
        NumberFormatter.stepsFormatter.string(from: NSNumber(value: n)) ?? "0"
    }

    private func formatDistance(_ km: Double) -> String {
        if useMetric {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.1f mi", km / 1.609)
        }
    }

    private func formatShort(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000)
        }
        return "\(n)"
    }
}

// MARK: - Stats Metric Card

private struct StatsMetricCard: View {
    let title: String
    let value: String
    let change: String?
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            if let change = change {
                Text(change)
                    .font(.system(size: 12))
                    .foregroundStyle(change.hasPrefix("+") ? AppTheme.success : AppTheme.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }
}

// MARK: - Line Graph View

struct LineGraphView: View {
    let data: [Int]

    private var maxValue: Int { max(data.max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack(alignment: .bottomLeading) {
                // Area under curve
                if data.count > 1 {
                    Path { path in
                        let stepX = width / CGFloat(max(data.count - 1, 1))
                        for (index, value) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value) / CGFloat(maxValue)) * height * 0.9

                            if index == 0 {
                                path.move(to: CGPoint(x: 0, y: height))
                                path.addLine(to: CGPoint(x: 0, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentOrange.opacity(0.3), AppTheme.accentOrange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Line
                if data.count > 1 {
                    Path { path in
                        let stepX = width / CGFloat(max(data.count - 1, 1))
                        for (index, value) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value) / CGFloat(maxValue)) * height * 0.9

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }

                // Highlight point (middle)
                if data.count > 1 {
                    let midIndex = data.count >= 4 ? 3 : data.count / 2
                    let stepX = width / CGFloat(max(data.count - 1, 1))
                    let x = CGFloat(midIndex) * stepX
                    let y = height - (CGFloat(data[midIndex]) / CGFloat(maxValue)) * height * 0.9

                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(AppTheme.accentOrange, lineWidth: 2))
                        .position(x: x, y: y)
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [StepRecord.self, UserProfile.self, EarnedBadge.self], inMemory: true)
}
