//
//  StepDetailsView.swift
//  Walkify
//
//  Adım detay analizi – referans uygulama tarzı (Ayrıntı ekranı)
//

import SwiftUI
import SwiftData

enum StepDetailPeriod: String, CaseIterable {
    case day = "Gün"
    case week = "Hafta"
    case month = "Ay"
    case year = "Yıl"
}

struct StepDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(StepDataManager.self) private var stepDataManager
    @Query(sort: \StepRecord.date, order: .reverse) private var stepRecords: [StepRecord]
    @Query private var profiles: [UserProfile]

    @State private var selectedPeriod: StepDetailPeriod = .week
    @State private var dailyHourlySteps: [Int] = []
    @State private var weekOffset: Int = 0

    private var goal: Int { profiles.first?.dailyStepGoal ?? 10000 }
    private var useMetric: Bool { profiles.first?.useMetricUnits ?? true }

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    periodTabs
                    summaryCards
                    comparisonSection
                    trendsSection
                    if selectedPeriod == .day {
                        mostActiveTimeSection
                    }
                    metricsGrid
                    if selectedPeriod == .week {
                        weeklyBarChartSection
                        statisticsCards
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await stepDataManager.syncHistoricalData()
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Adım")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {}
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
            .task(id: selectedPeriod) {
                if selectedPeriod == .day {
                    dailyHourlySteps = await stepDataManager.fetchHourlyStepsForToday()
                } else {
                    dailyHourlySteps = []
                }
            }
    }

    // MARK: - Period Tabs

    private var periodTabs: some View {
        HStack(spacing: 8) {
            ForEach(StepDetailPeriod.allCases, id: \.rawValue) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedPeriod == period ? AppTheme.textPrimary(for: colorScheme) : AppTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedPeriod == period ? AppTheme.cardBackgroundSecondary(for: colorScheme) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "\(periodDayCount) Gün",
                subtitle: periodDateRange
            )
            summaryCard(
                title: "Oran",
                subtitle: goalRateText
            )
        }
    }

    private func summaryCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var periodDayCount: Int {
        switch selectedPeriod {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    private var periodDateRange: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        switch selectedPeriod {
        case .day:
            return formatter.string(from: Date())
        case .week:
            let start = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset, to: Date()) ?? Date()
            let end = calendar.date(byAdding: .day, value: -7 * weekOffset, to: Date()) ?? Date()
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            let start = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return "\(formatter.string(from: start)) - \(formatter.string(from: Date()))"
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            return "\(formatter.string(from: start)) - \(formatter.string(from: Date()))"
        }
    }

    private var goalRateText: String {
        let (reached, total) = daysReachedGoal
        guard total > 0 else { return "—" }
        let pct = Int(Double(reached) / Double(total) * 100)
        return "\(reached)/\(total) (\(pct)%)"
    }

    private var daysReachedGoal: (Int, Int) {
        let calendar = Calendar.current
        var reached = 0
        var total = 0
        switch selectedPeriod {
        case .day:
            total = 1
            reached = periodSteps >= goal ? 1 : 0
        case .week:
            total = 7
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                let steps = stepRecords
                    .filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.steps }
                if steps >= goal { reached += 1 }
            }
        case .month, .year:
            total = selectedPeriod == .month ? 30 : 365
            guard let start = calendar.date(byAdding: selectedPeriod == .month ? .day : .year, value: selectedPeriod == .month ? -30 : -1, to: Date()) else { return (0, total) }
            let end = Date()
            var check = start
            while check <= end {
                let steps = stepRecords
                    .filter { calendar.isDate($0.date, inSameDayAs: check) }
                    .reduce(0) { $0 + $1.steps }
                if steps >= goal { reached += 1 }
                check = calendar.date(byAdding: .day, value: 1, to: check) ?? check
            }
        }
        return (reached, total)
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.accentOrange)
            Text("Önceki \(selectedPeriod == .week ? "7" : selectedPeriod == .month ? "30" : "365") güne göre")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eğilimler")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accentOrange)
            Text(trendMessage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var trendMessage: String {
        let diff = stepsChangeFromPrevious
        if diff > 0 {
            return "Her zamankinden aktif 💪"
        } else if diff < 0 {
            return "Biraz daha hareket et!"
        }
        return "İstikrarlı gidiyorsun"
    }

    private var stepsChangeFromPrevious: Int {
        let current = periodSteps
        let previous = previousPeriodSteps
        guard previous > 0 else { return 0 }
        return current - previous
    }

    private var periodSteps: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            return stepRecords.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.steps }
        case .week:
            var total = 0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                total += stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.steps }
            }
            return total
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
        case .year:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.steps }
        }
    }

    private var previousPeriodSteps: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }.reduce(0) { $0 + $1.steps }
        case .week:
            var total = 0
            for offset in 7..<14 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * (weekOffset + 1) + (offset - 7), to: Date()) else { continue }
                total += stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.steps }
            }
            return total
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -60, to: Date()),
                  let end = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.steps }
        case .year:
            guard let start = calendar.date(byAdding: .year, value: -2, to: Date()),
                  let end = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.steps }
        }
    }

    // MARK: - Most Active Time (Daily)

    private var mostActiveTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("En aktif zaman")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accentOrange)
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            Text(mostActiveHourText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var mostActiveHourText: String {
        guard !dailyHourlySteps.isEmpty else { return "—" }
        guard let maxIdx = dailyHourlySteps.enumerated().max(by: { $0.element < $1.element })?.offset else { return "—" }
        let startHour = String(format: "%02d:00", maxIdx)
        let endHour = String(format: "%02d:00", min(maxIdx + 1, 23))
        return "\(startHour) - \(endHour)"
    }

    // MARK: - Steps Change

    private var stepsChangeText: String {
        let diff = stepsChangeFromPrevious
        if diff > 0 { return "+\(diff)" }
        if diff < 0 { return "\(diff)" }
        return "0"
    }

    private var stepsChangePositive: Bool { stepsChangeFromPrevious >= 0 }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepsChangeCard
            metricsGridContent
        }
    }

    private var stepsChangeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adım değişimi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accentOrange)
            Text(stepsChangeText)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(stepsChangePositive ? AppTheme.success : AppTheme.error)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var metricsGridContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            detailMetricCard(icon: "figure.walk", value: formatNumber(periodSteps), change: stepsChangeText, label: "Adım")
            detailMetricCard(icon: "map.fill", value: formatDistance(periodDistance), change: formatDistanceChange(periodDistance - previousPeriodDistance), label: "Mesafe")
            detailMetricCard(icon: "flame.fill", value: "\(periodCalories) Kcal", change: "\(periodCalories - previousPeriodCalories >= 0 ? "+" : "")\(periodCalories - previousPeriodCalories)", label: "Kalori")
            detailMetricCard(icon: "clock.fill", value: formatDuration(periodActiveMinutes), change: "\(periodActiveMinutes - previousPeriodActiveMinutes >= 0 ? "+" : "")\(formatShortDuration(periodActiveMinutes - previousPeriodActiveMinutes))", label: "Süre")
            detailMetricCard(icon: "mountain.2.fill", value: periodElevationText, change: elevationChangeText, label: "Rakım")
            detailMetricCard(icon: "arrow.up.right", value: "\(periodFloorsAscended) kat", change: "\(periodFloorsAscended - previousPeriodFloorsAscended >= 0 ? "+" : "")\(periodFloorsAscended - previousPeriodFloorsAscended)", label: "Kat Çıkılan")
        }
    }

    private func detailMetricCard(icon: String, value: String, change: String, label: String) -> some View {
        let isPositive = !change.hasPrefix("-") && change != "0"
        return VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.accentOrange)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text(change)
                .font(.system(size: 13))
                .foregroundStyle(isPositive ? AppTheme.success : AppTheme.textSecondary(for: colorScheme))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var periodDistance: Double {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            let rec = stepRecords.first { calendar.isDateInToday($0.date) }
            return rec?.distance ?? ActivityCalculator.distanceFromSteps(periodSteps, profile: profiles.first)
        case .week:
            var total = 0.0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                let steps = stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.steps }
                let rec = stepRecords.first { calendar.isDate($0.date, inSameDayAs: date) }
                total += rec?.distance ?? ActivityCalculator.distanceFromSteps(steps, profile: profiles.first)
            }
            return total
        case .month, .year:
            guard let start = calendar.date(byAdding: selectedPeriod == .month ? .day : .year, value: selectedPeriod == .month ? -30 : -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0.0) { $0 + $1.distance }
        }
    }

    private var previousPeriodDistance: Double {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
            let steps = stepRecords.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }.reduce(0) { $0 + $1.steps }
            let rec = stepRecords.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
            return rec?.distance ?? ActivityCalculator.distanceFromSteps(steps, profile: profiles.first)
        default:
            return 0
        }
    }

    private var periodCalories: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            let rec = stepRecords.first { calendar.isDateInToday($0.date) }
            return rec?.calories ?? ActivityCalculator.caloriesFromSteps(periodSteps, profile: profiles.first)
        case .week:
            var total = 0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                let rec = stepRecords.first { calendar.isDate($0.date, inSameDayAs: date) }
                total += rec?.calories ?? 0
            }
            return total > 0 ? total : ActivityCalculator.caloriesFromSteps(periodSteps, profile: profiles.first)
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            let cal = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.calories }
            return cal > 0 ? cal : ActivityCalculator.caloriesFromSteps(periodSteps, profile: profiles.first)
        case .year:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            let cal = stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.calories }
            return cal > 0 ? cal : ActivityCalculator.caloriesFromSteps(periodSteps, profile: profiles.first)
        }
    }

    private var previousPeriodCalories: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        let rec = stepRecords.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
        return rec?.calories ?? 0
    }

    private var periodActiveMinutes: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            return stepRecords.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.activeMinutes }
        case .week:
            var total = 0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                total += stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.activeMinutes }
            }
            return total
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.activeMinutes }
        case .year:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.activeMinutes }
        }
    }

    private var previousPeriodActiveMinutes: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        return stepRecords.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }.reduce(0) { $0 + $1.activeMinutes }
    }

    private var periodFloorsAscended: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            return stepRecords.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.floorsAscended }
        case .week:
            var total = 0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
                total += stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.floorsAscended }
            }
            return total
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.floorsAscended }
        case .year:
            guard let start = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            return stepRecords.filter { $0.date >= start }.reduce(0) { $0 + $1.floorsAscended }
        }
    }

    private var previousPeriodFloorsAscended: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        return stepRecords.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }.reduce(0) { $0 + $1.floorsAscended }
    }

    private var periodElevationText: String {
        let meters = Double(periodFloorsAscended) * 3.0
        if useMetric {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.0f ft", meters * 3.281)
        }
    }

    private var elevationChangeText: String {
        let diff = periodFloorsAscended - previousPeriodFloorsAscended
        let meters = Double(diff) * 3.0
        if useMetric {
            return "\(diff >= 0 ? "+" : "")\(Int(meters)) m"
        } else {
            return "\(diff >= 0 ? "+" : "")\(Int(meters * 3.281)) ft"
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyBarChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            weeklyChartNavigation
            weeklyChartBars
            weeklyChartLegend
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var weeklyChartNavigation: some View {
        HStack {
            Button { weekOffset -= 1 } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }
            Spacer()
            Text(periodDateRange)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Spacer()
            Button { weekOffset += 1 } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }
        }
    }

    private var weeklyChartBars: some View {
        let data = weeklyChartData
        let maxSteps = max(data.0.max() ?? 1, goal, 1)
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.0.enumerated()), id: \.offset) { i, steps in
                weeklyBarColumn(steps: steps, label: data.1[i], maxSteps: maxSteps)
            }
        }
        .frame(height: 160)
    }

    private func weeklyBarColumn(steps: Int, label: String, maxSteps: Int) -> some View {
        let reached = steps >= goal
        let barHeight = max(20.0, CGFloat(steps) / CGFloat(maxSteps) * 120)
        return VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    reached
                        ? AnyShapeStyle(LinearGradient(colors: [AppTheme.accentOrange, AppTheme.accentRed], startPoint: .bottom, endPoint: .top))
                        : AnyShapeStyle(AppTheme.cardBackgroundSecondary(for: colorScheme))
                )
                .frame(height: barHeight)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyChartLegend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [AppTheme.accentOrange, AppTheme.accentRed], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 12, height: 12)
                Text("Başarıldı")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 12, height: 12)
                Text("Başarılmadı")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
    }

    private var weeklyChartData: ([Int], [String]) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var steps: [Int] = []
        var labels: [String] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + offset, to: Date()) else { continue }
            let s = stepRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.steps }
            steps.append(s)
            labels.append(String(formatter.string(from: date).prefix(1)))
        }
        return (steps, labels)
    }

    // MARK: - Statistics Cards (En Aktif / En Rahatlatıcı)

    private var statisticsCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.accentOrange)
                Text("İstatistikler (\(periodDateRange))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }

            HStack(spacing: 12) {
                if let best = mostActiveDayThisWeek {
                    statCard(
                        icon: "medal.fill",
                        title: "En Aktif Gün",
                        value: "\(formatNumber(best.steps)) Adım",
                        date: formatShortDate(best.date)
                    )
                }
                if let relax = mostRelaxingDayThisWeek {
                    statCard(
                        icon: "sofa.fill",
                        title: "En Rahatlatıcı Gün",
                        value: "\(formatNumber(relax.steps)) Adım",
                        date: formatShortDate(relax.date)
                    )
                }
            }
        }
    }

    private func statCard(icon: String, title: String, value: String, date: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.accentOrange)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Text(date)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var mostActiveDayThisWeek: (date: Date, steps: Int)? {
        let (steps, _) = weeklyChartData
        let calendar = Calendar.current
        guard let maxIdx = steps.enumerated().max(by: { $0.element < $1.element }), maxIdx.element > 0 else { return nil }
        guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + maxIdx.offset, to: Date()) else { return nil }
        return (date, maxIdx.element)
    }

    private var mostRelaxingDayThisWeek: (date: Date, steps: Int)? {
        let (steps, _) = weeklyChartData
        let calendar = Calendar.current
        guard let minIdx = steps.enumerated().min(by: { $0.element < $1.element }), minIdx.element >= 0 else { return nil }
        guard let date = calendar.date(byAdding: .day, value: -6 - 7 * weekOffset + minIdx.offset, to: Date()) else { return nil }
        return (date, minIdx.element)
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        NumberFormatter.stepsFormatter.string(from: NSNumber(value: n)) ?? "0"
    }

    private func formatDistance(_ km: Double) -> String {
        useMetric ? String(format: "%.2f Km", km) : String(format: "%.2f mi", km / 1.609)
    }

    private func formatDistanceChange(_ diff: Double) -> String {
        let prefix = diff >= 0 ? "+" : ""
        return useMetric ? "\(prefix)\(String(format: "%.2f", diff))" : "\(prefix)\(String(format: "%.2f", diff / 1.609))"
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h):\(String(format: "%02d", m)) sa" }
        return "\(m) dk"
    }

    private func formatShortDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h != 0 { return "\(h):\(String(format: "%02d", m))" }
        return "\(m)dk"
    }

    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }
}
