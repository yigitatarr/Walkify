//
//  OverviewView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData
import UIKit

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \StepRecord.date, order: .reverse) private var stepRecords: [StepRecord]
    @Query private var profiles: [UserProfile]
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse) private var earnedBadges: [EarnedBadge]
    @State private var showNotifications = false
    @State private var showBadges = false
    @State private var showWidgetSheet = false
    @Environment(StepDataManager.self) private var stepDataManager

    private var todayRecord: StepRecord? {
        stepRecords.first { Calendar.current.isDateInToday($0.date) }
    }

    private var weeklyData: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dayKey = formatter.string(from: date).uppercased().prefix(3)
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.steps }
            return (String(dayKey), steps)
        }
    }

    private var userProfile: UserProfile? { profiles.first }
    private var goal: Int { userProfile?.dailyStepGoal ?? 10000 }
    private var stepsToday: Int { todayRecord?.steps ?? 0 }
    private var stepsLeft: Int { max(0, goal - stepsToday) }
    private var distanceKm: Double { todayRecord?.distance ?? ActivityCalculator.distanceFromSteps(stepsToday, profile: userProfile) }
    private var distance: String {
        let km = distanceKm
        if userProfile?.useMetricUnits ?? true {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.1f mi", km / 1.609)
        }
    }
    private var calories: Int { todayRecord?.calories ?? ActivityCalculator.caloriesFromSteps(stepsToday, profile: userProfile) }
    private var activeMinutes: Int { todayRecord?.activeMinutes ?? (stepsToday / 100) }
    private var floorsAscended: Int { todayRecord?.floorsAscended ?? stepDataManager.todayFloorsAscended }
    private var elevationText: String {
        let meters = todayRecord?.elevationGainMeters ?? Double(floorsAscended) * 3.0
        if userProfile?.useMetricUnits ?? true {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.0f ft", meters * 3.281)
        }
    }

    private var dailyInsightText: String {
        let calendar = Calendar.current
        guard let lastWeekSameDay = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) else {
            return "Günlük hedefine ulaşmak için yürümeye devam et!"
        }
        let lastWeekSteps = stepRecords
            .filter { calendar.isDate($0.date, inSameDayAs: lastWeekSameDay) }
            .reduce(0) { $0 + $1.steps }
        let currentSteps = stepsToday
        guard lastWeekSteps > 0 else {
            return "Bugün yürüyüş yolculuğuna başla!"
        }
        let percent = ((currentSteps - lastWeekSteps) * 100) / lastWeekSteps
        if percent > 0 {
            return "Geçen \(weekdayName(from: lastWeekSameDay))'e göre %\(percent) daha aktifsin. Devam et!"
        } else if percent < 0 {
            return "Geçen \(weekdayName(from: lastWeekSameDay))'e göre %\(-percent) daha az aktifsin. Biraz daha yürüyelim!"
        } else {
            return "Geçen \(weekdayName(from: lastWeekSameDay))'le aynı tempoda. Biraz daha zorlayalım!"
        }
    }

    private func weekdayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var currentStreak: Int {
        StreakManager.currentStreak(stepRecords: stepRecords, goal: goal)
    }

    private var weeklySteps: Int {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.steps }
    }

    private var weeklyAverage: Int {
        let (_, total) = StreakManager.daysReachedGoalThisWeek(stepRecords: stepRecords, goal: goal)
        guard total > 0 else { return 0 }
        return weeklySteps / total
    }

    private var daysReachedGoalThisWeek: (Int, Int) {
        StreakManager.daysReachedGoalThisWeek(stepRecords: stepRecords, goal: goal)
    }

    private var totalDistanceThisWeek: Double {
        stepRecords
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0.0) { $0 + $1.distance }
    }

    private var stageMessage: String {
        let (reached, total) = daysReachedGoalThisWeek
        if currentStreak >= 7 {
            return "\(currentStreak) günlük seri! Hızını koru! 💪"
        }
        if currentStreak >= 3 {
            return "\(currentStreak) günlük seri devam ediyor. Harikasın!"
        }
        if stepsToday >= goal {
            return "Bugün hedefe ulaştın! Yarın da devam et 🎯"
        }
        if stepsLeft > 0 && stepsLeft <= goal / 4 {
            return "Neredeyse bitti! \(formatNumber(stepsLeft)) adım kaldı."
        }
        if reached > 0 && total > 0 {
            return "Bu hafta \(reached)/\(total) gün hedefe ulaştın."
        }
        return "Her adım seni hedefe yaklaştırıyor!"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<17: return "İyi günler"
        default: return "İyi akşamlar"
        }
    }

    var body: some View {
        NavigationStack {
        ScrollView {
            if stepDataManager.isSyncing {
                ProgressView()
                    .tint(AppTheme.accentOrange)
                    .padding(.top, 8)
            }
            VStack(spacing: 24) {
                // Header
                headerSection

                // Bugün + Haftalık hedef kartı (aşama göstergesi)
                weeklyGoalCard

                // Ana adım kartı - daire + haftalık ortalama + Geçmiş / Paylaş
                mainStepCard

                // Seri ve motivasyon bölümü
                streakMotivationSection

                // Duraklat / Devam et butonu
                Button {
                    userProfile?.isStepTrackingPaused.toggle()
                    try? modelContext.save()
                    if userProfile?.isStepTrackingPaused == true {
                        stepDataManager.stopLiveUpdates()
                    } else {
                        stepDataManager.startLiveUpdates()
                        Task {
                            await stepDataManager.syncHistoricalData()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: (userProfile?.isStepTrackingPaused ?? false) ? "play.circle.fill" : "pause.circle.fill")
                        Text((userProfile?.isStepTrackingPaused ?? false) ? "Sayacı Başlat" : "Sayacı Duraklat")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle((userProfile?.isStepTrackingPaused ?? false) ? AppTheme.success : AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cardBackground(for: colorScheme))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                // Goal & Left & Streak
                HStack(spacing: 16) {
                    labelValue("HEDEF", value: formatNumber(goal))
                    Rectangle()
                        .fill(AppTheme.textMuted(for: colorScheme).opacity(0.5))
                        .frame(width: 1, height: 20)
                    labelValue("KALAN", value: formatNumber(stepsLeft))
                    if currentStreak > 0 {
                        Rectangle()
                            .fill(AppTheme.textMuted(for: colorScheme).opacity(0.5))
                            .frame(width: 1, height: 20)
                        labelValue("SERİ", value: "🔥 \(currentStreak)")
                    }
                }
                .padding(.vertical, 8)

                // Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(icon: "map.fill", value: distance, label: "MESAFE")
                    MetricCard(icon: "flame.fill", value: "\(calories) kcal", label: "KALORİ", iconColor: AppTheme.accentOrange)
                    MetricCard(icon: "clock.fill", value: formatTime(activeMinutes), label: "SÜRE", iconColor: AppTheme.accentRed)
                    MetricCard(icon: "mountain.2.fill", value: elevationText, label: "RAKIM", iconColor: Color(red: 0.3, green: 0.7, blue: 0.4))
                }

                // Rapor (haftalık özet + Ayrıntı)
                reportSection

                // Daily Insight
                dailyInsightCard

                // Rozetler
                if !earnedBadges.isEmpty {
                    badgesSection
                }

                // Widget seçimi - ana ekrana koyulacak widget
                widgetSection
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await stepDataManager.syncHistoricalData()
        }
        .background(AppTheme.background(for: colorScheme))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(onDismiss: { showNotifications = false })
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showWidgetSheet) {
            WidgetSheet(onDismiss: { showWidgetSheet = false })
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showBadges) {
            BadgesView(onDismiss: { showBadges = false })
                .presentationDetents([.medium, .large])
        }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .top) {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        )
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(AppTheme.background(for: colorScheme), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bugün")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text("\(greeting), \(userProfile?.name ?? "Kullanıcı")")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            Button { showNotifications = true } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Haftalık hedef kartı (referans: Sahara Çölü tarzı)
    private var weeklyGoalCard: some View {
        let (reached, total) = daysReachedGoalThisWeek
        let progress = total > 0 ? Double(reached) / Double(total) : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bu hafta hedef")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text("\(total - reached) gün kaldı")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppTheme.accentOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(reached)/\(total)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.accentGradient)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Ana adım kartı (haftalık ortalama + Geçmiş + Paylaş)
    private var mainStepCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                StepProgressCircle(steps: stepsToday, goal: goal)
                    .frame(width: 220, height: 220)
                    .opacity((userProfile?.isStepTrackingPaused ?? false) ? 0.6 : 1)

                if userProfile?.isStepTrackingPaused == true {
                    VStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Text("Duraklatıldı")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .padding(.bottom, 30)
                }
            }

            Text("Haftalık ortalama \(formatNumber(weeklyAverage))")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: 12) {
                NavigationLink {
                    StepDetailsView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                        Text("Geçmiş")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    shareSteps()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Paylaş")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accentOrange.opacity(0.2))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
        )
    }

    private func shareSteps() {
        let text = "Bugün \(formatNumber(stepsToday)) adım attım! 🚶‍♂️ #Walkify"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }

    // MARK: - Seri ve motivasyon (günler + mesaj)
    private var streakMotivationSection: some View {
        let goalPerDay = goalReachedPerDay
        return VStack(alignment: .leading, spacing: 12) {
            if currentStreak > 0 {
                HStack(spacing: 8) {
                    Text("x\(currentStreak)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("gün seri")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(goalPerDay.enumerated()), id: \.offset) { i, item in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(item.0 ? AppTheme.accentOrange : AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(item.1)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(item.0 ? .white : AppTheme.textSecondary(for: colorScheme))
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(stageMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.accentOrange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
        )
    }

    private var goalReachedPerDay: [(Bool, String)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "tr_TR")
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.steps }
            return (steps >= goal, String(formatter.string(from: date).prefix(1)))
        }
    }

    private func labelValue(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
        }
    }

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rapor")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Spacer()
                NavigationLink {
                    StepDetailsView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Ayrıntı")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
            }

            let maxSteps = max(weeklyData.map(\.1).max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentOrange, AppTheme.accentRed],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(24, CGFloat(item.1) / CGFloat(maxSteps) * 100))

                        Text(item.0)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
        )
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rozetler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Spacer()
                Button { showBadges = true } label: {
                    Text("Tümü")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.warning)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(earnedBadges.prefix(6), id: \.id) { badge in
                        if let type = badge.type {
                            BadgeChip(badgeType: type)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var widgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ana Sayfa Widget'ı")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Button { showWidgetSheet = true } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accentOrange.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accentOrange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Widget seç ve ekle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Text("Küçük, Orta veya Büyük – ana ekranda adım sayını gör")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
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
        }
    }

    private var dailyInsightCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentOrange.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.accentOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Günlük İpucu")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text(dailyInsightText)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
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

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        NumberFormatter.stepsFormatter.string(from: NSNumber(value: n)) ?? "0"
    }

    private func formatTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

}

#Preview {
    OverviewView()
        .environment(StepDataManager())
        .modelContainer(for: [StepRecord.self, UserProfile.self, EarnedBadge.self], inMemory: true)
}
