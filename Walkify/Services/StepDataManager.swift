//
//  StepDataManager.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

/// Pedometer verilerini SwiftData ile senkronize eden yönetici
@Observable
final class StepDataManager {
    private let stepService = StepCounterService()
    private var modelContext: ModelContext?

    var todaySteps: Int = 0
    var todayDistance: Double = 0
    var todayCalories: Int = 0
    var todayFloorsAscended: Int = 0
    var todayFloorsDescended: Int = 0
    var isSyncing: Bool = false

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        syncWidgetData()
    }

    /// Widget için mevcut veriyi App Group'a yaz (streak + haftalık özet dahil)
    func syncWidgetData() {
        guard let modelContext else { return }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let descriptor = FetchDescriptor<StepRecord>(
            predicate: #Predicate<StepRecord> { record in
                record.date >= startOfToday && record.date < endOfToday
            }
        )
        let todayRecord = try? modelContext.fetch(descriptor).first
        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
        let goal = profile?.dailyStepGoal ?? 10000
        let allRecords = (try? modelContext.fetch(FetchDescriptor<StepRecord>())) ?? []
        let streak = StreakManager.currentStreak(stepRecords: allRecords, goal: goal)
        let (daysReachedThisWeek, _) = StreakManager.daysReachedGoalThisWeek(stepRecords: allRecords, goal: goal)

        if let record = todayRecord {
            WidgetDataWriter.write(
                steps: record.steps,
                goal: goal,
                distance: record.distance,
                calories: record.calories,
                useMetric: profile?.useMetricUnits ?? true,
                currentStreak: streak,
                daysReachedThisWeek: daysReachedThisWeek
            )
        } else {
            WidgetDataWriter.write(
                steps: todaySteps,
                goal: goal,
                distance: todayDistance,
                calories: todayCalories,
                useMetric: profile?.useMetricUnits ?? true,
                currentStreak: streak,
                daysReachedThisWeek: daysReachedThisWeek
            )
        }
    }

    /// Bugünkü adımları başlat (Overview için real-time)
    func startLiveUpdates() {
        stepService.startTodayStepCounting { [weak self] steps, distance, calories, floorsUp, floorsDown in
            guard let self else { return }
            self.todaySteps = steps
            self.todayDistance = distance
            self.todayCalories = calories
            self.todayFloorsAscended = floorsUp
            self.todayFloorsDescended = floorsDown
            self.saveTodayRecord(steps: steps, distance: distance, calories: calories, floorsAscended: floorsUp, floorsDescended: floorsDown)
        }
    }

    func stopLiveUpdates() {
        stepService.stopUpdates()
    }

    /// Performance (Daily) grafiği için bugünün saatlik adım sayıları
    func fetchHourlyStepsForToday() async -> [Int] {
        await stepService.queryHourlyStepsForToday()
    }

    /// Bugünkü kaydı kaydet veya güncelle (profil varsa kişiselleştirilmiş hesaplama)
    private func saveTodayRecord(steps: Int, distance: Double, calories: Int, floorsAscended: Int = 0, floorsDescended: Int = 0) {
        guard let modelContext else { return }

        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
        guard profile?.isStepTrackingPaused != true else { return }
        let (calcDistance, calcCalories) = ActivityCalculator.distanceAndCalories(from: steps, profile: profile)
        let finalDistance = profile != nil ? calcDistance : distance
        let finalCalories = profile != nil ? calcCalories : calories

        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<StepRecord>(
            predicate: #Predicate<StepRecord> { record in
                record.date >= startOfDay && record.date < endOfDay
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first
            let previousSteps = existing?.steps ?? 0
            let goalReached = steps >= (profile?.dailyStepGoal ?? 10000) && previousSteps < (profile?.dailyStepGoal ?? 10000)

            if let record = existing {
                record.steps = steps
                record.distance = finalDistance
                record.calories = finalCalories
                record.activeMinutes = steps / 100
                record.floorsAscended = floorsAscended
                record.floorsDescended = floorsDescended
            } else {
                let record = StepRecord(
                    date: calendar.startOfDay(for: today),
                    steps: steps,
                    distance: finalDistance,
                    calories: finalCalories,
                    activeMinutes: steps / 100,
                    floorsAscended: floorsAscended,
                    floorsDescended: floorsDescended
                )
                modelContext.insert(record)
            }

            try modelContext.save()

            let goal = profile?.dailyStepGoal ?? 10000
            let useMetric = profile?.useMetricUnits ?? true
            let allRecords = (try? modelContext.fetch(FetchDescriptor<StepRecord>())) ?? []
            let streak = StreakManager.currentStreak(stepRecords: allRecords, goal: goal)
            let (daysReachedThisWeek, _) = StreakManager.daysReachedGoalThisWeek(stepRecords: allRecords, goal: goal)
            WidgetDataWriter.write(
                steps: steps,
                goal: goal,
                distance: finalDistance,
                calories: finalCalories,
                useMetric: useMetric,
                currentStreak: streak,
                daysReachedThisWeek: daysReachedThisWeek
            )

            if goalReached {
                NotificationService.shared.scheduleGoalCelebration(streak: streak)
            }

            BadgeChecker.checkAndAwardBadges(modelContext: modelContext, stepRecords: allRecords, profile: profile)
        } catch {
            #if DEBUG
            print("StepDataManager save error: \(error)")
            #endif
        }
    }

    /// Geçmiş günlerin verilerini senkronize et (uygulama açıldığında)
    func syncHistoricalData() async {
        guard let modelContext, !isSyncing else { return }
        isSyncing = true

        defer { isSyncing = false }

        let results = await stepService.queryLastDays(7)
        let calendar = Calendar.current

        await MainActor.run {
            for (date, steps, distance, floorsUp, floorsDown) in results {
                let startOfDay = calendar.startOfDay(for: date)

                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                let descriptor = FetchDescriptor<StepRecord>(
                    predicate: #Predicate<StepRecord> { record in
                        record.date >= startOfDay && record.date < endOfDay
                    }
                )

                do {
                    let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
                    let (calcDistance, calcCalories) = ActivityCalculator.distanceAndCalories(from: steps, profile: profile)

                    let existing = try modelContext.fetch(descriptor).first

                    if let record = existing {
                        record.steps = steps
                        record.distance = calcDistance
                        record.calories = calcCalories
                        record.activeMinutes = steps / 100
                        record.floorsAscended = floorsUp
                        record.floorsDescended = floorsDown
                    } else if steps > 0 || distance > 0 {
                        let record = StepRecord(
                            date: startOfDay,
                            steps: steps,
                            distance: calcDistance,
                            calories: calcCalories,
                            activeMinutes: steps / 100,
                            floorsAscended: floorsUp,
                            floorsDescended: floorsDown
                        )
                        modelContext.insert(record)
                    }
                } catch {
                    #if DEBUG
                    print("Sync error for \(date): \(error)")
                    #endif
                }
            }

            try? modelContext.save()
            syncWidgetData()

            let allRecords = (try? modelContext.fetch(FetchDescriptor<StepRecord>())) ?? []
            let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
            BadgeChecker.checkAndAwardBadges(modelContext: modelContext, stepRecords: allRecords, profile: profile)
        }
    }
}
