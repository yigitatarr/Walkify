//
//  BadgeChecker.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

/// Yeni rozet kazanımlarını kontrol eder
struct BadgeChecker {

    static func checkAndAwardBadges(
        modelContext: ModelContext,
        stepRecords: [StepRecord],
        profile: UserProfile?
    ) {
        let earned = Set((try? modelContext.fetch(FetchDescriptor<EarnedBadge>()))?.compactMap(\.type) ?? [])
        let goal = profile?.dailyStepGoal ?? 10000

        // Günlük max adım rozetleri
        let stepBadges: [(BadgeType, Int)] = [
            (.thousandSteps, 1000), (.fiveThousand, 5000), (.tenThousand, 10000),
            (.fifteenThousand, 15000), (.twentyThousand, 20000)
        ]
        let maxDay = stepRecords.map(\.steps).max() ?? 0
        for (type, threshold) in stepBadges {
            if maxDay >= threshold, !earned.contains(type) {
                award(type, context: modelContext)
            }
        }

        // Streak rozetleri
        let streak = StreakManager.currentStreak(stepRecords: stepRecords, goal: goal)
        if streak >= 7, !earned.contains(.weekStreak) { award(.weekStreak, context: modelContext) }
        if streak >= 14, !earned.contains(.twoWeekStreak) { award(.twoWeekStreak, context: modelContext) }
        if streak >= 30, !earned.contains(.monthStreak) { award(.monthStreak, context: modelContext) }

        // Toplam mesafe
        let totalKm = stepRecords.reduce(0) { $0 + $1.distance }
        if totalKm >= 100, !earned.contains(.hundredKm) { award(.hundredKm, context: modelContext) }

        // Erken kuş: sabah 7'den önce 5000+ adım
        let calendar = Calendar.current
        let earlyBirdDays = stepRecords.filter { record in
            let hour = calendar.component(.hour, from: record.date)
            return hour < 7 && record.steps >= 5000
        }
        if !earlyBirdDays.isEmpty, !earned.contains(.earlyBird) { award(.earlyBird, context: modelContext) }

        // Gece kuşu: akşam 22'den sonra 5000+ adım
        let nightOwlDays = stepRecords.filter { record in
            let hour = calendar.component(.hour, from: record.date)
            return hour >= 22 && record.steps >= 5000
        }
        if !nightOwlDays.isEmpty, !earned.contains(.nightOwl) { award(.nightOwl, context: modelContext) }

        // İlk adım (en az 1 kayıt)
        if !stepRecords.isEmpty, !earned.contains(.firstSteps) { award(.firstSteps, context: modelContext) }

        try? modelContext.save()
    }

    private static func award(_ type: BadgeType, context: ModelContext) {
        context.insert(EarnedBadge(badgeType: type))
    }
}
